import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/features/achievements/presentation/pages/missions_screen.dart';
import 'package:mobile_app/features/Map/presentation/page/map.dart';
import 'package:mobile_app/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:mobile_app/features/reporting/presentation/pages/camera_screen.dart';
import 'package:mobile_app/bloc/index.dart';
import 'package:mobile_app/models/index.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _HeaderSection(state: state),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      const _ReportDamageAction(),
                      const SizedBox(height: 24),
                      _QuickStatsRow(state: state),
                      const SizedBox(height: 32),
                      _DailyMissionsSection(state: state),
                      const SizedBox(height: 32),
                      const _NearbyIssuesSection(),
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

class _HeaderSection extends StatefulWidget {
  final AuthState state;
  const _HeaderSection({required this.state});

  @override
  State<_HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<_HeaderSection> {
  late final ApiService _apiService;
  int? _rank;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Supabase.instance.client);
    // Fetch user data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(const AuthFetchCurrentUserEvent());
      _loadRank();
    });
  }

  @override
  void didUpdateWidget(covariant _HeaderSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.state is AuthSuccess
        ? (oldWidget.state as AuthSuccess).user.id
        : null;
    final newId = widget.state is AuthSuccess
        ? (widget.state as AuthSuccess).user.id
        : null;
    if (newId != null && newId != oldId) {
      _loadRank();
    }
  }

  Future<void> _loadRank() async {
    if (widget.state is! AuthSuccess) {
      return;
    }
    final userId = (widget.state as AuthSuccess).user.id;
    try {
      final entries = await _apiService.getLeaderboard(limit: 100);
      int? rank;
      for (final entry in entries) {
        if (entry.userId == userId) {
          rank = entry.rank;
          break;
        }
      }
      if (mounted) {
        setState(() => _rank = rank);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _rank = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.state is AuthSuccess
        ? (widget.state as AuthSuccess).user
        : null;
    final points = user?.points ?? 0;
    final level = (points ~/ 500) + 1;
    final xpInLevel = points % 500;
    const xpToNextLevel = 500;
    final xpRemaining = xpToNextLevel - xpInLevel;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                    color: Colors.white.withValues(alpha: 0.12),
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
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
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
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  user?.fullName ?? user?.username ?? 'User',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 28,
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
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.notifications_none,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF97316),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF1E3A8A),
                                          width: 2,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '3',
                                          style: GoogleFonts.outfit(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Color(0xFF10B981),
                                              Color(0xFF84CC16),
                                            ],
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$level',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Level',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white.withValues(
                                                alpha: 0.8,
                                              ),
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            'Level $level',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 18,
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
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        _rank != null ? '#$_rank' : '#--',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearPercentIndicator(
                                padding: EdgeInsets.zero,
                                lineHeight: 8,
                                percent: (xpInLevel / xpToNextLevel).clamp(
                                  0.0,
                                  1.0,
                                ),
                                animation: true,
                                animationDuration: 900,
                                barRadius: const Radius.circular(99),
                                linearGradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF3B82F6),
                                    Color(0xFF60A5FA),
                                  ],
                                ),
                                backgroundColor: const Color(0xFFF1F5F9),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$xpRemaining XP to Level ${level + 1}',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
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
}

class _ReportDamageAction extends StatefulWidget {
  const _ReportDamageAction();

  @override
  State<_ReportDamageAction> createState() => _ReportDamageActionState();
}

class _ReportDamageActionState extends State<_ReportDamageAction> {
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        );
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        scale: _isPressed ? 0.95 : 1,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFFF97316), Color(0xFFFB923C)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -64,
                right: -64,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Positioned(
                bottom: -48,
                left: -48,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
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
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Spot an issue? Capture it now!',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
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
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatefulWidget {
  final AuthState state;
  const _QuickStatsRow({required this.state});

  @override
  State<_QuickStatsRow> createState() => _QuickStatsRowState();
}

class _QuickStatsRowState extends State<_QuickStatsRow> {
  late final ApiService _apiService;
  UserStats? _stats;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Supabase.instance.client);
    _loadStats();
  }

  @override
  void didUpdateWidget(covariant _QuickStatsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.state is AuthSuccess
        ? (oldWidget.state as AuthSuccess).user.id
        : null;
    final newId = widget.state is AuthSuccess
        ? (widget.state as AuthSuccess).user.id
        : null;
    if (newId != null && newId != oldId) {
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    if (widget.state is! AuthSuccess) return;
    final userId = (widget.state as AuthSuccess).user.id;
    try {
      final stats = await _apiService.getUserStats(userId);
      if (!mounted) return;
      setState(() => _stats = stats);
    } catch (_) {
      if (!mounted) return;
      setState(() => _stats = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.state is AuthSuccess
        ? (widget.state as AuthSuccess).user
        : null;

    final reportsCount = _stats?.reportsCount ?? user?.totalReports ?? 0;
    final points = _stats?.points ?? user?.points ?? 0;
    final badgesCount = _stats?.badgesCount ?? 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.my_location,
            value: '$reportsCount',
            label: 'Reports',
            iconColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt,
            value: '$points',
            label: 'Total XP',
            iconColor: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            value: '$badgesCount',
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
  final AuthState state;

  const _DailyMissionsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final user = state is AuthSuccess ? (state as AuthSuccess).user : null;
    final totalReports = user?.totalReports ?? 0;
    final verifiedReports = user?.verifiedReports ?? 0;

    const missionOneTarget = 3;
    final missionOneProgress = totalReports % missionOneTarget;
    final missionOnePercent = (missionOneProgress / missionOneTarget)
        .clamp(0.0, 1.0)
        .toDouble();

    const missionTwoTarget = 5;
    final missionTwoProgress = verifiedReports % missionTwoTarget;
    final missionTwoPercent = (missionTwoProgress / missionTwoTarget)
        .clamp(0.0, 1.0)
        .toDouble();

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
        _MissionCard(
          title: 'Daily Scout',
          description: 'Submit 3 reports to complete today\'s mission',
          progress: '$missionOneProgress/$missionOneTarget',
          percent: missionOnePercent,
          reward: '+200 XP',
        ),
        const SizedBox(height: 16),
        _MissionCard(
          title: 'Quality Reporter',
          description: 'Reach 5 verified reports for this cycle',
          progress: '$missionTwoProgress/$missionTwoTarget',
          percent: missionTwoPercent,
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

class _NearbyIssuesSection extends StatefulWidget {
  const _NearbyIssuesSection();

  @override
  State<_NearbyIssuesSection> createState() => _NearbyIssuesSectionState();
}

class _NearbyIssuesSectionState extends State<_NearbyIssuesSection> {
  late final ApiService _apiService;
  bool _isLoading = true;
  String? _error;
  List<Report> _reports = const [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Supabase.instance.client);
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final position = await _getCurrentPosition();
      final reports = await _apiService.getNearbyReports(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusKm: 5.0,
      );
      if (!mounted) return;
      setState(() {
        _reports = reports.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission denied');
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Color _severityColor(Severity severity) {
    switch (severity) {
      case Severity.high:
        return Colors.orange;
      case Severity.medium:
        return Colors.yellow.shade700;
      case Severity.low:
        return Colors.green;
    }
  }

  String _severityLabel(Severity severity) {
    switch (severity) {
      case Severity.high:
        return 'High';
      case Severity.medium:
        return 'Medium';
      case Severity.low:
        return 'Low';
    }
  }

  String _damageLabel(DamageType damageType) {
    switch (damageType) {
      case DamageType.pothole:
        return 'Pothole';
      case DamageType.crack:
        return 'Cracked Pavement';
      case DamageType.flooding:
        return 'Flooding';
      case DamageType.debris:
        return 'Road Debris';
      case DamageType.other:
        return 'Infrastructure Issue';
    }
  }

  String _locationLabel(Report report) {
    if (report.distanceMeters != null) {
      final km = report.distanceMeters! / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
    return '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}';
  }

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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapPage()),
                );
              },
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
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          )
        else if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  'Failed to load nearby issues.',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(onPressed: _loadNearby, child: const Text('Retry')),
              ],
            ),
          )
        else if (_reports.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No nearby issues found yet.',
              style: GoogleFonts.outfit(
                color: const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          )
        else
          ..._reports.asMap().entries.map((entry) {
            final index = entry.key;
            final report = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == _reports.length - 1 ? 0 : 16,
              ),
              child: _IssueCard(
                title: _damageLabel(report.damageType),
                location: _locationLabel(report),
                severity: _severityLabel(report.severity),
                severityColor: _severityColor(report.severity),
                imageUrl: report.imageUrl,
              ),
            );
          }),
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

  const _IssueCard({
    required this.title,
    required this.location,
    required this.severity,
    required this.severityColor,
    this.imageUrl,
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
            child: imageUrl == null || imageUrl!.isEmpty
                ? const Icon(
                    Icons.image_not_supported,
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
