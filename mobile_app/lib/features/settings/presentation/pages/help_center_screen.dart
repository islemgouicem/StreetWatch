import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      (
        'How do I submit a report?',
        'Use the Report button on Home, capture damage, review, then submit.',
      ),
      (
        'How is XP calculated?',
        'You gain XP for valid reports, confirmations, and community activity.',
      ),
      (
        'Why is my report pending?',
        'Reports are reviewed by votes and moderation before final verification.',
      ),
    ];

    return SettingsPageShell(
      title: 'Help Center',
      subtitle: 'FAQs and support',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          ...faqs.map(
            (faq) => Container(
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
                    faq.$1,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    faq.$2,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              const supportEmail = 'support@streetwatch.app';
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Support email copied: support@streetwatch.app',
                  ),
                ),
              );
            },
            icon: const Icon(Icons.support_agent),
            label: Text(
              'Contact Support',
              style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
