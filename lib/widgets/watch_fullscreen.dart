import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WatchFullscreen extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoTitle;
  final String selectedQuality;
  final List<String> availableQualities;
  final Map<String, String> qualityUrls;
  final bool wasPlaying;

  const WatchFullscreen({
    super.key,
    required this.controller,
    required this.videoTitle,
    required this.selectedQuality,
    required this.availableQualities,
    required this.qualityUrls,
    required this.wasPlaying,
  });

  @override
  State<WatchFullscreen> createState() => _WatchFullscreenState();
}

class _WatchFullscreenState extends State<WatchFullscreen> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isBuffering = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  late String _selectedQuality;
  double _playbackSpeed = 1.0;
  BoxFit _videoFit = BoxFit.contain;
  late List<String> _qualityOptions;
  final List<Map<String, dynamic>> _fitModes = [
    {'fit': BoxFit.contain, 'icon': Icons.fit_screen, 'label': 'Contain'},
    {'fit': BoxFit.cover, 'icon': Icons.crop_free, 'label': 'Cover'},
    {'fit': BoxFit.fill, 'icon': Icons.crop_square, 'label': 'Fill'},
    {'fit': BoxFit.fitWidth, 'icon': Icons.swap_horiz, 'label': 'Fit Width'},
    {'fit': BoxFit.fitHeight, 'icon': Icons.swap_vert, 'label': 'Fit Height'},
    {'fit': BoxFit.none, 'icon': Icons.do_not_disturb, 'label': 'None'},
    {'fit': BoxFit.scaleDown, 'icon': Icons.compress, 'label': 'Scale Down'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedQuality = widget.selectedQuality;
    _qualityOptions = widget.availableQualities.isNotEmpty
        ? widget.availableQualities
        : ['Auto'];
    _setLandscapeOrientation();
    _initializeFromExistingController();
    WakelockPlus.enable();
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _initializeFromExistingController() {
    _controller = widget.controller;

    setState(() {
      _totalDuration = _controller.value.duration;
      _currentPosition = _controller.value.position;
      _isPlaying = _controller.value.isPlaying;
      _isBuffering = _controller.value.isBuffering;
    });

    _controller.addListener(_videoListener);

    if (widget.wasPlaying && !_controller.value.isPlaying) {
      _controller.play();
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

  void _exitFullscreen() {
    _controller.setPlaybackSpeed(1.0);
    _controller.removeListener(_videoListener);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    Navigator.pop(context, {
      'quality': _selectedQuality,
      'controller': _controller,
    });
  }

  Future<void> _onQualitySelected(String quality) async {
    // Enforce locked tiers
    if (quality == '1080p' || quality == '2K') {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upgrade ke VIP untuk menonton dalam $quality',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }
    setState(() {
      _selectedQuality = quality;
    });
    await _switchQualityTo(quality);
  }

  Future<void> _switchQualityTo(String quality) async {
    try {
      String? url;
      if (quality == 'Auto') {
        url = widget.qualityUrls['Auto'];
      } else {
        url = widget.qualityUrls[quality];
      }

      if (url == null || url.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Kualitas $quality tidak tersedia',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.pinkAccent,
          ),
        );
        return;
      }

      final wasPlaying = _controller.value.isPlaying;
      final pos = _controller.value.position;

      _controller.removeListener(_videoListener);
      final old = _controller;
      final newController = VideoPlayerController.networkUrl(Uri.parse(url));
      setState(() {
        _isBuffering = true;
      });
      await newController.initialize();
      await newController.seekTo(pos);
      if (wasPlaying) await newController.play();

      setState(() {
        _controller = newController;
        _totalDuration = newController.value.duration;
      });
      _controller.addListener(_videoListener);
      await old.dispose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengganti kualitas: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    }
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.6,
          minChildSize: 0.3,
          initialChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select Quality',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _qualityOptions.length,
                    itemBuilder: (context, index) {
                      final quality = _qualityOptions[index];
                      final bool isLocked = (quality == '1080p' || quality == '2K');
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
                            : () async {
                                final selected = quality;
                                Navigator.pop(context);
                                await _onQualitySelected(selected);
                              },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSpeedSelector() {
    final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.6,
          minChildSize: 0.3,
          initialChildSize: 0.4,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Playback Speed',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: speeds.length,
                    itemBuilder: (context, index) {
                      final speed = speeds[index];
                      return ListTile(
                        title: Text(
                          '${speed}x',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        trailing: _playbackSpeed == speed
                            ? const Icon(Icons.check, color: Colors.pinkAccent)
                            : null,
                        onTap: () {
                          setState(() {
                            _playbackSpeed = speed;
                            _controller.setPlaybackSpeed(speed);
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFitSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          minChildSize: 0.3,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Video Fit Mode',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _fitModes.length,
                    itemBuilder: (context, index) {
                      final mode = _fitModes[index];
                      return ListTile(
                        leading: Icon(mode['icon'], color: Colors.white),
                        title: Text(
                          mode['label'],
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        trailing: _videoFit == mode['fit']
                            ? const Icon(Icons.check, color: Colors.pinkAccent)
                            : null,
                        onTap: () {
                          setState(() {
                            _videoFit = mode['fit'];
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _exitFullscreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
          },
          child: Stack(
            children: [
              // Video Player
              Center(
                child: Positioned.fill(
                  child: FittedBox(
                    fit: _videoFit,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),
              ),

              // Watermark (top-right, plain text)
              Positioned(
                right: 16,
                top: 12,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                        children: const [
                          TextSpan(text: 'Nanime', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'ID', style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // UI Controls
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                              onPressed: _exitFullscreen,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.videoTitle,
                                style: GoogleFonts.poppins(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Center Controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: _seekBackward,
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isBuffering)
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    color: Colors.pinkAccent,
                                  ),
                                ),
                              IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: _seekForward,
                          ),
                        ],
                      ),

                      const Spacer(),

                      // Bottom Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            Slider(
                              value: _currentPosition.inSeconds.toDouble(),
                              max: _totalDuration.inSeconds.toDouble(),
                              onChanged: _onSeek,
                              activeColor: Colors.pinkAccent,
                              inactiveColor: Colors.white30,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: _showQualitySelector,
                                      child: Text(
                                        _selectedQuality,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.speed,
                                        color: Colors.white,
                                      ),
                                      onPressed: _showSpeedSelector,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.aspect_ratio,
                                        color: Colors.white,
                                      ),
                                      onPressed: _showFitSelector,
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.fullscreen_exit,
                                        color: Colors.white,
                                      ),
                                      onPressed: _exitFullscreen,
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
      ),
    );
  }
}
