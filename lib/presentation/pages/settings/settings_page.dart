import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/widgets/settings_widgets.dart';
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
        title: Text(
          'settings'.tr(),
          style: GoogleFonts.geist(fontWeight: FontWeight.w500),
        ),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsSectionHeader(title: 'localization'.tr()),
            SettingsCard(
              children: [
                SettingsListTile(
                  title: 'language'.tr(),
                  subtitle: _languageName(state.language),
                  icon: Icons.language_rounded,
                  onTap: () => _showLang(context),
                ),
                SettingsListTile(
                  title: 'currency'.tr(),
                  subtitle: state.currency,
                  icon: Icons.monetization_on_rounded,
                  onTap: () => _showCurr(context, state.currency),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSectionHeader(title: 'appearance'.tr()),
            SettingsCard(
              children: [
                SettingsListTile(
                  title: 'theme'.tr(),
                  subtitle: _themeName(state.themeMode).tr(),
                  icon: Icons.palette_rounded,
                  onTap: () => _showTheme(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSectionHeader(title: 'debug'.tr()),
            SettingsCard(
              children: [
                SettingsListTile(
                  title: 'reset_local_data'.tr(),
                  icon: Icons.refresh_rounded,
                  color: Colors.red,
                  onTap: () => _showReset(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode m) => m == ThemeMode.system
      ? 'system'
      : (m == ThemeMode.light ? 'light' : 'dark');

  String _languageName(String language) {
    if (language == 'system') return 'system'.tr();
    return language == 'en' ? 'English' : 'Français';
  }

  void _showLang(BuildContext context) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      title: Text(
        'select_language'.tr(),
        style: GoogleFonts.geist(fontWeight: FontWeight.w500),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.language_rounded, size: 30),
            title: Text('system'.tr()),
            onTap: () async {
              context.read<SettingsCubit>().changeLanguage('system');
              await context.resetLocale();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 32)),
            title: const Text('English'),
            onTap: () {
              context.read<SettingsCubit>().changeLanguage('en');
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🇫🇷', style: TextStyle(fontSize: 32)),
            title: const Text('Français'),
            onTap: () {
              context.read<SettingsCubit>().changeLanguage('fr');
              context.setLocale(const Locale('fr'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );

  void _showTheme(BuildContext context) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      title: Text(
        'select_theme'.tr(),
        style: GoogleFonts.geist(fontWeight: FontWeight.w500),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto_rounded),
            title: Text('system'.tr()),
            onTap: () {
              context.read<SettingsCubit>().changeTheme(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.light_mode_rounded),
            title: Text('light'.tr()),
            onTap: () {
              context.read<SettingsCubit>().changeTheme(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: Text('dark'.tr()),
            onTap: () {
              context.read<SettingsCubit>().changeTheme(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );

  void _showCurr(BuildContext context, String curr) {
    final key = GlobalKey<FormBuilderState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        title: Text(
          'currency'.tr(),
          style: GoogleFonts.geist(fontWeight: FontWeight.w500),
        ),
        content: FormBuilder(
          key: key,
          initialValue: {'currency': curr},
          child: FormBuilderTextField(
            name: 'currency',
            decoration: InputDecoration(
              hintText: 'USD, EUR, etc.',
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide.none,
              ),
            ),
            validator: FormBuilderValidators.compose([
              FormBuilderValidators.required(),
              FormBuilderValidators.maxLength(3),
            ]),
            textCapitalization: TextCapitalization.sentences,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              if (key.currentState?.saveAndValidate() ?? false) {
                context.read<SettingsCubit>().changeCurrency(
                  (key.currentState!.value['currency'] as String).trim(),
                );
                Navigator.pop(context);
              }
            },
            child: Text('save'.tr()),
          ),
        ],
      ),
    );
  }

  void _showReset(BuildContext context) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      title: Text('reset_confirmation_title'.tr()),
      content: Text('reset_confirmation_message'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () async {
            // InstantDB owns persistence and syncs automatically; there is no
            // local Drift store to wipe. Re-pull data through the cubits.
            Navigator.pop(context);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('local_data_reset_success'.tr())),
            );

            context.read<ExpensesCubit>().loadExpenses();
            context.read<CategoriesCubit>().loadCategories();
            context.read<ProjectsCubit>().loadProjects();
          },
          child: Text('reset'.tr(), style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
