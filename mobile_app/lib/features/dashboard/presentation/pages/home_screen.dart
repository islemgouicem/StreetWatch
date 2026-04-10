import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../theme/app_theme.dart';
import 'detection_result_screen.dart';
import 'missions_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _HeaderSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 0),
                  const _ReportDamageAction(),
                  const SizedBox(height: 24),
                  const _QuickStatsRow(),
                  const SizedBox(height: 32),
                  const _DailyMissionsSection(),
                  const SizedBox(height: 32),
                  const _NearbyIssuesSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Curved background
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 340,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
              ),
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.only(top: 60, left: 24, right: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Alex Rivera',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24, // Reduced from 28
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10), // Reduced from 10
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 24, // Reduced from 28
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF97316),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '3',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10, // Reduced from 10
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26), // Reduced from 32
              // Level Card
              Container(
                padding: const EdgeInsets.all(16), // Reduced from 20
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24), // Reduced from 28
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Level Circle
                            Container(
                              width: 44, // Reduced from 52
                              height: 44,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppTheme.xpGradientStart,
                                    AppTheme.xpGradientEnd,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '12',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16, // Reduced from 20
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Level',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13, // Reduced from 14
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  'Level 12',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 18, // Reduced from 20
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Rank',
                              style: GoogleFonts.outfit(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13, // Reduced from 14
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              '#3',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 22, // Reduced from 24
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Animated Progress Bar with Gradient
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 10.0,
                      percent: 0.72,
                      animation: true,
                      animationDuration: 1200,
                      barRadius: const Radius.circular(10),
                      linearGradient: const LinearGradient(
                        colors: [
                          AppTheme.xpGradientStart,
                          AppTheme.xpGradientEnd,
                        ],
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '653 XP to Level 13',
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12, // Reduced from 14
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _ReportDamageAction extends StatelessWidget {
  const _ReportDamageAction();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DetectionResultScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFFFB923C)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report Damage',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Spot an issue? Capture it now!',
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Color(0xFFF97316),
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.my_location,
            value: '87',
            label: 'Reports',
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt,
            value: '2847',
            label: 'Total XP',
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            value: '6',
            label: 'Badges',
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        padding: const EdgeInsets.all(12), // Further reduced from 14
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18), // Reduced from 20
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 20, // Slightly reduced for safety
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11, // Slightly reduced
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyMissionsSection extends StatelessWidget {
  const _DailyMissionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Missions',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
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
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _MissionCard(
          title: 'Daily Scout',
          description: 'Report 3 issues today',
          progress: '2/3',
          percent: 0.66,
          reward: '+200 XP',
        ),
        const SizedBox(height: 16),
        const _MissionCard(
          title: 'Explorer',
          description: 'Report issues in 3 different neighborhoods',
          progress: '2/3',
          percent: 0.66,
          reward: '+350 XP',
        ),
      ],
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final String description;
  final String progress;
  final double percent;
  final String reward;

  const _MissionCard({
    required this.title,
    required this.description,
    required this.progress,
    required this.percent,
    required this.reward,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                reward,
                style: GoogleFonts.outfit(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: LinearPercentIndicator(
                  padding: EdgeInsets.zero,
                  lineHeight: 8.0,
                  percent: percent,
                  animation: true,
                  animationDuration: 1000,
                  barRadius: const Radius.circular(10),
                  progressColor: AppTheme.primaryBlue,
                  backgroundColor: const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                progress,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NearbyIssuesSection extends StatelessWidget {
  const _NearbyIssuesSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nearby Issues',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View Map',
                style: GoogleFonts.outfit(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _IssueCard(
          title: 'Large Pothole',
          location: '845 Market St, San Francisco, CA',
          severity: 'High',
          severityColor: Colors.orange,
          showPlaceholder: true,
        ),
        const SizedBox(height: 16),
        const _IssueCard(
          title: 'Cracked Pavement',
          location: '1234 Mission St, San Francisco, CA',
          severity: 'Medium',
          severityColor: Colors.yellow,
          showPlaceholder: true,
        ),
        _IssueCard(
          title: 'Damaged Sign',
          location: '567 Valencia St, San Francisco, CA',
          severity: 'Low',
          severityColor: Colors.green.shade400,
          imageUrl:
              'https://images.unsplash.com/photo-1596464716127-f2a82984de30',
        ),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  final String title;
  final String location;
  final String severity;
  final Color severityColor;
  final String? imageUrl;
  final bool showPlaceholder;

  const _IssueCard({
    required this.title,
    required this.location,
    required this.severity,
    required this.severityColor,
    this.imageUrl,
    this.showPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFF8FAFC),
            ),
            clipBehavior: Clip.antiAlias,
            child: showPlaceholder
                ? const Icon(
                    Icons.help_center_outlined,
                    color: Color(0xFF94A3B8),
                    size: 32,
                  )
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF94A3B8),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF64748B),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity,
                    style: GoogleFonts.outfit(
                      color: severityColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
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
