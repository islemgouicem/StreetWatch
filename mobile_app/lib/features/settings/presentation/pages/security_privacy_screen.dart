import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  bool twoFactor = false;
  bool biometricLock = true;
  bool locationMasking = true;
  bool _isSaving = false;
  bool _isLoading = true;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _apiService = ApiService(supabase);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final preferences = await _apiService.getMyPreferences();
      final security =
          preferences['security'] as Map<String, dynamic>? ?? const {};
      if (!mounted) return;
      setState(() {
        twoFactor = security['two_factor_enabled'] as bool? ?? false;
        biometricLock = security['biometric_lock'] as bool? ?? false;
        locationMasking = security['location_masking'] as bool? ?? false;
      });
    } catch (_) {
      // Keep defaults if loading fails.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateSecuritySettings() async {
    setState(() => _isSaving = true);

    try {
      await _apiService.updateSecuritySettings(
        twoFactor: twoFactor,
        biometricLock: biometricLock,
        locationMasking: locationMasking,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Security settings updated'),
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
      title: 'Security & Privacy',
      subtitle: 'Password and privacy settings',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Change Password',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Last updated 43 days ago',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final email =
                        Supabase.instance.client.auth.currentUser?.email;
                    if (email == null || email.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No authenticated email found.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      await Supabase.instance.client.auth.resetPasswordForEmail(
                        email,
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Password reset email sent to $email'),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to send reset email: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const Divider(color: Color(0xFFF1F5F9)),
                _switchRow('Two-factor authentication', twoFactor, (v) async {
                  setState(() => twoFactor = v);
                  await _updateSecuritySettings();
                }),
                const Divider(color: Color(0xFFF1F5F9)),
                _switchRow('Biometric app lock', biometricLock, (v) async {
                  setState(() => biometricLock = v);
                  await _updateSecuritySettings();
                }),
                const Divider(color: Color(0xFFF1F5F9)),
                _switchRow('Mask precise location', locationMasking, (v) async {
                  setState(() => locationMasking = v);
                  await _updateSecuritySettings();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
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
