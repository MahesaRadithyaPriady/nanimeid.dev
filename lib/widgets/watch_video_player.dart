import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'watch_fullscreen.dart'; // Import halaman fullscreen
import '../models/episode_detail_model.dart';
import '../services/episode_progress_service.dart';
import '../services/vip_service.dart';
import '../models/vip_model.dart';
import '../services/watchparty_socket.dart';
import '../services/watchparty_service.dart';
import 'video_player/components/quality_selector_sheet.dart';
import 'video_player/components/inline_video_controls.dart';
import 'video_player/components/video_loading_overlay.dart';
import 'video_player/components/video_error_overlay.dart';
import '../controllers/settings_controller.dart';
import '../services/watch_session_service.dart';

class WatchVideoPlayer extends StatefulWidget {
  final EpisodeDetailModel? episodeDetail;
  // Offline mode additions
  final bool offlineMode;
  final String? offlineFilePath;
  final String? offlineTitleOverride;
  final String? offlineQualityLabel;
  final void Function(VideoPlayerController controller)? onControllerReady;
  // Watch party mode additions
  final bool watchParty; // differentiate behavior for watch party
  final void Function(Duration position, bool isPlaying)? onPlaybackUpdate; // sync position/state upstream
  final VoidCallback? onControllerDisposed;
  final WatchPartySocket? watchPartySocket;
  final String? watchPartyRoomCode;
  // When in watch party, whether local user is allowed to control playback
  final bool allowControls;

  const WatchVideoPlayer({
    super.key,
    this.episodeDetail,
    this.offlineMode = false,
    this.offlineFilePath,
    this.offlineTitleOverride,
    this.offlineQualityLabel,
    this.onControllerReady,
    this.watchParty = false,
    this.onPlaybackUpdate,
    this.onControllerDisposed,
    this.watchPartySocket,
    this.watchPartyRoomCode,
    this.allowControls = true,
  });

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
  DateTime _lastReport = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastProgressSave = DateTime.fromMillisecondsSinceEpoch(0);
  bool _markedCompleted = false;
  Timer? _hideTimer;
  bool? _isVip; // null while loading
  bool _vipLoading = false;
  // Skip intro controller
  static const Duration _introSkip = Duration(seconds: 90);
  bool _introApplied = false;
  // Watch session state
  String? _watchSessionToken;
  Timer? _heartbeatTimer;
  bool _sessionStarting = false;
  bool _sessionCompleted = false;

  bool get _controlsAllowed => !widget.watchParty || widget.allowControls;
  bool _resumePromptShown = false;
  bool? _lastBufferReady;
  bool _initNotified = false;

  // Build dynamic title from episode detail
  String get _videoTitle {
    if (widget.offlineMode && widget.offlineTitleOverride != null) {
      return widget.offlineTitleOverride!;
    }
    return widget.episodeDetail != null
        ? 'Episode ${widget.episodeDetail!.nomorEpisode} - ${widget.episodeDetail!.judulEpisode}'
        : 'Episode 8 - My Dress-Up Darling';
  }
  // Manual skip intro action for the inline player
  Future<void> _skipIntroManually() async {
    if (!_controlsAllowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    try {
      final dur = _controller.value.duration;
      if (dur.inSeconds > _introSkip.inSeconds) {
        await _controller.seekTo(_introSkip);
        _introApplied = true;
        _showControlsAndScheduleHide();
      }
    } catch (_) {}
  }

  Future<void> _startWatchSessionIfNeeded() async {
    if (widget.offlineMode) return; // no session in offline mode
    if (_sessionStarting) return;
    if (_watchSessionToken != null) return;
    final epId = widget.episodeDetail?.id ?? 0;
    if (epId <= 0) return;
    _sessionStarting = true;
    try {
      final data = await WatchSessionService.startSession(episodeId: epId);
      _watchSessionToken = (data['sessionToken'] ?? data['token'] ?? '').toString();
      if ((_watchSessionToken ?? '').isEmpty) {
        _watchSessionToken = null;
      } else {
        _startHeartbeat();
      }
    } catch (_) {
      // ignore start errors silently
    } finally {
      _sessionStarting = false;
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    if (_watchSessionToken == null) return;
    // Send immediately once, then on interval
    _sendHeartbeatOnce();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _sendHeartbeatOnce();
    });
  }

  Future<void> _sendHeartbeatOnce() async {
    if (!mounted) return;
    if (_watchSessionToken == null) return;
    final token = _watchSessionToken!;
    try {
      final val = _controller.value;
      if (!val.isInitialized) return;
      // Optionally skip sending when paused to reduce noise
      if (!val.isPlaying) return;
      final positionSec = val.position.inSeconds;
      final playbackRate = val.playbackSpeed;
      await WatchSessionService.sendProgress(
        sessionToken: token,
        positionSec: positionSec,
        playbackRate: playbackRate,
      );
    } catch (_) {
      // ignore heartbeat errors
    }
  }

  Future<void> _completeWatchSessionIfNeeded() async {
    if (_sessionCompleted) return;
    final token = _watchSessionToken;
    if (token == null || token.isEmpty) return;
    _sessionCompleted = true;
    _heartbeatTimer?.cancel();
    try {
      final data = await WatchSessionService.completeSession(sessionToken: token);
      if (!mounted) return;
      final granted = data['granted'] == true;
      final xp = (data['xp'] is num) ? (data['xp'] as num).toInt() : null;
      if (granted) {
        final msg = xp != null && xp > 0
            ? (xp == 20 ? '+20 XP (VIP)' : '+$xp XP')
            : 'XP granted';
        try {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selamat! $msg', style: GoogleFonts.poppins()),
              backgroundColor: Colors.green,
            ),
          );
        } catch (_) {}
      }
    } catch (_) {
      // ignore complete errors
    }
  }

  Future<void> _loadVipStatus() async {
    setState(() {
      _vipLoading = true;
    });
    try {
      final VipResponseModel res = await VipService.getMyVip();
      if (!mounted) return;
      setState(() {
        _isVip = res.isActive;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVip = false; // default to non-VIP on error
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _vipLoading = false;
      });
    }
  }

  Future<void> _maybeApplyIntroSkip() async {
    if (!mounted) return;
    if (_introApplied) return;
    // Only skip if duration > 90s and current position is before 90s
    final dur = _controller.value.duration;
    final pos = _controller.value.position;
    if (dur.inSeconds > _introSkip.inSeconds && pos < _introSkip) {
      try {
        await _controller.seekTo(_introSkip);
        _introApplied = true;
      } catch (_) {}
    } else {
      _introApplied = true; // mark as applied to avoid re-checks
    }
  }

  // VIP gating now centralized in video_player/utils.dart -> requiresVip()

  // Quality options come from API response
  List<String> get _apiQualities {
    final names = widget.episodeDetail?.availableQualityNames ?? [];
    // Sort descending by resolution if recognizable
    final order = ['2K', '1080p', '720p', '480p', '360p', '240p'];
    names.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return names;
  }

  List<String> get _qualityOptions {
    if (widget.offlineMode) return ['Offline'];
    final api = _apiQualities;
    if (api.isEmpty) return ['Auto'];
    return ['Auto', ...api];
  }

  Map<String, String> get _qualityUrlMap {
    final map = <String, String>{};
    final best = widget.episodeDetail?.bestQuality?.sourceQuality;
    if (best != null && best.isNotEmpty) {
      map['Auto'] = best;
    }
    for (final name in widget.episodeDetail?.availableQualityNames ?? []) {
      final url = widget.episodeDetail?.getQualityByName(name)?.sourceQuality;
      if (url != null && url.isNotEmpty) {
        map[name] = url;
      }
    }
    return map;
  }

  @override
  void initState() {
    super.initState();
    // Initialize selected quality label
    _selectedQuality = widget.offlineMode
        ? (widget.offlineQualityLabel ?? 'Offline')
        : 'Auto';
    _initializeVideoPlayer();
    if (!widget.offlineMode) {
      _loadVipStatus();
    }
  }

  void _initializeVideoPlayer() async {
    try {
      if (widget.offlineMode) {
        final path = widget.offlineFilePath;
        if (path == null || path.isEmpty) {
          throw Exception('Offline file path is required in offline mode');
        }
        _controller = VideoPlayerController.file(File(path));
      } else {
        // Use episode video source if available, otherwise use default
        String videoUrl = 'https://pixeldrain.com/api/file/icN64hL2';
        if (widget.episodeDetail?.bestQuality?.sourceQuality != null &&
            widget.episodeDetail!.bestQuality!.sourceQuality.isNotEmpty) {
          videoUrl = widget.episodeDetail!.bestQuality!.sourceQuality;
        }
        _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      }

      await _controller.initialize();

      setState(() {
        _isLoading = false;
        _totalDuration = _controller.value.duration;
      });

      // Seek to last watched progress if available (Host only in watch party)
      final epId = widget.episodeDetail?.id ?? 0;
      final shouldFetchProgress = (epId > 0) && (!widget.watchParty || _controlsAllowed);
      if (shouldFetchProgress) {
        try {
          final res = await EpisodeProgressService.getEpisodeProgress(epId);
          final totalSecs = _controller.value.duration.inSeconds;
          if (res.isSuccess && totalSecs > 0) {
            final lastSecs = res.data.progressWatching;
            if (lastSecs > 0) {
              final clamped = lastSecs.clamp(0, totalSecs - 2);
              if (widget.watchParty && _controlsAllowed && !_resumePromptShown && mounted) {
                _resumePromptShown = true;
                final shouldResume = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: Colors.pinkAccent,
                    title: Text(
                      'Lanjutkan Menonton?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    content: Text(
                      'Apakah ingin melanjutkan progress menonton kamu?\n\nJikalau tidak maka progress sebelumnya akan hilang.',
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(false);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Mulai dari Awal', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pink.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                        child: Text('Lanjutkan', style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (shouldResume == true) {
                  if (clamped > 0) {
                    await _controller.seekTo(Duration(seconds: clamped));
                  }
                } else {
                  // Reset to beginning and clear previous progress on server
                  await _controller.seekTo(Duration.zero);
                  try {
                    await EpisodeProgressService.saveOrUpdateProgress(
                      episodeId: epId,
                      progressWatching: 0,
                      isCompleted: false,
                    );
                  } catch (_) {}
                }
              } else {
                if (clamped > 0) {
                  await _controller.seekTo(Duration(seconds: clamped));
                }
              }
            }
          }
        } catch (_) {
          // ignore errors silently
        }
      }

      // Do not auto-skip intro. Skipping is now manual-only via the Skip Intro button.

      _controller.addListener(_videoListener);
      // In watch party: do not autoplay; mark as ready (initialized)
      if (widget.watchParty) {
        try { await _controller.pause(); } catch (_) {}
        try {
          if (widget.watchPartySocket != null) {
            widget.watchPartySocket?.setReady(true);
          } else if ((widget.watchPartyRoomCode ?? '').isNotEmpty) {
            // HTTP fallback readiness
            await WatchPartyService.setReady(code: widget.watchPartyRoomCode!, isReady: true);
          }
        } catch (_) {}
        try {
          final ready = _controller.value.isInitialized && !_controller.value.isBuffering;
          _lastBufferReady = ready;
          try { widget.watchPartySocket?.setBufferReady(ready); } catch (_) {}
        } catch (_) {}
        // One-time local notification that initialization is complete
        if (!_initNotified && mounted) {
          _initNotified = true;
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Video siap untuk diputar', style: GoogleFonts.poppins()),
                backgroundColor: Colors.pinkAccent,
              ),
            );
          } catch (_) {}
        }
      } else {
        // Autoplay after init and seek (non-watch-party)
        try { await _controller.play(); } catch (_) {}
      }
      _showControlsAndScheduleHide();
      if (widget.onControllerReady != null) {
        widget.onControllerReady!(_controller);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _switchQualityTo(String quality) async {
    if (widget.offlineMode) {
      // Disabled in offline mode
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengaturan kualitas tidak tersedia dalam mode offline', style: GoogleFonts.poppins()),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }
    try {
      String? url;
      if (quality == 'Auto') {
        url = widget.episodeDetail?.bestQuality?.sourceQuality;
      } else {
        url = widget.episodeDetail?.getQualityByName(quality)?.sourceQuality;
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
      final posAtStart = _controller.value.position;

      // Prepare new controller while keeping old playing and active
      final old = _controller;
      final newController = VideoPlayerController.networkUrl(Uri.parse(url));
      setState(() {
        _isBuffering = true; // show subtle spinner only
      });
      await newController.initialize();
      // Capture the latest position from the current (old) controller
      Duration latestPos = _controller.value.isInitialized ? _controller.value.position : posAtStart;
      await newController.seekTo(latestPos);
      // Right before swapping, capture once more and compensate small drift (+200ms)
      final justBeforeSwap = _controller.value.isInitialized ? _controller.value.position : latestPos;
      if (justBeforeSwap > latestPos) {
        final compensated = justBeforeSwap + const Duration(milliseconds: 200);
        await newController.seekTo(compensated);
        latestPos = compensated;
      }
      // Pre-render a frame to avoid black screen
      try {
        await newController.play();
        await Future.delayed(const Duration(milliseconds: 80));
        await newController.pause();
      } catch (_) {}

      // Ensure new controller is truly ready (initialized and has aspect ratio)
      int _tries = 0;
      while (mounted && _tries < 8) {
        final val = newController.value;
        if (val.isInitialized && val.aspectRatio > 0) break;
        _tries++;
        await Future.delayed(const Duration(milliseconds: 40));
      }
      if (wasPlaying) await newController.play();

      setState(() {
        _controller = newController;
        _totalDuration = newController.value.duration;
      });
      // Now detach listener from old and attach to new
      try { old.removeListener(_videoListener); } catch (_) {}
      _controller.addListener(_videoListener);
      await old.dispose();
      if (mounted) {
        setState(() {
          _isBuffering = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengganti kualitas: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.pinkAccent,
        ),
      );
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

    // Emit buffer readiness changes in watch party
    if (widget.watchParty && widget.watchPartySocket != null) {
      final ready = value.isInitialized && !value.isBuffering;
      if (_lastBufferReady != ready) {
        _lastBufferReady = ready;
        try { widget.watchPartySocket!.setBufferReady(ready); } catch (_) {}
      }
    }

    // Throttled playback update reporting (every 500ms)
    if (widget.watchParty && widget.onPlaybackUpdate != null) {
      final now = DateTime.now();
      if (now.difference(_lastReport).inMilliseconds >= 500) {
        _lastReport = now;
        widget.onPlaybackUpdate!.call(_currentPosition, _isPlaying);
      }
    }

    // Periodically save progress (every ~10s)
    final now = DateTime.now();
    if ((widget.episodeDetail?.id ?? 0) > 0 && now.difference(_lastProgressSave).inSeconds >= 10) {
      _lastProgressSave = now;
      _saveProgress();
    }

    // Start watch session when playback really starts
    if (value.isPlaying && _watchSessionToken == null && !widget.offlineMode) {
      _startWatchSessionIfNeeded();
    }

    // Mark as completed when near the end (within last 2 seconds)
    if ((widget.episodeDetail?.id ?? 0) > 0 && !_markedCompleted) {
      final dur = value.duration;
      if (dur.inSeconds > 0 && value.position >= dur - const Duration(seconds: 2)) {
        _markedCompleted = true;
        _saveProgress(completed: true);
        // Complete the watch session to award XP (server-side rules)
        _completeWatchSessionIfNeeded();
      }
    }
  }

  // Show controls and auto-hide them after a short delay
  void _showControlsAndScheduleHide({Duration delay = const Duration(seconds: 3)}) {
    if (!mounted) return;
    setState(() {
      _showControls = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(delay, () {
      if (!mounted) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  // Any tap inside the player should reveal controls and reset the hide timer
  void _onAnyTap() {
    _showControlsAndScheduleHide();
  }

  void _togglePlayPause() async {
    if (!_controlsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    if (_controller.value.isPlaying) {
      await _controller.pause();
      // Save on pause
      _saveProgress();
      _showControlsAndScheduleHide();
    } else {
      await _controller.play();
      _showControlsAndScheduleHide();
    }
    if (widget.watchParty && widget.onPlaybackUpdate != null) {
      // Report with the actual updated state
      widget.onPlaybackUpdate!.call(_controller.value.position, _controller.value.isPlaying);
    }
  }

  void _seekForward() {
    if (!_controlsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    final newPosition = _currentPosition + const Duration(seconds: 10);
    if (newPosition <= _totalDuration) {
      _controller.seekTo(newPosition);
    }
  }

  void _seekBackward() {
    if (!_controlsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    final newPosition = _currentPosition - const Duration(seconds: 10);
    if (newPosition >= Duration.zero) {
      _controller.seekTo(newPosition);
    }
  }

  void _onSeek(double value) {
    if (!_controlsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    final newPosition = Duration(seconds: value.toInt());
    _controller.seekTo(newPosition);
    if (widget.watchParty && widget.onPlaybackUpdate != null) {
      widget.onPlaybackUpdate!.call(newPosition, _controller.value.isPlaying);
    }
  }

  void _toggleFullscreen() async {
    if (!_controlsAllowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    bool wasPlaying = _controller.value.isPlaying;
    if (wasPlaying) {
      await _controller.pause();
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WatchFullscreen(
          controller: _controller,
          videoTitle: _videoTitle,
          selectedQuality: _selectedQuality,
          availableQualities: widget.offlineMode ? ['Offline'] : _qualityOptions,
          qualityUrls: widget.offlineMode ? const {} : _qualityUrlMap,
          wasPlaying: wasPlaying,
          watchParty: widget.watchParty,
          socket: widget.watchPartySocket,
          roomCode: widget.watchPartyRoomCode,
          onPlaybackUpdate: widget.onPlaybackUpdate,
          isVip: _isVip,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedQuality = result['quality'] ?? _selectedQuality;
      });
      // Adopt controller returned from fullscreen to avoid re-init/loading
      final returned = result['controller'];
      if (returned is VideoPlayerController && returned != _controller) {
        _controller.removeListener(_videoListener);
        final old = _controller;
        _controller = returned;
        _controller.addListener(_videoListener);
        setState(() {
          _totalDuration = _controller.value.duration;
          _currentPosition = _controller.value.position;
          _isPlaying = _controller.value.isPlaying;
          _isBuffering = _controller.value.isBuffering;
        });
        await old.dispose();
      }
    }

    if (wasPlaying && mounted) {
      _controller.play();
    }
  }

  void _showQualitySelector() {
    if (widget.offlineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pengaturan kualitas tidak tersedia dalam mode offline', style: GoogleFonts.poppins()),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }
    bool isLockedQuality(String q) {
      final sc = SettingsController.instance;
      final hasServerPaid = (sc.settings?.paidQualities.isNotEmpty == true);
      // If server provides paid_qualities, only those are VIP; else all free
      final isPaid = hasServerPaid && sc.isQualityPaid(q);
      return isPaid && (_isVip != true);
    }
    QualitySelectorSheet.show(
      context,
      qualities: _qualityOptions,
      selectedQuality: _selectedQuality,
      isLocked: (q) => isLockedQuality(q),
      onSelect: (q) async {
        setState(() {
          _selectedQuality = q;
        });
        await _onQualitySelected(q);
      },
      isScrollControlled: false,
    );
  }

  Future<void> _onQualitySelected(String quality) async {
    // Enforce locks strictly from server paid_qualities. If absent, all free
    final sc = SettingsController.instance;
    final hasServerPaid = (sc.settings?.paidQualities.isNotEmpty == true);
    final isPaid = hasServerPaid && sc.isQualityPaid(quality);
    if (isPaid && (_isVip != true)) {
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
    await _switchQualityTo(quality);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _heartbeatTimer?.cancel();
    try {
      widget.onControllerDisposed?.call();
    } catch (_) {}
    // In watch party, unset readiness on dispose
    try {
      if (widget.watchParty) {
        widget.watchPartySocket?.setReady(false);
        widget.watchPartySocket?.setBufferReady(false);
      }
    } catch (_) {}
    // Try to save final progress (fire-and-forget)
    _saveProgress();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveProgress({bool completed = false}) async {
    final epId = widget.episodeDetail?.id ?? 0;
    if (epId <= 0) return;
    try {
      final secs = _controller.value.position.inSeconds;
      await EpisodeProgressService.saveOrUpdateProgress(
        episodeId: epId,
        progressWatching: secs,
        isCompleted: completed || _markedCompleted,
      );
    } catch (_) {
      // swallow errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.black,
      child: _isLoading
          ? const VideoLoadingOverlay()
          : _hasError
          ? VideoErrorOverlay(
              onRetry: () {
                setState(() {
                  _isLoading = true;
                  _hasError = false;
                });
                _initializeVideoPlayer();
              },
            )
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _onAnyTap,
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                  InlineVideoControls(
                    videoTitle: _videoTitle,
                    showControls: _showControls,
                    isPlaying: _isPlaying,
                    isBuffering: _isBuffering,
                    currentPosition: _currentPosition,
                    totalDuration: _totalDuration,
                    selectedQuality: _selectedQuality,
                    onPlayPause: _togglePlayPause,
                    onSeekForward: () {
                      _onAnyTap();
                      _seekForward();
                    },
                    onSeekBackward: () {
                      _onAnyTap();
                      _seekBackward();
                    },
                    onSeek: (v) => _onSeek(v),
                    onShowQualitySelector: _showQualitySelector,
                    onToggleFullscreen: _toggleFullscreen,
                    onSkipIntro: ((MediaQuery.of(context).orientation != Orientation.portrait) &&
                            _controlsAllowed &&
                            _totalDuration.inSeconds > _introSkip.inSeconds &&
                            _currentPosition < _introSkip)
                        ? () {
                            _onAnyTap();
                            _skipIntroManually();
                          }
                        : null,
                  ),
                ],
              ),
            ),
    );
  }
}
