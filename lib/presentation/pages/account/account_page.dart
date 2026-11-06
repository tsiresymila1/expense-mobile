import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});
  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _key = GlobalKey<FormBuilderState>();
  AuthUser? _user;
  String? _displayName;
  bool _loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthCubit>().state;
    _user = auth.user;
    _displayName = auth.displayName;
  }

  Future<void> _update() async {
    if (!(_key.currentState?.saveAndValidate() ?? false)) return;
    setState(() => _loading = true);
    try {
      final name = _key.currentState!.value['name'] as String;
      await context.read<AuthCubit>().updateDisplayName(name);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('profile_updated'.tr())));
    } catch (error) {
      if (mounted) _err(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'logout'.tr(),
          style: GoogleFonts.geist(fontWeight: FontWeight.w500),
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
      if (!mounted) return;
      context.read<AuthCubit>().signOut();
      context.go('/login');
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('account'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(_displayName ?? 'user_profile_fallback'.tr()),
            subtitle: Text(_user?.email ?? ''),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          FormBuilder(
            key: _key,
            initialValue: {
              'name': _displayName ?? '',
              'email': _user?.email ?? '',
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'profile_info'.tr().toUpperCase(),
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 18),
                FormBuilderTextField(
                  name: 'name',
                  decoration: InputDecoration(labelText: 'full_name'.tr()),
                  validator: FormBuilderValidators.required(),
                ),
                const SizedBox(height: 18),
                FormBuilderTextField(
                  name: 'email',
                  readOnly: true,
                  decoration: InputDecoration(labelText: 'email'.tr()),
                ),
                const SizedBox(height: 22),
                ElevatedButton(
                  onPressed: _loading ? null : _update,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('update_profile'.tr()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'management'.tr().toUpperCase(),
            style: theme.textTheme.bodySmall,
          ),
          ListTile(
            title: Text('manage_projects'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/projects'),
          ),
          const Divider(),
          ListTile(
            title: Text('settings'.tr()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings'),
          ),
          const Divider(),
          ListTile(
            title: Text(
              'logout'.tr(),
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}
