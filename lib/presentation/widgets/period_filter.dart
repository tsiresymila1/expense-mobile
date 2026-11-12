import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/widgets/ui_kit.dart';
import 'package:flutter/material.dart';

enum PeriodPreset { thisMonth, last7, last30, lastMonth, thisYear, all, custom }

/// A date window shared by Activity and Analysis (each keeps its own copy).
class PeriodFilter {
  final PeriodPreset preset;
  final DateTimeRange? custom;
  const PeriodFilter(this.preset, [this.custom]);

  static const all = PeriodFilter(PeriodPreset.all);
  static const thisMonth = PeriodFilter(PeriodPreset.thisMonth);

  /// Inclusive window, or null for "all dates".
  DateTimeRange? range([DateTime? now]) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    DateTime endOf(DateTime d) =>
        DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
    switch (preset) {
      case PeriodPreset.thisMonth:
        return DateTimeRange(start: DateTime(n.year, n.month), end: endOf(today));
      case PeriodPreset.last7:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 6)),
          end: endOf(today),
        );
      case PeriodPreset.last30:
        return DateTimeRange(
          start: today.subtract(const Duration(days: 29)),
          end: endOf(today),
        );
      case PeriodPreset.lastMonth:
        return DateTimeRange(
          start: DateTime(n.year, n.month - 1),
          end: endOf(DateTime(n.year, n.month, 0)),
        );
      case PeriodPreset.thisYear:
        return DateTimeRange(start: DateTime(n.year), end: endOf(today));
      case PeriodPreset.custom:
        final c = custom;
        return c == null
            ? null
            : DateTimeRange(start: c.start, end: endOf(c.end));
      case PeriodPreset.all:
        return null;
    }
  }

  bool contains(DateTime d, [DateTime? now]) {
    final r = range(now);
    return r == null || (!d.isBefore(r.start) && !d.isAfter(r.end));
  }

  static String presetKey(PeriodPreset p) => switch (p) {
    PeriodPreset.thisMonth => 'this_month',
    PeriodPreset.last7 => 'period_7d',
    PeriodPreset.last30 => 'period_30d',
    PeriodPreset.lastMonth => 'last_month',
    PeriodPreset.thisYear => 'this_year',
    PeriodPreset.all => 'all_time',
    PeriodPreset.custom => 'custom',
  };

  String label(BuildContext context) {
    final c = custom;
    if (preset == PeriodPreset.custom && c != null) {
      final f = DateFormat.MMMd(context.locale.toString());
      return '${f.format(c.start)} → ${f.format(c.end)}';
    }
    return presetKey(preset).tr();
  }

  @override
  bool operator ==(Object other) =>
      other is PeriodFilter && other.preset == preset && other.custom == custom;
  @override
  int get hashCode => Object.hash(preset, custom);
}

/// Bottom sheet: presets + custom interval. Returns the chosen filter when
/// the user taps Apply, null when dismissed. [countFor] feeds the live
/// "n transactions" summary.
Future<PeriodFilter?> showPeriodSheet(
  BuildContext context, {
  required PeriodFilter initial,
  int Function(PeriodFilter)? countFor,
}) => showAppSheet<PeriodFilter>(
  context,
  builder: (_) => _PeriodSheet(initial: initial, countFor: countFor),
);

class _PeriodSheet extends StatefulWidget {
  final PeriodFilter initial;
  final int Function(PeriodFilter)? countFor;
  const _PeriodSheet({required this.initial, this.countFor});
  @override
  State<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends State<_PeriodSheet> {
  late PeriodPreset _preset = widget.initial.preset;
  DateTime? _from, _to;
  String? _error;

  @override
  void initState() {
    super.initState();
    final r = widget.initial.range();
    final today = DateTime.now();
    _from = r?.start ?? DateTime(today.year, today.month, today.day - 29);
    _to = r == null || r.end.isAfter(today)
        ? DateTime(today.year, today.month, today.day)
        : r.end;
  }

  PeriodFilter? get _current {
    if (_preset != PeriodPreset.custom) return PeriodFilter(_preset);
    if (_from == null || _to == null || _from!.isAfter(_to!)) return null;
    return PeriodFilter(
      PeriodPreset.custom,
      DateTimeRange(start: _from!, end: _to!),
    );
  }

  Future<void> _pick(bool from) async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _to) ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked == null) return;
    setState(() {
      _preset = PeriodPreset.custom;
      if (from) {
        _from = picked;
      } else {
        _to = picked;
      }
      _error = _from!.isAfter(_to!) ? 'period_invalid'.tr() : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = DateFormat.yMMMd(context.locale.toString());
    final cur = _current;
    final count = cur == null ? null : widget.countFor?.call(cur);
    return SheetBody(
      title: 'period'.tr(),
      footer: FilledButton(
        onPressed: cur == null ? null : () => Navigator.pop(context, cur),
        child: Text('apply'.tr()),
      ),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PeriodPreset.values
              .map(
                (p) => ChoiceChip(
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  label: Text(PeriodFilter.presetKey(p).tr()),
                  selected: _preset == p,
                  onSelected: (_) => setState(() {
                    _preset = p;
                    _error = null;
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        Text('custom_interval'.tr(), style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'date_from'.tr(),
                value: _from == null ? null : f.format(_from!),
                invalid: _error != null,
                onTap: () => _pick(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'date_to'.tr(),
                value: _to == null ? null : f.format(_to!),
                invalid: _error != null,
                onTap: () => _pick(false),
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ),
        if (count != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'n_transactions'.tr(args: ['$count']),
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String? value;
  final bool invalid;
  final VoidCallback onTap;
  const _DateField({
    required this.label,
    required this.value,
    required this.invalid,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: '$label ${value ?? ''}',
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          alignment: Alignment.centerLeft,
          side: BorderSide(
            color: invalid ? theme.colorScheme.error : theme.dividerColor,
            width: invalid ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(value ?? '—', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
