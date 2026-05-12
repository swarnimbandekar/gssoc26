import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/debouncer.dart';
import '../../data/models/contributor.dart';
import '../../providers/leaderboard_provider.dart';
import '../widgets/contributor_card.dart';
import '../widgets/pagination_bar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debouncer = Debouncer(duration: const Duration(milliseconds: 300));
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debouncer.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debouncer.call(() {
      ref.read(searchProvider.notifier).search(value, page: 1);
    });
  }

  void _clearSearch() {
    _controller.clear();
    ref.read(searchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _navigateToProfile(Contributor c) {
    context.push('/profile/${c.creatorId}', extra: c);
  }

  @override
  Widget build(BuildContext context) {
    final search = ref.watch(searchProvider);
    final lb = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: SafeArea(
          child: Column(
            children: [
              // Search header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(searchProvider.notifier).clear();
                        context.pop();
                      },
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textSecondary),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onChanged: _onChanged,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        cursorColor: AppColors.primary,
                        decoration: InputDecoration(
                          hintText: 'Search by name, college, city...',
                          hintStyle: const TextStyle(
                              color: AppColors.textMuted, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          suffixIcon: search.query.isNotEmpty
                              ? IconButton(
                                  onPressed: _clearSearch,
                                  icon: const Icon(Icons.close_rounded,
                                      color: AppColors.textMuted, size: 18),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 0.5,
                color: AppColors.border,
              ),

              // Quick filters
              if (search.query.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'QUICK FILTERS',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppColors.textMuted,
                                  letterSpacing: 1.5,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFilterChip('Ambassador', Icons.campaign_rounded),
                          _buildFilterChip('Mentor', Icons.school_rounded),
                          _buildFilterChip('Python', Icons.code_rounded),
                          _buildFilterChip('React', Icons.web_rounded),
                          _buildFilterChip('AI/ML', Icons.psychology_rounded),
                          _buildFilterChip(
                              'JavaScript', Icons.javascript_rounded),
                          _buildFilterChip('TypeScript', Icons.code_rounded),
                          _buildFilterChip('DevOps', Icons.cloud_rounded),
                        ],
                      ),
                    ],
                  ),
                ),

              // Results header
              if (search.query.isNotEmpty && !search.isSearching)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Page ${search.page}/${search.pages} · ${search.total} total',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                      ),
                    ],
                  ),
                ),

              // Results list
              Expanded(
                child: _buildBody(context, search, lb),
              ),

              if (search.query.isNotEmpty && !search.isSearching)
                PaginationBar(
                  page: search.page,
                  pages: search.pages,
                  onPageSelected: (p) {
                    ref.read(searchProvider.notifier).search(search.query, page: p);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, SearchState search, LeaderboardState lb) {
    if (search.query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.3), size: 64),
            const SizedBox(height: 12),
            Text(
              'Search ${lb.totalContributors} contributors',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    if (search.isSearching) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (search.results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            Text(
              'No results for "${search.query}"',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: search.results.length,
      itemBuilder: (context, index) {
        return ContributorCard(
          contributor: search.results[index],
          index: index,
          onTap: () => _navigateToProfile(search.results[index]),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _controller.text = label;
        ref.read(searchProvider.notifier).search(label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
