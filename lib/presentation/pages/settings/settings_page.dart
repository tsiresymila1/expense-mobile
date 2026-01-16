import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text('settings'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSectionHeader(theme, 'localization'.tr()),
              _buildSettingsCard(theme, [
                _buildListTile(
                  theme: theme,
                  title: 'language'.tr(),
                  subtitle: state.language == 'en' ? 'English' : 'Français',
                  icon: Icons.language_rounded,
                  onTap: () => _showLanguageDialog(context),
                ),
                _buildListTile(
                  theme: theme,
                  title: 'currency'.tr(),
                  subtitle: state.currency,
                  icon: Icons.monetization_on_rounded,
                  onTap: () => _showCurrencyDialog(context, state.currency),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, 'appearance'.tr()),
              _buildSettingsCard(theme, [
                _buildListTile(
                  theme: theme,
                  title: 'theme'.tr(),
                  subtitle: _getThemeName(state.themeMode).tr(),
                  icon: Icons.palette_rounded,
                  onTap: () => _showThemeDialog(context),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionHeader(theme, 'debug'.tr()),
              _buildSettingsCard(theme, [
                _buildListTile(
                  theme: theme,
                  title: 'reset_local_data'.tr(),
                  icon: Icons.refresh_rounded,
                  color: Colors.red,
                  onTap: () => _showResetConfirmation(context),
                ),
              ]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: theme.disabledColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(ThemeData theme, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required ThemeData theme,
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? theme.colorScheme.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: color),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: GoogleFonts.outfit(fontSize: 13)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'system';
      case ThemeMode.light: return 'light';
      case ThemeMode.dark: return 'dark';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('select_language'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('English', style: GoogleFonts.outfit()),
              onTap: () {
                context.read<SettingsBloc>().add(ChangeLanguage('en'));
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Français', style: GoogleFonts.outfit()),
              onTap: () {
                context.read<SettingsBloc>().add(ChangeLanguage('fr'));
                context.setLocale(const Locale('fr'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('select_theme'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('system'.tr(), style: GoogleFonts.outfit()),
              onTap: () {
                context.read<SettingsBloc>().add(ChangeTheme(ThemeMode.system));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('light'.tr(), style: GoogleFonts.outfit()),
              onTap: () {
                context.read<SettingsBloc>().add(ChangeTheme(ThemeMode.light));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('dark'.tr(), style: GoogleFonts.outfit()),
              onTap: () {
                context.read<SettingsBloc>().add(ChangeTheme(ThemeMode.dark));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context, String currentCurrency) {
    final formKey = GlobalKey<FormBuilderState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('currency'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: FormBuilder(
          key: formKey,
          initialValue: {'currency': currentCurrency},
          child: FormBuilderTextField(
            name: 'currency',
            decoration: InputDecoration(
              hintText: 'USD, EUR, etc.',
              filled: true,
              fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.maxLength(3),
            ]),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.saveAndValidate() ?? false) {
                final newCurrency = formKey.currentState!.value['currency'] as String;
                context.read<SettingsBloc>().add(ChangeCurrency(newCurrency.trim()));
                Navigator.pop(context);
              }
            },
            child: Text('save'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('reset_confirmation_title'.tr(), style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Text('reset_confirmation_message'.tr(), style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('cancel'.tr(), style: GoogleFonts.outfit(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              final db = context.read<AppDatabase>();
              await db.transaction(() async {
                await db.delete(db.localExpenses).go();
                await db.delete(db.syncQueue).go();
              });
              if (context.mounted) {
                context.read<ExpensesBloc>().add(LoadExpenses());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Local data reset.'.tr())));
              }
            },
            child: Text('reset'.tr(), style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
