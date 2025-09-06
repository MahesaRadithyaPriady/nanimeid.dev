import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    try {
      final res = await AuthService.changePassword(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      final message = res['message']?.toString() ?? 'Password berhasil diubah';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      if (res['success'] == true) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah password')),
      );
    }
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Wajib diisi';
    if (v.length < 6) return 'Minimal 6 karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Privasi & Keamanan',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ganti Password',
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Password Lama', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _oldPassword,
                        obscureText: _obscureOld,
                        cursorColor: Colors.pinkAccent,
                        style: const TextStyle(color: Colors.white),
                        validator: _validatePassword,
                        decoration: _inputDecoration('Masukkan password lama',
                          suffix: _VisibilityButton(
                            isObscured: _obscureOld,
                            onTap: () => setState(() => _obscureOld = !_obscureOld),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Password Baru', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _newPassword,
                        obscureText: _obscureNew,
                        cursorColor: Colors.pinkAccent,
                        style: const TextStyle(color: Colors.white),
                        validator: _validatePassword,
                        decoration: _inputDecoration('Masukkan password baru',
                          suffix: _VisibilityButton(
                            isObscured: _obscureNew,
                            onTap: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text('Konfirmasi Password Baru', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _confirmPassword,
                        obscureText: _obscureConfirm,
                        cursorColor: Colors.pinkAccent,
                        style: const TextStyle(color: Colors.white),
                        validator: (v) {
                          final basic = _validatePassword(v);
                          if (basic != null) return basic;
                          if (v != _newPassword.text) return 'Konfirmasi tidak cocok';
                          return null;
                        },
                        decoration: _inputDecoration('Ulangi password baru',
                          suffix: _VisibilityButton(
                            isObscured: _obscureConfirm,
                            onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _onSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Simpan',
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.white30, fontSize: 13),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      suffixIcon: suffix,
    );
  }
}

class _VisibilityButton extends StatelessWidget {
  final bool isObscured;
  final VoidCallback onTap;
  const _VisibilityButton({required this.isObscured, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
      color: Colors.white54,
    );
  }
}
