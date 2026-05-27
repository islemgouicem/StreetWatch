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

  double get _topConfidence {
    final boxes = widget.draft.boundingBoxes;
    if (boxes == null || boxes.isEmpty) return 0.0;
    return (boxes.first['score'] as double?) ?? 0.0;
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
                  _CapturedImageCard(
                    imagePath: widget.draft.imagePath,
                    boundingBoxes: widget.draft.boundingBoxes,
                  ),
                  const SizedBox(height: 20),
                  const _ModelDetailsCard(),
                  const SizedBox(height: 20),
                  _DetectionDetailsCard(
                    damageType: _damageType,
                    severity: _severity,
                    confidence: _topConfidence,
                    labelize: _labelize,
                  ),
                  const SizedBox(height: 20),
                  if (widget.draft.boundingBoxes != null &&
                      widget.draft.boundingBoxes!.isNotEmpty)
                    _AllDetectionsCard(
                      boxes: widget.draft.boundingBoxes!,
                      labelize: _labelize,
                    ),
                  if (widget.draft.boundingBoxes != null &&
                      widget.draft.boundingBoxes!.isNotEmpty)
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
                'AI Analysis Complete',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'AI',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'The model identified the issue.',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
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

class _CapturedImageCard extends StatelessWidget {
  final String imagePath;
  final List<Map<String, dynamic>>? boundingBoxes;

  const _CapturedImageCard({required this.imagePath, this.boundingBoxes});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(imagePath), fit: BoxFit.cover),
          if (boundingBoxes != null && boundingBoxes!.isNotEmpty)
            CustomPaint(painter: _BoundingBoxPainter(boxes: boundingBoxes!)),
        ],
      ),
    );
  }
}

class _BoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> boxes;

  _BoundingBoxPainter({required this.boxes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = const Color(0xFFEF4444);

    final bgPaint = Paint()..color = const Color(0xFFEF4444);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var box in boxes) {
      double left = box['left'] * size.width;
      double top = box['top'] * size.height;
      double width = box['width'] * size.width;
      double height = box['height'] * size.height;

      final rect = Rect.fromLTWH(left, top, width, height);
      canvas.drawRect(rect, paint);

      textPainter.text = TextSpan(
        text: ' ${box['label']} ${(box['score'] * 100).toStringAsFixed(0)}% ',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();

      // Draw label background
      final labelY = top > 16 ? top - 16 : top + height;
      canvas.drawRect(
        Rect.fromLTWH(left, labelY, textPainter.width, textPainter.height),
        bgPaint,
      );

      textPainter.paint(canvas, Offset(left, labelY));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _DetectionDetailsCard extends StatelessWidget {
  final String damageType;
  final String severity;
  final double confidence;
  final String Function(String) labelize;

  const _DetectionDetailsCard({
    required this.damageType,
    required this.severity,
    required this.confidence,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelize(damageType),
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: severity == 'high'
                      ? const Color(0xFFFEF2F2)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      severity == 'high'
                          ? Icons.error_outline
                          : Icons.warning_amber_rounded,
                      color: severity == 'high'
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFEA580C),
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      labelize(severity),
                      style: GoogleFonts.outfit(
                        color: severity == 'high'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFEA580C),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AI Confidence',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                '${(confidence * 100).toStringAsFixed(1)}%',
                style: GoogleFonts.outfit(
                  color: confidence >= 0.7
                      ? AppTheme.successGreen
                      : confidence >= 0.5
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF64748B),
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
            percent: confidence.clamp(0.0, 1.0),
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

class _ModelDetailsCard extends StatelessWidget {
  const _ModelDetailsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.smart_toy,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Model Details',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _modelInfoRow('Architecture', 'YOLOv8n'),
          const SizedBox(height: 8),
          _modelInfoRow('Input Size', '320 × 320 px'),
          const SizedBox(height: 8),
          _modelInfoRow('Classes', '5 (RDD2022)'),
          const SizedBox(height: 8),
          _modelInfoRow('Format', 'TFLite (Float32)'),
          const SizedBox(height: 8),
          _modelInfoRow('NMS Threshold', '0.45'),
          const SizedBox(height: 8),
          _modelInfoRow('Confidence Threshold', '0.45'),
        ],
      ),
    );
  }

  Widget _modelInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: const Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: const Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AllDetectionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> boxes;
  final String Function(String) labelize;

  const _AllDetectionsCard({required this.boxes, required this.labelize});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.list_alt, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                'All Detections (${boxes.length})',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...boxes.asMap().entries.map((entry) {
            final i = entry.key;
            final box = entry.value;
            final label = labelize(box['label'] as String);
            final score = ((box['score'] as double) * 100).toStringAsFixed(1);
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '$score%',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
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
              text:
                  'Confirm the location and submit your report to the live backend.',
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
