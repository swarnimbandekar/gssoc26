import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/contributor.dart';

class ContributorCard extends StatelessWidget {
  final Contributor contributor;
  final int index;
  final VoidCallback? onTap;

  const ContributorCard({
    super.key,
    required this.contributor,
    required this.index,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index.clamp(0, 20) * 30)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: contributor.rank <= 3
                  ? AppColors.rankColor(contributor.rank).withValues(alpha: 0.3)
                  : AppColors.border.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 36,
                child: _buildRank(context),
              ),
              const SizedBox(width: 10),
              // Avatar
              Hero(
                tag: 'avatar_${contributor.creatorId}',
                child: _buildAvatar(),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contributor.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.code_rounded,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '@${contributor.githubUser}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (contributor.college.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        contributor.displayCollege,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted.withValues(alpha: 0.7),
                              fontSize: 9,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Score + Badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: contributor.rank <= 3
                          ? AppColors.rankGradient(contributor.rank)
                          : null,
                      color: contributor.rank > 3
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${contributor.displayScore}',
                      style: TextStyle(
                        color: contributor.rank <= 3
                            ? AppColors.background
                            : AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildRoleBadges(context),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRank(BuildContext context) {
    final color = AppColors.rankColor(contributor.rank);
    if (contributor.rank <= 3) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.rankGradient(contributor.rank),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '#${contributor.rank}',
            style: const TextStyle(
              color: AppColors.background,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    return Text(
      '#${contributor.rank}',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: contributor.rank <= 3
              ? AppColors.rankColor(contributor.rank).withValues(alpha: 0.6)
              : AppColors.border,
          width: contributor.rank <= 3 ? 2 : 1,
        ),
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: contributor.avatarUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (ctx, url) => Container(
            color: AppColors.surfaceBright,
            child: const Icon(Icons.person, size: 20, color: AppColors.textMuted),
          ),
          errorWidget: (ctx, url, err) => Container(
            color: AppColors.surfaceBright,
            child: Center(
              child: Text(
                contributor.fullName.isNotEmpty
                    ? contributor.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadges(BuildContext context) {
    final roles = contributor.acceptedRoles.take(2).toList();
    if (roles.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: roles.map((role) {
        return Container(
          margin: const EdgeInsets.only(left: 3),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: _roleColor(role).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            _roleLabel(role),
            style: TextStyle(
              color: _roleColor(role),
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }).toList(),
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

  String _roleLabel(String role) {
    switch (role) {
      case 'contributor':
        return 'CTR';
      case 'mentor':
        return 'MNT';
      case 'project_admin':
        return 'PA';
      case 'ambassador':
        return 'AMB';
      default:
        return role.toUpperCase().substring(0, 3);
    }
  }
}
