import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/features/settings/presentation/widgets/settings_page_shell.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfileSettingsScreen extends StatefulWidget {
  const EditProfileSettingsScreen({super.key});

  @override
  State<EditProfileSettingsScreen> createState() => _EditProfileSettingsScreenState();
}

class _EditProfileSettingsScreenState extends State<EditProfileSettingsScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController(text: 'Helping improve city roads one report at a time.');
  
  bool _isLoading = false;
  bool _isFetchingProfile = true;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _apiService = ApiService(supabase);
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final user = await _apiService.getCurrentUser();
      if (!mounted) return;

      _nameController.text = (user.fullName ?? user.username ?? '').trim();
      _usernameController.text = (user.username ?? '').trim();
      _bioController.text = (user.bio ?? '').trim().isNotEmpty
          ? user.bio!.trim()
          : _bioController.text;
    } catch (_) {
      // Keep empty fields if fetch fails; save flow still works.
    } finally {
      if (mounted) {
        setState(() => _isFetchingProfile = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty || _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.updateUser(
        fullName: _nameController.text,
        username: _usernameController.text,
        bio: _bioController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPageShell(
      title: 'Edit Profile',
      subtitle: 'Update your personal info',
      child: _isFetchingProfile
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFE2E8F0),
                      child: Icon(Icons.person, size: 44, color: Color(0xFF64748B)),
                    ),
                    Positioned(
                      right: -6,
                      bottom: -4,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _field('Full Name', _nameController),
                const SizedBox(height: 14),
                _field('Username', _usernameController),
                const SizedBox(height: 14),
                _field('Bio', _bioController, maxLines: 3),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            await _saveChanges();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFBFDBFE),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
