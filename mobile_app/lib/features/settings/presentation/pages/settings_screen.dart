import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/auth/presentation/pages/sign_in_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/appearance_settings_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/edit_profile_settings_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/email_settings_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/help_center_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/language_settings_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/privacy_policy_screen.dart';
import 'package:mobile_app/features/settings/presentation/pages/security_privacy_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;
  bool soundEnabled = true;
  bool darkMode = false;

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFC), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Settings',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 52, top: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Manage your preferences',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  children: [
                    _sectionTitle('Account'),
                    _SettingsGroup(
                      children: [
                        _SettingsLinkTile(
                          icon: Icons.person_outline,
                          iconBg: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Edit Profile',
                          subtitle: 'Update your personal info',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const EditProfileSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsLinkTile(
                          icon: Icons.mail_outline,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Email Settings',
                          subtitle: 'Manage your email preferences',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EmailSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsLinkTile(
                          icon: Icons.lock_outline,
                          iconBg: const Color(0xFFFCE7F3),
                          iconColor: const Color(0xFFEC4899),
                          title: 'Security & Privacy',
                          subtitle: 'Password and privacy settings',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SecurityPrivacyScreen(),
                              ),
                            );
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Preferences'),
                    _SettingsGroup(
                      children: [
                        _SettingsToggleTile(
                          icon: Icons.notifications_none,
                          iconBg: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Notifications',
                          subtitle: 'Push notifications',
                          value: notificationsEnabled,
                          onChanged: (value) =>
                              setState(() => notificationsEnabled = value),
                        ),
                        _SettingsToggleTile(
                          icon: Icons.volume_up_outlined,
                          iconBg: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Sound Effects',
                          subtitle: 'App sounds',
                          value: soundEnabled,
                          onChanged: (value) =>
                              setState(() => soundEnabled = value),
                        ),
                        _SettingsToggleTile(
                          icon: Icons.dark_mode_outlined,
                          iconBg: const Color(0xFFE0E7FF),
                          iconColor: const Color(0xFF6366F1),
                          title: 'Dark Mode',
                          subtitle: 'Manage in Appearance',
                          value: darkMode,
                          enabled: false,
                          onChanged: (_) {},
                        ),
                        _SettingsLinkTile(
                          icon: Icons.palette_outlined,
                          iconBg: const Color(0xFFFCE7F3),
                          iconColor: const Color(0xFFEC4899),
                          title: 'Appearance',
                          subtitle: 'Customize your theme',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AppearanceSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsLinkTile(
                          icon: Icons.language_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF10B981),
                          title: 'Language',
                          subtitle: 'English (US)',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LanguageSettingsScreen(),
                              ),
                            );
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionTitle('Support'),
                    _SettingsGroup(
                      children: [
                        _SettingsLinkTile(
                          icon: Icons.help_outline,
                          iconBg: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF3B82F6),
                          title: 'Help Center',
                          subtitle: 'FAQs and support',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpCenterScreen(),
                              ),
                            );
                          },
                        ),
                        _SettingsLinkTile(
                          icon: Icons.shield_outlined,
                          iconBg: const Color(0xFFE0E7FF),
                          iconColor: const Color(0xFF6366F1),
                          title: 'Privacy Policy',
                          subtitle: 'How we protect your data',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFEF4444),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Log Out',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'StreetWatch v1.0.0\n© 2026 All rights reserved',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsLinkTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsLinkTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))
              : null,
        ),
        child: Row(
          children: [
            _IconBox(icon: icon, bg: iconBg, color: iconColor),
            const SizedBox(width: 12),
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
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          _IconBox(icon: icon, bg: iconBg, color: iconColor),
          const SizedBox(width: 12),
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
          Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Switch.adaptive(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: Colors.white,
              activeTrackColor: const Color(0xFF3B82F6),
              inactiveTrackColor: const Color(0xFFCBD5E1),
              inactiveThumbColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color color;

  const _IconBox({required this.icon, required this.bg, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
