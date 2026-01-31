import 'package:expense/core/theme.dart';
import 'package:expense/core/sync_engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SyncIndicator extends StatelessWidget {
  final SyncStatus status;

  const SyncIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;

    switch (status) {
      case SyncStatus.syncing:
        icon = Icons.sync_rounded;
        color = theme.colorScheme.primary;
        return Icon(icon, color: color, size: 24)
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 1.seconds);
      case SyncStatus.error:
        icon = Icons.sync_problem_rounded;
        color = theme.colorScheme.error;
        return Icon(icon, color: color, size: 24)
            .animate()
            .shake(duration: 500.ms);
      case SyncStatus.success:
        icon = Icons.check_circle_rounded;
        color = AppTheme.primaryColor;
        return Icon(icon, color: color, size: 24)
            .animate()
            .scale(duration: 300.ms, curve: Curves.easeOutBack)
            .fadeIn();
      default:
        icon = Icons.sync_rounded;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.3);
        return Icon(icon, color: color, size: 24).animate().fadeIn();
    }
  }
}
