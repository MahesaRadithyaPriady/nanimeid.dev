import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VideoErrorOverlay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const VideoErrorOverlay({
    super.key,
    this.title = 'Error loading video',
    this.message = '',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.pinkAccent,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              message,
              style: GoogleFonts.poppins(
                color: Colors.white54,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
