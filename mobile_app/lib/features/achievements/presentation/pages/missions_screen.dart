import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/models/badge.dart' as app_models;
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const List<Map<String, String>> _defaultBadgeCatalog = [
  {
    'code': 'first_report',
    'title': 'First Report',
    'description': 'Submit your first infrastructure report',
    'emoji': '🎯',
  },
  {
    'code': 'verified_reporter',
    'title': 'Verified Reporter',
    'description': 'Get your first report verified',
    'emoji': '🛡️',
  },
  {
    'code': 'sharp_eye',
    'title': 'Sharp Eye',
    'description': 'Submit 10 reports',
    'emoji': '👁️',
  },
  {
    'code': 'street_guardian',
    'title': 'Street Guardian',
    'description': 'Submit 25 reports',
    'emoji': '🏙️',
  },
  {
    'code': 'community_hero',
    'title': 'Community Hero',
    'description': 'Reach 1000 points',
    'emoji': '⭐',
  },
  {
    'code': 'century_club',
    'title': 'Century Club',
    'description': 'Submit 100 reports',
    'emoji': '💯',
  },
  {
    'code': 'fast_responder',
    'title': 'Fast Responder',
    'description': 'Reach 10 verified reports',
    'emoji': '⚡',
  },
  {
    'code': 'top_reporter',
    'title': 'Top Reporter',
    'description': 'Reach 2500 points',
    'emoji': '🏆',
  },
  {
    'code': 'first_vote',
    'title': 'Civic Validator',
    'description': 'Cast your first report vote',
    'emoji': '🗳️',
  },
];

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  late final ApiService _apiService;
  List<app_models.Badge> _unlockedBadges = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Supabase.instance.client);
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final badges = await _apiService.getMyBadges();
      if (!mounted) {
        return;
      }
      setState(() {
        _unlockedBadges = badges;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, String>> get _lockedBadges {
    final unlockedCodes = _unlockedBadges
        .map((badge) => badge.code)
        .whereType<String>()
        .toSet();
    return _defaultBadgeCatalog
        .where((badge) => !unlockedCodes.contains(badge['code']))
        .toList();
  }

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
                  _SectionHeader(
                    title: 'Unlocked',
                    count: '${_unlockedBadges.length} earned',
                    color: const Color(0xFF22C55E),
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    const _StateCard(
                      title: 'Loading badges...',
                      description: 'Fetching your unlocked achievements from the backend.',
                    )
                  else if (_error != null)
                    _StateCard(
                      title: 'Couldn\'t load badges',
                      description: _error!,
                    )
                  else
                    _BadgeGridUnlocked(items: _unlockedBadges),
                  const SizedBox(height: 44),
                  _SectionHeader(
                    title: 'Locked',
                    count: '${_lockedBadges.length} remaining',
                    color: const Color(0xFFF1F5F9),
                    textColor: const Color(0xFF64748B),
                  ),
                  const SizedBox(height: 24),
                  _BadgeGridLocked(items: _lockedBadges),
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

class _StateCard extends StatelessWidget {
  final String title;
  final String description;

  const _StateCard({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeGridUnlocked extends StatelessWidget {
  final List<app_models.Badge> items;

  const _BadgeGridUnlocked({required this.items});

  String _emojiForBadge(app_models.Badge badge) {
    final match = _defaultBadgeCatalog.firstWhere(
      (entry) => entry['code'] == badge.code,
      orElse: () => {'emoji': '🏅'},
    );
    return match['emoji'] ?? '🏅';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Unlocked recently';
    }
    return 'Unlocked ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final badge = items[index];
        return _BadgeCard(
          title: badge.name,
          description: badge.description ?? 'Unlocked achievement',
          emoji: _emojiForBadge(badge),
          date: _formatDate(badge.awardedAt),
          borderColor: const Color(0xFF3B82F6),
        );
      },
    );
  }
}

class _BadgeGridLocked extends StatelessWidget {
  final List<Map<String, String>> items;

  const _BadgeGridLocked({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final badge = items[index];
        return _BadgeCard(
          title: badge['title'] ?? 'Locked badge',
          description: badge['description'] ?? 'Keep contributing to unlock this badge.',
          emoji: badge['emoji'] ?? '🔒',
          borderColor: const Color(0xFF94A3B8),
          isLocked: true,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor.withOpacity(isLocked ? 0.2 : 0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          if (date != null) ...[
            const SizedBox(height: 6),
            Text(
              date!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: borderColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 10,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 20,
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
