import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super.key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  bool incidentDigest = true;
  bool milestoneAlerts = true;
  bool productUpdates = false;
  bool _isSaving = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _apiService = ApiService(supabase);
  }

  Future<void> _updateEmailPreferences() async {
    setState(() => _isSaving = true);

    try {
      await _apiService.updateEmailPreferences(
        incidentDigest: incidentDigest,
        milestoneAlerts: milestoneAlerts,
        productUpdates: productUpdates,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email preferences saved'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageShell(
      title: 'Email Settings',
      subtitle: 'Manage your email preferences',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                _toggleTile(
                  title: 'Incident Digest',
                  subtitle: 'Weekly summary of nearby road issues',
                  value: incidentDigest,
                  onChanged: (v) async {
                    setState(() => incidentDigest = v);
                    await _updateEmailPreferences();
                  },
                ),
                const Divider(height: 18, color: Color(0xFFF1F5F9)),
                _toggleTile(
                  title: 'Milestone Alerts',
                  subtitle: 'XP gains, badges and rank updates',
                  value: milestoneAlerts,
                  onChanged: (v) async {
                    setState(() => milestoneAlerts = v);
                    await _updateEmailPreferences();
                  },
                ),
                const Divider(height: 18, color: Color(0xFFF1F5F9)),
                _toggleTile(
                  title: 'Product Updates',
                  subtitle: 'New features and release notes',
                  value: productUpdates,
                  onChanged: (v) async {
                    setState(() => productUpdates = v);
                    await _updateEmailPreferences();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Tip: You can unsubscribe from non-critical emails anytime.',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
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
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (_isSaving)
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.blue.withValues(alpha: 0.6),
              ),
            ),
          )
        else
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF3B82F6),
            activeThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
            inactiveThumbColor: Colors.white,
          ),
      ],
    );
  }
}
