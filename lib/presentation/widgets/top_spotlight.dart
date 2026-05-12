import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/contributor.dart';

class TopSpotlight extends StatelessWidget {
  final List<Contributor> topThree;
  final void Function(Contributor) onTap;

  const TopSpotlight({
    super.key,
    required this.topThree,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (topThree.length < 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          Expanded(child: _buildPodium(context, topThree[1], 2)),
          const SizedBox(width: 8),
          // 1st place
          Expanded(child: _buildPodium(context, topThree[0], 1)),
          const SizedBox(width: 8),
          // 3rd place
          Expanded(child: _buildPodium(context, topThree[2], 3)),
        ],
      ),
    );
  }

  Widget _buildPodium(BuildContext context, Contributor c, int rank) {
    final color = AppColors.rankColor(rank);
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 72.0 : 58.0;
    final heightBoost = isFirst ? 20.0 : 0.0;

    return GestureDetector(
      onTap: () => onTap(c),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Crown for #1
            if (isFirst)
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.goldGradient.createShader(bounds),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            if (isFirst) const SizedBox(height: 4),

            // Avatar with glow
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.rankGradient(rank),
                ),
                child: Hero(
                  tag: 'avatar_${c.creatorId}',
                  child: CircleAvatar(
                    radius: avatarSize / 2,
                    backgroundColor: AppColors.surfaceBright,
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: c.avatarUrl,
                        width: avatarSize,
                        height: avatarSize,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: AppColors.surfaceBright,
                          child: const Icon(Icons.person,
                              color: AppColors.textMuted),
                        ),
                        errorWidget: (ctx, url, err) => Center(
                          child: Text(
                            c.fullName.isNotEmpty
                                ? c.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w800,
                              fontSize: avatarSize * 0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Rank badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                gradient: AppColors.rankGradient(rank),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: AppColors.background,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Name
            Text(
              c.fullName.split(' ').first,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            // Score
            Text(
              '${c.displayScore} pts',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),

            SizedBox(height: heightBoost),
          ],
      ),
    );
  }
}
