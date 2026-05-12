import 'dart:convert';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/contributor.dart';
import '../widgets/animated_counter.dart';
import '../widgets/glassmorphic_container.dart';

class ProfileScreen extends StatefulWidget {
  final String creatorId;
  final Contributor? initialContributor;

  const ProfileScreen({
    super.key,
    required this.creatorId,
    this.initialContributor,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _profileApi;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (widget.creatorId.trim().isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing creator id';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/profile/${widget.creatorId}'),
        headers: const {
          'accept': 'application/json',
        },
      );

      if (res.statusCode != 200) {
        throw Exception('Profile API failed: ${res.statusCode}');
      }

      final decoded = jsonDecode(res.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid response');
      }

      if (!mounted) return;
      setState(() {
        _profileApi = decoded;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialContributor;
    final api = _profileApi;
    final profile = (api?['profile'] is Map) ? Map<String, dynamic>.from(api!['profile'] as Map) : null;

    // Prefer initial contributor for rich header fields (rank, score, github user).
    final displayName =
        initial?.fullName.isNotEmpty == true ? initial!.fullName : (profile?['full_name']?.toString() ?? 'Profile');

    final githubUrl = (profile?['github_url']?.toString().trim().isNotEmpty == true)
        ? profile!['github_url'].toString()
        : (initial?.githubUrl ?? '');

    final linkedinUrl = (profile?['linkedin_url']?.toString().trim().isNotEmpty == true)
        ? profile!['linkedin_url'].toString()
        : (initial?.linkedinUrl ?? '');

    final githubUser = initial?.githubUser ?? _inferGithubUser(githubUrl);

    final rank = (api?['rank'] as num?)?.toInt() ?? initial?.rank ?? 0;
    final score = (api?['score'] as num?)?.toInt() ?? initial?.displayScore ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(
                context,
                creatorId: widget.creatorId,
                name: displayName,
                githubUser: githubUser,
                rank: rank,
                score: score,
                githubUrl: githubUrl,
                linkedinUrl: linkedinUrl,
              ),
            ),
          ),

          if (_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),

          if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GlassmorphicContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Failed to load profile',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _fetch,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (api != null && !_loading) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'PROFILE'),
                    const SizedBox(height: 12),
                    _buildProfileCard(profile ?? const {}),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle(context, 'STATS'),
                    const SizedBox(height: 12),
                    _buildStatsGrid({
                      'rank': api['rank'],
                      'score': api['score'],
                      'bounties': api['bountyCount'],
                      'bounty points': api['bountyPoints'],
                      'referrals': api['ambassadorReferralCount'],
                      'merged PRs': api['mergedPrCount'],
                      'projects': api['projectsCount'],
                      'streak': api['streak'],
                    }),
                  ],
                ),
              ),
            ),

            if (api['bountyRows'] is List)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'BOUNTIES'),
                      const SizedBox(height: 12),
                      _buildBounties(api['bountyRows'] as List),
                    ],
                  ),
                ),
              ),

            if (api['prs'] is List)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'PULL REQUESTS'),
                      const SizedBox(height: 12),
                      _buildPullRequests(api['prs'] as List),
                    ],
                  ),
                ),
              ),

            if (api['heatmapData'] is List)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle(context, 'HEATMAP'),
                      const SizedBox(height: 12),
                      _buildHeatmap(api['heatmapData'] as List),
                    ],
                  ),
                ),
              ),
          ],

          const SliverPadding(padding: EdgeInsets.only(bottom: 48)),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required String creatorId,
    required String name,
    required String githubUser,
    required int rank,
    required int score,
    required String githubUrl,
    required String linkedinUrl,
  }) {
    final rankColor = AppColors.rankColor(rank);
    final avatarUrl = githubUser.isNotEmpty ? AppConstants.avatarUrl(githubUser) : '';

    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rankColor.withValues(alpha: 0.15),
                  AppColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: const SizedBox(),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Column(
            children: [
              Hero(
                tag: 'avatar_$creatorId',
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.rankGradient(rank),
                    boxShadow: [
                      BoxShadow(
                        color: rankColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.surfaceBright,
                    child: ClipOval(
                      child: avatarUrl.isEmpty
                          ? Center(
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: TextStyle(
                                  color: rankColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 36,
                                ),
                              ),
                            )
                          : CachedNetworkImage(
                              imageUrl: avatarUrl,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorWidget: (ctx, url, err) => Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: rankColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 36,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              if (githubUser.isNotEmpty)
                Text(
                  '@$githubUser',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              const SizedBox(height: 12),
              if (githubUrl.isNotEmpty || linkedinUrl.isNotEmpty)
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    if (githubUrl.isNotEmpty)
                      _socialButton(
                        label: 'GitHub',
                        svg: _githubSvg,
                        color: AppColors.textPrimary,
                        background: AppColors.surfaceLight,
                        onTap: () => _openUrl(githubUrl),
                      ),
                    if (linkedinUrl.isNotEmpty)
                      _socialButton(
                        label: 'LinkedIn',
                        svg: _linkedinSvg,
                        color: AppColors.primary,
                        background: AppColors.primary.withValues(alpha: 0.12),
                        onTap: () => _openUrl(linkedinUrl),
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: AppColors.rankGradient(rank),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rank > 0 ? 'Rank #$rank' : 'Rank',
                      style: const TextStyle(
                        color: AppColors.background,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.warning, size: 14),
                        const SizedBox(width: 4),
                        AnimatedCounter(
                          value: score,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          suffix: ' pts',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    final items = <_InfoItem>[];

    void add(String label, String key) {
      final value = profile[key];
      if (value == null || value.toString().trim().isEmpty) return;
      items.add(_InfoItem(label: label, value: value.toString()));
    }

    add('Name', 'full_name');
    add('Role', 'your_role');
    add('City', 'city_name');
    add('College', 'college_name');
    add('Track', 'track');
    add('Bio', 'bio');

    return _infoGrid(items);
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final entries = stats.entries
        .where((e) => e.value != null)
        .map((e) => _InfoItem(label: e.key, value: e.value.toString()))
        .toList();
    return _infoGrid(entries);
  }

  Widget _buildBounties(List list) {
    if (list.isEmpty) {
      return _emptyCard('No bounties yet');
    }

    final cards = list.take(30).map((item) {
      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{'value': item};
      final title = _pickFirst(map, ['title', 'bounty_title', 'issue_title', 'task', 'name']) ?? 'Bounty';
      final subtitle = _pickFirst(map, ['repo_name', 'repository', 'project', 'org']) ?? '';
      final points = _pickFirst(map, ['points', 'bounty_points', 'score', 'amount']);

      return _listCard(
        title: title,
        subtitle: subtitle,
        leading: points != null ? _pill('+$points', AppColors.success) : null,
        chips: _toChips(map, skip: {'title', 'bounty_title', 'issue_title', 'task', 'name', 'repo_name', 'repository', 'project', 'org', 'points', 'bounty_points', 'score', 'amount'}),
      );
    }).toList();

    return Column(children: cards);
  }

  Widget _buildPullRequests(List list) {
    if (list.isEmpty) {
      return _emptyCard('No pull requests yet');
    }

    final cards = list.take(30).map((item) {
      final map = item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{'value': item};
      final title = _pickFirst(map, ['title', 'pr_title', 'message']) ?? 'Pull Request';
      final subtitle = _pickFirst(map, ['repo', 'repository', 'project', 'url']) ?? '';
      final status = _pickFirst(map, ['state', 'status', 'merged']);

      return _listCard(
        title: title,
        subtitle: subtitle,
        leading: status != null ? _pill(status.toString(), AppColors.warning) : null,
        chips: _toChips(map, skip: {'title', 'pr_title', 'message', 'repo', 'repository', 'project', 'url', 'state', 'status', 'merged'}),
      );
    }).toList();

    return Column(children: cards);
  }

  Widget _buildHeatmap(List list) {
    if (list.isEmpty) {
      return _emptyCard('No activity data');
    }

    final chips = list.take(60).map((item) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item);
        final day = _pickFirst(map, ['date', 'day', 'created_at']) ?? '';
        final count = _pickFirst(map, ['count', 'value', 'score']) ?? '';
        return _pill('$day · $count', AppColors.surfaceLight);
      }
      return _pill(item.toString(), AppColors.surfaceLight);
    }).toList();

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(12),
      child: Wrap(spacing: 8, runSpacing: 8, children: chips),
    );
  }

  Widget _infoGrid(List<_InfoItem> items) {
    if (items.isEmpty) {
      return _emptyCard('No data');
    }

    return GlassmorphicContainer(
      padding: const EdgeInsets.all(14),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: items
            .map(
              (i) => Container(
                constraints: const BoxConstraints(minWidth: 140),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.3), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      i.label.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i.value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _listCard({
    required String title,
    String? subtitle,
    Widget? leading,
    required List<Widget> chips,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
            if (chips.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: chips),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _toChips(Map<String, dynamic> map, {required Set<String> skip}) {
    final chips = <Widget>[];
    map.forEach((key, value) {
      if (skip.contains(key)) return;
      if (value == null) return;
      final text = '${_labelize(key)}: ${value.toString()}';
      chips.add(_pill(text, AppColors.surfaceLight));
    });
    return chips.take(8).toList();
  }

  String? _pickFirst(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map[k] != null && map[k].toString().trim().isNotEmpty) return map[k].toString();
    }
    return null;
  }

  String _labelize(String key) {
    return key.replaceAll('_', ' ');
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _emptyCard(String text) {
    return GlassmorphicContainer(
      padding: const EdgeInsets.all(14),
      child: Text(text, style: const TextStyle(color: AppColors.textMuted)),
    );
  }

  Widget _socialButton({
    required String label,
    required String svg,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.string(
                svg,
                width: 12,
                height: 12,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
    );
  }

  String _inferGithubUser(String url) {
    final u = url.trim();
    if (u.isEmpty) return '';
    final m = RegExp(r'github\\.com/([^/]+)', caseSensitive: false).firstMatch(u);
    return m?.group(1) ?? '';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem({required this.label, required this.value});
}

const String _githubSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M12 2C6.48 2 2 6.58 2 12.26c0 4.54 2.87 8.38 6.84 9.74.5.1.66-.23.66-.5 0-.25-.01-1.08-.01-1.96-2.78.62-3.37-1.21-3.37-1.21-.45-1.18-1.1-1.49-1.1-1.49-.9-.64.07-.63.07-.63 1 .07 1.53 1.06 1.53 1.06.89 1.57 2.34 1.12 2.91.86.09-.66.35-1.12.63-1.38-2.22-.26-4.56-1.15-4.56-5.11 0-1.13.39-2.05 1.03-2.77-.1-.26-.45-1.3.1-2.71 0 0 .85-.28 2.78 1.06.81-.23 1.68-.34 2.55-.34.86 0 1.74.12 2.55.34 1.93-1.34 2.78-1.06 2.78-1.06.55 1.41.2 2.45.1 2.71.64.72 1.03 1.64 1.03 2.77 0 3.97-2.35 4.85-4.58 5.11.36.32.68.95.68 1.92 0 1.39-.01 2.51-.01 2.85 0 .28.16.61.67.5 3.97-1.36 6.83-5.2 6.83-9.74C22 6.58 17.52 2 12 2z"/>'
    '</svg>';

const String _linkedinSvg =
    '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="M4.98 3.5C3.34 3.5 2 4.85 2 6.5s1.34 3 2.98 3 2.98-1.35 2.98-3-1.34-3-2.98-3zM2.4 20.5h5.16V9.95H2.4V20.5zM9.6 9.95V20.5h5.16v-5.5c0-1.47.28-2.9 2.1-2.9 1.8 0 1.82 1.68 1.82 2.99v5.41H24V13.9c0-3.36-1.82-4.93-4.24-4.93-1.95 0-2.82 1.08-3.3 1.83h-.04V9.95H9.6z"/>'
    '</svg>';
