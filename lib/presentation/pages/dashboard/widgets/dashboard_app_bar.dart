import 'package:easy_localization/easy_localization.dart';
import 'package:expense/presentation/pages/dashboard/widgets/sync_indicator.dart';
import 'package:expense/sync_engine/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardAppBar extends StatelessWidget {
  final SyncEngine syncEngine;

  const DashboardAppBar({super.key, required this.syncEngine});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'dashboard'.tr(),
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        centerTitle: false,
      ),
      actions: [
        StreamBuilder<SyncState>(
          stream: syncEngine.syncState,
          builder: (context, snapshot) {
            final status = snapshot.data?.status ?? SyncStatus.idle;
            return SyncIndicator(status: status);
          },
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          onPressed: () => context.push('/account'),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
