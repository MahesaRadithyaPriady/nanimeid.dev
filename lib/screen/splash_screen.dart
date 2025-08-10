import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'onboarding_screen.dart';

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


  @override
  void initState() {
    super.initState();
    selectedQuote = _quotes[Random().nextInt(_quotes.length)];

    Timer(const Duration(seconds: 5), () {
      Navigator.of(context).pushReplacement(_createRouteToOnboarding());
    });
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
            const CircularProgressIndicator(
              color: Colors.pinkAccent,
              strokeWidth: 2,
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
