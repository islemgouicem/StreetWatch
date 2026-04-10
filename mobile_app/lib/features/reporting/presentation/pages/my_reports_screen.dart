import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/app_theme.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> reports = [
      {
        'title': 'Large Pothole',
        'location': '845 Market St, San Francisco, CA',
        'severity': 'High',
        'severityColor': Colors.orange,
        'status': 'Verified',
        'statusColor': const Color(0xFF22C55E),
        'xp': '+150 XP',
        'date': '31/03/2026 at 11:30',
        'hasImage': false,
      },
      {
        'title': 'Cracked Pavement',
        'location': '1234 Mission St, San Francisco, CA',
        'severity': 'Medium',
        'severityColor': Colors.amber,
        'status': 'In Progress',
        'statusColor': const Color(0xFF3B82F6),
        'xp': '+100 XP',
        'date': '30/03/2026 at 15:15',
        'hasImage': false,
      },
      {
        'title': 'Surface Crack',
        'location': '456 Howard St, San Francisco, CA',
        'severity': 'Low',
        'severityColor': Colors.green,
        'status': 'Pending',
        'statusColor': const Color(0xFF64748B),
        'xp': '+75 XP',
        'date': '29/03/2026 at 09:45',
        'imageUrl':
            'https://images.unsplash.com/photo-1596464716127-f2a82984de30',
        'hasImage': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _HeaderSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const _StatsSummaryRow(),
                  const SizedBox(height: 32),
                  ...reports
                      .map(
                        (report) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _ReportCard(
                            title: report['title'],
                            location: report['location'],
                            severity: report['severity'],
                            severityColor: report['severityColor'],
                            status: report['status'],
                            statusColor: report['statusColor'],
                            xp: report['xp'],
                            date: report['date'],
                            imageUrl: report['imageUrl'],
                            hasImage: report['hasImage'],
                          ),
                        ),
                      )
                      .toList(),
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
  const _StatsSummaryRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatCard('3', 'Total'),
        _buildStatCard('1', 'Verified'),
        _buildStatCard('0', 'Resolved'),
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
  final String xp;
  final String date;
  final String? imageUrl;
  final bool hasImage;

  const _ReportCard({
    required this.title,
    required this.location,
    required this.severity,
    required this.severityColor,
    required this.status,
    required this.statusColor,
    required this.xp,
    required this.date,
    this.imageUrl,
    this.hasImage = false,
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
                child: hasImage
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
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
                              if (status == 'Verified')
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: Color(0xFF22C55E),
                                  size: 14,
                                ),
                              if (status == 'In Progress')
                                const Icon(
                                  Icons.access_time,
                                  color: Color(0xFF3B82F6),
                                  size: 14,
                                ),
                              if (status == 'Pending')
                                const Icon(
                                  Icons.help_outline,
                                  color: Color(0xFF64748B),
                                  size: 14,
                                ),
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
                          xp,
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF22C55E),
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
