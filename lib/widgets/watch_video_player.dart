import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'watch_fullscreen.dart'; // Import halaman fullscreen
import '../models/episode_detail_model.dart';

class WatchVideoPlayer extends StatefulWidget {
  final EpisodeDetailModel? episodeDetail;

  const WatchVideoPlayer({super.key, this.episodeDetail});

  @override
  State<WatchVideoPlayer> createState() => _WatchVideoPlayerState();
}

class _WatchVideoPlayerState extends State<WatchVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isBuffering = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String _selectedQuality = 'Auto';

  final List<String> _qualityOptions = [
    'Auto',
    '720p',
    '480p',
    '360p',
    '1080p',
    '2K',
  ];
  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    try {
      // Use episode video source if available, otherwise use default
      String videoUrl = 'https://pixeldrain.com/api/file/icN64hL2';

      if (widget.episodeDetail?.bestQuality?.sourceQuality != null) {
        videoUrl = widget.episodeDetail!.bestQuality!.sourceQuality;
      }

      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

      await _controller.initialize();

      setState(() {
        _isLoading = false;
        _totalDuration = _controller.value.duration;
      });

      _controller.addListener(_videoListener);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _videoListener() {
    if (!mounted) return;

    final value = _controller.value;

    setState(() {
      _currentPosition = value.position;
      _isPlaying = value.isPlaying;
      _isBuffering = value.isBuffering;
    });
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seekForward() {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition <= _totalDuration) {
      _controller.seekTo(newPosition);
    }
  }

  void _seekBackward() {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      _controller.seekTo(newPosition);
    }
  }

  void _onSeek(double value) {
    final newPosition = Duration(seconds: value.toInt());
    _controller.seekTo(newPosition);
  }

  void _toggleFullscreen() async {
    bool wasPlaying = _controller.value.isPlaying;
    if (wasPlaying) {
      await _controller.pause();
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WatchFullscreen(
          controller: _controller,
          videoTitle: 'Episode 8 - My Dress-Up Darling',
          selectedQuality: _selectedQuality,
          wasPlaying: wasPlaying,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedQuality = result['quality'] ?? _selectedQuality;
      });
    }

    if (wasPlaying && mounted) {
      _controller.play();
    }
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Quality',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._qualityOptions.map((quality) {
              bool isLocked = (quality == '1080p' || quality == '2K');

              return ListTile(
                leading: Icon(
                  _selectedQuality == quality && !isLocked
                      ? Icons.check_circle
                      : isLocked
                      ? Icons.lock
                      : Icons.radio_button_unchecked,
                  color: isLocked
                      ? Colors.grey
                      : _selectedQuality == quality
                      ? Colors.pinkAccent
                      : Colors.white70,
                ),
                title: Text(
                  quality,
                  style: GoogleFonts.poppins(
                    color: isLocked ? Colors.grey : Colors.white,
                  ),
                ),
                onTap: isLocked
                    ? () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Upgrade ke VIP untuk menonton dalam $quality',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.pinkAccent,
                          ),
                        );
                      }
                    : () {
                        setState(() {
                          _selectedQuality = quality;
                        });
                        Navigator.pop(context);
                      },
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Colors.pinkAccent,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading video...',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          : _hasError
          ? Center(
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
                    'Error loading video',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _hasError = false;
                      });
                      _initializeVideoPlayer();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
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
                                'Episode 8 - My Dress-Up Darling',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.replay_10,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _seekBackward,
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_isBuffering)
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
                                      _isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: Colors.white,
                                      size: 48,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.forward_10,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _seekForward,
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_currentPosition),
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(_totalDuration),
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
                                    overlayColor: Colors.pinkAccent.withOpacity(
                                      0.2,
                                    ),
                                  ),
                                  child: Slider(
                                    value: _currentPosition.inSeconds
                                        .toDouble(),
                                    max: _totalDuration.inSeconds.toDouble(),
                                    onChanged: _onSeek,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _selectedQuality,
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
                                          onPressed: _showQualitySelector,
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                          onPressed: _toggleFullscreen,
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
                ],
              ),
            ),
    );
  }
}
