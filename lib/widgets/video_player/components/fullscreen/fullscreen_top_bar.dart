import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FullscreenTopBar extends StatelessWidget {
  final String videoTitle;
  final VoidCallback onBack;
  final GlobalKey backKey;

  const FullscreenTopBar({
    super.key,
    required this.videoTitle,
    required this.onBack,
    required this.backKey,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            key: backKey,
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              videoTitle,
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
