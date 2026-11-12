import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/blocs/expenses/categories_bloc.dart';
import 'package:expense/presentation/blocs/expenses/expenses_bloc.dart';
import 'package:expense/presentation/blocs/projects/projects_bloc.dart';
import 'package:expense/presentation/blocs/settings/settings_bloc.dart';
import 'package:expense/presentation/widgets/category_management_modal.dart';
import 'package:expense/presentation/widgets/settings_widgets.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Currencies offered in the picker (symbols come from [SettingsState]).
const _currencies = ['MGA', 'EUR', 'USD', 'GBP', 'CAD', 'JPY'];

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryCount = context
        .watch<CategoriesCubit>()
        .state
        .categories
        .length;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              SubPageHeader(
                title: 'settings'.tr(),
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/'),
              ),
              SettingsSectionHeader(title: 'appearance'.tr()),
              SurfaceCard(
                padding: const EdgeInsets.all(12),
                child: Semantics(
                  label: 'theme'.tr(),
                  child: AppSegmented<ThemeMode>(
                    items: [
                      (ThemeMode.light, 'light'.tr()),
                      (ThemeMode.dark, 'dark'.tr()),
                      (ThemeMode.system, 'system'.tr()),
                    ],
                    value: state.themeMode,
                    onChanged: context.read<SettingsCubit>().changeTheme,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SettingsSectionHeader(title: 'localization'.tr()),
              SettingsCard(
                children: [
                  SettingsListTile(
                    title: 'currency'.tr(),
                    subtitle: _currencyLabel(state.currency),
                    icon: Icons.monetization_on_outlined,
                    onTap: () => _showCurr(context, state.currency),
                  ),
                  SettingsListTile(
                    title: 'language'.tr(),
                    subtitle: _languageName(state.language),
                    icon: Icons.language_rounded,
                    onTap: () => _showLang(context, state.language),
                  ),
                  SettingsListTile(
                    title: 'categories'.tr(),
                    subtitle: '$categoryCount',
                    icon: Icons.sell_outlined,
                    onTap: () => showCategoryManagement(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SettingsSectionHeader(title: 'data_section'.tr()),
              SettingsCard(
                children: [
                  SettingsListTile(
                    title: 'reset_local_data'.tr(),
                    icon: Icons.refresh_rounded,
                    color: theme.colorScheme.error,
                    onTap: () => _showReset(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _currencyLabel(String code) => _currencies.contains(code)
      ? '${'currency_$code'.tr()} (${SettingsState(currency: code).currencySymbol})'
      : code;

  String _languageName(String language) {
    if (language == 'system') return 'system'.tr();
    return language == 'en' ? 'English' : 'Français';
  }

  void _showLang(BuildContext context, String current) {
    final cubit = context.read<SettingsCubit>();
    showAppSheet<void>(
      context,
      builder: (sheet) {
        Widget option(String code, String name, Future<void> Function() apply) =>
            _OptionRow(
              title: name,
              selected: current == code,
              onTap: () async {
                Navigator.pop(sheet);
                await apply();
              },
            );
        return SheetBody(
          title: 'select_language'.tr(),
          children: [
            option('system', 'system'.tr(), () async {
              cubit.changeLanguage('system');
              if (context.mounted) await context.resetLocale();
            }),
            option('en', 'English', () async {
              cubit.changeLanguage('en');
              if (context.mounted) await context.setLocale(const Locale('en'));
            }),
            option('fr', 'Français', () async {
              cubit.changeLanguage('fr');
              if (context.mounted) await context.setLocale(const Locale('fr'));
            }),
          ],
        );
      },
    );
  }

  void _showCurr(BuildContext context, String current) {
    final cubit = context.read<SettingsCubit>();
    showAppSheet<void>(
      context,
      builder: (sheet) => _CurrencySheet(
        current: current,
        onSelected: (code) {
          cubit.changeCurrency(code);
          Navigator.pop(sheet);
        },
      ),
    );
  }

  Future<void> _showReset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final expenses = context.read<ExpensesCubit>();
    final categories = context.read<CategoriesCubit>();
    final projects = context.read<ProjectsCubit>();
    final message = 'local_data_reset_success'.tr();
    final ok = await showConfirmSheet(
      context,
      title: 'reset_confirmation_title'.tr(),
      message: 'reset_confirmation_message'.tr(),
      confirmLabel: 'reset'.tr(),
      destructive: true,
    );
    if (!ok) return;
    // InstantDB owns persistence and syncs automatically; there is no
    // local Drift store to wipe. Re-pull data through the cubits.
    messenger.showSnackBar(SnackBar(content: Text(message)));
    expenses.loadExpenses();
    categories.loadCategories();
    projects.loadProjects();
  }
}

/// 56px option row with a trailing check on the selected value.
class _OptionRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _OptionRow({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_rounded, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencySheet extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSelected;
  const _CurrencySheet({required this.current, required this.onSelected});
  @override
  State<_CurrencySheet> createState() => _CurrencySheetState();
}

class _CurrencySheetState extends State<_CurrencySheet> {
  final _other = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _saveOther() {
    final code = _other.text.trim().toUpperCase();
    if (code.isEmpty || code.length > 3) {
      setState(() => _error = 'currency_code_invalid'.tr());
      return;
    }
    widget.onSelected(code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = !_currencies.contains(widget.current);
    return SheetBody(
      title: 'select_currency'.tr(),
      children: [
        for (final code in _currencies)
          _OptionRow(
            title: 'currency_$code'.tr(),
            subtitle: '$code · ${SettingsState(currency: code).currencySymbol}',
            selected: widget.current == code,
            onTap: () => widget.onSelected(code),
          ),
        if (custom)
          _OptionRow(
            title: widget.current,
            selected: true,
            onTap: () => widget.onSelected(widget.current),
          ),
        const SizedBox(height: 12),
        Text(
          'other_currency'.tr(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _other,
                maxLength: 3,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _saveOther(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: InputDecoration(
                  hintText: 'USD, EUR, etc.',
                  counterText: '',
                  errorText: _error,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(onPressed: _saveOther, child: Text('save'.tr())),
          ],
        ),
      ],
    );
  }
}
