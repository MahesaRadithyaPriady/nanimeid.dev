import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'register_screen.dart';
import '../protected/navigation/main_navigation.dart';
import '../../services/auth_service.dart';
import '../../utils/secure_storage.dart';
import '../../config/settings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

Route _createRegisterRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const RegisterScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(-1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 500),
  );
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool agreeToPolicy = false;
  bool isLoading = false;
  bool get isFormValid =>
      usernameController.text.isNotEmpty &&
      passwordController.text.isNotEmpty &&
      agreeToPolicy;

  @override
  void initState() {
    super.initState();

    // Listener supaya tombol login realtime update
    usernameController.addListener(_updateState);
    passwordController.addListener(_updateState);
  }

  void _updateState() {
    // Memanggil setState agar build dijalankan ulang
    setState(() {});
  }

  @override
  void dispose() {
    usernameController.removeListener(_updateState);
    passwordController.removeListener(_updateState);
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      AppSettings.appName,
                      style: GoogleFonts.inter(
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),

                    if (AppSettings.isDebug) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Aplikasi Dalam Debug Mode',
                        style: GoogleFonts.inter(
                          textStyle: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Username',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Masukkan username'),
                    ),
                    const SizedBox(height: 20),

                    /// Password
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Masukkan password'),
                    ),
                    const SizedBox(height: 20),

                    /// Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: agreeToPolicy,
                          activeColor: Colors.pinkAccent,
                          onChanged: (value) {
                            setState(() {
                              agreeToPolicy = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Saya menyetujui kebijakan privasi dan ketentuan penggunaan.',
                            style: GoogleFonts.inter(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /// Tombol Login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (isFormValid && !isLoading)
                            ? () async {
                                // ⌨️ Tutup keyboard
                                FocusScope.of(context).unfocus();

                                setState(() {
                                  isLoading = true;
                                });

                                final result = await AuthService.login(
                                  usernameController.text.trim(),
                                  passwordController.text.trim(),
                                );

                                if (!mounted) return;

                                if (result['success'] == true) {
                                  final token =
                                      await SecureStorage.getToken() ?? "";

                                  if (AppSettings.isDebug) {
                                    // 🎯 Kalau debug mode -> tampilkan popup token
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          backgroundColor: Colors.black87,
                                          title: const Text(
                                            "Login Berhasil 🎉",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Text(
                                              "Pesan: ${result['message']}\n\nToken:\n$token",
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const MainNavigation(),
                                                  ),
                                                );
                                              },
                                              child: const Text(
                                                "Lanjutkan",
                                                style: TextStyle(
                                                  color: Colors.pinkAccent,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // 🚀 Kalau bukan debug mode -> langsung masuk
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MainNavigation(),
                                      ),
                                    );
                                  }
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ?? "Login gagal",
                                      ),
                                      backgroundColor: Colors.redAccent,
                                    ),
                                  );
                                }

                                setState(() {
                                  isLoading = false;
                                });
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          disabledBackgroundColor: Colors.pinkAccent
                              .withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Masuk',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    /// Link Register
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_createRegisterRoute());
                      },
                      child: Text(
                        'Belum punya akun? Daftar sekarang',
                        style: GoogleFonts.inter(
                          color: Colors.white38,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// Wave bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 100,
              child: WaveWidget(
                config: CustomConfig(
                  gradients: [
                    [
                      Colors.pinkAccent.withOpacity(0.3),
                      Colors.pinkAccent.withOpacity(0.2),
                    ],
                    [
                      Colors.pink.withOpacity(0.2),
                      Colors.purple.withOpacity(0.1),
                    ],
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
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: Colors.white30),
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
