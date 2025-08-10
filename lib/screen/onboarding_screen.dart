import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:wave/wave.dart';
import 'package:wave/config.dart';
import 'authenticate/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  double verticalDrag = 0.0;
  int currentPage = 0;

  final List<Map<String, dynamic>> pages = [
    {
      "title": "Selamat Datang di NanimeID!",
      "description": "Streaming anime favoritmu kapan saja, di mana saja.",
      "icon": Icons.play_circle_fill,
    },
    {
      "title": "Koleksi Lengkap",
      "description": "Dari anime klasik hingga yang paling baru.",
      "icon": Icons.collections_bookmark,
    },
    {
      "title": "Siap Nonton?",
      "description": "Geser ke atas untuk mulai petualangan animemu!",
      "icon": Icons.rocket_launch,
      "swipeUp": true,
    },
  ];

  Route _createLoginRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
    transitionDuration: const Duration(milliseconds: 600),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0); // dari bawah ke atas
      const end = Offset.zero;
      final curve = Curves.easeOutCubic;

      final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      return SlideTransition(
        position: animation.drive(tween),
        child: child,
      );
    },
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: pages.length,
            onPageChanged: (index) => setState(() => currentPage = index),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
  final page = pages[index];
  final isLast = page['swipeUp'] == true;

  return _buildPage(
    title: page['title'],
    description: page['description'],
    image: page['icon'],
    showStartButton: isLast,
  );
},
          ),

          // Slide indicator
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _controller,
                count: pages.length,
                effect: WormEffect(
                  activeDotColor: Colors.pinkAccent,
                  dotColor: Colors.white30,
                  dotHeight: 10,
                  dotWidth: 10,
                ),
              ),
            ),
          ),

          // Moving wave decoration at bottom
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
                  durations: [35000, 19440],
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
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData image,
   bool showStartButton = false,

  }) {
    return Container(
  padding: const EdgeInsets.all(32),
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        image,
        size: 100,
        color: Colors.pinkAccent,
      ),
      const SizedBox(height: 40),
      Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        description,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ),
      if (showStartButton) ...[
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(_createLoginRoute());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Mulai',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ],
  ),
);

}
}