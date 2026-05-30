import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile_app/mock_images.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:mobile_app/models/index.dart';
import 'package:mobile_app/services/tflite_service.dart';

import 'detection_result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _isSimulator = false;
  final TfliteService _tfliteService = TfliteService();

  // The currently displayed random image (simulator only)
  String? _currentAssetPath;
  File? _currentImageFile;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _tfliteService.loadModel();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _isSimulator = true);
        _loadRandomImage(); // pre-load random image for viewfinder
        return;
      }

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (!mounted) return;
      setState(() => _isSimulator = true);
      _loadRandomImage(); // pre-load random image for viewfinder
    }
  }

  /// Loads a random image from the bundled test images and writes it to temp
  Future<void> _loadRandomImage() async {
    final randomAssetPath = mockImages[Random().nextInt(mockImages.length)];
    try {
      final byteData = await rootBundle.load(randomAssetPath);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${randomAssetPath.split('/').last}');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!mounted) return;
      setState(() {
        _currentAssetPath = randomAssetPath;
        _currentImageFile = file;
      });
    } catch (e) {
      debugPrint('Failed to load random image: $e');
    }
  }

  String _mapSeverity(double score) {
    if (score >= 0.4) return 'high';
    if (score >= 0.2) return 'medium';
    return 'low';
  }

  Future<void> _captureAndContinue() async {
    final controller = _controller;
    if (!_isSimulator &&
        (controller == null ||
            !controller.value.isInitialized ||
            _isCapturing)) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      late File imageFile;

      if (_isSimulator) {
        if (_currentImageFile != null) {
          imageFile = _currentImageFile!;
        } else {
          // fallback: load one now
          final randomAssetPath =
              mockImages[Random().nextInt(mockImages.length)];
          final byteData = await rootBundle.load(randomAssetPath);
          final tempDir = await getTemporaryDirectory();
          imageFile = File(
            '${tempDir.path}/${randomAssetPath.split('/').last}',
          );
          await imageFile.writeAsBytes(byteData.buffer.asUint8List());
        }
      } else {
        final picture = await controller!.takePicture();
        imageFile = File(picture.path);
      }

      // Run Inference
      final recognitions = await _tfliteService.runInference(imageFile);

      String detectedDamageType = 'other';
      String detectedSeverity = 'low';
      double confidence = 0.0;

      if (recognitions.isNotEmpty) {
        final topRecognition = recognitions.first;
        detectedDamageType = topRecognition.label;
        detectedSeverity = _mapSeverity(topRecognition.score);
        confidence = topRecognition.score;
      }

      if (!mounted) return;

      final draft = ReportDraft(
        imagePath: imageFile.path,
        damageType: detectedDamageType,
        severity: detectedSeverity,
        boundingBoxes: recognitions
            .map(
              (r) => {
                'label': r.label,
                'score': r.score,
                'left': r.location.left,
                'top': r.location.top,
                'width': r.location.width,
                'height': r.location.height,
              },
            )
            .toList(),
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetectionResultScreen(draft: draft),
        ),
      );

      // After returning from results, load next random image
      if (_isSimulator && mounted) {
        _loadRandomImage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _tfliteService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while camera / image initializes
    if (!_isSimulator && (!_isCameraInitialized || _controller == null)) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    Widget viewfinder;
    if (_isSimulator) {
      if (_currentImageFile != null) {
        viewfinder = Image.file(_currentImageFile!, fit: BoxFit.cover);
      } else {
        viewfinder = const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
    } else {
      viewfinder = CameraPreview(_controller!);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: viewfinder),
          const _GridOverlay(),
          const _DetectionFrameOverlay(),
          _TopStatusSection(
            isSimulator: _isSimulator,
            imageName: _currentAssetPath,
          ),
          _BottomActionSection(
            isCapturing: _isCapturing,
            onCapture: _captureAndContinue,
            onShuffle: _isSimulator ? _loadRandomImage : null,
          ),
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
          (_) => Expanded(
            child: Row(
              children: List.generate(
                3,
                (_) => Expanded(
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
            _buildCorner(top: 0, left: 0, rotation: 0),
            _buildCorner(top: 0, right: 0, rotation: 1.57),
            _buildCorner(bottom: 0, left: 0, rotation: 4.71),
            _buildCorner(bottom: 0, right: 0, rotation: 3.14),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Frame the road issue',
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

  Widget _buildCorner({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double rotation,
  }) {
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
  final bool isSimulator;
  final String? imageName;

  const _TopStatusSection({required this.isSimulator, this.imageName});

  @override
  Widget build(BuildContext context) {
    // Extract just the filename from the path
    final displayName = imageName?.split('/').last ?? '';

    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _StatusTag(
                icon: Icons.location_on,
                label: 'GPS on submit',
                color: Color(0xFF22C55E),
              ),
              const SizedBox(width: 12),
              const _StatusTag(
                icon: Icons.smart_toy,
                label: 'AI Ready',
                color: Color(0xFF3B82F6),
              ),
            ],
          ),
          if (isSimulator && displayName.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.image, color: Color(0xFFFBBF24), size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      displayName,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusTag({
    required this.icon,
    required this.label,
    required this.color,
  });

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
  final bool isCapturing;
  final VoidCallback onCapture;
  final VoidCallback? onShuffle;

  const _BottomActionSection({
    required this.isCapturing,
    required this.onCapture,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.only(
          bottom: 60,
          top: 40,
          left: 30,
          right: 30,
        ),
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
              onTap: isCapturing ? null : onCapture,
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
                  child: isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : const Icon(
                          Icons.camera_alt,
                          color: Colors.black,
                          size: 40,
                        ),
                ),
              ),
            ),
            // Shuffle button (simulator) or crop button (device)
            GestureDetector(
              onTap: onShuffle,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  onShuffle != null ? Icons.shuffle : Icons.crop_free,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
