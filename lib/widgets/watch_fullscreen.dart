import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'video_player/components/quality_selector_sheet.dart';
import 'video_player/components/speed_selector_sheet.dart';
import 'video_player/components/fit_selector_sheet.dart';
import 'video_player/utils.dart';
import 'video_player/components/fullscreen/fullscreen_bottom_bar.dart';
import 'video_player/components/fullscreen/fullscreen_center_controls.dart';
import 'video_player/components/fullscreen/seek_hints_overlay.dart';
import 'video_player/components/fullscreen/fullscreen_top_bar.dart';
import 'video_player/components/fullscreen/spotlight_overlay.dart';
import 'video_player/components/fullscreen/tutorial_dismiss_button.dart';
import '../services/watchparty_socket.dart';
import '../controllers/settings_controller.dart';
import '../services/watch_session_service.dart';

class WatchFullscreen extends StatefulWidget {
  final VideoPlayerController controller;
  final String videoTitle;
  final String selectedQuality;
  final List<String> availableQualities;
  final Map<String, String> qualityUrls;
  final bool wasPlaying;
  // Watch party sync
  final bool watchParty;
  final void Function(Duration position, bool isPlaying)? onPlaybackUpdate;
  // VIP status from parent (null while unknown)
  final bool? isVip;
  // Watch party socket & room code (optional)
  final WatchPartySocket? socket;
  final String? roomCode;
  // Watch session token (optional, provided by parent)
  final String? sessionToken;

  const WatchFullscreen({
    super.key,
    required this.controller,
    required this.videoTitle,
    required this.selectedQuality,
    required this.availableQualities,
    required this.qualityUrls,
    required this.wasPlaying,
    this.watchParty = false,
    this.onPlaybackUpdate,
    this.isVip,
    this.socket,
    this.roomCode,
    this.sessionToken,
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
  DateTime _lastReport = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool get _offlineMode =>
      widget.qualityUrls.isEmpty ||
      (widget.availableQualities.length == 1 &&
          widget.availableQualities.first == 'Offline');
  Timer? _hideTimer;
  bool _showTutorial = false;
  // Live chat (watch party)
  bool _chatOpen = false;
  Offset? _dragStart;
  final TextEditingController _chatController = TextEditingController();
  final FocusNode _chatFocus = FocusNode();
  // Chat state
  final List<Map<String, dynamic>> _chatMessages = [];
  int _peopleCount = 0;
  StreamSubscription? _subChat;
  StreamSubscription? _subPresenceJoin;
  StreamSubscription? _subPresenceLeave;
  StreamSubscription? _subParticipants;
  // Double-tap feedback overlays
  bool _showLeftHint = false;
  bool _showRightHint = false;
  Timer? _leftHintTimer;
  Timer? _rightHintTimer;
  // Right press-and-hold temporary speed boost
  bool _rightBoostActive = false;
  bool _showRightBoost = false;
  double _prevSpeedBeforeBoost = 1.0;
  static const String _prefsKeyTutorialSeen = 'fullscreen_tips_seen';
  // Disable tutorial entirely in all build modes for stability
  bool get _tutorialEnabled => false;
  // Lock all UI controls except the lock toggle itself
  bool _controlsLocked = false;
  bool _showLockButton = true; // visibility of lock button when controls are hidden
  Timer? _lockHideTimer;
  // Skip intro controller
  static const Duration _introSkip = Duration(seconds: 90);
  bool _introApplied = false;
  // Guided tour keys & state
  final GlobalKey _keyBack = GlobalKey();
  final GlobalKey _keyPlay = GlobalKey();
  final GlobalKey _keySlider = GlobalKey();
  final GlobalKey _keyQuality = GlobalKey();
  final GlobalKey _keyExit = GlobalKey();
  final GlobalKey _keyBackward = GlobalKey();
  final GlobalKey _keyForward = GlobalKey();
  final GlobalKey _keySpeed = GlobalKey();
  final GlobalKey _keyFit = GlobalKey();
  int _tutorialStep = 0; // 0..8
  final List<Map<String, dynamic>> _fitModes = [
    {'fit': BoxFit.contain, 'icon': Icons.fit_screen, 'label': 'Contain'},
    {'fit': BoxFit.cover, 'icon': Icons.crop_free, 'label': 'Cover'},
    {'fit': BoxFit.fill, 'icon': Icons.crop_square, 'label': 'Fill'},
    {'fit': BoxFit.fitWidth, 'icon': Icons.swap_horiz, 'label': 'Fit Width'},
    {'fit': BoxFit.fitHeight, 'icon': Icons.swap_vert, 'label': 'Fit Height'},
    {'fit': BoxFit.none, 'icon': Icons.do_not_disturb, 'label': 'None'},
    {'fit': BoxFit.scaleDown, 'icon': Icons.compress, 'label': 'Scale Down'},
  ];

  // VIP gating now centralized in video_player/utils.dart -> requiresVip()
  // Watch session completion guard
  bool _sessionCompleted = false;

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
    if (_tutorialEnabled && !widget.watchParty) {
      _loadTutorialSeen();
    }
    if (widget.watchParty) {
      _initSocket();
    }
  }

  Future<void> _initSocket() async {
    final s = widget.socket;
    final code = widget.roomCode;
    if (s == null || code == null || code.isEmpty) return;
    try {
      if (!s.isConnected) {
        await s.connect();
      }
      // Subscribe first
      _subChat = s.onChatNew.listen((event) {
        try {
          final m = Map<String, dynamic>.from(event);
          setState(() {
            _chatMessages.add(m);
          });
        } catch (_) {}
      });
      _subPresenceJoin = s.onPresenceJoin.listen((user) {
        setState(() {
          _peopleCount += 1;
        });
      });
      _subPresenceLeave = s.onPresenceLeave.listen((user) {
        setState(() {
          _peopleCount = (_peopleCount - 1).clamp(0, 1000000);
        });
      });
      _subParticipants = s.onParticipantsResult.listen((payload) {
        try {
          final p = Map<String, dynamic>.from(payload);
          final list = p['participants'];
          int count = 0;
          if (list is List) count = list.length;
          setState(() {
            _peopleCount = count;
          });
        } catch (_) {}
      });

      // Join and fetch participants
      s.joinRoom(code: code);
      s.requestParticipants();
    } catch (_) {}
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

    // Do not auto-skip intro in fullscreen. Skipping is manual-only via the Skip Intro button.

    if (widget.wasPlaying && !_controller.value.isPlaying) {
      _controller.play();
    }
    _showControlsAndScheduleHide();
  }

  // Manual Skip Intro action for fullscreen
  Future<void> _skipIntroManually() async {
    try {
      final dur = _controller.value.duration;
      if (dur.inSeconds > _introSkip.inSeconds) {
        await _controller.seekTo(_introSkip);
        _introApplied = true;
        _showControlsAndScheduleHide();
      }
    } catch (_) {}
  }

  Future<void> _maybeApplyIntroSkip() async {
    if (!mounted) return;
    if (_introApplied) return;
    final dur = _controller.value.duration;
    final pos = _controller.value.position;
    if (dur.inSeconds > _introSkip.inSeconds && pos < _introSkip) {
      try {
        await _controller.seekTo(_introSkip);
        _introApplied = true;
      } catch (_) {}
    } else {
      _introApplied = true;
    }
  }

  Future<void> _loadTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seen = prefs.getBool(_prefsKeyTutorialSeen) ?? false;
      if (!seen && mounted) {
        setState(() {
          _showTutorial = true;
        });
      }
    } catch (_) {
      // ignore errors; default to not showing
    }
  }

  Future<void> _dismissTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKeyTutorialSeen, true);
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _showTutorial = false;
    });
  }

  void _videoListener() {
    if (!mounted) return;

    final value = _controller.value;
    final now = DateTime.now();

    // Throttle frequent UI updates to reduce frame pressure (profile mode)
    final immediateChange =
        (value.isPlaying != _isPlaying) || (value.isBuffering != _isBuffering);
    final shouldThrottle = now.difference(_lastUiUpdate).inMilliseconds >= 200;

    if (immediateChange || shouldThrottle) {
      _lastUiUpdate = now;
      if (!mounted) return;
      setState(() {
        _currentPosition = value.position;
        _totalDuration = value.duration;
        _isPlaying = value.isPlaying;
        _isBuffering = value.isBuffering;
      });
    }

    if (widget.watchParty && widget.onPlaybackUpdate != null) {
      if (now.difference(_lastReport).inMilliseconds >= 500) {
        _lastReport = now;
        widget.onPlaybackUpdate!.call(_currentPosition, _isPlaying);
      }
    }

    // Near-end completion handling within fullscreen
    try {
      final dur = value.duration;
      if (!_sessionCompleted && (widget.sessionToken != null && widget.sessionToken!.isNotEmpty)) {
        if (dur.inSeconds > 0 && value.position >= dur - const Duration(seconds: 2)) {
          _sessionCompleted = true;
          _completeWatchSessionInFullscreen(widget.sessionToken!);
        }
      }
    } catch (_) {}
  }

  Future<void> _completeWatchSessionInFullscreen(String token) async {
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
    } catch (_) {}
  }

  void _toggleLock() {
    setState(() {
      _controlsLocked = !_controlsLocked;
      if (_controlsLocked) {
        _hideControlsImmediate();
        _showLockTemporarily();
      } else {
        // When unlocked, follow normal controls visibility rules
        _showLockButton = _showControls;
      }
    });
  }

  void _hideControlsImmediate() {
    _hideTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showControls = false;
    });
  }

  void _showLockTemporarily() {
    _lockHideTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _showLockButton = true;
    });
    _lockHideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_controlsLocked) {
        setState(() {
          _showLockButton = false;
        });
      }
    });
  }

  void _onSurfaceTap() {
    if (_controlsLocked) {
      // When locked, tapping should reveal the lock button temporarily
      _showLockTemporarily();
      return;
    }
    if (_showControls) {
      _hideControlsImmediate();
    } else {
      _onAnyTap();
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    _showControlsAndScheduleHide();
    if (widget.watchParty && widget.onPlaybackUpdate != null) {
      final playing = !_controller.value.isPlaying;
      widget.onPlaybackUpdate!.call(_currentPosition, playing);
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
    if (widget.watchParty && widget.onPlaybackUpdate != null) {
      widget.onPlaybackUpdate!.call(newPosition, _controller.value.isPlaying);
    }
    _showControlsAndScheduleHide();
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
    _hideTimer?.cancel();
    Navigator.pop(context, {
      'quality': _selectedQuality,
      'controller': _controller,
    });
  }

  Future<void> _onQualitySelected(String quality) async {
    // Enforce locked tiers
    final sc = SettingsController.instance;
    final hasServerPaid = (sc.settings?.paidQualities.isNotEmpty == true);
    final isPaid = hasServerPaid ? sc.isQualityPaid(quality) : requiresVip(quality);
    if (isPaid && (widget.isVip != true)) {
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
      final posAtStart = _controller.value.position;

      // Keep old active while preparing new
      final old = _controller;
      final newController = VideoPlayerController.networkUrl(Uri.parse(url));
      setState(() {
        _isBuffering = true;
      });
      await newController.initialize();
      // Seek to the latest known position, then compensate immediately before swap
      Duration latestPos = _controller.value.isInitialized
          ? _controller.value.position
          : posAtStart;
      await newController.seekTo(latestPos);
      final justBeforeSwap = _controller.value.isInitialized
          ? _controller.value.position
          : latestPos;
      if (justBeforeSwap > latestPos) {
        final compensated = justBeforeSwap + const Duration(milliseconds: 200);
        await newController.seekTo(compensated);
        latestPos = compensated;
      }
      if (wasPlaying) await newController.play();

      setState(() {
        _controller = newController;
        _totalDuration = newController.value.duration;
      });
      try {
        old.removeListener(_videoListener);
      } catch (_) {}
      _controller.addListener(_videoListener);
      await old.dispose();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengganti kualitas: $e',
            style: GoogleFonts.poppins(),
          ),
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
    if (_offlineMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengaturan kualitas tidak tersedia dalam mode offline',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.pinkAccent,
        ),
      );
      return;
    }
    QualitySelectorSheet.show(
      context,
      qualities: _qualityOptions,
      selectedQuality: _selectedQuality,
      isLocked: (q) {
        final sc = SettingsController.instance;
        final hasServerPaid = (sc.settings?.paidQualities.isNotEmpty == true);
        final isPaid = hasServerPaid ? sc.isQualityPaid(q) : requiresVip(q);
        return isPaid && (widget.isVip != true);
      },
      onSelect: (q) async {
        await _onQualitySelected(q);
      },
      isScrollControlled: true,
    );
  }

  void _showSpeedSelector() {
    SpeedSelectorSheet.show(
      context,
      selectedSpeed: _playbackSpeed,
      onSelect: (speed) {
        setState(() {
          _playbackSpeed = speed;
          _controller.setPlaybackSpeed(speed);
        });
      },
    );
  }

  void _showFitSelector() {
    FitSelectorSheet.show(
      context,
      selectedFit: _videoFit,
      options: _fitModes,
      onSelect: (fit) {
        setState(() {
          _videoFit = fit;
        });
      },
    );
  }

  // Duration formatting centralized in video_player/utils.dart -> formatDurationHMS()

  @override
  void dispose() {
    _hideTimer?.cancel();
    _leftHintTimer?.cancel();
    _rightHintTimer?.cancel();
    _lockHideTimer?.cancel();
    _subChat?.cancel();
    _subPresenceJoin?.cancel();
    _subPresenceLeave?.cancel();
    _subParticipants?.cancel();
    _chatController.dispose();
    _chatFocus.dispose();
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
        resizeToAvoidBottomInset: false,
        body: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: _onSurfaceTap,
          onDoubleTapDown: _onDoubleTapDown,
          onLongPressStart: _onLongPressStart,
          onLongPressEnd: _onLongPressEnd,
          onHorizontalDragStart: (details) {
            if (!widget.watchParty) return;
            _dragStart = details.globalPosition;
          },
          onHorizontalDragUpdate: (details) {
            if (!widget.watchParty) return;
            // no-op; we'll decide at end based on total delta
          },
          onHorizontalDragEnd: (details) {
            if (!widget.watchParty) return;
            final start = _dragStart;
            _dragStart = null;
            if (start == null) return;
            final vx = details.velocity.pixelsPerSecond.dx;
            // Fast swipe left from right half opens chat
            final size = MediaQuery.of(context).size;
            final startedOnRightHalf = start.dx > size.width * 0.5;
            if (startedOnRightHalf && vx < -400) {
              setState(() => _chatOpen = true);
              _showControlsAndScheduleHide();
              // focus input when opened via swipe
              Future.microtask(() => _chatFocus.requestFocus());
            }
          },
          child: Stack(
            children: [
              // Video Player
              Center(
                child: _controller.value.isInitialized
                    ? FittedBox(
                        fit: _videoFit,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _controller.value.size.width,
                          height: _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      )
                    : const ColoredBox(color: Colors.black),
              ),

              // Watermark (top-right, plain text)
              Positioned(
                right: 16,
                top: 12,
                child: IgnorePointer(
                  ignoring: true,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
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
                          TextSpan(
                            text: 'Nanime',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'ID',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Double-tap / right-boost visual feedback overlays
              if (!(_tutorialEnabled && _showTutorial))
                SeekHintsOverlay(
                  showLeftHint: _showLeftHint,
                  showRightHint: _showRightHint,
                  showRightBoost: _showRightBoost,
                ),

              // Tutorial overlay (visual only) and dismiss button
              if ((_tutorialEnabled && _showTutorial) && !widget.watchParty) ...[
                // Semi-transparent visual overlay that doesn't block taps
                IgnorePointer(
                  ignoring: true,
                  child: Positioned.fill(
                    child: Container(color: Colors.black.withOpacity(0.25)),
                  ),
                ),
                TutorialDismissButton(
                  onPressed: () {
                    _onAnyTap();
                    _dismissTutorial();
                  },
                ),
              ],

              // Guided spotlight tutorial overlay
              if ((_tutorialEnabled && _showTutorial) && !widget.watchParty)
                SpotlightOverlay(
                  targetRect:
                      _currentHighlightRect() ?? _centerFallbackRect(context),
                  overlayColor: Colors.black.withOpacity(0.60),
                  radius: 12,
                  onTap: () {
                    setState(() {
                      if (_tutorialStep < 10) {
                        _tutorialStep++;
                      } else {
                        _dismissTutorial();
                      }
                    });
                  },
                  sampleIcon: _currentHighlightRect() != null
                      ? _currentSampleIcon()
                      : null,
                  sampleIconTopLeft: _currentHighlightRect() != null
                      ? Offset(
                          _sampleIconLeft(context),
                          _sampleIconTop(context),
                        )
                      : null,
                  description: _currentHighlightRect() != null
                      ? _currentStepText()
                      : null,
                  descriptionTopLeft: _currentHighlightRect() != null
                      ? Offset(
                          _descriptionLeft(context),
                          _descriptionTop(context),
                        )
                      : null,
                  descriptionMaxWidth: MediaQuery.of(context).size.width * 0.6,
                ),

              // UI Controls (hidden when locked)
              IgnorePointer(
                ignoring: (widget.watchParty ? false : (_tutorialEnabled && _showTutorial)) || !_showControls || _controlsLocked,
                child: AnimatedOpacity(
                  opacity: (widget.watchParty ? false : (_tutorialEnabled && _showTutorial)) ? 0.0 : (_controlsLocked ? 0.0 : (_showControls ? 1.0 : 0.0)),
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
                        FullscreenTopBar(
                          videoTitle: widget.videoTitle,
                          onBack: _exitFullscreen,
                          backKey: _keyBack,
                        ),

                        const Spacer(),

                        // Center Controls
                        FullscreenCenterControls(
                          isPlaying: _isPlaying,
                          isBuffering: _isBuffering,
                          onPlayPause: _togglePlayPause,
                          onSeekBackward: () {
                            _onAnyTap();
                            _seekBackward();
                          },
                          onSeekForward: () {
                            _onAnyTap();
                            _seekForward();
                          },
                          playKey: _keyPlay,
                          backwardKey: _keyBackward,
                          forwardKey: _keyForward,
                        ),

                        const Spacer(),

                        // Bottom Bar
                        if (_controller.value.isInitialized)
                          FullscreenBottomBar(
                            position: _currentPosition,
                            duration: _totalDuration,
                            selectedQuality: _selectedQuality,
                            onSeek: _onSeek,
                            onShowQuality: _showQualitySelector,
                            onShowSpeed: _showSpeedSelector,
                            onShowFit: _showFitSelector,
                            onExit: _exitFullscreen,
                            onAnyTap: _onAnyTap,
                            sliderKey: _keySlider,
                            qualityKey: _keyQuality,
                            speedKey: _keySpeed,
                            fitKey: _keyFit,
                            exitKey: _keyExit,
                            showChatButton: widget.watchParty,
                            isChatOpen: _chatOpen,
                            onToggleChat: () {
                              setState(() => _chatOpen = !_chatOpen);
                              _showControlsAndScheduleHide();
                              if (_chatOpen) {
                                Future.microtask(() => _chatFocus.requestFocus());
                              }
                            },
                            showSkipIntro: _totalDuration.inSeconds > _introSkip.inSeconds && _currentPosition < _introSkip,
                            onSkipIntro: () {
                              _onAnyTap();
                              _skipIntroManually();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Live Chat Panel (right side)
              if (widget.watchParty)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  right: _chatOpen ? 0 : -320,
                  top: 0,
                  bottom: 0,
                  width: 320,
                  child: Material(
                    color: Colors.black.withOpacity(0.85),
                    elevation: 4,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: AnimatedPadding(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          color: Colors.pinkAccent,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _peopleCount > 0 ? 'Live Chat · $_peopleCount online' : 'Live Chat',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => setState(() => _chatOpen = false),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _chatMessages.length,
                            itemBuilder: (ctx, i) {
                              final m = _chatMessages[i];
                              final user = m['user'] is Map ? Map<String, dynamic>.from(m['user']) : null;
                              final name = (user?['fullName'] ?? user?['full_name'] ?? user?['username'] ?? 'User').toString();
                              final message = (m['message'] ?? '').toString();
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
                                    const SizedBox(height: 2),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      child: Text(
                                        message,
                                        style: GoogleFonts.poppins(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  focusNode: _chatFocus,
                                  style: GoogleFonts.poppins(color: Colors.white),
                                  cursorColor: Colors.pinkAccent,
                                  decoration: InputDecoration(
                                    hintText: 'Ketik pesan...',
                                    hintStyle: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                                    filled: true,
                                    fillColor: Colors.white10,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onTap: () {
                                    // prevent parent controls auto-hide while typing
                                    _showControlsAndScheduleHide();
                                  },
                                  onSubmitted: (_) => _sendChatMessage(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: _sendChatMessage,
                                child: Text('Kirim', style: GoogleFonts.poppins()),
                              ),
                            ],
                          ),
                        ),
                        ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Lock Button placed at the very top of the Stack (highest z-order)
              if ((_controlsLocked && _showLockButton) || (!_controlsLocked && _showControls))
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _toggleLock,
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Icon(
                            _controlsLocked ? Icons.lock : Icons.lock_open,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAnyTap() {
    if (_showTutorial) return;
    setState(() => _showControls = true);
    _scheduleAutoHide();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_showTutorial) return;
    final size = MediaQuery.of(context).size;
    final dx = details.localPosition.dx;
    // Right side: forward + speed 2x
    if (dx >= size.width / 2) {
      _seekForward();
      _triggerRightHint();
    } else {
      // Left side: backward
      _seekBackward();
      _triggerLeftHint();
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (_showTutorial) return;
    // Only boost if pressing on the right half
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final width = box.size.width;
    if (local.dx >= width / 2) {
      _prevSpeedBeforeBoost = _controller.value.playbackSpeed;
      _controller.setPlaybackSpeed(2.0);
      setState(() {
        _rightBoostActive = true;
        _showRightBoost = true;
        _playbackSpeed = 2.0;
      });
    }
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_rightBoostActive) return;
    _controller.setPlaybackSpeed(_prevSpeedBeforeBoost);
    setState(() {
      _rightBoostActive = false;
      _showRightBoost = false;
      _playbackSpeed = _prevSpeedBeforeBoost;
    });
  }

  void _triggerLeftHint() {
    _leftHintTimer?.cancel();
    setState(() => _showLeftHint = true);
    _leftHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _showLeftHint = false);
    });
  }

  void _triggerRightHint() {
    _rightHintTimer?.cancel();
    setState(() => _showRightHint = true);
    _rightHintTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _showRightHint = false);
    });
  }

  void _showControlsAndScheduleHide() {
    if (_showTutorial) return;
    setState(() => _showControls = true);
    _scheduleAutoHide();
  }

  void _scheduleAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _showControls = false);
    });
  }

  void _sendChatMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    try {
      final s = widget.socket;
      if (s == null || !s.isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat mengirim pesan sekarang',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.pinkAccent,
          ),
        );
        return;
      }
      s.sendChat(text);
      setState(() {
        _chatController.clear();
      });
      _showControlsAndScheduleHide();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengirim pesan: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.pinkAccent,
        ),
      );
    }
  }

  // ===== Guided tutorial helpers =====
  Rect? _getRectFromKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return Rect.fromLTWH(offset.dx, offset.dy, box.size.width, box.size.height);
  }

  Rect? _currentHighlightRect() {
    switch (_tutorialStep) {
      case 0:
        return _getRectFromKey(_keyPlay);
      case 1:
        return _getRectFromKey(_keySlider);
      case 2:
        return _getRectFromKey(_keyQuality);
      case 3:
        return _getRectFromKey(_keyBack);
      case 4:
        return _getRectFromKey(_keyExit);
      case 5:
        return _getRectFromKey(_keyBackward);
      case 6:
        return _getRectFromKey(_keyForward);
      case 7:
        return _getRectFromKey(_keySpeed);
      case 8:
        return _getRectFromKey(_keyFit);
      case 9:
        return _leftHalfRect();
      case 10:
        return _rightHalfRect();
    }
    return null;
  }

  Rect _centerFallbackRect(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const w = 200.0;
    const h = 120.0;
    return Rect.fromCenter(
      center: size.center(Offset.zero),
      width: w,
      height: h,
    );
  }

  String _currentStepText() {
    switch (_tutorialStep) {
      case 0:
        return 'Putar/Jeda video di sini';
      case 1:
        return 'Geser untuk berpindah waktu';
      case 2:
        return 'Pilih kualitas video';
      case 3:
        return 'Kembali/keluar fullscreen';
      case 4:
        return 'Keluar dari mode fullscreen';
      case 5:
        return 'Mundur 10 detik';
      case 6:
        return 'Maju 10 detik';
      case 7:
        return 'Atur kecepatan pemutaran';
      case 8:
        return 'Atur mode tampilan video (fit)';
      case 9:
        return 'Double tap kiri: mundur 10 detik';
      case 10:
        return 'Double tap kanan: maju 10 detik';
      default:
        return '';
    }
  }

  double _descriptionLeft(BuildContext context) {
    final rect = _currentHighlightRect();
    final screenW = MediaQuery.of(context).size.width;
    if (rect == null) return (screenW - 240) / 2;
    final desired = rect.center.dx - 120; // center bubble width ~240
    return desired.clamp(12.0, screenW - 12.0 - 240.0);
  }

  double _descriptionTop(BuildContext context) {
    final rect = _currentHighlightRect();
    final screenH = MediaQuery.of(context).size.height;
    if (rect == null) return (screenH - 60) / 2;
    const bubbleH = 60.0;
    final below = rect.bottom + 12.0;
    if (below + bubbleH <= screenH - 12) return below;
    // place above if not enough space below
    final above = rect.top - 12.0 - bubbleH;
    return above.clamp(12.0, screenH - 12.0 - bubbleH);
  }

  // Sample icon helpers (to visualize target when controls are hidden)
  double _sampleIconLeft(BuildContext context) {
    final rect = _currentHighlightRect();
    if (rect == null) return 0;
    final sz = _currentSampleIconSize();
    return rect.center.dx - sz / 2;
  }

  double _sampleIconTop(BuildContext context) {
    final rect = _currentHighlightRect();
    if (rect == null) return 0;
    final sz = _currentSampleIconSize();
    return rect.center.dy - sz / 2;
  }

  double _currentSampleIconSize() {
    switch (_tutorialStep) {
      case 0:
        return 56;
      case 1:
        return 14;
      case 5:
        return 40;
      case 6:
        return 40;
      case 7:
        return 28;
      case 8:
        return 28;
      case 9:
        return 40;
      case 10:
        return 40;
      default:
        return 28;
    }
  }

  Widget _currentSampleIcon() {
    final color = Colors.white;
    switch (_tutorialStep) {
      case 0:
        return Icon(
          Icons.play_circle_filled,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 1:
        return Icon(Icons.circle, color: color, size: _currentSampleIconSize());
      case 2:
        return Icon(Icons.hd, color: color, size: _currentSampleIconSize());
      case 3:
        return Icon(
          Icons.arrow_back,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 4:
        return Icon(
          Icons.fullscreen_exit,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 5:
        return Icon(
          Icons.replay_10,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 6:
        return Icon(
          Icons.forward_10,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 7:
        return Icon(Icons.speed, color: color, size: _currentSampleIconSize());
      case 8:
        return Icon(
          Icons.aspect_ratio,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 9:
        return Icon(
          Icons.replay_10,
          color: color,
          size: _currentSampleIconSize(),
        );
      case 10:
        return Icon(
          Icons.forward_10,
          color: color,
          size: _currentSampleIconSize(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Rect _leftHalfRect() {
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  Rect _rightHalfRect() {
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height);
  }
}
