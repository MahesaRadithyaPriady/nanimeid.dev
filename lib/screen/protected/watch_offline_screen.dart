import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../widgets/watch_video_player.dart';

class WatchOfflineScreen extends StatefulWidget {
  final String filePath;
  final String title;
  final int episodeNumber;
  final String quality;
  final int? fileSizeBytes;

  const WatchOfflineScreen({
    super.key,
    required this.filePath,
    required this.title,
    required this.episodeNumber,
    required this.quality,
    this.fileSizeBytes,
  });

  @override
  State<WatchOfflineScreen> createState() => _WatchOfflineScreenState();
}

class _WatchOfflineScreenState extends State<WatchOfflineScreen> {
  VideoPlayerController? _controller;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _savePosition();
    WakelockPlus.disable();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _videoListener() {
    if (!mounted) return;
    final v = _controller!.value;
    setState(() {
      _currentPosition = v.position;
      _totalDuration = v.duration;
    });
  }

  Future<void> _maybeResume() async {
    try {
      final posFile = File('${widget.filePath}.pos');
      if (await posFile.exists()) {
        final raw = await posFile.readAsString();
        final ms = int.tryParse(raw) ?? 0;
        final duration = _controller?.value.duration ?? Duration.zero;
        final target = Duration(milliseconds: ms);
        if (ms > 0 && target < duration - const Duration(seconds: 1)) {
          await _controller?.seekTo(target);
        }
      }
    } catch (_) {}
  }

  Future<void> _savePosition() async {
    try {
      final pos = _controller?.value.position ?? Duration.zero;
      final posFile = File('${widget.filePath}.pos');
      await posFile.writeAsString(pos.inMilliseconds.toString(), flush: true);
    } catch (_) {}
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String get _videoTitle => 'Episode ${widget.episodeNumber} - ${widget.title}';
  String get _selectedQuality => widget.quality.isNotEmpty ? widget.quality : 'Offline';

  String? _fmtSize(int? bytes) {
    if (bytes == null) return null;
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int u = 0;
    while (size >= 1024 && u < units.length - 1) {
      size /= 1024;
      u++;
    }
    return '${size.toStringAsFixed(u == 0 ? 0 : 1)} ${units[u]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky video player area using shared widget
            WatchVideoPlayer(
              offlineMode: true,
              offlineFilePath: widget.filePath,
              offlineTitleOverride: 'Episode ${widget.episodeNumber} - ${widget.title}',
              offlineQualityLabel: widget.quality.isNotEmpty ? widget.quality : 'Offline',
              onControllerReady: (controller) async {
                _controller = controller;
                _controller!.addListener(_videoListener);
                setState(() {
                  _totalDuration = _controller!.value.duration;
                });
                await _maybeResume();
                if (mounted && !_controller!.value.isPlaying) {
                  await _controller!.play();
                }
                await WakelockPlus.enable();
              },
            ),
            const SizedBox(height: 16),
            // Limited information area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    // Meta row with offline badge
                    Row(
                      children: [
                        Text('Ep ${widget.episodeNumber}', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 12),
                        Text(widget.quality, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        if (_fmtSize(widget.fileSizeBytes) != null) ...[
                          const SizedBox(width: 12),
                          Text(_fmtSize(widget.fileSizeBytes)!, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                        ],
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade800,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blueGrey.shade600),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_off, color: Colors.white70, size: 14),
                              const SizedBox(width: 6),
                              Text('Offline mode', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Controls are provided by WatchVideoPlayer; this screen focuses on info and offline badge
}
