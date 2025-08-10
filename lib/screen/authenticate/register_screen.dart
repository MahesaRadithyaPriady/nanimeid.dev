import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/config.dart';
import 'package:wave/wave.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController userIdController = TextEditingController();

  bool agreeToPolicy = false;
  bool agreeToRecommendation = false;

  @override
  void initState() {
    super.initState();
    userIdController.text = ''; // biar bisa input angka saja
  }

  bool get isFormValid =>
      agreeToPolicy &&
      agreeToRecommendation &&
      emailController.text.isNotEmpty &&
      usernameController.text.isNotEmpty &&
      passwordController.text == confirmPasswordController.text &&
      passwordController.text.length >= 6 &&
      userIdController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // ⛔ Wave tidak akan ikut naik
      body: Stack(
        children: [
          // Wave tetap di bawah
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _WaveBackground(),
          ),

          // Form scrollable
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Daftar Akun',
                      style: GoogleFonts.poppins(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _label('Email'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: emailController,
                    hint: 'Masukkan email',
                  ),

                  const SizedBox(height: 20),
                  _label('Username'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: usernameController,
                    hint: 'Masukkan username',
                  ),

                  const SizedBox(height: 20),
                  _label('Password'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: passwordController,
                    hint: 'Masukkan password',
                    obscure: true,
                  ),

                  const SizedBox(height: 20),
                  _label('Konfirmasi Password'),
                  const SizedBox(height: 8),
                  _inputField(
                    controller: confirmPasswordController,
                    hint: 'Ulangi password',
                    obscure: true,
                  ),

                  const SizedBox(height: 20),
                  _label('User ID (NanimeID - Angka)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'NanimeID -',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: userIdController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('Contoh: 0899'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Checkbox(
                        value: agreeToPolicy,
                        activeColor: Colors.pinkAccent,
                        onChanged: (value) {
                          setState(() => agreeToPolicy = value ?? false);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Saya menyetujui kebijakan privasi dan ketentuan penggunaan.',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: agreeToRecommendation,
                        activeColor: Colors.pinkAccent,
                        onChanged: (value) {
                          setState(
                            () => agreeToRecommendation = value ?? false,
                          );
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Izinkan kami mengirim rekomendasi anime ke email Anda.',
                          style: GoogleFonts.poppins(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isFormValid
                          ? () {
                              // TODO: proses register
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        disabledBackgroundColor: Colors.pinkAccent.withOpacity(
                          0.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Daftar',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 100,
                  ), // ruang kosong agar tidak ketutup wave
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: GoogleFonts.poppins(color: Colors.white70));

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      filled: true,
      fillColor: Colors.white10,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}

/// Wave dipisah biar tidak terpengaruh layout form
class _WaveBackground extends StatelessWidget {
  const _WaveBackground();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: WaveWidget(
        config: CustomConfig(
          gradients: [
            [
              Colors.pinkAccent.withOpacity(0.3),
              Colors.pinkAccent.withOpacity(0.2),
            ],
            [Colors.pink.withOpacity(0.2), Colors.purple.withOpacity(0.1)],
          ],
          durations: [34000, 25000],
          heightPercentages: [0.20, 0.25],
          blur: const MaskFilter.blur(BlurStyle.solid, 2),
          gradientBegin: Alignment.bottomLeft,
          gradientEnd: Alignment.topRight,
        ),
        waveAmplitude: 0,
        size: const Size(double.infinity, double.infinity),
      ),
    );
  }
}
