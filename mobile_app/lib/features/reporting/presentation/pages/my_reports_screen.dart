import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/models/index.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late final ApiService _apiService;
  bool _isLoading = true;
  String? _error;
  List<Report> _reports = const [];

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(Supabase.instance.client);
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final mine = await _apiService.getMyReports(page: 1, pageSize: 100);

      if (!mounted) return;
      setState(() {
        _reports = mine;
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

  String _statusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.verified:
        return 'Verified';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
      case ReportStatus.pending:
        return 'Pending';
    }
  }

  Color _statusColor(ReportStatus status) {
    switch (status) {
      case ReportStatus.verified:
        return const Color(0xFF22C55E);
      case ReportStatus.resolved:
        return const Color(0xFF10B981);
      case ReportStatus.rejected:
        return const Color(0xFFEF4444);
      case ReportStatus.pending:
        return const Color(0xFF64748B);
    }
  }

  IconData _statusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.verified:
        return Icons.check_circle_outline;
      case ReportStatus.resolved:
        return Icons.task_alt;
      case ReportStatus.rejected:
        return Icons.cancel_outlined;
      case ReportStatus.pending:
        return Icons.help_outline;
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

  Color _severityColor(Severity severity) {
    switch (severity) {
      case Severity.high:
        return Colors.orange;
      case Severity.medium:
        return Colors.amber;
      case Severity.low:
        return Colors.green;
    }
  }

  String _damageLabel(DamageType damageType) {
    switch (damageType) {
      case DamageType.pothole:
        return 'Pothole';
      case DamageType.longitudinalCrack:
        return 'Longitudinal Crack';
      case DamageType.transverseCrack:
        return 'Transverse Crack';
      case DamageType.alligatorCrack:
        return 'Alligator Crack';
      case DamageType.other:
        return 'Other Damage';
    }
  }

  String _locationLabel(Report report) {
    return '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}';
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final day = twoDigits(date.day);
    final month = twoDigits(date.month);
    final year = date.year.toString();
    final hour = twoDigits(date.hour);
    final minute = twoDigits(date.minute);
    return '$day/$month/$year at $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final total = _reports.length;
    final verified = _reports
        .where((report) => report.status == ReportStatus.verified)
        .length;
    final resolved = _reports
        .where((report) => report.status == ReportStatus.resolved)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const _HeaderSection(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _StatsSummaryRow(
                      total: total,
                      verified: verified,
                      resolved: resolved,
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              'Failed to load your reports.',
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadReports,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (_reports.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'You have not submitted any reports yet.',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF64748B),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ..._reports.map(
                        (report) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _ReportCard(
                            title: _damageLabel(report.damageType),
                            location: _locationLabel(report),
                            severity: _severityLabel(report.severity),
                            severityColor: _severityColor(report.severity),
                            status: _statusLabel(report.status),
                            statusColor: _statusColor(report.status),
                            statusIcon: _statusIcon(report.status),
                            score: 'Score ${report.voteScore}',
                            date: _formatDate(report.createdAt),
                            imageUrl: report.imageUrl,
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
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

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipPath(
          clipper: _HeaderClipper(),
          child: Container(
            height: 220,
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
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        Positioned(
          top: 100,
          left: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Reports',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Track your contributions',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsSummaryRow extends StatelessWidget {
  final int total;
  final int verified;
  final int resolved;

  const _StatsSummaryRow({
    required this.total,
    required this.verified,
    required this.resolved,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('$total', 'Total'),
        _buildStatCard('$verified', 'Verified'),
        _buildStatCard('$resolved', 'Resolved'),
      ],
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
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
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String location;
  final String severity;
  final Color severityColor;
  final String status;
  final Color statusColor;
  final IconData statusIcon;
  final String score;
  final String date;
  final String? imageUrl;

  const _ReportCard({
    required this.title,
    required this.location,
    required this.severity,
    required this.severityColor,
    required this.status,
    required this.statusColor,
    required this.statusIcon,
    required this.score,
    required this.date,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
                ),
                clipBehavior: Clip.antiAlias,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(
                              child: Icon(
                                Icons.help_center_outlined,
                                color: Color(0xFF94A3B8),
                                size: 32,
                              ),
                            ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.help_center_outlined,
                          color: Color(0xFF94A3B8),
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.1),
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
                    const SizedBox(height: 6),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, color: statusColor, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                status,
                                style: GoogleFonts.outfit(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          score,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF16A34A),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Text(
            'Reported $date',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
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
