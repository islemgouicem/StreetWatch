import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPageShell(
      title: 'Privacy Policy',
      subtitle: 'How we protect your data',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: const [
          _PolicyCard(
            title: 'Data We Collect',
            text:
                'We collect account details, reports you submit, and app usage data required to operate StreetWatch.',
          ),
          _PolicyCard(
            title: 'How We Use Data',
            text:
                'Your data powers map insights, report moderation, leaderboard metrics, and security monitoring.',
          ),
          _PolicyCard(
            title: 'Storage & Security',
            text:
                'Data is stored with encrypted transport and role-based access. Sensitive actions require authenticated sessions.',
          ),
          _PolicyCard(
            title: 'Your Controls',
            text:
                'You can edit profile information, manage notification preferences, and request account deletion through support.',
          ),
        ],
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  final String title;
  final String text;

  const _PolicyCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
