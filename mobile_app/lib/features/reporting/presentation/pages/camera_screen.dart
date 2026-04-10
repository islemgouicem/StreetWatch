import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'detection_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Grid Lines Overlay
          const _GridOverlay(),

          // Detection Frame
          const _DetectionFrameOverlay(),

          // Top Status Tags
          const _TopStatusSection(),

          // Bottom Action Bar
          _BottomActionSection(onCapture: () {
            // In a real app, capture image here. 
            // For now, navigate to detection result.
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DetectionResultScreen()),
            );
          }),
        ],
      ),
    );
  }
}

class _GridOverlay extends StatelessWidget {
  const _GridOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: List.generate(
          4,
          (index) => Expanded(
            child: Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetectionFrameOverlay extends StatelessWidget {
  const _DetectionFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        height: 320,
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF3B82F6).withOpacity(0.8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          children: [
            // Corners
            _buildCorner(top: 0, left: 0, rotation: 0),
            _buildCorner(top: 0, right: 0, rotation: 1.57),
            _buildCorner(bottom: 0, left: 0, rotation: 4.71),
            _buildCorner(bottom: 0, right: 0, rotation: 3.14),
            
            // Preview Label
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Preview',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required double rotation}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 4),
              left: BorderSide(color: Colors.white, width: 4),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _TopStatusSection extends StatelessWidget {
  const _TopStatusSection();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Row(
        children: [
          _StatusTag(
            icon: Icons.location_on,
            label: 'GPS Active',
            color: const Color(0xFF22C55E),
          ),
          const SizedBox(width: 12),
          _StatusTag(
            icon: Icons.bolt,
            label: 'AI Ready',
            color: const Color(0xFF84CC16),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusTag({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionSection extends StatelessWidget {
  final VoidCallback onCapture;
  const _BottomActionSection({required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(bottom: 60, top: 40, left: 30, right: 30),
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
            GestureDetector(
              onTap: onCapture,
              child: Container(
                width: 85,
                height: 85,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black, size: 40),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.crop_free, color: Colors.white, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}
