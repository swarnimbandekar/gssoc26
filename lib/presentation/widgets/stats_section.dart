import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/leaderboard_provider.dart';
import 'animated_counter.dart';
import 'glassmorphic_container.dart';

class StatsSection extends ConsumerWidget {
  const StatsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    if (stats.isEmpty) return const SizedBox.shrink();

    final roleCounts = stats['roleCounts'] as Map<String, int>? ?? {};
    final totalContributors = stats['totalContributors'] as int? ?? 0;
    final topScore = stats['topScore'] as int? ?? 0;
    final avgScore = stats['avgScore'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatCard(
                context,
                icon: Icons.people_alt_rounded,
                label: 'Contributors',
                value: totalContributors,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                context,
                icon: Icons.emoji_events_rounded,
                label: 'Top Score',
                value: topScore,
                color: AppColors.gold,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                context,
                icon: Icons.trending_up_rounded,
                label: 'Avg Score',
                value: avgScore,
                color: AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Role breakdown chips
          if (roleCounts.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: roleCounts.entries
                    .where((e) => e.key != 'all')
                    .map((e) => _buildRoleChip(context, e.key, e.value))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            AnimatedCounter(
              value: value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, String role, int count) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _roleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _roleColor(role).withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _roleColor(role),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${_roleDisplayName(role)} · $count',
            style: TextStyle(
              color: _roleColor(role),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'contributor':
        return AppColors.primary;
      case 'mentor':
        return AppColors.warning;
      case 'project_admin':
        return AppColors.secondary;
      case 'ambassador':
        return AppColors.accent;
      default:
        return AppColors.textMuted;
    }
  }

  String _roleDisplayName(String role) {
    switch (role) {
      case 'contributor':
        return 'Contributors';
      case 'mentor':
        return 'Mentors';
      case 'project_admin':
        return 'Project Admins';
      case 'ambassador':
        return 'Ambassadors';
      default:
        return role;
    }
  }
}
