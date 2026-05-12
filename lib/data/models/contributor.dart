class Contributor {
  final String creatorId;
  final String fullName;
  final String githubUrl;
  final String githubUser;
  final String linkedinUrl;
  final String city;
  final String college;
  final String yourRole;
  final List<String> roles;
  final List<String> acceptedRoles;
  final List<String> techStack;
  final List<String> tracks;
  final String? projectName;
  final String? projectRepo;
  final int score;
  final Map<String, int> roleScores;
  final String computedAt;
  final int rank;
  final int displayScore;

  const Contributor({
    required this.creatorId,
    required this.fullName,
    required this.githubUrl,
    required this.githubUser,
    required this.linkedinUrl,
    required this.city,
    required this.college,
    required this.yourRole,
    required this.roles,
    required this.acceptedRoles,
    required this.techStack,
    required this.tracks,
    this.projectName,
    this.projectRepo,
    required this.score,
    required this.roleScores,
    required this.computedAt,
    required this.rank,
    required this.displayScore,
  });

  String get avatarUrl =>
      'https://avatars.githubusercontent.com/$githubUser';

  String get displayCity {
    if (city.isEmpty) return '';
    final parts = city.split(',');
    return parts.first.trim();
  }

  String get displayCollege {
    if (college.isEmpty) return '';
    if (college.length > 40) return '${college.substring(0, 37)}...';
    return college;
  }

  factory Contributor.fromJson(Map<String, dynamic> json) {
    return Contributor(
      creatorId: json['creator_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      githubUrl: json['github_url'] as String? ?? '',
      githubUser: json['github_user'] as String? ?? '',
      linkedinUrl: json['linkedin_url'] as String? ?? '',
      city: json['city'] as String? ?? '',
      college: json['college'] as String? ?? '',
      yourRole: json['your_role'] as String? ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      acceptedRoles: List<String>.from(json['accepted_roles'] ?? []),
      techStack: List<String>.from(json['tech_stack'] ?? []),
      tracks: List<String>.from(json['tracks'] ?? []),
      projectName: json['project_name'] as String?,
      projectRepo: json['project_repo'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      roleScores: (json['role_scores'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, (v as num).toInt()),
          ) ??
          {},
      computedAt: json['computed_at'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      displayScore: (json['displayScore'] as num?)?.toInt() ??
          (json['display_score'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'creator_id': creatorId,
      'full_name': fullName,
      'github_url': githubUrl,
      'github_user': githubUser,
      'linkedin_url': linkedinUrl,
      'city': city,
      'college': college,
      'your_role': yourRole,
      'roles': roles,
      'accepted_roles': acceptedRoles,
      'tech_stack': techStack,
      'tracks': tracks,
      'project_name': projectName,
      'project_repo': projectRepo,
      'score': score,
      'role_scores': roleScores,
      'computed_at': computedAt,
      'rank': rank,
      'displayScore': displayScore,
    };
  }

  bool matchesQuery(String query) {
    final q = query.toLowerCase();
    return fullName.toLowerCase().contains(q) ||
        githubUser.toLowerCase().contains(q) ||
        college.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        (projectName?.toLowerCase().contains(q) ?? false) ||
        roles.any((r) => r.toLowerCase().contains(q)) ||
        acceptedRoles.any((r) => r.toLowerCase().contains(q)) ||
        techStack.any((t) => t.toLowerCase().contains(q)) ||
        tracks.any((t) => t.toLowerCase().contains(q)) ||
        rank.toString() == q ||
        displayScore.toString().contains(q);
  }
}
