// Location: agrivana\lib\features\profile\view\edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/cloudinary_service.dart';
import '../../../utils/dialogs.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/model/user_model.dart';
import '../bloc/profile_bloc.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCityCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  bool _uploadingPhoto = false;
  File? _pickedImage;
  String? _currentPhotoUrl;

  // Original values to detect changes
  String _origName = '';
  String _origBio = '';
  String _origLocationCity = '';
  String _origPhotoUrl = '';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _populateFields(authState.user);
    }
    // Also fetch fresh data from API
    context.read<ProfileBloc>().add(ProfileLoadRequested());
  }

  void _populateFields(UserModel user) {
    _nameCtrl.text = user.name;
    _bioCtrl.text = user.bio ?? '';
    _locationCityCtrl.text = user.locationCity ?? '';
    _emailCtrl.text = user.email ?? '';
    _phoneCtrl.text = user.phone ?? '';
    _currentPhotoUrl = user.profilePhoto;

    // Store originals for partial update diff
    _origName = user.name;
    _origBio = user.bio ?? '';
    _origLocationCity = user.locationCity ?? '';
    _origPhotoUrl = user.profilePhoto ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCityCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text('Pilih Foto Profil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                ),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto langsung', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppTheme.accent),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri foto', style: TextStyle(fontSize: 12)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
    if (picked == null) return;

    setState(() {
      _pickedImage = File(picked.path);
      _uploadingPhoto = true;
    });

    // Upload to Cloudinary
    final url = await CloudinaryService.uploadProfilePhoto(File(picked.path));
    if (url != null && mounted) {
      setState(() {
        _currentPhotoUrl = url;
        _uploadingPhoto = false;
      });
    } else if (mounted) {
      setState(() => _uploadingPhoto = false);
      AppDialogs.showError('Gagal mengupload foto. Coba lagi.');
    }
  }

  Future<void> _save() async {
    // Build partial update body – only changed fields
    final Map<String, dynamic> body = {};

    final newName = _nameCtrl.text.trim();
    final newBio = _bioCtrl.text.trim();
    final newCity = _locationCityCtrl.text.trim();
    final newPhotoUrl = _currentPhotoUrl ?? '';

    if (newName != _origName && newName.isNotEmpty) body['name'] = newName;
    if (newBio != _origBio) body['bio'] = newBio;
    if (newCity != _origLocationCity) body['locationCity'] = newCity;
    if (newPhotoUrl != _origPhotoUrl && newPhotoUrl.isNotEmpty) body['profilePhotoUrl'] = newPhotoUrl;

    if (body.isEmpty) {
      AppDialogs.showError('Tidak ada perubahan untuk disimpan');
      return;
    }

    setState(() => _loading = true);
    context.read<ProfileBloc>().add(ProfileUpdateRequested(body));
  }

  void _showUnavailableMessage(String field) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Maaf, fitur ganti $field belum tersedia'),
        backgroundColor: AppTheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Edit Profil')),
      body: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            _populateFields(state.user);
            if (mounted) setState(() {});
          } else if (state is ProfileSuccess) {
            setState(() => _loading = false);
            Navigator.of(context).pop(true); // return true to indicate update
          } else if (state is ProfileError) {
            setState(() => _loading = false);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Profile Photo Section ──
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 3),
                          ),
                          child: ClipOval(
                            child: _uploadingPhoto
                                ? Container(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  )
                                : _pickedImage != null
                                    ? Image.file(_pickedImage!, width: 94, height: 94, fit: BoxFit.cover)
                                    : _currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty
                                        ? Image.network(_currentPhotoUrl!, width: 94, height: 94, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _defaultAvatar())
                                        : _defaultAvatar(),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _uploadingPhoto ? null : _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _uploadingPhoto ? null : _pickImage,
                      child: Text(
                        _uploadingPhoto ? 'Mengupload...' : 'Ubah Foto',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Editable Fields ──
              _sectionLabel('Informasi Pribadi'),
              const SizedBox(height: 12),

              // Name
              _buildTextField(
                controller: _nameCtrl,
                label: 'Nama Lengkap',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 12),

              // Bio
              _buildTextField(
                controller: _bioCtrl,
                label: 'Bio',
                icon: Icons.info_outline,
                maxLines: 3,
                hint: 'Ceritakan sedikit tentang dirimu...',
              ),
              const SizedBox(height: 12),

              // Location City
              _buildTextField(
                controller: _locationCityCtrl,
                label: 'Kota',
                icon: Icons.location_on_outlined,
                hint: 'Contoh: Bandung',
              ),
              const SizedBox(height: 20),

              // ── Read-only Fields ──
              _sectionLabel('Informasi Akun'),
              const SizedBox(height: 4),
              Text('Hubungi dukungan untuk mengubah email atau nomor telepon',
                  style: TextStyle(fontSize: 12, color: AppTheme.textHint)),
              const SizedBox(height: 12),

              // Email (read-only)
              _buildReadOnlyField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.email_outlined,
                onTap: () => _showUnavailableMessage('email'),
              ),
              const SizedBox(height: 12),

              // Phone (read-only)
              _buildReadOnlyField(
                controller: _phoneCtrl,
                label: 'Nomor Telepon',
                icon: Icons.phone_outlined,
                onTap: () => _showUnavailableMessage('nomor telepon'),
              ),
              const SizedBox(height: 32),

              // ── Save Button ──
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: (_loading || _uploadingPhoto) ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Simpan Perubahan'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 94, height: 94,
      color: AppTheme.primary.withValues(alpha: 0.1),
      child: const Icon(Icons.person_rounded, size: 44, color: AppTheme.primary),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textHint),
        suffixIcon: const Icon(Icons.lock_outline, size: 16, color: AppTheme.textHint),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        labelStyle: const TextStyle(color: AppTheme.textHint),
      ),
      style: const TextStyle(color: AppTheme.textSecondary),
    );
  }
}
