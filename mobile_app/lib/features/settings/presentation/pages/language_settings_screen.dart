import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String selected = 'English (US)';
  bool _isSaving = false;
  late ApiService _apiService;
  
  final options = const ['English (US)', 'French', 'Arabic', 'Spanish'];

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _apiService = ApiService(supabase);
  }

  Future<void> _updateLanguage(String language) async {
    setState(() => _isSaving = true);

    try {
      await _apiService.updateLanguagePreference(language);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Language updated'),
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
      title: 'Language',
      subtitle: 'Choose your app language',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: options
                  .asMap()
                  .entries
                  .map(
                    (entry) {
                      final index = entry.key;
                      final lang = entry.value;
                      final isSelected = lang == selected;

                      return InkWell(
                        onTap: () async {
                          setState(() => selected = lang);
                          await _updateLanguage(lang);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: index != options.length - 1
                                ? const Border(
                                    bottom: BorderSide(color: Color(0xFFF1F5F9)),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang,
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0F172A),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lang == 'English (US)'
                                          ? 'Current language'
                                          : 'Tap to switch',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _isSaving && isSelected
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
                                  : Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF94A3B8),
                                    ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
