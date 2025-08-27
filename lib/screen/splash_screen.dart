import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'onboarding_screen.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../utils/secure_storage.dart';
import 'protected/navigation/main_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late String selectedQuote;

  final List<String> _quotes = [
    "Nonton satu episode, ujung-ujungnya marathon 12!",
    "Anime bukan sekadar tontonan, tapi pelarian dari kenyataan.",
    "Makan mie instan sambil nonton anime = combo terbaik!",
    "Satu anime, sejuta emosi.",
    "Anime hari ini, healing esok hari.",
    "Waifu adalah motivasi hidup!",
    "Nonton anime bukan hobi, itu gaya hidup.",
    "Ending sedih? Biasa, udah kebal sejak Naruto kecil.",
  ];

  Route _createRouteToOnboarding() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const OnboardingScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // dari bawah ke atas
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  Route _createRouteToHome() {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const MainNavigation(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0); // dari bawah ke atas
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(position: offsetAnimation, child: child);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    selectedQuote = _quotes[Random().nextInt(_quotes.length)];
    _bootstrap();
  }

  Future<void> _showConnectionErrorDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('Gagal Terhubung', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda atau coba lagi nanti.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Keluar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _bootstrap();
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _bootstrap() async {
    // Initialize API with auth interceptor
    ApiService.initialize();

    final token = await SecureStorage.getToken();
    if (!mounted) return;

    // If no token, go straight to onboarding after short delay
    if (token == null || token.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_createRouteToOnboarding());
      return;
    }

    try {
      // Try to fetch profile using saved token
      final profileRes = await ProfileService.getMyProfile();
      if (!profileRes.isSuccess) {
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(_createRouteToOnboarding());
        return;
      }
      // Print entire API output as requested
      // ignore: avoid_print
      print(profileRes.toJson());

      // Success: go to MainNavigation after short delay
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_createRouteToHome());
      return;
    } catch (e) {
      // Jika API tidak dapat diakses (timeout/connection error), tampilkan dialog retry/keluar
      await _showConnectionErrorDialog();
      return;
    }

    // No further action; navigation handled above for all branches
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, 
      body: Stack(
  children: [
    // 1. Wave di posisi paling bawah
    Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: 100,
        child: WaveWidget(
          config: CustomConfig(
            gradients: [
              [Colors.pinkAccent.withOpacity(0.3), Colors.pinkAccent.withOpacity(0.2)],
              [Colors.pink.withOpacity(0.2), Colors.purple.withOpacity(0.1)],
            ],
            durations: [32000, 21000],
            heightPercentages: [0.20, 0.23],
            blur: const MaskFilter.blur(BlurStyle.solid, 2),
            gradientBegin: Alignment.bottomLeft,
            gradientEnd: Alignment.topRight,
          ),
          waveAmplitude: 0,
          size: const Size(double.infinity, double.infinity),
        ),
      ),
    ),

    // 2. Konten tengah
    SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'NanimeID',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'v1.0.0',
              style: GoogleFonts.poppins(
                textStyle: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                selectedQuote,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Enhanced loading indicator
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const SizedBox(
                    width: 180,
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      color: Colors.pinkAccent,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Menyiapkan aplikasi...',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),

    // 3. Copyright di atas wave & jelas
    Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Text(
        '© 2025 Mahesa Development',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ),
  ],
), 

  );
  }
}
