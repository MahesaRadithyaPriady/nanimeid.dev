import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../services/vip_service.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  DateTime? _birthdate;
  String? _gender;

  bool _loading = true;
  ProfileModel? _profile;
  bool _isVip = false;
  XFile? _pickedAvatar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ProfileService.getMyProfile();
      final p = res.profile;
      // Fetch VIP status
      final vip = await VipService.getMyVip();
      setState(() {
        _profile = p;
        _nameCtrl.text = p?.fullName ?? '';
        _bioCtrl.text = p?.bio ?? '';
        _avatarCtrl.text = p?.avatarUrl ?? '';
        _birthdate = p?.birthdate;
        _gender = p?.gender;
        _isVip = vip.isActive;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat profil')),
      );
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _birthdate ?? DateTime(now.year - 18, now.month, now.day);
    final res = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
      helpText: 'Pilih Tanggal Lahir',
    );
    if (res != null) setState(() => _birthdate = res);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      String? avatarUrlToSend;

      final rawAvatar = _avatarCtrl.text.trim();

      if (_isVip) {
        // If VIP and picked a local image, upload it first
        if (_pickedAvatar != null) {
          final upload = await ProfileService.uploadMyAvatar(
            filePath: _pickedAvatar!.path,
          );
          if (upload.profile?.avatarUrl != null) {
            avatarUrlToSend = upload.profile!.avatarUrl;
          }
        } else if (rawAvatar.isNotEmpty) {
          // If VIP entered a URL manually, only accept http(s)
          if (rawAvatar.startsWith('http://') || rawAvatar.startsWith('https://')) {
            avatarUrlToSend = rawAvatar;
          } else if (rawAvatar.startsWith('/')) {
            // Looks like a local path but no _pickedAvatar; suggest using picker
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('VIP: Gunakan tombol galeri untuk unggah avatar, atau masukkan URL http(s).')),
            );
            return;
          }
        }
      } else {
        // Non-VIP must provide http(s) URL if provided at all
        if (rawAvatar.isNotEmpty) {
          if (!(rawAvatar.startsWith('http://') || rawAvatar.startsWith('https://'))) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Non‑VIP hanya dapat mengisi Avatar URL berupa http(s).')),
            );
            return;
          }
          avatarUrlToSend = rawAvatar;
        }
      }

      final res = await ProfileService.updateMyProfile(
        fullName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        avatarUrl: avatarUrlToSend,
        birthdate: _birthdate,
        gender: _gender,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
        // Fetch profil terbaru agar state lokal dan layar sebelumnya konsisten
        try {
          final latest = await ProfileService.getMyProfile();
          if (mounted) {
            setState(() {
              _profile = latest.profile;
              _nameCtrl.text = latest.profile?.fullName ?? _nameCtrl.text;
              _bioCtrl.text = latest.profile?.bio ?? _bioCtrl.text;
              _avatarCtrl.text = latest.profile?.avatarUrl ?? _avatarCtrl.text;
              _birthdate = latest.profile?.birthdate ?? _birthdate;
              _gender = latest.profile?.gender ?? _gender;
            });
          }
        } catch (_) {
          // ignore fetch error here; UI will still refresh on previous screen
        }
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: ${res.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat memperbarui profil')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatarFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedAvatar = image;
          // Temporarily fill the text field with local file path as a placeholder
          _avatarCtrl.text = image.path;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memilih gambar dari galeri')),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Pengaturan Akun', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Profil', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      cursorColor: Colors.pinkAccent,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Nama Lengkap'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioCtrl,
                      cursorColor: Colors.pinkAccent,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: _inputDecoration('Bio'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _avatarCtrl,
                      cursorColor: Colors.pinkAccent,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Avatar URL').copyWith(
                        suffixIcon: _isVip
                            ? IconButton(
                                tooltip: 'Pilih dari galeri (VIP)',
                                icon: const Icon(Icons.photo, color: Colors.pinkAccent),
                                onPressed: _pickAvatarFromGallery,
                              )
                            : null,
                      ),
                    ),
                    if (_pickedAvatar != null) ...[
                      const SizedBox(height: 10),
                      Text('Pratinjau Avatar (lokal):', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_pickedAvatar!.path),
                          height: 120,
                          width: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: _inputDecoration('Tanggal Lahir'),
                              child: Text(
                                _birthdate == null
                                    ? 'Pilih tanggal'
                                    : '${_birthdate!.day.toString().padLeft(2, '0')}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.year}',
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _gender,
                            items: [
                              DropdownMenuItem(
                                value: 'Laki-laki',
                                child: Text('Laki-laki', style: GoogleFonts.poppins(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: 'Perempuan',
                                child: Text('Perempuan', style: GoogleFonts.poppins(color: Colors.white)),
                              ),
                            ],
                            onChanged: (v) => setState(() => _gender = v),
                            dropdownColor: const Color(0xFF1A1A1A),
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: _inputDecoration('Gender'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _save,
                        child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A1A1A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.pinkAccent),
      ),
    );
  }
}
