import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:mobile_app/features/achievements/presentation/pages/missions_screen.dart';
import 'package:mobile_app/features/reporting/presentation/pages/my_reports_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/settings_screen.dart';
import 'package:mobile_app/bloc/index.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fallbackDisplayName() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final metadata = currentUser?.userMetadata;
    final fullName = (metadata?['full_name'] as String?)?.trim();
    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final email = currentUser?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }

    return 'Citizen';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthFetchCurrentUserEvent());
    });
  }

  int _levelFromPoints(int points) {
    return (points ~/ 500) + 1;
  }

  String _formatDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  List<Map<String, String>> _buildUnlockedBadges({
    required int totalReports,
    required int verifiedReports,
    required int points,
  }) {
    final badges = <Map<String, String>>[];

    if (totalReports >= 1) {
      badges.add({'icon': '🎯', 'name': 'First Report'});
    }
    if (verifiedReports >= 1) {
      badges.add({'icon': '🛡️', 'name': 'Verified Reporter'});
    }
    if (totalReports >= 10) {
      badges.add({'icon': '👁️', 'name': 'Sharp Eye'});
    }
    if (points >= 1000) {
      badges.add({'icon': '⭐', 'name': 'Community Hero'});
    }
    if (verifiedReports >= 10) {
      badges.add({'icon': '⚡', 'name': 'Fast Responder'});
    }
    if (points >= 2500) {
      badges.add({'icon': '🏆', 'name': 'Top Reporter'});
    }

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final points = state is AuthSuccess ? state.user.points : 0;
          final totalReports = state is AuthSuccess
              ? state.user.totalReports
              : 0;
          final verifiedReports = state is AuthSuccess
              ? state.user.verifiedReports
              : 0;
          final username = state is AuthSuccess
              ? (state.user.fullName?.trim().isNotEmpty == true
                    ? state.user.fullName!.trim()
                    : state.user.username?.trim().isNotEmpty == true
                    ? state.user.username!.trim()
                    : _fallbackDisplayName())
              : _fallbackDisplayName();
          final avatarUrl = state is AuthSuccess ? state.user.avatarUrl : null;
          final createdAt = state is AuthSuccess
              ? state.user.createdAt
              : DateTime.now();

          final unlockedBadges = _buildUnlockedBadges(
            totalReports: totalReports,
            verifiedReports: verifiedReports,
            points: points,
          );
          final recentBadges = unlockedBadges.take(4).toList();
          final level = _levelFromPoints(points);
          final nextLevelXp = level * 500;
          final progress = ((points % 500) / 500).clamp(0.0, 1.0);

          return SingleChildScrollView(
            child: Column(
              children: [
                _HeaderSection(
                  username: username,
                  level: level,
                  avatarUrl: avatarUrl,
                  onSettingsTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: _StatsCard(
                      totalReports: totalReports,
                      totalXp: points,
                      badgesCount: unlockedBadges.length,
                      level: level,
                      nextLevelXp: nextLevelXp,
                      progress: progress,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Badges',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MissionsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _RecentBadgesGrid(badges: recentBadges),
                      const SizedBox(height: 24),
                      Text(
                        'Activity',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ActivityCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Member Since',
                        value: _formatDate(createdAt),
                        iconColor: Color(0xFF3B82F6),
                        iconBgColor: Color(0xFFDBEAFE),
                      ),
                      const SizedBox(height: 12),
                      _ActivityCard(
                        icon: Icons.verified_outlined,
                        title: 'Verified Reports',
                        value: '$verifiedReports verified',
                        iconColor: Color(0xFF22C55E),
                        iconBgColor: Color(0xFFDCFCE7),
                      ),
                      const SizedBox(height: 24),
                      const _MenuSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final String username;
  final int level;
  final String? avatarUrl;
  final VoidCallback onSettingsTap;

  const _HeaderSection({
    required this.username,
    required this.level,
    required this.avatarUrl,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 350),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -110,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -75,
            left: -70,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your civic impact',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.82),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: onSettingsTap,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.85, end: 1),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.24),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 56,
                            backgroundColor: const Color(0xFFE2E8F0),
                            backgroundImage: hasAvatar
                                ? NetworkImage(avatarUrl!)
                                : null,
                            onBackgroundImageError: hasAvatar
                                ? (_, __) {}
                                : null,
                            child: !hasAvatar
                                ? const Icon(
                                    Icons.person,
                                    size: 54,
                                    color: Color(0xFF64748B),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF10B981),
                                    Color(0xFF84CC16),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF1E3A8A),
                                  width: 3,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '$level',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    username,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Rank #--',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '•',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Text(
                        'Level $level',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final int totalReports;
  final int totalXp;
  final int badgesCount;
  final int level;
  final int nextLevelXp;
  final double progress;

  const _StatsCard({
    required this.totalReports,
    required this.totalXp,
    required this.badgesCount,
    required this.level,
    required this.nextLevelXp,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.track_changes,
                  iconColor: const Color(0xFF3B82F6),
                  value: '$totalReports',
                  label: 'Reports',
                ),
              ),
              Container(width: 1, height: 54, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.bolt,
                  iconColor: const Color(0xFF84CC16),
                  value: '$totalXp',
                  label: 'Total XP',
                ),
              ),
              Container(width: 1, height: 54, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.emoji_events_outlined,
                  iconColor: const Color(0xFFF97316),
                  value: '$badgesCount',
                  label: 'Badges',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              Text(
                '$totalXp / $nextLevelXp XP',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 12,
            percent: progress,
            animation: true,
            animationDuration: 1000,
            barRadius: const Radius.circular(16),
            progressColor: const Color(0xFF22C55E),
            backgroundColor: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _RecentBadgesGrid extends StatelessWidget {
  final List<Map<String, String>> badges;

  const _RecentBadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: badges.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.82,
      ),
      itemBuilder: (context, index) {
        final badge = badges[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: Duration(milliseconds: 260 + (index * 60)),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge['icon'] ?? '⭐',
                  style: const TextStyle(fontSize: 27),
                ),
                const SizedBox(height: 4),
                Text(
                  badge['name'] ?? 'Badge',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBgColor;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.iconColor,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.location_on_outlined,
            title: 'My Reports',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyReportsScreen(),
                ),
              );
            },
          ),
          _buildDivider(),
          _MenuTile(
            icon: Icons.emoji_events_outlined,
            title: 'Achievements',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MissionsScreen()),
              );
            },
          ),
          _buildDivider(),
          _MenuTile(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 54, color: Color(0xFFF1F5F9));
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _MenuTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 22),
          ],
        ),
      ),
    );
  }
}
