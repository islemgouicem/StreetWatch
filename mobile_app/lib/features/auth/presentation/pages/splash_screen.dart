import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/auth/presentation/pages/onboarding_screen.dart';
import 'package:mobile_app/navigation/navigation_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _sparkleController;
  Timer? _timer;

  Widget _nextScreen() {
    final hasSession = Supabase.instance.client.auth.currentSession != null;
    return hasSession ? const NavigationWrapper() : const OnboardingScreen();
  }

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _nextScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  double _pulse(double delay) {
    final shifted = (_sparkleController.value + delay) % 1.0;
    if (shifted < 0.5) {
      return 0.3 + (shifted * 2) * 0.7;
    }
    return 1.0 - ((shifted - 0.5) * 2) * 0.7;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0, end: 1).animate(
                  CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.6, end: 1).animate(
                  CurvedAnimation(
                    parent: _logoController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          margin: const EdgeInsets.only(bottom: 28),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 26,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.eco_rounded,
                            size: 66,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        Positioned(
                          right: -6,
                          top: -6,
                          child: AnimatedBuilder(
                            animation: _sparkleController,
                            builder: (context, child) {
                              final opacity = _pulse(0.0);
                              return Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: opacity,
                                  child: child,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFDE047),
                              size: 32,
                            ),
                          ),
                        ),
                        Positioned(
                          left: -6,
                          bottom: 16,
                          child: AnimatedBuilder(
                            animation: _sparkleController,
                            builder: (context, child) {
                              final opacity = _pulse(0.25);
                              return Opacity(
                                opacity: opacity,
                                child: Transform.scale(
                                  scale: opacity,
                                  child: child,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Color(0xFFFDE047),
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _logoController,
                        curve: const Interval(0.4, 1, curve: Curves.easeOut),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'StreetWatch',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Empowering communities together',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.82),
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: AnimatedBuilder(
                  animation: _sparkleController,
                  builder: (context, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LoadingDot(opacity: _pulse(0.0)),
                        const SizedBox(width: 8),
                        _LoadingDot(opacity: _pulse(0.18)),
                        const SizedBox(width: 8),
                        _LoadingDot(opacity: _pulse(0.36)),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDot extends StatelessWidget {
  final double opacity;

  const _LoadingDot({required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: const DecoratedBox(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: SizedBox(width: 8, height: 8),
      ),
    );
  }
}
