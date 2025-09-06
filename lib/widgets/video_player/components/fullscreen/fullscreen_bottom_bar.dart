import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils.dart' as vputils;

class FullscreenBottomBar extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final String selectedQuality;
  final ValueChanged<double> onSeek;
  final VoidCallback onShowQuality;
  final VoidCallback onShowSpeed;
  final VoidCallback onShowFit;
  final VoidCallback onExit;
  final VoidCallback onAnyTap;
  // Optional live chat toggle (watch party)
  final bool showChatButton;
  final bool isChatOpen;
  final VoidCallback? onToggleChat;
  // Optional Skip Intro button
  final bool showSkipIntro;
  final VoidCallback? onSkipIntro;

  // Keys for guided tutorial highlighting
  final GlobalKey sliderKey;
  final GlobalKey qualityKey;
  final GlobalKey speedKey;
  final GlobalKey fitKey;
  final GlobalKey exitKey;

  const FullscreenBottomBar({
    super.key,
    required this.position,
    required this.duration,
    required this.selectedQuality,
    required this.onSeek,
    required this.onShowQuality,
    required this.onShowSpeed,
    required this.onShowFit,
    required this.onExit,
    required this.onAnyTap,
    required this.sliderKey,
    required this.qualityKey,
    required this.speedKey,
    required this.fitKey,
    required this.exitKey,
    this.showChatButton = false,
    this.isChatOpen = false,
    this.onToggleChat,
    this.showSkipIntro = false,
    this.onSkipIntro,
  });

  @override
  Widget build(BuildContext context) {
    final totalSecs = duration.inSeconds;
    final posSecs = position.inSeconds;
    final hasDuration = totalSecs > 0;
    final sliderMax = hasDuration ? totalSecs.toDouble() : 1.0;
    final sliderValue = hasDuration
        ? posSecs.clamp(0, totalSecs).toDouble()
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        children: [
          Slider(
            key: sliderKey,
            value: sliderValue,
            max: sliderMax,
            onChanged: hasDuration
                ? (v) {
                    onAnyTap();
                    onSeek(v);
                  }
                : null,
            activeColor: Colors.pinkAccent,
            inactiveColor: Colors.white30,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${vputils.formatDurationHMS(position)} / ${vputils.formatDurationHMS(duration)}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  if (showChatButton)
                    IconButton(
                      icon: Icon(
                        isChatOpen ? Icons.chat_bubble : Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      tooltip: kReleaseMode ? null : 'Live Chat',
                      onPressed: () {
                        onAnyTap();
                        onToggleChat?.call();
                      },
                    ),
                  if (showSkipIntro)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: TextButton.icon(
                        onPressed: () {
                          onAnyTap();
                          onSkipIntro?.call();
                        },
                        icon: const Icon(Icons.skip_next, color: Colors.white),
                        label: Text(
                          'Skip Intro',
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white10,
                        ),
                      ),
                    ),
                  TextButton(
                    key: qualityKey,
                    onPressed: () {
                      onAnyTap();
                      onShowQuality();
                    },
                    child: Text(
                      selectedQuality,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    key: speedKey,
                    icon: const Icon(
                      Icons.speed,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      onAnyTap();
                      onShowSpeed();
                    },
                  ),
                  IconButton(
                    key: fitKey,
                    icon: const Icon(
                      Icons.aspect_ratio,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      onAnyTap();
                      onShowFit();
                    },
                  ),
                  IconButton(
                    key: exitKey,
                    icon: const Icon(
                      Icons.fullscreen_exit,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      onAnyTap();
                      onExit();
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
