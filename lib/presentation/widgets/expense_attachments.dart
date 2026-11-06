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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !busy,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          if (widget.canEdit) ...[
            Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final item in [
                    ('camera', Icons.photo_camera_outlined, 'receipt_camera'),
                    (
                      'gallery',
                      Icons.photo_library_outlined,
                      'receipt_gallery',
                    ),
                    ('file', Icons.attach_file, 'receipt_file'),
                  ])
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      leading: Icon(
                        item.$2,
                        color: theme.colorScheme.onSurface,
                      ),
                      title: Text(item.$3.tr()),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      enabled: !busy,
                      onTap: () => pick(item.$1),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('receipt_limit'.tr(), style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
          ],
          if (busy) ...[
            Text(_operation.tr(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
            const SizedBox(height: 24),
          ],
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (files.isEmpty && !busy)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.receipt_long_outlined,
                      size: 28,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'receipt_empty'.tr(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ...files.map(
            (f) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const Icon(Icons.insert_drive_file_outlined),
                title: Text(
                  (f['path'] as String).split('/').last,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: busy ? null : () => open(f),
                trailing: widget.canEdit
                    ? IconButton(
                        tooltip: 'delete'.tr(),
                        onPressed: busy ? null : () => remove(f),
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                      )
                    : const Icon(Icons.open_in_new, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
