import 'package:expense/core/theme.dart';
import 'package:flutter/material.dart';

/// Shared v6 building blocks. Keep screens on these so spacing, radius and
/// touch targets stay consistent (4/8 spacing, >=44 targets, 20px cards).

/// Opens a modal bottom sheet the v6 way: root navigator, safe area, keyboard aware.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: isDismissible,
  builder: builder,
);

/// Sheet layout: header (optional back + close), scrolling body, pinned footer.
class SheetBody extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Widget? footer;
  final Widget? toolbar; // pinned under the header (search, "new" button...)
  final VoidCallback? onBack;
  final bool expand; // fill the available height (long lists)
  const SheetBody({
    super.key,
    required this.title,
    required this.children,
    this.footer,
    this.toolbar,
    this.onBack,
    this.expand = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = Column(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              if (onBack != null)
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: onBack,
                )
              else
                const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
        ),
        if (toolbar != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: toolbar,
          ),
        Flexible(
          fit: expand ? FlexFit.tight : FlexFit.loose,
          child: ListView(
            shrinkWrap: !expand,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: children,
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: footer,
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: expand
          ? SizedBox(
              height: MediaQuery.sizeOf(context).height * .92,
              child: body,
            )
          : body,
    );
  }
}

/// Soft pill segmented control (Tout / Dépenses / Revenus, theme choice...).
class AppSegmented<T> extends StatelessWidget {
  final List<(T, String)> items;
  final T value;
  final ValueChanged<T> onChanged;
  const AppSegmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: items.map((it) {
          final on = it.$1 == value;
          return Expanded(
            child: Semantics(
              button: true,
              selected: on,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(it.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  constraints: const BoxConstraints(minHeight: 44),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: on ? theme.colorScheme.surfaceContainerLow : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: on
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .08),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    it.$2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                      color: on
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Always-visible period button: calendar + label + chevron.
class PeriodChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool wide;
  const PeriodChip({
    super.key,
    required this.label,
    required this.onTap,
    this.wide = false,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final content = Row(
      mainAxisSize: wide ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_rounded, size: 18, color: primary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.expand_more_rounded, size: 18),
      ],
    );
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: theme.colorScheme.primaryContainer,
        shape: wide
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: primary, width: 1.5),
              )
            : StadiumBorder(side: BorderSide(color: primary, width: 1.5)),
        child: InkWell(
          customBorder: wide
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              : const StadiumBorder(),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: wide ? 52 : 44),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Active-filter chip with a 44px remove target.
class RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemoved;
  final String? removeTooltip;
  const RemovableChip({
    super.key,
    required this.label,
    required this.onRemoved,
    this.removeTooltip,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.only(left: 14),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          IconButton(
            tooltip: removeTooltip ?? label,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close_rounded, size: 16),
            onPressed: onRemoved,
          ),
        ],
      ),
    );
  }
}

/// Rounded, bordered container whose children are separated by hairlines.
class GroupedList extends StatelessWidget {
  final List<Widget> children;
  const GroupedList({super.key, required this.children});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: theme.dividerColor),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Plain bordered surface card.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      child: child,
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, size: 28, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (action != null) ...[const SizedBox(height: 12), action!],
        ],
      ),
    );
  }
}

/// Section title row: "Récentes ........ Tout voir >"
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    ),
  );
}
