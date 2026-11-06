import 'package:expense/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_instantdb/flutter_instantdb.dart';

/// Minimal InstantDB-backed connection indicator.
///
/// Shows a synced check icon when the InstantDB socket is authenticated
/// (fully online); otherwise a spinning sync icon while connecting/offline.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final db = InstantProvider.of(context);

    return Watch((context) {
      final status = db.connectionStatus.value;
      if (status == ConnectionStatus.authenticated) {
        return Icon(
          Icons.check_circle_rounded,
          color: AppTheme.primaryColor,
          size: 24,
        );
      }
      if (status == ConnectionStatus.errored) {
        return Icon(
          Icons.sync_problem_rounded,
          color: theme.colorScheme.error,
          size: 24,
        ).animate().shake(duration: 500.ms);
      }
      return Icon(
            Icons.sync_rounded,
            color: theme.colorScheme.primary,
            size: 24,
          )
          .animate(onPlay: (controller) => controller.repeat())
          .rotate(duration: 1.seconds);
    });
  }
}
