import 'package:expense/data/local/database.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/core/sync_engine/engine.dart';
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
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SettingsSectionHeader(title: 'localization'.tr()),
            SettingsCard(
              children: [
                SettingsListTile(
                  title: 'language'.tr(),
                  subtitle: state.language == 'en' ? 'English' : 'Français',
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

  void _showLang(BuildContext context) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'select_language'.tr(),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Text('🇺🇸', style: TextStyle(fontSize: 32)),
            title: const Text('English'),
            onTap: () {
              context.read<SettingsBloc>().add(ChangeLanguage('en'));
              context.setLocale(const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🇫🇷', style: TextStyle(fontSize: 32)),
            title: const Text('Français'),
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

  void _showTheme(BuildContext context) => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'select_theme'.tr(),
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.brightness_auto_rounded),
            title: Text('system'.tr()),
            onTap: () {
              context.read<SettingsBloc>().add(ChangeTheme(ThemeMode.system));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.light_mode_rounded),
            title: Text('light'.tr()),
            onTap: () {
              context.read<SettingsBloc>().add(ChangeTheme(ThemeMode.light));
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded),
            title: Text('dark'.tr()),
            onTap: () {
              context.read<SettingsBloc>().add(ChangeTheme(ThemeMode.dark));
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'currency'.tr(),
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
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
                borderRadius: BorderRadius.circular(16),
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
                context.read<SettingsBloc>().add(
                  ChangeCurrency(
                    (key.currentState!.value['currency'] as String).trim(),
                  ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('reset_confirmation_title'.tr()),
      content: Text('reset_confirmation_message'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: () async {
            final db = context.read<AppDatabase>();
            final syncEngine = context.read<SyncEngine>();
            
            await db.transaction(() async {
              await db.delete(db.localExpenses).go();
              await db.delete(db.localCategories).go();
              await db.delete(db.localProjects).go();
              await db.delete(db.localProjectMembers).go();
              await db.delete(db.localProfiles).go();
              await db.delete(db.syncQueue).go();
            });

            if (context.mounted) {
              Navigator.pop(context);
              
              // Show loading or indicator?
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('local_data_reset_success'.tr())),
              );

              // Trigger a fresh sync to pull everything back
              await syncEngine.triggerSync();
              
              if (context.mounted) {
                context.read<ExpensesBloc>().add(LoadExpenses());
                context.read<CategoriesBloc>().add(LoadCategories());
                context.read<ProjectsBloc>().add(LoadProjects());
              }
            }
          },
          child: Text('reset'.tr(), style: const TextStyle(color: Colors.red)),
        ),
      ],
    ),
  );
}
