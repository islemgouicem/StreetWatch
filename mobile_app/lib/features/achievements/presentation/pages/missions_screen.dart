import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/app_theme.dart';

class MissionsScreen extends StatelessWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _HeaderSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const _SectionHeader(
                    title: 'Unlocked',
                    count: '6 earned',
                    color: Color(0xFF22C55E),
                  ),
                  SizedBox(height: 24),
                  const _BadgeGrid(isLocked: false),
                  SizedBox(height: 44),
                  const _SectionHeader(
                    title: 'Locked',
                    count: '3 remaining',
                    color: Color(0xFFF1F5F9),
                    textColor: Color(0xFF64748B),
                  ),
                  SizedBox(height: 24),
                  const _BadgeGrid(isLocked: true),
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
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 140,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.primaryBlue, AppTheme.accentBlue],
              ),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: 10,
          child: TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            label: Text(
              'Back',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String count;
  final Color color;
  final Color textColor;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    this.textColor = const Color(0xFF22C55E),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            count,
            style: GoogleFonts.outfit(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _BadgeGrid extends StatelessWidget {
  final bool isLocked;

  const _BadgeGrid({required this.isLocked});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = isLocked
        ? [
            {
              'title': 'Week Warrior',
              'description': 'Report issues 7 days in a row',
              'emoji': '🔥',
              'color': const Color(0xFF3B82F6),
            },
            {
              'title': 'Critical Spotter',
              'description': 'Find and report 3 critical issues',
              'emoji': '⚠️',
              'color': const Color(0xFFA855F7),
            },
            {
              'title': 'Neighborhood Legend',
              'description': 'Reach level 20',
              'emoji': '👑',
              'color': const Color(0xFFF59E0B),
            },
          ]
        : [
            {
              'title': 'First Report',
              'description': 'Submit your first infrastructure report',
              'emoji': '🎯',
              'date': 'Unlocked 15/02/2026',
              'color': const Color(0xFF3B82F6),
            },
            {
              'title': 'Street Guardian',
              'description': 'Report 25 issues in your city',
              'emoji': '🛡️',
              'date': 'Unlocked 01/03/2026',
              'color': const Color(0xFF64748B),
            },
            {
              'title': 'Sharp Eye',
              'description': 'Report 5 high-severity issues',
              'emoji': '👁️',
              'date': 'Unlocked 10/03/2026',
              'color': const Color(0xFF3B82F6),
            },
            {
              'title': 'Community Hero',
              'description': 'Reach top 10 on the leaderboard',
              'emoji': '⭐',
              'date': 'Unlocked 20/03/2026',
              'color': const Color(0xFFA855F7),
            },
            {
              'title': 'Century Club',
              'description': 'Submit 100 reports',
              'emoji': '💯',
              'date': 'Unlocked 25/03/2026',
              'color': const Color(0xFFA855F7),
            },
            {
              'title': 'Urban Sentinel',
              'description': 'Complete all daily missions for a month',
              'emoji': '🏅',
              'date': 'Unlocked 28/03/2026',
              'color': const Color(0xFFF59E0B),
            },
          ];

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _BadgeCard(
          title: items[index]['title'],
          description: items[index]['description'],
          emoji: items[index]['emoji'],
          date: items[index]['date'],
          borderColor: items[index]['color'],
          isLocked: isLocked,
        );
      },
    );
  }
}

class _BadgeCard extends StatelessWidget {
  final String title;
  final String description;
  final String emoji;
  final String? date;
  final Color borderColor;
  final bool isLocked;

  const _BadgeCard({
    required this.title,
    required this.description,
    required this.emoji,
    this.date,
    required this.borderColor,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor.withOpacity(isLocked ? 0.2 : 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: isLocked ? 3 : 0,
                  sigmaY: isLocked ? 3 : 0,
                ),
                child: Container(
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: isLocked ? 2 : 0,
                  sigmaY: isLocked ? 2 : 0,
                ),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLocked && date != null) ...[
                const SizedBox(height: 12),
                Text(
                  date!,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (isLocked)
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFF64748B),
                  size: 28,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
