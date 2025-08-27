import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/profile_model.dart';
import '../../services/profile_service.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ProfileService.getMyProfile();
      final p = res.profile;
      setState(() {
        _profile = p;
        _nameCtrl.text = p?.fullName ?? '';
        _bioCtrl.text = p?.bio ?? '';
        _avatarCtrl.text = p?.avatarUrl ?? '';
        _birthdate = p?.birthdate;
        _gender = p?.gender;
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
      final res = await ProfileService.updateMyProfile(
        fullName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        avatarUrl: _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        birthdate: _birthdate,
        gender: _gender,
      );
      if (!mounted) return;
      if (res.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui')),
        );
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
                      decoration: _inputDecoration('Avatar URL'),
                    ),
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
