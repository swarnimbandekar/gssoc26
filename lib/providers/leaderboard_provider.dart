import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/contributor.dart';
import '../data/repositories/leaderboard_repository.dart';

// ============================================================
// Leaderboard State
// ============================================================
class LeaderboardState {
  final List<Contributor> contributors;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;
  final int totalContributors;
  final Map<String, int> roleCounts;
  final int page;
  final int pages;
  final int limit;
  final String role;
  final String q;

  const LeaderboardState({
    this.contributors = const [],
    this.isLoading = true,
    this.error,
    this.lastUpdated,
    this.totalContributors = 0,
    this.roleCounts = const {},
    this.page = 1,
    this.pages = 1,
    this.limit = 50,
    this.role = 'all',
    this.q = '',
  });

  LeaderboardState copyWith({
    List<Contributor>? contributors,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
    int? totalContributors,
    Map<String, int>? roleCounts,
    int? page,
    int? pages,
    int? limit,
    String? role,
    String? q,
  }) {
    return LeaderboardState(
      contributors: contributors ?? this.contributors,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      totalContributors: totalContributors ?? this.totalContributors,
      roleCounts: roleCounts ?? this.roleCounts,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      limit: limit ?? this.limit,
      role: role ?? this.role,
      q: q ?? this.q,
    );
  }
}

// ============================================================
// Leaderboard Notifier
// ============================================================
class LeaderboardNotifier extends StateNotifier<LeaderboardState> {
  final LeaderboardRepository _repo;

  LeaderboardNotifier(this._repo) : super(const LeaderboardState()) {
    loadPage(1);
  }

  Future<void> loadPage(
    int page, {
    String? role,
    String? q,
    int? limit,
  }) async {
    final nextRole = role ?? state.role;
    final nextQ = q ?? state.q;
    final nextLimit = limit ?? state.limit;

    state = state.copyWith(
      isLoading: true,
      error: null,
      page: page,
      role: nextRole,
      q: nextQ,
      limit: nextLimit,
    );

    try {
      final res = await _repo.fetchLeaderboardPage(
        page: page,
        limit: nextLimit,
        role: nextRole,
        q: nextQ,
      );
      if (!mounted) return;

      state = state.copyWith(
        isLoading: false,
        contributors: res.participants,
        totalContributors: res.total,
        roleCounts: res.roleCounts,
        pages: res.pages,
        page: res.page,
        limit: res.limit,
        role: res.role,
        q: res.q,
        lastUpdated: res.lastUpdated,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await loadPage(state.page);
  }
}

// ============================================================
// Search State + Notifier (server-side via Supabase)
// ============================================================
class SearchState {
  final List<Contributor> results;
  final bool isSearching;
  final String query;
  final int page;
  final int pages;
  final int total;
  final int limit;

  const SearchState({
    this.results = const [],
    this.isSearching = false,
    this.query = '',
    this.page = 1,
    this.pages = 1,
    this.total = 0,
    this.limit = 50,
  });

  SearchState copyWith({
    List<Contributor>? results,
    bool? isSearching,
    String? query,
    int? page,
    int? pages,
    int? total,
    int? limit,
  }) {
    return SearchState(
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      query: query ?? this.query,
      page: page ?? this.page,
      pages: pages ?? this.pages,
      total: total ?? this.total,
      limit: limit ?? this.limit,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final LeaderboardRepository _repo;

  SearchNotifier(this._repo) : super(const SearchState());

  Future<void> search(String query, {int page = 1}) async {
    final q = query.trim();
    if (q.isEmpty) {
      state = const SearchState();
      return;
    }
    state = state.copyWith(isSearching: true, query: q, page: page);
    try {
      final res = await _repo.fetchLeaderboardPage(
        page: page,
        limit: state.limit,
        role: 'all',
        q: q,
      );
      if (mounted && state.query == q) {
        state = state.copyWith(
          results: res.participants,
          isSearching: false,
          pages: res.pages,
          total: res.total,
          page: res.page,
          limit: res.limit,
        );
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isSearching: false);
      }
    }
  }

  void clear() {
    state = const SearchState();
  }
}

// ============================================================
// Providers
// ============================================================
final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

final leaderboardProvider =
    StateNotifierProvider<LeaderboardNotifier, LeaderboardState>((ref) {
  return LeaderboardNotifier(ref.read(leaderboardRepositoryProvider));
});

final searchProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(leaderboardRepositoryProvider));
});

final topContributorsProvider = Provider<List<Contributor>>((ref) {
  final contributors = ref.watch(leaderboardProvider).contributors;
  if (contributors.length < 3) return contributors;
  return contributors.take(3).toList();
});

final statsProvider = Provider<Map<String, dynamic>>((ref) {
  final lb = ref.watch(leaderboardProvider);
  final contributors = lb.contributors;
  if (contributors.isEmpty) return {};

  final totalScore = contributors.fold<int>(0, (sum, c) => sum + c.displayScore);
  final avgScore = contributors.isNotEmpty
      ? (totalScore / contributors.length).round()
      : 0;
  final topScore = contributors.isNotEmpty ? contributors.first.displayScore : 0;

  return {
    'totalScore': totalScore,
    'avgScore': avgScore,
    'topScore': topScore,
    'totalContributors': lb.totalContributors,
    'roleCounts': lb.roleCounts,
  };
});
