class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'https://gssoc.girlscript.org/api';
  static const String leaderboardEndpoint = '/leaderboard';
  static const int pageLimit = 100;
  static const int concurrentFetchBatch = 8;
  static const Duration syncInterval = Duration(minutes: 20);
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const String cacheBoxName = 'gssoc_leaderboard';
  static const String contributorsKey = 'contributors_data';
  static const String lastUpdatedKey = 'last_updated';
  static const String roleCountsKey = 'role_counts';
  static const String totalCountKey = 'total_count';

  static String avatarUrl(String githubUser) =>
      'https://avatars.githubusercontent.com/$githubUser';

  static String githubProfileUrl(String githubUser) =>
      'https://github.com/$githubUser';
}
