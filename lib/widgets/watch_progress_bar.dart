import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/episode_detail_model.dart';

class WatchProgressBar extends StatelessWidget {
  final EpisodeDetailModel? episodeDetail;

  const WatchProgressBar({super.key, this.episodeDetail});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.activity,
                  color: Colors.pinkAccent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Progress Menonton',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  episodeDetail != null
                      ? 'Episode ${episodeDetail!.nomorEpisode}'
                      : '8 / 12 Episode',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: episodeDetail != null
                    ? 1.0
                    : 0.67, // Show as completed for current episode
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
