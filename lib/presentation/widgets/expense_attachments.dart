import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

const maxReceiptBytes = 10 * 1024 * 1024;
bool validReceiptSize(int size) => size > 0 && size <= maxReceiptBytes;

String receiptFailureKey(Object failure) {
  if (failure is PlatformException &&
      (failure.code.contains('access_denied') ||
          failure.code.contains('permission'))) {
    return 'receipt_permission_error';
  }
  if (failure is TimeoutException) return 'receipt_timeout_error';
  return 'receipt_error';
}

class ExpenseAttachments extends StatefulWidget {
  final String expenseId;
  final bool canEdit;
  const ExpenseAttachments({
    super.key,
    required this.expenseId,
    required this.canEdit,
  });
  @override
  State<ExpenseAttachments> createState() => _ExpenseAttachmentsState();
}

class _ExpenseAttachmentsState extends State<ExpenseAttachments> {
  bool busy = false;
  String? error;
  String _operation = 'receipt_select';
  List<Map<String, dynamic>> files = [];
  late InstantDB db;
  void Function()? disposeQuery;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (disposeQuery != null) return;
    db = InstantProvider.of(context);
    // Query file metadata directly: the SDK misclassifies entities in nested file queries.
    final signal = db.query({
      r'$files': {
        'where': {
          'path': {r'$like': '%/${widget.expenseId}/%'},
        },
      },
    });
    disposeQuery = effect(() {
      final result = signal.value;
      final rows = result.data?[r'$files'] as List? ?? [];
      if (mounted) {
        setState(() {
          files = rows.map((r) => Map<String, dynamic>.from(r)).toList();
          if (result.hasError) {
            error = '${'receipt_load'.tr()} : ${'receipt_error'.tr()}';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    disposeQuery?.call();
    super.dispose();
  }

  Future<void> run(Future<void> Function() task) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await task();
    } catch (failure) {
      if (mounted) {
        setState(
          () =>
              error = '${_operation.tr()} : ${receiptFailureKey(failure).tr()}',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pick(String source) => run(() async {
    _operation = 'receipt_select';
    XFile? file;
    if (source == 'file') {
      final result = await FilePicker.pickFile();
      if (result == null) return;
      file = result.xFile;
    } else {
      file = await ImagePicker().pickImage(
        source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
      );
    }
    if (file == null) return;
    _operation = 'receipt_read';
    if (!validReceiptSize(await file.length())) {
      if (mounted) setState(() => error = 'receipt_size'.tr());
      return;
    }
    final uid = db.auth.currentUser.value?.id;
    if (uid == null) throw StateError('Unauthenticated');
    final name = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._ -]'), '_');
    final path = '$uid/${widget.expenseId}/${db.id()}/$name';
    final bytes = await file.readAsBytes();
    if (!validReceiptSize(bytes.length)) throw StateError('Invalid file size');
    final ext = name.split('.').last.toLowerCase();
    final type =
        {
          'jpg': 'image/jpeg',
          'jpeg': 'image/jpeg',
          'png': 'image/png',
          'heic': 'image/heic',
          'pdf': 'application/pdf',
        }[ext] ??
        'application/octet-stream';
    _operation = 'receipt_upload';
    final uploaded = await db.storage.uploadFile(
      path,
      bytes,
      contentType: type,
    );
    try {
      _operation = 'receipt_link';
      final id = uploaded.id.isNotEmpty
          ? uploaded.id
          : await _uploadedFileId(path);
      await db.transact(
        // shortcut: SDK 2.2.2 drops link operations; update the existing ref attribute until the SDK supports them.
        db.tx['expenses'][widget.expenseId].update({'files': id}),
      );
    } catch (_) {
      // Remove an upload that could not be associated with its expense.
      try {
        await db.storage.delete(path);
      } catch (_) {
        // Keep the original linking failure if cleanup also fails.
      }
      rethrow;
    }
  });
  Future<String> _uploadedFileId(String path) async {
    final result = Completer<String>();
    final signal = db.subscribeQuery({
      r'$files': {
        'where': {'path': path},
      },
    });
    final stop = effect(() {
      if (result.isCompleted) return;
      final value = signal.value;
      if (value.hasError) {
        result.completeError(StateError(value.error ?? 'File query failed'));
        return;
      }
      final rows = value.data?[r'$files'] as List? ?? [];
      if (rows.isNotEmpty) result.complete(rows.first['id'] as String);
    });
    try {
      return await result.future.timeout(const Duration(seconds: 30));
    } finally {
      stop();
    }
  }

  Future<void> open(Map<String, dynamic> file) => run(() async {
    _operation = 'receipt_open';
    final url = Uri.parse(
      await db.storage.getDownloadUrl(file['path'] as String),
    );
    if (url.scheme != 'https' && url.scheme != 'http') {
      throw StateError('Invalid download URL');
    }
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw StateError('Cannot open receipt');
    }
  });
  Future<void> remove(Map<String, dynamic> file) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('delete_confirmation_title'.tr()),
        content: Text('receipt_delete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text('delete'.tr()),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      await run(() async {
        _operation = 'receipt_remove';
        await db.storage.delete(file['path'] as String);
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.canEdit)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                ('camera', Icons.photo_camera_outlined, 'receipt_camera'),
                ('gallery', Icons.photo_library_outlined, 'receipt_gallery'),
                ('file', Icons.attach_file, 'receipt_file'),
              ])
                OutlinedButton.icon(
                  onPressed: busy ? null : () => pick(item.$1),
                  icon: Icon(item.$2),
                  label: Text(item.$3.tr()),
                ),
            ],
          ),
        Text(
          'receipt_limit'.tr(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (busy) const LinearProgressIndicator(),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (files.isEmpty && !busy)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text('receipt_empty'.tr()),
          ),
        ...files.map(
          (f) => ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text((f['path'] as String).split('/').last),
            onTap: busy ? null : () => open(f),
            trailing: widget.canEdit
                ? IconButton(
                    tooltip: 'delete'.tr(),
                    onPressed: busy ? null : () => remove(f),
                    icon: const Icon(Icons.delete_outline),
                  )
                : null,
          ),
        ),
      ],
    ),
  );
}
