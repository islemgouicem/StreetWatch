import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  int selectedTheme = 0;
  bool _isSaving = false;
  late ApiService _apiService;

  final themes = const [
    {'name': 'Classic Blue', 'start': Color(0xFF1E3A8A), 'end': Color(0xFF3B82F6)},
    {'name': 'Civic Green', 'start': Color(0xFF0F766E), 'end': Color(0xFF10B981)},
    {'name': 'Sunset Orange', 'start': Color(0xFFEA580C), 'end': Color(0xFFF97316)},
  ];

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _apiService = ApiService(supabase);
  }

  Future<void> _updateTheme(int themeIndex) async {
    setState(() => _isSaving = true);
    
    final themeNames = ['classic_blue', 'civic_green', 'sunset_orange'];

    try {
      await _apiService.updateAppearancePreferences(
        theme: themeNames[themeIndex],
        darkMode: false,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Theme updated'),
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
      title: 'Appearance',
      subtitle: 'Customize your theme',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme Palette',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(themes.length, (index) {
                  final item = themes[index];
                  return InkWell(
                    onTap: () async {
                      setState(() => selectedTheme = index);
                      await _updateTheme(index);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selectedTheme == index
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                          width: selectedTheme == index ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [item['start'] as Color, item['end'] as Color],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item['name'] as String,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          if (selectedTheme == index)
                            _isSaving
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.blue.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.check_circle, color: Color(0xFF3B82F6)),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(
                  'Dark mode will be available soon.',
                  style: GoogleFonts.outfit(color: const Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
