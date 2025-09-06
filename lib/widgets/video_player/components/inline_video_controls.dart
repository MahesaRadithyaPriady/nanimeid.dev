import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InlineVideoControls extends StatelessWidget {
  final String videoTitle;
  final bool showControls;
  final bool isPlaying;
  final bool isBuffering;
  final Duration currentPosition;
  final Duration totalDuration;
  final String selectedQuality;

  final VoidCallback onPlayPause;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final ValueChanged<double> onSeek;
  final VoidCallback onShowQualitySelector;
  final VoidCallback onToggleFullscreen;
  // Optional Skip Intro button (visible when within first 90s and duration > 90s)
  final VoidCallback? onSkipIntro;

  const InlineVideoControls({
    super.key,
    required this.videoTitle,
    required this.showControls,
    required this.isPlaying,
    required this.isBuffering,
    required this.currentPosition,
    required this.totalDuration,
    required this.selectedQuality,
    required this.onPlayPause,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onSeek,
    required this.onShowQualitySelector,
    required this.onToggleFullscreen,
    this.onSkipIntro,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !showControls,
      child: AnimatedOpacity(
        opacity: showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    videoTitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Skip Intro button appears near the center controls when applicable
              if (onSkipIntro != null &&
                  totalDuration.inSeconds > 90 &&
                  currentPosition < const Duration(seconds: 90))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onSkipIntro,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    label: Text('Skip Intro', style: GoogleFonts.poppins()),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.replay_10,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: onSeekBackward,
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isBuffering)
                        const SizedBox(
                          width: 45,
                          height: 45,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          color: Colors.white,
                          size: 48,
                        ),
                        onPressed: onPlayPause,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.forward_10,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: onSeekForward,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(currentPosition),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          _formatDuration(totalDuration),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 12,
                        ),
                        activeTrackColor: Colors.pinkAccent,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.pinkAccent,
                        overlayColor: Colors.pinkAccent.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: currentPosition.inSeconds.toDouble().clamp(0.0, totalDuration.inSeconds.toDouble()),
                        max: totalDuration.inSeconds.toDouble().clamp(0.0, double.infinity),
                        onChanged: onSeek,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedQuality,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: onShowQualitySelector,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                                size: 18,
                              ),
                              onPressed: onToggleFullscreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
