import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WatchEpisodeInfo extends StatelessWidget {
  const WatchEpisodeInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Episode 8 - My Dress-Up Darling',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _iconText(LucideIcons.calendar, 'April 2024'),
              const SizedBox(width: 16),
              _iconText(Icons.access_time, '24 Menit'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _iconText(Icons.bookmark, 'Ongoing'),
              const SizedBox(width: 16),
              _iconText(Icons.star, '8.3'),
              const SizedBox(width: 16),
              _iconText(Icons.remove_red_eye, '1.2M Views'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _actionButton(Icons.favorite_border, 'Suka'),
              const SizedBox(width: 12),
              _actionButton(Icons.download, 'Unduh'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
