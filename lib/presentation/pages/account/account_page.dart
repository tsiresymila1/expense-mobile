import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        child: Column(
          children: [
            _buildPremiumHeader(t, _user),
            const SizedBox(height: 12),
            _buildQuickStats(t),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FormBuilder(
                key: _key,
                initialValue: {
                  'name': _user?.userMetadata?['name'] ?? '',
                  'email': _user?.email ?? '',
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('profile_info'.tr(), t),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: t.dividerColor.withValues(alpha: 0.05)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
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
                          ],
                        ),
                      ),
                    ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                    _buildSectionHeader('security'.tr(), t),
                    _buildMenuCard(
                      icon: Icons.lock_outline_rounded,
                      title: 'change_password'.tr(),
                      color: Colors.blue,
                      onTap: () => _showPwDialog(context),
                    ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 24),
                    _buildSectionHeader('management'.tr(), t),
                    _buildMenuCard(
                      icon: Icons.folder_open_rounded,
                      title: 'manage_projects'.tr(),
                      color: t.colorScheme.primary,
                      onTap: () => context.push('/projects'),
                    ).animate(delay: 600.ms).fadeIn().slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 40),
                    if (_loading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: t.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _update,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: t.colorScheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: Text('update_profile'.tr()),
                        ),
                      ).animate(delay: 700.ms).fadeIn(),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                        label: Text(
                          'logout'.tr(),
                          style: GoogleFonts.outfit(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ).animate(delay: 800.ms).fadeIn(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(ThemeData t, User? user) => Container(
        width: double.infinity,
        padding: const EdgeInsets.only(bottom: 32, top: 12),
        decoration: BoxDecoration(
          color: t.colorScheme.surface,
          border: Border(
            bottom: BorderSide(color: t.dividerColor.withValues(alpha: 0.1)),
          ),
        ),
        child: Column(
          children: [
            Stack(
              children: [
                _avatar(t).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: t.colorScheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.colorScheme.surface, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  ),
                ).animate().scale(delay: 400.ms),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.userMetadata?['name'] ?? 'User',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: t.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.email ?? '',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: t.colorScheme.primary,
                ),
              ),
            ).animate().fadeIn(delay: 300.ms),
          ],
        ),
      );

  Widget _buildQuickStats(ThemeData t) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _buildStatItem('transactions'.tr(), 'exp_count', Icons.receipt_long_rounded, Colors.orange),
            const SizedBox(width: 12),
            _buildStatItem('projects'.tr(), 'prj_count', Icons.folder_rounded, Colors.blue),
            const SizedBox(width: 12),
            _buildStatItem('categories'.tr(), 'cat_count', Icons.category_rounded, Colors.green),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms);

  Widget _buildStatItem(String label, String key, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            _getStatValue(key),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getStatValue(String key) {
    if (key == 'exp_count') {
      return BlocBuilder<ExpensesBloc, ExpensesState>(
        builder: (context, state) => Text(
          state.expenses.length.toString(),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      );
    } else if (key == 'prj_count') {
      return BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) => Text(
          state.projects.length.toString(),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      );
    } else if (key == 'cat_count') {
      return BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) => Text(
          state.categories.length.toString(),
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      );
    } else {
      return Text(
        '0',
        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
      );
    }
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) => Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
        ),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
      );


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

  Widget _buildSectionHeader(String title, ThemeData t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 12),
    child: Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: t.colorScheme.primary,
        letterSpacing: 0.5,
      ),
    ),
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
