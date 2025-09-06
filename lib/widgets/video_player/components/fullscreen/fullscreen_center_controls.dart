import 'package:flutter/material.dart';

class FullscreenCenterControls extends StatelessWidget {
  final bool isPlaying;
  final bool isBuffering;
  final VoidCallback onPlayPause;
  final VoidCallback onSeekBackward;
  final VoidCallback onSeekForward;

  // Keys for tutorial highlights
  final GlobalKey playKey;
  final GlobalKey backwardKey;
  final GlobalKey forwardKey;

  const FullscreenCenterControls({
    super.key,
    required this.isPlaying,
    required this.isBuffering,
    required this.onPlayPause,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.playKey,
    required this.backwardKey,
    required this.forwardKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          key: backwardKey,
          icon: const Icon(
            Icons.replay_10,
            color: Colors.white,
            size: 40,
          ),
          onPressed: onSeekBackward,
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            if (isBuffering)
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Colors.pinkAccent,
                ),
              ),
            IconButton(
              key: playKey,
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white,
                size: 64,
              ),
              onPressed: onPlayPause,
            ),
          ],
        ),
        IconButton(
          key: forwardKey,
          icon: const Icon(
            Icons.forward_10,
            color: Colors.white,
            size: 40,
          ),
          onPressed: onSeekForward,
        ),
      ],
    );
  }
}
