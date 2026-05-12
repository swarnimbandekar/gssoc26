import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../models/contributor.dart';

class LeaderboardPageResponse {
  final List<Contributor> participants;
  final int total;
  final int page;
  final int pages;
  final int limit;
  final String role;
  final String q;
  final Map<String, int> roleCounts;
  final DateTime? lastUpdated;

  const LeaderboardPageResponse({
    required this.participants,
    required this.total,
    required this.page,
    required this.pages,
    required this.limit,
    required this.role,
    required this.q,
    required this.roleCounts,
    required this.lastUpdated,
  });
}

class LeaderboardRepository {
  final http.Client _client;

  LeaderboardRepository({
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<LeaderboardPageResponse> fetchLeaderboardPage({
    required int page,
    int limit = 50,
    String role = 'all',
    String q = '',
  }) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.leaderboardEndpoint}')
        .replace(queryParameters: {
      'page': page.toString(),
      'limit': limit.toString(),
      'role': role,
      'q': q,
    });

    final res = await _client.get(uri, headers: {
      'accept': 'application/json',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load leaderboard: ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final rawParticipants = (decoded['participants'] as List?) ?? const [];

    final participants = rawParticipants
        .map((e) => Contributor.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final roleCountsRaw = decoded['role_counts'];
    final roleCounts = roleCountsRaw is Map
        ? roleCountsRaw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()))
        : <String, int>{};

    return LeaderboardPageResponse(
      participants: participants,
      total: (decoded['total'] as num?)?.toInt() ?? 0,
      page: (decoded['page'] as num?)?.toInt() ?? page,
      pages: (decoded['pages'] as num?)?.toInt() ?? 1,
      limit: (decoded['limit'] as num?)?.toInt() ?? limit,
      role: decoded['role']?.toString() ?? role,
      q: decoded['q']?.toString() ?? q,
      roleCounts: roleCounts,
      lastUpdated: decoded['lastUpdated'] != null
          ? DateTime.tryParse(decoded['lastUpdated'].toString())
          : null,
    );
  }

  Future<Map<String, dynamic>> fetchProfile(String creatorId) async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/profile/$creatorId');
    final res = await _client.get(uri, headers: {
      'accept': 'application/json',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load profile: ${res.statusCode}');
    }
    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    return decoded;
  }

  Future<List<Map<String, dynamic>>> fetchProjects() async {
    final uri = Uri.parse('${AppConstants.apiBaseUrl}/projects');
    final res = await _client.get(uri, headers: {
      'accept': 'application/json',
    });
    if (res.statusCode != 200) {
      throw Exception('Failed to load projects: ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map && decoded['projects'] is List) {
      return (decoded['projects'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }
}
