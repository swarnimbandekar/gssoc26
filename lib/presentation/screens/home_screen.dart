import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/contributor.dart';
import '../../providers/leaderboard_provider.dart';
import '../widgets/contributor_card.dart';
import '../widgets/pagination_bar.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/stats_section.dart';
import '../widgets/sync_indicator.dart';
import '../widgets/top_spotlight.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref.read(leaderboardProvider.notifier).refresh();
  }

  void _navigateToProfile(Contributor c) {
    context.push('/profile/${c.creatorId}', extra: c);
  }

  void _navigateToSearch() {
    context.push('/search');
  }

  @override
  Widget build(BuildContext context) {
    final lb = ref.watch(leaderboardProvider);
    final topThree = ref.watch(topContributorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: AppColors.background.withValues(alpha: 0.85),
                surfaceTintColor: Colors.transparent,
                expandedHeight: 60,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  title: Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.neonGradient.createShader(bounds),
                        child: const Text(
                          'GSSoC',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const Text(
                        ' Leaderboard',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const SyncIndicator(),
                    ],
                  ),
                ),
              ),

              // Search Bar
              SliverToBoxAdapter(
                child: GestureDetector(
                  onTap: _navigateToSearch,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 10),
                        Text(
                          'Search contributors, colleges, tech...',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBright,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '⌘K',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats
              const SliverToBoxAdapter(child: StatsSection()),

              // Top 3 Spotlight
              if (!lb.isLoading && lb.page == 1 && topThree.length >= 3) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                    child: Text(
                      'TOP PERFORMERS',
                      style:
                          Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textMuted,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TopSpotlight(
                    topThree: topThree,
                    onTap: _navigateToProfile,
                  ),
                ),
              ],

              // Leaderboard header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'LEADERBOARD',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const Spacer(),
                      if (lb.contributors.isNotEmpty)
                        Text(
                          'Page ${lb.page}/${lb.pages} · ${lb.totalContributors} total',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                    ],
                  ),
                ),
              ),

              // Loading shimmer
              if (lb.isLoading) const ShimmerList(),

              // Error
              if (lb.error != null && lb.contributors.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load data',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pull down to retry',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),

              // Contributor list
              if (!lb.isLoading && lb.contributors.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final contributor = lb.contributors[index];
                      return ContributorCard(
                        contributor: contributor,
                        index: index,
                        onTap: () => _navigateToProfile(contributor),
                      );
                    },
                    childCount: lb.contributors.length,
                  ),
                ),

              // Pagination
              SliverToBoxAdapter(
                child: PaginationBar(
                  page: lb.page,
                  pages: lb.pages,
                  onPageSelected: (p) async {
                    await ref.read(leaderboardProvider.notifier).loadPage(p);
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                ),
              ),

              // Bottom padding
              const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
            ],
          ),
        ),
      );
  }
}
