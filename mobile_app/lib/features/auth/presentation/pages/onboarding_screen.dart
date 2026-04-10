import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/auth/presentation/pages/sign_in_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Spot & Report',
      description:
          'Take photos of potholes, cracks, and damaged infrastructure in your neighborhood',
      icon: Icons.camera_alt_outlined,
      iconBg: Color(0xFF2F58C0),
    ),
    _OnboardingItem(
      title: 'Build the Map',
      description:
          'Your reports create a real-time infrastructure map to help your community',
      icon: Icons.location_on_outlined,
      iconBg: Color(0xFFFF8A23),
    ),
    _OnboardingItem(
      title: 'Earn Rewards',
      description:
          'Gain XP, unlock badges, climb the leaderboard and become a civic hero',
      icon: Icons.emoji_events_outlined,
      iconBg: Color(0xFF57CC71),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToSignIn() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const SignInScreen()));
  }

  void _next() {
    if (_currentIndex == _items.length - 1) {
      _goToSignIn();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF274AA2), Color(0xFF3F82F2), Color(0xFF10B981)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'StreetWatch',
                  style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your City. Your Mission.',
                  style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _OnboardingPage(item: item);
                  },
                ),
              ),
              _DotIndicator(length: _items.length, index: _currentIndex),
              const SizedBox(height: 26),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1D4295),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: _next,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex == _items.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                        if (_currentIndex != _items.length - 1) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 14),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _goToSignIn,
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 520;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 100 : 128,
                  height: compact ? 100 : 128,
                  decoration: BoxDecoration(
                    color: item.iconBg,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: compact ? 44 : 56,
                  ),
                ),
                SizedBox(height: compact ? 20 : 32),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: compact ? 30 : 34,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  item.description,
                  textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.93),
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.length, required this.index});

  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (dotIndex) {
        final isActive = dotIndex == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: isActive ? 28 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isActive ? 0.95 : 0.45),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconBg,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color iconBg;
}
