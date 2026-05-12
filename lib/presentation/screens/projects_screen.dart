import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';

class ProjectsScreen extends ConsumerStatefulWidget {
  const ProjectsScreen({super.key});

  @override
  ConsumerState<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends ConsumerState<ProjectsScreen> {
  bool _isLoading = true;
  List<dynamic> _projects = [];
  String? _errorMessage;
  String _query = '';
  String _selectedLanguage = 'All';
  String _selectedDifficulty = 'All';
  String _selectedSort = 'More issues';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, Map<String, dynamic>> _detailsCache = {};

  static const String _gssocApiUrl = 'https://gssoc.girlscript.org/api';

  @override
  void initState() {
    super.initState();
    _fetchProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse('$_gssocApiUrl/projects'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is Map && data['projects'] is List) {
            _projects = data['projects'] as List;
          } else if (data is List) {
            _projects = data;
          } else {
            _projects = [];
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load projects: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languages = _languageOptions();
    final difficulties = _difficultyOptions();
    final filtered = _filteredProjects();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Projects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchProjects,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _projects.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 80,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No projects available',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          child: _buildSearchBar(),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: _buildFilters(languages, difficulties),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${filtered.length} projects',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _selectedSort,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final project = filtered[index];
                              return _buildProjectCard(project);
                            },
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildProjectCard(dynamic project) {
    final name = _getString(project, ['name', 'project_name']) ?? 'Unnamed Project';
    final difficulty = _getString(project, ['difficulty', 'level']) ?? 'Unknown';

    return InkWell(
      onTap: () => _openProjectDetails(project),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            _pill(difficulty, _difficultyColor(difficulty)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _query = value),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Search projects',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildFilters(List<String> languages, List<String> difficulties) {
    return Row(
      children: [
        Expanded(
          child: _dropdown(
            label: 'Language',
            value: _selectedLanguage,
            items: languages,
            onChanged: (value) => setState(() => _selectedLanguage = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _dropdown(
            label: 'Difficulty',
            value: _selectedDifficulty,
            items: difficulties,
            onChanged: (value) => setState(() => _selectedDifficulty = value),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _dropdown(
            label: 'Sort',
            value: _selectedSort,
            items: const [
              'More issues',
              'High stars',
              'Recently updated',
            ],
            onChanged: (value) => setState(() => _selectedSort = value),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map(
            (v) => DropdownMenuItem<String>(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
    );
  }

  List<String> _languageOptions() {
    final set = <String>{'All'};
    for (final p in _projects) {
      final gh = _getGh(p);
      final lang = gh?['language']?.toString().trim();
      if (lang != null && lang.isNotEmpty) set.add(lang);
      final stack = p is Map ? p['tech_stack'] : null;
      if (stack is List) {
        for (final item in stack) {
          final v = item.toString().trim();
          if (v.isNotEmpty) set.add(v);
        }
      } else if (stack is String) {
        for (final part in stack.split(',')) {
          final v = part.trim();
          if (v.isNotEmpty) set.add(v);
        }
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<String> _difficultyOptions() {
    final set = <String>{'All'};
    for (final p in _projects) {
      final diff = _getString(p, ['difficulty', 'level']);
      if (diff != null && diff.trim().isNotEmpty) {
        set.add(diff.trim());
      }
    }
    final list = set.toList()..sort();
    return list;
  }

  List<dynamic> _filteredProjects() {
    Iterable<dynamic> list = _projects;

    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list.where((p) {
        final name = _getString(p, ['name', 'project_name'])?.toLowerCase() ?? '';
        final desc = _getString(p, ['description', 'about'])?.toLowerCase() ?? '';
        return name.contains(q) || desc.contains(q);
      });
    }

    if (_selectedLanguage != 'All') {
      list = list.where((p) => _matchesLanguage(p, _selectedLanguage));
    }

    if (_selectedDifficulty != 'All') {
      list = list.where((p) => _getString(p, ['difficulty', 'level']) == _selectedDifficulty);
    }

    final sorted = list.toList();
    if (_selectedSort == 'More issues') {
      sorted.sort((a, b) => _issueCount(b).compareTo(_issueCount(a)));
    } else if (_selectedSort == 'High stars') {
      sorted.sort((a, b) => _ghNum(b, 'stars').compareTo(_ghNum(a, 'stars')));
    } else if (_selectedSort == 'Recently updated') {
      sorted.sort((a, b) => _lastUpdated(b).compareTo(_lastUpdated(a)));
    }

    return sorted;
  }

  void _openProjectDetails(dynamic project) {
    final repo = _getString(project, ['owner_repo', 'repo']);
    final repoUrl = _getString(project, ['repo_url', 'repository']);
    final future = repo == null ? Future<Map<String, dynamic>?>.value(null) : _fetchProjectDetails(repo);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: future,
          builder: (context, snapshot) {
            final detail = snapshot.data ?? (project is Map ? Map<String, dynamic>.from(project) : <String, dynamic>{});
            final gh = (detail['gh'] is Map) ? Map<String, dynamic>.from(detail['gh'] as Map) : _getGh(project);
            final name = detail['name']?.toString() ?? _getString(project, ['name', 'project_name']) ?? 'Project';
            final description = detail['description']?.toString() ?? _getString(project, ['description', 'about']) ?? 'No description available.';
            final language = gh?['language']?.toString() ?? _getPrimaryStack(project);
            final difficulty = detail['difficulty']?.toString() ?? _getString(project, ['difficulty', 'level']);
            final stars = (gh?['stars'] as num?)?.toInt() ?? 0;
            final forks = (gh?['forks'] as num?)?.toInt() ?? 0;
            final issues = (gh?['open_issues'] as num?)?.toInt() ?? 0;
            final updatedAt = gh?['last_push']?.toString() ?? detail['updated_at']?.toString();
            final topics = (gh?['topics'] is List)
                ? (gh!['topics'] as List).map((e) => e.toString()).toList()
                : _getList(project, ['topics', 'tags', 'labels']);
            final adminName = detail['admin_name']?.toString() ?? _getString(project, ['admin_name']);
            final adminGithub = detail['admin_github']?.toString() ?? _getString(project, ['admin_github']);

            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        description,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (language != null && language.isNotEmpty) _pill(language, AppColors.primary),
                          if (difficulty != null && difficulty.isNotEmpty)
                            _pill(difficulty, _difficultyColor(difficulty)),
                          if (stars > 0) _pill('$stars stars', AppColors.warning),
                          if (forks > 0) _pill('$forks forks', AppColors.surface),
                          if (issues > 0) _pill('$issues open issues', AppColors.error),
                          if (updatedAt != null && updatedAt.isNotEmpty) _pill('Updated $updatedAt', AppColors.textMuted),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (adminName != null || adminGithub != null) ...[
                        const Text(
                          'Project Admin',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                adminName ?? adminGithub ?? 'Unknown',
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (adminGithub != null && adminGithub.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _openUrl(adminGithub),
                                icon: const Icon(Icons.open_in_new, size: 16),
                                label: const Text('GitHub'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (topics.isNotEmpty) ...[
                        const Text(
                          'Topics',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: topics.map((t) => _pill(t, AppColors.surface)).toList(),
                        ),
                        const SizedBox(height: 18),
                      ],
                      if (repoUrl != null && repoUrl.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _openUrl(repoUrl),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Repository'),
                        ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: LinearProgressIndicator(color: AppColors.primary),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchProjectDetails(String repo) async {
    if (_detailsCache.containsKey(repo)) return _detailsCache[repo];
    try {
      final response = await http.get(
        Uri.parse('$_gssocApiUrl/projects').replace(queryParameters: {'repo': repo}),
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is Map<String, dynamic>) {
        _detailsCache[repo] = data;
        return data;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _getString(dynamic project, List<String> keys) {
    if (project is! Map) return null;
    for (final k in keys) {
      final v = project[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return null;
  }

  int _getNum(dynamic project, List<String> keys) {
    if (project is! Map) return 0;
    for (final k in keys) {
      final v = project[k];
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  DateTime _getDate(dynamic project, List<String> keys) {
    if (project is! Map) return DateTime.fromMillisecondsSinceEpoch(0);
    for (final k in keys) {
      final v = project[k];
      if (v is String) {
        final parsed = DateTime.tryParse(v);
        if (parsed != null) return parsed;
      }
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  List<String> _getList(dynamic project, List<String> keys) {
    if (project is! Map) return const [];
    for (final k in keys) {
      final v = project[k];
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
      }
    }
    return const [];
  }

  Map<String, dynamic>? _getGh(dynamic project) {
    if (project is! Map) return null;
    final gh = project['gh'];
    if (gh is Map) return Map<String, dynamic>.from(gh);
    return null;
  }

  int _ghNum(dynamic project, String key) {
    final gh = _getGh(project);
    final v = gh?[key];
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  int _issueCount(dynamic project) {
    final ghIssues = _ghNum(project, 'open_issues');
    if (ghIssues > 0) return ghIssues;
    return _getNum(project, ['good_first_count']);
  }

  DateTime _lastUpdated(dynamic project) {
    final gh = _getGh(project);
    final lastPush = gh?['last_push']?.toString();
    if (lastPush != null) {
      final parsed = DateTime.tryParse(lastPush);
      if (parsed != null) return parsed;
    }
    return _getDate(project, ['applied_at', 'updated_at', 'last_updated']);
  }

  bool _matchesLanguage(dynamic project, String selected) {
    final gh = _getGh(project);
    if (gh?['language']?.toString() == selected) return true;
    if (project is Map) {
      final stack = project['tech_stack'];
      if (stack is List) {
        return stack.any((e) => e.toString() == selected);
      }
      if (stack is String) {
        return stack.split(',').any((e) => e.trim() == selected);
      }
    }
    return false;
  }

  String? _getPrimaryStack(dynamic project) {
    if (project is Map) {
      final stack = project['tech_stack'];
      if (stack is List && stack.isNotEmpty) return stack.first.toString();
      if (stack is String && stack.trim().isNotEmpty) return stack.split(',').first.trim();
    }
    return null;
  }

  Color _difficultyColor(String difficulty) {
    final d = difficulty.toLowerCase();
    if (d.contains('easy')) return AppColors.success;
    if (d.contains('medium')) return AppColors.warning;
    if (d.contains('hard')) return AppColors.error;
    return AppColors.textMuted;
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
