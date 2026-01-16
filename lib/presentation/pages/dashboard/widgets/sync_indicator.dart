import 'package:expense/core/theme.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';

class SyncIndicator extends StatelessWidget {
  final SyncStatus status;

  const SyncIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    bool rotating = false;

    switch (status) {
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = theme.colorScheme.primary;
        rotating = true;
        break;
      case SyncStatus.error:
        icon = Icons.sync_problem_rounded;
        color = theme.colorScheme.error;
        break;
      case SyncStatus.success:
        icon = Icons.check_circle_rounded;
        color = AppTheme.primaryColor;
        break;
      default:
        icon = Icons.sync_rounded;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    }

    if (rotating) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    return Icon(icon, color: color, size: 24);
  }
}
