import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _key = GlobalKey<FormBuilderState>();
  User? _user;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
  }

  Future<void> _update() async {
    if (!(_key.currentState?.saveAndValidate() ?? false)) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'name': (_key.currentState!.value['name'] as String).trim()},
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('profile_updated'.tr())));
      }
    } catch (e) {
      _err(e is AuthException ? e.message : 'error_unexpected'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'logout'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text('logout_confirmation'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(
              'logout'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    }
  }

  void _err(String m) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: Theme.of(context).colorScheme.error,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'account'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FormBuilder(
          key: _key,
          initialValue: {
            'name': _user?.userMetadata?['name'] ?? '',
            'email': _user?.email ?? '',
          },
          child: Column(
            children: [
              _avatar(t),
              const SizedBox(height: 32),
              _field(
                'name',
                'full_name'.tr(),
                Icons.person_outline_rounded,
                t,
                validator: FormBuilderValidators.compose([
                  FormBuilderValidators.required(),
                  FormBuilderValidators.minLength(2),
                ]),
              ),
              const SizedBox(height: 16),
              _field(
                'email',
                'email'.tr(),
                Icons.email_outlined,
                t,
                enabled: false,
              ),
              const SizedBox(height: 32),
              if (_loading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _update,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: t.colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'update_profile'.tr(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _showPwDialog(context),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'change_password'.tr(),
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Colors.red),
                label: Text(
                  'logout'.tr(),
                  style: GoogleFonts.outfit(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(ThemeData t) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: t.colorScheme.primary.withValues(alpha: 0.2),
        width: 2,
      ),
    ),
    child: CircleAvatar(
      radius: 50,
      backgroundColor: t.colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person_rounded, size: 50, color: t.colorScheme.primary),
    ),
  );
  Widget _field(
    String name,
    String label,
    IconData icon,
    ThemeData t, {
    String? Function(String?)? validator,
    bool enabled = true,
  }) => FormBuilderTextField(
    name: name,
    enabled: enabled,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: t.colorScheme.onSurface.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    validator: validator,
  );

  void _showPwDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (c) => _PasswordChangeDialog(
        onError: _err,
        parentContext: context,
      ),
    );
  }
}

class _PasswordChangeDialog extends StatefulWidget {
  final Function(String) onError;
  final BuildContext parentContext;

  const _PasswordChangeDialog({
    required this.onError,
    required this.parentContext,
  });

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _key = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  Future<void> _handleSave() async {
    if (!(_key.currentState?.saveAndValidate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: _key.currentState!.value['password'],
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('password_changed'.tr())
          ),
        );
      }
    } catch (e) {
      widget.onError('error_unexpected'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('change_password'.tr()),
      content: FormBuilder(
        key: _key,
        child: FormBuilderTextField(
          name: 'password',
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'password'.tr(),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
          validator: FormBuilderValidators.compose([
            FormBuilderValidators.required(),
            FormBuilderValidators.minLength(6),
          ]),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('save'.tr()),
        ),
      ],
    );
  }
}
