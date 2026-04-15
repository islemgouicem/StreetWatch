import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/core/theme/app_theme.dart';
import 'package:mobile_app/models/index.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'review_submit_screen.dart';

class DetectionResultScreen extends StatefulWidget {
  final ReportDraft draft;

  const DetectionResultScreen({super.key, required this.draft});

  @override
  State<DetectionResultScreen> createState() => _DetectionResultScreenState();
}

class _DetectionResultScreenState extends State<DetectionResultScreen> {
  late String _damageType;
  late String _severity;

  static const List<String> _damageTypes = [
    'pothole',
    'crack',
    'broken_sign',
    'flooding',
    'debris',
    'other',
  ];

  static const List<String> _severityLevels = ['low', 'medium', 'high'];

  @override
  void initState() {
    super.initState();
    _damageType = widget.draft.damageType;
    _severity = widget.draft.severity;
  }

  String _labelize(String value) {
    return value
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const _HeaderSection(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                children: [
                  _CapturedImageCard(imagePath: widget.draft.imagePath),
                  const SizedBox(height: 20),
                  _DetectionDetailsCard(
                    damageType: _damageType,
                    severity: _severity,
                    onDamageTypeChanged: (value) => setState(() => _damageType = value),
                    onSeverityChanged: (value) => setState(() => _severity = value),
                    damageTypes: _damageTypes,
                    severityLevels: _severityLevels,
                    labelize: _labelize,
                  ),
                  const SizedBox(height: 20),
                  const _XpRewardCard(),
                  const SizedBox(height: 20),
                  const _NextStepInformation(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomActionSection(
        onRetake: () => Navigator.pop(context),
        onContinue: () {
          final nextDraft = widget.draft.copyWith(
            damageType: _damageType,
            severity: _severity,
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReviewSubmitScreen(draft: nextDraft),
            ),
          );
        },
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
            height: 280,
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
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            children: [
              const SizedBox(height: 60),
              Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Color(0xFF22C55E),
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Review Damage',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'AI comes later, choose the issue details now',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.9),
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

class _CapturedImageCard extends StatelessWidget {
  final String imagePath;

  const _CapturedImageCard({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: FileImage(File(imagePath)),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
    );
  }
}

class _DetectionDetailsCard extends StatelessWidget {
  final String damageType;
  final String severity;
  final ValueChanged<String> onDamageTypeChanged;
  final ValueChanged<String> onSeverityChanged;
  final List<String> damageTypes;
  final List<String> severityLevels;
  final String Function(String) labelize;

  const _DetectionDetailsCard({
    required this.damageType,
    required this.severity,
    required this.onDamageTypeChanged,
    required this.onSeverityChanged,
    required this.damageTypes,
    required this.severityLevels,
    required this.labelize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Report Details',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: damageType,
            items: damageTypes
                .map((value) => DropdownMenuItem(value: value, child: Text(labelize(value))))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onDamageTypeChanged(value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Damage type',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: severity,
            items: severityLevels
                .map((value) => DropdownMenuItem(value: value, child: Text(labelize(value))))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onSeverityChanged(value);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Severity',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Detection confidence',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                'Manual review',
                style: GoogleFonts.outfit(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            padding: EdgeInsets.zero,
            lineHeight: 12,
            percent: 1,
            animation: true,
            animationDuration: 700,
            barRadius: const Radius.circular(10),
            progressColor: AppTheme.successGreen,
            backgroundColor: Colors.grey.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

class _XpRewardCard extends StatelessWidget {
  const _XpRewardCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF22C55E), Color(0xFF84CC16)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'XP Reward',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '+25 XP',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.bolt, color: Colors.amber, size: 32),
          ),
        ],
      ),
    );
  }
}

class _NextStepInformation extends StatelessWidget {
  const _NextStepInformation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.outfit(
            color: const Color(0xFF3730A3),
            fontSize: 14,
            height: 1.5,
          ),
          children: const [
            TextSpan(
              text: 'Next Step: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: 'Confirm the location and submit your report to the live backend.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionSection extends StatelessWidget {
  final VoidCallback onRetake;
  final VoidCallback onContinue;

  const _BottomActionSection({
    required this.onRetake,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Retake'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
