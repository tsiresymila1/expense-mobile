import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

/// Uppercase small group title ("APPARENCE", "LOCALISATION"...).
class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: .7,
          ),
        ),
      ),
    );
  }
}

/// Rounded, hairline-separated group of [SettingsListTile] rows.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) => GroupedList(children: children);
}

/// 60px settings row: tinted 40px icon tile, title, trailing value + chevron.
class SettingsListTile extends StatelessWidget {
  final String title;
  final String? subtitle; // trailing value text
  final IconData icon;
  final VoidCallback onTap;
  final Color? color; // destructive/accent tint for icon + title

  const SettingsListTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Page header: back arrow (44px) + title. Used by Account and Settings.
class SubPageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const SubPageHeader({super.key, required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 16),
      child: Row(
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: theme.dividerColor),
            ),
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(Icons.arrow_back_rounded, size: 22),
              onPressed: onBack,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Initials avatar (profile card, dashboard header).
class InitialsAvatar extends StatelessWidget {
  final String? name;
  final double size;
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  static String initialsOf(String? name) => (name ?? '')
      .trim()
      .split(RegExp(r'\s+'))
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s.characters.first.toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = initialsOf(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        initials.isEmpty ? '•' : initials,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: size * .36,
        ),
      ),
    );
  }
}

/// Confirmation bottom sheet: explanatory text + two buttons. Resolves to
/// `true` only when the user confirms.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final ok = await showAppSheet<bool>(
    context,
    builder: (sheet) {
      final scheme = Theme.of(sheet).colorScheme;
      return SheetBody(
        title: title,
        footer: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheet, false),
                child: Text(cancelLabel ?? 'cancel'.tr()),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      )
                    : null,
                onPressed: () => Navigator.pop(sheet, true),
                child: Text(confirmLabel),
              ),
            ),
          ],
        ),
        children: [
          if (message != null)
            Text(
              message,
              style: Theme.of(sheet).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
        ],
      );
    },
  );
  return ok == true;
}
