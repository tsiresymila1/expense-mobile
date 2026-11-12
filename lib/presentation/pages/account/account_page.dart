import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/auth/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:expense/presentation/widgets/settings_widgets.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';

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
    final auth = context.read<AuthCubit>();
    final ok = await showConfirmSheet(
      context,
      title: 'logout_title'.tr(),
      message: 'logout_sheet_message'.tr(),
      cancelLabel: 'keep'.tr(),
      confirmLabel: 'logout'.tr(),
      destructive: true,
    );
    if (ok) {
      if (!mounted) return;
      auth.signOut();
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
    final scheme = theme.colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            SubPageHeader(
              title: 'account'.tr(),
              onBack: () => context.canPop() ? context.pop() : context.go('/'),
            ),
            SurfaceCard(
              child: Row(
                children: [
                  InitialsAvatar(name: _displayName, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName ?? 'user_profile_fallback'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _user?.email ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SettingsSectionHeader(title: 'profile_info'.tr()),
            SurfaceCard(
              child: FormBuilder(
                key: _key,
                initialValue: {
                  'name': _displayName ?? '',
                  'email': _user?.email ?? '',
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormBuilderTextField(
                      name: 'name',
                      decoration: InputDecoration(labelText: 'full_name'.tr()),
                      textInputAction: TextInputAction.done,
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 14),
                    FormBuilderTextField(
                      name: 'email',
                      readOnly: true,
                      decoration: InputDecoration(labelText: 'email'.tr()),
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
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
            ),
            const SizedBox(height: 20),
            SettingsSectionHeader(title: 'management'.tr()),
            SettingsCard(
              children: [
                SettingsListTile(
                  title: 'manage_projects'.tr(),
                  icon: Icons.folder_outlined,
                  onTap: () => context.go('/projects'),
                ),
                SettingsListTile(
                  title: 'settings'.tr(),
                  icon: Icons.tune_rounded,
                  onTap: () => context.push('/settings'),
                ),
              ],
            ),
            const SizedBox(height: 36),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(
                  color: Color.alphaBlend(
                    scheme.error.withValues(alpha: .5),
                    theme.dividerColor,
                  ),
                ),
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text('sign_out'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
