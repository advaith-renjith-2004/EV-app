import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/theme_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestoreService = FirestoreService();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  Map<String, dynamic>? _userData;
  String? _selectedAvatarUrl;

  // Preset cyber avatars
  final List<String> _presetAvatars = [
    'https://api.dicebear.com/7.x/bottts/png?seed=NeonAlpha',
    'https://api.dicebear.com/7.x/bottts/png?seed=VoltDrive',
    'https://api.dicebear.com/7.x/bottts/png?seed=CyberCore',
    'https://api.dicebear.com/7.x/bottts/png?seed=GridRunner',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final data = await _firestoreService.getUserData(user.uid);
      if (data != null) {
        setState(() {
          _userData = data;
          _nameController.text = data['name'] ?? '';
          _selectedAvatarUrl = data['photoUrl'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileChanges() async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestoreService.updateUserProfile(
        user.uid,
        name: _nameController.text.trim(),
        photoUrl: _selectedAvatarUrl,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
      await _loadUserProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 70,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = 'data:image/png;base64,${base64Encode(bytes)}';
        setState(() {
          _selectedAvatarUrl = base64String;
        });
        Navigator.pop(context); // Close selection sheet
        await _saveProfileChanges();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _selectPresetAvatar(String url) async {
    setState(() {
      _selectedAvatarUrl = url;
    });
    Navigator.pop(context); // Close selection sheet
    await _saveProfileChanges();
  }

  void _showAvatarPickerSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Profile Picture',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('CHOOSE FROM GALLERY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.white24)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR CHOOSE CYBER PRESET', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11)),
                ),
                const Expanded(child: Divider(color: Colors.white24)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 70,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _presetAvatars.length,
                itemBuilder: (context, index) {
                  final url = _presetAvatars[index];
                  return GestureDetector(
                    onTap: () => _selectPresetAvatar(url),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _selectedAvatarUrl == url ? theme.primaryColor : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF0F172A),
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentTheme = Theme.of(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FLEET MEMBER PROFILE'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading && _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: currentTheme.primaryColor, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: currentTheme.primaryColor.withValues(alpha: 0.25),
                                blurRadius: 20,
                              )
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 54,
                            backgroundColor: const Color(0xFF1E293B),
                            backgroundImage: _selectedAvatarUrl != null
                                ? (_selectedAvatarUrl!.startsWith('data:image')
                                    ? MemoryImage(base64Decode(_selectedAvatarUrl!.split(',')[1]))
                                    : NetworkImage(_selectedAvatarUrl!) as ImageProvider)
                                : const NetworkImage('https://api.dicebear.com/7.x/bottts/png?seed=Default'),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showAvatarPickerSheet,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: currentTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // User metadata Info Cards
                  _buildProfileCard(
                    title: 'FLEET IDENTITY',
                    icon: Icons.badge_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaRow('Auth Email', _userData?['email'] ?? 'N/A'),
                        const Divider(color: Colors.white10, height: 20),
                        _buildMetaRow('System Role', (_userData?['role'] ?? 'N/A').toString().toUpperCase()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Edit Username Card
                  _buildProfileCard(
                    title: 'EDIT SHIFT USERNAME',
                    icon: Icons.person_outline,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'Enter username',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton.filled(
                          onPressed: _isLoading ? null : _saveProfileChanges,
                          icon: const Icon(Icons.check),
                          style: IconButton.styleFrom(
                            backgroundColor: currentTheme.primaryColor,
                            foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Themes Settings Card
                  _buildProfileCard(
                    title: 'COSMETIC CUSTOMIZATION',
                    icon: Icons.palette_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Dark Dashboard Mode', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                            Switch(
                              value: isDark,
                              activeColor: currentTheme.primaryColor,
                              onChanged: (val) {
                                themeProvider.toggleThemeMode(val);
                              },
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white10, height: 24),
                        const Text(
                          'Accent Color Theme:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: CustomAccentColor.values.length,
                            itemBuilder: (context, index) {
                              final preset = CustomAccentColor.values[index];
                              final isSelected = themeProvider.accentColor == preset;

                              return GestureDetector(
                                onTap: () => themeProvider.setAccentColor(preset),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 8),
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: preset.color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? Colors.white : Colors.transparent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      if (isSelected)
                                        BoxShadow(
                                          color: preset.color.withValues(alpha: 0.6),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.blueGrey.shade400),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: Colors.blueGrey.shade400,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
