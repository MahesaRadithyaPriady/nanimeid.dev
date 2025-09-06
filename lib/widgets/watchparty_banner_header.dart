import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

class WatchPartyBannerHeader extends StatelessWidget {
  final String bannerUrl;
  final String episodeTitle;
  final int episodeNumber;
  final String roomCode;
  final bool isPaused;
  final VoidCallback onTogglePlayPause;

  const WatchPartyBannerHeader({
    super.key,
    required this.bannerUrl,
    required this.episodeTitle,
    required this.episodeNumber,
    required this.roomCode,
    required this.isPaused,
    required this.onTogglePlayPause,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background banner image
        bannerUrl.isEmpty
            ? Container(
                color: const Color(0xFF1A1A1A),
                child: Center(
                  child: Text('Banner tidak tersedia', style: GoogleFonts.poppins(color: Colors.white54)),
                ),
              )
            : Image.network(
                bannerUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: Center(
                    child: Text('Gagal memuat banner', style: GoogleFonts.poppins(color: Colors.white54)),
                  ),
                ),
              ),
        // Gradient overlay bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xCC000000), Color(0x00000000)],
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        episodeTitle.isEmpty ? 'Episode' : episodeTitle,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kode: $roomCode · E${episodeNumber == 0 ? '-' : episodeNumber}',
                        style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onTogglePlayPause,
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                  tooltip: kReleaseMode ? null : 'Toggle Play/Pause (sinkronisasi)'
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
