import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../models/watchparty_session_model.dart';
import 'package:nanimeid/services/watchparty_service.dart';
import 'package:nanimeid/services/watchparty_socket.dart';
import 'package:nanimeid/services/episode_service.dart';
import 'package:nanimeid/widgets/global_chat_input_bar.dart';
import '../../services/profile_service.dart';
import '../../models/profile_model.dart';
import '../../widgets/watchparty_banner_header.dart';
import '../../widgets/watchparty_chat_pane.dart';
import '../../widgets/watchparty_participants_pane.dart';
import '../../widgets/watchparty_options_pane.dart';
import '../../widgets/watch_video_player.dart';
import '../../models/episode_detail_model.dart';

class WatchPartyLobbyScreen extends StatefulWidget {
  final String roomCode;
  final int episodeId;
  final WatchPartySocket socket;
  final WatchPartySessionModel? session; // optional pre-fetched
  final bool useSocket; // allow forcing HTTP-only mode

  const WatchPartyLobbyScreen({
    super.key,
    required this.roomCode,
    required this.episodeId,
    required this.socket,
    this.session,
    this.useSocket = true,
  });

  @override
  State<WatchPartyLobbyScreen> createState() => _WatchPartyLobbyScreenState();
}

class _WatchPartyLobbyScreenState extends State<WatchPartyLobbyScreen> {
  bool _loading = true;
  bool _isPaused = true; // kept for future playback sync
  double _currentTime = 0.0; // kept for future playback sync
  DateTime? _lastServerUpdateAt; // last server player state timestamp
  DateTime? _lastRemoteAppliedAt; // last time we applied remote state
  List<Map<String, dynamic>> _messages = [];
  final _chatCtrl = TextEditingController();
  final ScrollController _chatScrollCtrl = ScrollController();
  bool _autoScrollChat = true;
  StreamSubscription? _chatSub;
  StreamSubscription? _playerSub;
  StreamSubscription? _presenceJoinSub;
  StreamSubscription? _presenceLeaveSub;
  StreamSubscription? _participantsResultSub;
  // Hysteresis / rate limiting for HTTP polling apply
  DateTime? _lastRemoteSeekAt;
  // Cooldown to prevent HTTP polling from overriding immediate local actions
  DateTime? _lastLocalControlAt;
  StreamSubscription? _readyUpdatedSub;
  StreamSubscription? _readyStateSub;
  Timer? _pollMessagesTimer;
  Timer? _pollStatusTimer;
  int _lastMessageId = 0;
  bool _isHost = false;

  // Episode banner & meta
  EpisodeDetailModel? _episodeDetail;
  String _bannerUrl = '';
  String _episodeTitle = '';
  int _episodeNumber = 0;

  // Participants
  final Set<int> _participants = {};

  // Current user profile (for proper name/avatar resolution)
  ProfileModel? _me;

  // Directory of known users in room: userId -> { username, avatar_url? }
  final Map<int, Map<String, dynamic>> _userDir = {};

  // Local player controller (when video is showing)
  VideoPlayerController? _playerCtrl;
  bool _applyingRemote = false; // prevent echo loops when applying remote sync
  bool _playerAlive = false; // track disposal race
  // Deferred play handling when socket says play but local is buffering
  Timer? _deferredPlayTimer;
  int _deferredPlayAttempts = 0;
  double? _pendingPlayTime;

  // Readiness state
  bool _isReady = false;
  int _readyCount = 0;
  int _nonHostCount = 0;
  bool _allNonHostReady = false;
  List<int> _pendingUserIds = const [];
  bool _startedOnce = false; // gate only the first unpause/start

  // Temporarily disable sockets for this screen; focus on HTTP polling
  bool get _socketActive => false; // widget.useSocket && widget.socket.isConnected;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    // Rebuild chat pane on scroll to show/hide jump-to-bottom button
    _chatScrollCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _scheduleDeferredPlay() {
    _deferredPlayTimer?.cancel();
    _deferredPlayAttempts = 0;
    _deferredPlayTimer = Timer.periodic(const Duration(milliseconds: 300), (tm) async {
      _deferredPlayAttempts++;
      if (_isPaused) {
        tm.cancel();
        return;
      }
      final c = _playerCtrl;
      if (c == null || !_playerAlive) {
        tm.cancel();
        return;
      }
      final ready = c.value.isInitialized && !c.value.isBuffering;
      if (ready) {
        if (!c.value.isPlaying) {
          try { await c.play(); } catch (_) {}
        }
        tm.cancel();
        return;
      }
      if (_deferredPlayAttempts >= 20) { // ~6s max wait
        tm.cancel();
      }
    });
  }

  Future<void> _bootstrap() async {
    try {
      // Load my profile (for name/avatar when payload lacks user object)
      try {
        final meRes = await ProfileService.getMyProfile();
        _me = meRes.profile;
      } catch (_) {
        // ignore profile load errors; we'll fallback to generic labels
      }

      // Setup socket listeners first (only if enabled)
      if (_socketActive) {
        _chatSub = widget.socket.onChatNew.listen((event) {
          // Normalize payload to ensure user info is present
          final Map<String, dynamic> m = Map<String, dynamic>.from(event as Map);

          int extractId(dynamic v) {
            if (v == null) return 0;
            if (v is int) return v;
            return int.tryParse(v.toString()) ?? 0;
          }

          int userId = extractId(m['userId']);
          if (userId == 0) userId = extractId(m['user_id']);
          if (userId == 0 && m['user'] is Map) {
            userId = extractId((m['user'] as Map)['id']);
            m['userId'] = userId;
          }

          // If still missing, use local profile for own message
          if (userId == 0 && _me != null) {
            userId = _me!.userId;
            m['userId'] = userId;
          }
          if ((m['user'] is! Map) && _me != null && _me!.userId == userId) {
            m['user'] = {
              'username': _me!.fullName,
              'full_name': _me!.fullName,
              'fullName': _me!.fullName,
              'avatar_url': _me!.avatarUrl,
              'avatarUrl': _me!.avatarUrl,
            }..removeWhere((k, v) => v == null);
          }

          setState(() {
            _messages.add(m);
          });

          // Auto-scroll to bottom when a new message arrives
          if (_autoScrollChat) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
          }
        });
        // Readiness events
        _readyUpdatedSub = widget.socket.onReadyUpdated.listen((payload) {
          try {
            _applyReadinessPayload(payload);
          } catch (_) {}
        });
        _readyStateSub = widget.socket.onReadyState.listen((payload) {
          try {
            _applyReadinessPayload(payload);
          } catch (_) {}
        });
        _playerSub = widget.socket.onPlayerSync.listen((payload) async {
          final hasTime = payload.containsKey('currentTime') && payload['currentTime'] != null;
          final t = hasTime ? (double.tryParse('${payload['currentTime']}') ?? _currentTime) : _currentTime;
          final p = payload['isPaused'] == true;
          if (!p) _startedOnce = true;

          // Ignore echoes from self to prevent double-application
          int byId = 0;
          final byRaw = payload['by'];
          if (byRaw != null) {
            byId = int.tryParse(byRaw.toString()) ?? 0;
          }
          final myId = _me?.userId;
          if (myId != null && myId != 0 && byId != 0 && byId == myId) {
            return; // event originated from self; no-op
          }

          _applyingRemote = true;
          try {
            setState(() {
              if (hasTime) _currentTime = t;
              _isPaused = p;
            });
            // Apply to local controller if available
            final c = _playerCtrl;
            if (c != null && _playerAlive) {
              try {
                if (hasTime) {
                  final target = Duration(milliseconds: (t * 1000).round());
                  // Avoid excessive seeks if already close (<300ms)
                  final diff = (c.value.position - target).inMilliseconds.abs();
                  if (diff > 300) {
                    await c.seekTo(target);
                  }
                }
                if (p) {
                  // Pause requested
                  _deferredPlayTimer?.cancel();
                  _deferredPlayAttempts = 0;
                  if (c.value.isPlaying) {
                    await c.pause();
                  }
                } else {
                  // Play requested: if buffering or not ready, defer until ready
                  final isReadyToPlay = c.value.isInitialized && !c.value.isBuffering;
                  if (!isReadyToPlay) {
                    // remember target time to sync upon ready
                    _pendingPlayTime = hasTime ? t : _currentTime;
                    _scheduleDeferredPlay();
                  } else if (!c.value.isPlaying) {
                    // ensure we are at target before play
                    final target = Duration(milliseconds: ((hasTime ? t : _currentTime) * 1000).round());
                    final diff = (c.value.position - target).inMilliseconds.abs();
                    if (diff > 300) {
                      try { await c.seekTo(target); } catch (_) {}
                    }
                    await c.play();
                  }
                }
              } catch (_) {/* controller might have been disposed during rebuild */}
            }
          } finally {
            _applyingRemote = false;
          }
        });
        _presenceJoinSub = widget.socket.onPresenceJoin.listen((user) {
          try {
            final u = Map<String, dynamic>.from(user as Map);
            final id = int.tryParse(u['id']?.toString() ?? '');
            if (id != null) {
              setState(() {
                _participants.add(id);
                final name = (u['username'] ?? u['fullName'] ?? u['full_name'] ?? u['name'])?.toString();
                final avatar = (u['avatarUrl'] ?? u['avatar_url'] ?? u['avatar'] ?? u['photo_url'])?.toString();
                final existing = _userDir[id] ?? const {};
                _userDir[id] = {
                  ...existing,
                  if (name != null && name.isNotEmpty) 'username': name,
                  if (avatar != null && avatar.isNotEmpty) 'avatar_url': avatar,
                };
                // debug log
                // ignore: avoid_print
                print('[Lobby] presence:join user=$id name=${name ?? '-'} avatar=${avatar?.isNotEmpty == true}');
              });
            }
          } catch (_) {}
        });
        _presenceLeaveSub = widget.socket.onPresenceLeave.listen((user) {
          try {
            final u = Map<String, dynamic>.from(user as Map);
            final id = int.tryParse(u['id']?.toString() ?? '');
            if (id != null) setState(() => _participants.remove(id));
          } catch (_) {}
        });

        // Request participants via socket and listen for result
        _participantsResultSub = widget.socket.onParticipantsResult.listen((payload) {
          try {
            final p = Map<String, dynamic>.from(payload as Map);
            final list = p['participants'];
            final host = p['host'];
            setState(() {
              // participants array
              if (list is List) {
                for (final item in list) {
                  if (item is Map) {
                    final id = int.tryParse(item['userId']?.toString() ?? '');
                    final name = (item['username'] ?? item['fullName'] ?? item['full_name'])?.toString();
                    final avatar = (item['avatarUrl'] ?? item['avatar_url'] ?? item['avatar'] ?? item['photo_url'])?.toString();
                    if (id != null) {
                      _participants.add(id);
                      final existing = _userDir[id] ?? const {};
                      _userDir[id] = {
                        ...existing,
                        if (name != null && name.isNotEmpty) 'username': name,
                        if (avatar != null && avatar.isNotEmpty) 'avatar_url': avatar,
                      };
                      // debug log
                      // ignore: avoid_print
                      print('[Lobby] participants:result user=$id name=${name ?? '-'} avatar=${avatar?.isNotEmpty == true}');
                    }
                  }
                }
              }
              // host object (may include richer fields)
              if (host is Map) {
                final hid = int.tryParse(host['userId']?.toString() ?? '');
                final hname = (host['username'] ?? host['fullName'] ?? host['full_name'])?.toString();
                final havatar = (host['avatarUrl'] ?? host['avatar_url'] ?? host['avatar'] ?? host['photo_url'])?.toString();
                if (hid != null) {
                  _participants.add(hid);
                  final existing = _userDir[hid] ?? const {};
                  _userDir[hid] = {
                    ...existing,
                    if (hname != null && hname.isNotEmpty) 'username': hname,
                    if (havatar != null && havatar.isNotEmpty) 'avatar_url': havatar,
                  };
                  // debug log
                  // ignore: avoid_print
                  print('[Lobby] participants:result host=$hid name=${hname ?? '-'} avatar=${havatar?.isNotEmpty == true}');
                }
              }
            });
          } catch (_) {}
        });

        // Ensure socket connected and joined AFTER listeners are ready
        try {
          if (!widget.socket.isConnected) {
            await widget.socket.connect();
          }
          widget.socket.joinRoom(code: widget.roomCode);
        } catch (_) {}
      }

      // Try to get initial state via socket 'room:joined' first
      bool loadedFromSocket = false;
      try {
        if (_socketActive) {
          final joined = await widget.socket.onRoomJoined.first
              .timeout(const Duration(seconds: 2));
          if (joined is Map) {
            // messages from socket payload
            final recent = joined['recentMessages'];
            if (recent is List) {
              _messages = recent
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
              _lastMessageId = _calcLastMessageId();
            }
            // participants (if provided)
            final sess = joined['session'];
            if (sess is Map && sess['participants'] is List) {
              final list = sess['participants'] as List;
              for (final p in list) {
                try {
                  int? id;
                  String? username;
                  String? avatarUrl;
                  if (p is Map && p['userId'] != null) {
                    id = int.tryParse(p['userId'].toString());
                  }
                  if (p is Map && p['user'] is Map) {
                    final u = Map<String, dynamic>.from(p['user']);
                    id ??= int.tryParse(u['id']?.toString() ?? '');
                    username = (u['username'] ?? u['full_name'] ?? u['name'])?.toString();
                    avatarUrl = (u['avatar_url'] ?? u['avatarUrl'] ?? u['avatar'] ?? u['photo_url'])?.toString();
                  }
                  if (id != null) {
                    _participants.add(id);
                    final existing = _userDir[id] ?? const {};
                    _userDir[id] = {
                      ...existing,
                      if (username != null && username.isNotEmpty) 'username': username,
                      if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
                    };
                    // debug log
                    // ignore: avoid_print
                    print('[Lobby] room:joined participant user=$id name=${username ?? '-'} avatar=${avatarUrl?.isNotEmpty == true}');
                  }
                } catch (_) {}
              }
            }
            // detect host id from session
            if (sess is Map) {
              final hid = int.tryParse('${sess['host_user_id'] ?? sess['hostUserId'] ?? 0}');
              if (hid != null && _me != null) {
                _isHost = (hid == _me!.userId);
              }
            }
            loadedFromSocket = true;
          }
        }
      } catch (_) {
        // ignore timeout/error -> will fallback to HTTP
      }

      // Ask server for participants list (align with docs)
      if (_socketActive) {
        widget.socket.requestParticipants();
      } else {
        _startPolling();
      }

      // Fallback to HTTP for messages if socket did not provide them
      if (!loadedFromSocket) {
        final res = await WatchPartyService.getRecentMessages(
          code: widget.roomCode,
          take: 30,
        );
        final data = res.data;
        if (data is List) {
          _messages = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _lastMessageId = _calcLastMessageId();
        } else if (data is Map && data['data'] is List) {
          _messages = List<Map<String, dynamic>>.from(
            (data['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
          );
          _lastMessageId = _calcLastMessageId();
        }
      }

      // Build user directory via HTTP session detail as fallback
      try {
        final detail = await WatchPartyService.getSessionDetailTyped(widget.roomCode);
        for (final part in detail.participants) {
          final id = part.userId;
          final name = part.user?.fullName ?? part.user?.username;
          final avatar = part.user?.avatarUrl;
          if (id != 0) {
            _participants.add(id);
            final existing = _userDir[id] ?? const {};
            _userDir[id] = {
              ...existing,
              if (name != null && name.isNotEmpty) 'username': name,
              if (avatar != null && avatar.isNotEmpty) 'avatar_url': avatar,
            };
            // debug log
            // ignore: avoid_print
            print('[Lobby] http:fallback participant user=$id name=${name ?? '-'} avatar=${avatar?.isNotEmpty == true}');
          }
        }
        // determine host from HTTP detail
        if (_me != null) {
          _isHost = (detail.hostUserId == _me!.userId);
        }
      } catch (_) {
        // ignore directory build failure
      }

      // Initial readiness fetch (HTTP if socket not used yet)
      await _refreshReadiness();

      // Load episode meta for banner (HTTP fallback is fine here)
      final detail = await EpisodeService.getEpisodeDetail(widget.episodeId);
      if (!mounted) return;
      setState(() {
        _episodeDetail = detail;
        _bannerUrl = detail.thumbnailEpisode;
        _episodeTitle = detail.judulEpisode;
        _episodeNumber = detail.nomorEpisode;
        _loading = false;
      });
      // After initial load, scroll chat to bottom if enabled
      if (_autoScrollChat) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
      }

      // Start HTTP polling fallbacks
      _startPolling();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat lobby: $e', style: GoogleFonts.poppins())),
      );
      setState(() => _loading = false);
    }
  }

  void _startPolling() {
    _pollMessagesTimer?.cancel();
    _pollStatusTimer?.cancel();
    _pollMessagesTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollMessages());
    // Consolidated status (player + readiness) — faster to reduce start delay
    _pollStatusTimer = Timer.periodic(const Duration(seconds: 1), (_) => _pollStatus());
  }

  int _calcLastMessageId() {
    int last = _lastMessageId;
    for (final m in _messages) {
      final id = int.tryParse('${m['id'] ?? m['messageId'] ?? 0}') ?? 0;
      if (id > last) last = id;
    }
    return last;
  }

  Future<void> _pollMessages() async {
    // Poll only if socket is not connected
    if (_socketActive) return;
    try {
      final res = await WatchPartyService.pollMessagesSince(
        code: widget.roomCode,
        sinceId: _lastMessageId,
        limit: 50,
      );
      final data = res.data;
      List<Map<String, dynamic>> list = const [];
      int? lastIdFromServer;
      if (data is Map) {
        if (data['items'] is List) {
          list = (data['items'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
          final lid = data['lastId'];
          if (lid != null) {
            lastIdFromServer = int.tryParse('$lid');
          }
        } else if (data['data'] is List) {
          list = (data['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } else if (data is List) {
        list = data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }

      if (list.isNotEmpty) {
        setState(() {
          _messages.addAll(list);
          if (lastIdFromServer != null && lastIdFromServer! > _lastMessageId) {
            _lastMessageId = lastIdFromServer!;
          } else {
            _lastMessageId = _calcLastMessageId();
          }
        });
        if (_autoScrollChat) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
        }
      }
    } catch (_) {}
  }

  void _applyReadinessPayload(Map<String, dynamic> p) {
    try {
      final readyCount = int.tryParse('${p['readyCount'] ?? 0}') ?? 0;
      final nonHostCount = int.tryParse('${p['nonHostCount'] ?? 0}') ?? 0;
      final allReady = p['allNonHostReady'] == true;
      final pending = (p['pendingUserIds'] is List)
          ? (p['pendingUserIds'] as List).map((e) => int.tryParse('$e') ?? 0).where((e) => e != 0).toList()
          : const <int>[];
      setState(() {
        _readyCount = readyCount;
        _nonHostCount = nonHostCount;
        _allNonHostReady = allReady;
        _pendingUserIds = pending;
      });
    } catch (_) {}
  }

  Future<void> _refreshReadiness() async {
    try {
      if (_socketActive) {
        widget.socket.getReady();
        return;
      }
      final res = await WatchPartyService.getReadiness(widget.roomCode);
      final data = res.data;
      if (data is Map) {
        _applyReadinessPayload(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
  }

  Future<void> _setReady(bool value) async {
    setState(() => _isReady = value);
    try {
      if (_socketActive) {
        widget.socket.setReady(value);
      } else {
        await WatchPartyService.setReady(code: widget.roomCode, isReady: value);
      }
      await _refreshReadiness();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal set siap: $e', style: GoogleFonts.poppins())),
      );
    }
  }

  Future<void> _pollStatus() async {
    // Poll only when sockets are disabled
    if (_socketActive) return;
    try {
      final res = await WatchPartyService.getStatus(widget.roomCode);
      final data = res.data;
      if (data is Map) {
        // Apply player state from session
        if (data['session'] is Map) {
          final s = Map<String, dynamic>.from(data['session']);
          final hasTime = s.containsKey('currentTime') && s['currentTime'] != null;
          final t = hasTime ? (double.tryParse('${s['currentTime']}') ?? _currentTime) : _currentTime;
          final p = s['isPaused'] == true;
          // Parse updatedAt to filter stale states
          DateTime? ts;
          final rawTs = s['updatedAt'] ?? s['updated_at'];
          if (rawTs is String) {
            ts = DateTime.tryParse(rawTs);
          }
          _lastServerUpdateAt = ts ?? _lastServerUpdateAt;
          if (!p) _startedOnce = true;
          await _applyRemotePlayer(hasTime ? t : null, p, ts);
        }
        // Apply readiness
        if (data['readiness'] is Map) {
          _applyReadinessPayload(Map<String, dynamic>.from(data['readiness']));
        }
      }
    } catch (_) {}
  }

  Future<void> _applyRemotePlayer(double? t, bool? paused, [DateTime? serverTs]) async {
    // If this is an HTTP status push and we're the host, ignore to avoid self-override
    if (serverTs != null && _isHost) return;
    // Drop stale updates
    if (serverTs != null && _lastRemoteAppliedAt != null && !serverTs.isAfter(_lastRemoteAppliedAt!)) {
      return;
    }
    _applyingRemote = true;
    try {
      // Capture previous paused state to detect transitions
      final wasPaused = _isPaused;
      // Update local state optimistically
      setState(() {
        if (t != null) _currentTime = t;
        if (paused != null) _isPaused = paused;
      });
      final c = _playerCtrl;
      if (c != null && _playerAlive) {
        try {
          final now = DateTime.now();
          const seekThresholdMs = 500; // tolerate small drifts
          const minSeekIntervalMs = 800; // rate-limit seeks
          final target = Duration(milliseconds: (1000 * _currentTime).round());
          if (c.value.isInitialized) {
            final diffMs = (c.value.position - target).inMilliseconds.abs();
            final canRateLimit = _lastRemoteSeekAt == null || now.difference(_lastRemoteSeekAt!).inMilliseconds > minSeekIntervalMs;
            if (t != null && diffMs > seekThresholdMs && canRateLimit) {
              await c.seekTo(target);
              _lastRemoteSeekAt = now;
            }
          }
          final isPlayingLocal = c.value.isInitialized && c.value.isPlaying;
          // Apply pause/play only if mismatch
          if (_isPaused && isPlayingLocal) {
            await c.pause();
          } else if (!_isPaused && !isPlayingLocal) {
            await c.play();
          }
          // If transitioning to playing, keep trying until buffer ready
          if (wasPaused && !_isPaused) {
            _scheduleDeferredPlay();
          }
        } catch (_) {}
      }
      if (serverTs != null) {
        _lastRemoteAppliedAt = serverTs;
      }
    } finally {
      _applyingRemote = false;
    }
  }

  @override
  void dispose() {
    _deferredPlayTimer?.cancel();
    _pollMessagesTimer?.cancel();
    _pollStatusTimer?.cancel();
    _chatSub?.cancel();
    _playerSub?.cancel();
    _presenceJoinSub?.cancel();
    _presenceLeaveSub?.cancel();
    _participantsResultSub?.cancel();
    _chatCtrl.dispose();
    _chatScrollCtrl.dispose();
    super.dispose();
  }

  void _sendChat() {
    final msg = _chatCtrl.text.trim();
    if (msg.isEmpty) return;
    if (_socketActive) {
      widget.socket.sendChat(msg);
    } else {
      // HTTP fallback
      WatchPartyService.postMessage(code: widget.roomCode, message: msg);
    }
    _chatCtrl.clear();
  }

  void _togglePlayPause() async {
    if (!_isHost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hanya host yang dapat mengontrol pemutar', style: GoogleFonts.poppins())),
      );
      return;
    }
    final c = _playerCtrl;
    final playing = (c != null && _playerAlive && c.value.isInitialized) ? c.value.isPlaying : !_isPaused;

    if (playing) {
      // STOP with confirmation
      final sure = await _confirmStop();
      if (!sure) return;
      try {
        if (c != null && _playerAlive && c.value.isInitialized) {
          try { await c.pause(); } catch (_) {}
          try { await c.seekTo(Duration.zero); } catch (_) {}
          if (mounted) setState(() {
            _isPaused = true;
            _currentTime = 0.0;
          });
        } else {
          // No local player; just update state
          _isPaused = true;
          _currentTime = 0.0;
          if (mounted) setState(() {});
        }
        _lastLocalControlAt = DateTime.now();
      } catch (_) {}
      if (_socketActive) {
        widget.socket.updatePlayer(currentTime: 0.0, isPaused: true);
      } else {
        await WatchPartyService.updatePlayerState(code: widget.roomCode, currentTime: 0.0, isPaused: true);
      }
      return;
    } else {
      // START from 0
      try {
        if (c != null && _playerAlive && c.value.isInitialized) {
          try { await c.seekTo(Duration.zero); } catch (_) {}
          try { await c.play(); } catch (_) {}
          if (mounted) setState(() => _isPaused = false);
        } else {
          // No local player; broadcast intent to start from 0
          _isPaused = false;
          _currentTime = 0.0;
          if (mounted) setState(() {});
        }
        _lastLocalControlAt = DateTime.now();
        _startedOnce = true;
      } catch (_) {}
      if (_socketActive) {
        widget.socket.updatePlayer(currentTime: 0.0, isPaused: false);
      } else {
        try {
          await WatchPartyService.updatePlayerState(code: widget.roomCode, currentTime: 0.0, isPaused: false);
        } catch (e) {
          // Show 409 readiness error if server rejects first unpause
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak bisa mulai: peserta lain belum selesai inisialisasi', style: GoogleFonts.poppins())),
          );
        }
      }
      return;
    }
  }

  Future<void> _prepareStart() async {
    // Host presses this to ensure all participants initialize their videos first
    await _refreshReadiness();
    if (!mounted) return;
    if (_allNonHostReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Semua peserta sudah menginisialisasi video. Siap untuk mulai.', style: GoogleFonts.poppins())),
      );
    } else {
      final remaining = (_nonHostCount - _readyCount).clamp(0, 999);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menunggu inisialisasi video dari $remaining peserta...', style: GoogleFonts.poppins())),
      );
    }
  }

  Future<bool> _confirmStop() async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              backgroundColor: Colors.pink,
              titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
              contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
              title: const Text('Akhiri Tontonan?'),
              content: const Text('Yakin mengakhiri? Video akan berhenti dan kembali ke awal.'),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Akhiri'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _syncToCurrent() {
    // Without player, just broadcast the current known time
    _lastLocalControlAt = DateTime.now();
    if (_socketActive) {
      widget.socket.updatePlayer(currentTime: _currentTime, isPaused: _isPaused);
    } else {
      WatchPartyService.updatePlayerState(code: widget.roomCode, currentTime: _currentTime, isPaused: _isPaused);
    }
  }

  void _toggleAutoScrollChat() {
    setState(() => _autoScrollChat = !_autoScrollChat);
    if (_autoScrollChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Lobby • ${widget.roomCode}', style: GoogleFonts.poppins(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncToCurrent,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Keep the video always mounted; overlay banner when paused
                      SizedBox(
                        width: double.infinity,
                        height: 220,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Opacity(
                              opacity: _isPaused ? 0.0 : 1.0,
                              child: WatchVideoPlayer(
                                episodeDetail: _episodeDetail,
                                watchParty: true,
                                watchPartySocket: _socketActive ? widget.socket : null,
                                watchPartyRoomCode: widget.roomCode,
                                allowControls: _isHost,
                                onControllerReady: (controller) {
                                  _playerCtrl = controller;
                                  _playerAlive = true;
                                },
                                onControllerDisposed: () {
                                  _playerCtrl = null;
                                  _playerAlive = false;
                                },
                                onPlaybackUpdate: (position, isPlaying) {
                                  // Update local state and broadcast
                                  if (_applyingRemote) return; // avoid echo
                                  _currentTime = position.inMilliseconds / 1000.0;
                                  _isPaused = !isPlaying;
                                  if (_socketActive) {
                                    widget.socket.updatePlayer(
                                      currentTime: _currentTime,
                                      isPaused: _isPaused,
                                    );
                                  } else {
                                    WatchPartyService.updatePlayerState(
                                      code: widget.roomCode,
                                      currentTime: _currentTime,
                                      isPaused: _isPaused,
                                    );
                                  }
                                },
                              ),
                            ),
                            if (_isPaused)
                              WatchPartyBannerHeader(
                                bannerUrl: _bannerUrl,
                                episodeTitle: _episodeTitle,
                                episodeNumber: _episodeNumber,
                                roomCode: widget.roomCode,
                                isPaused: _isPaused,
                                onTogglePlayPause: _togglePlayPause,
                              ),
                          ],
                        ),
                      ),
                      // Meta row below player (hide when paused since overlay shows it)
                      if (!_isPaused)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _episodeTitle.isEmpty ? 'Episode' : _episodeTitle,
                                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Kode: ${widget.roomCode} · E${_episodeNumber == 0 ? '-' : _episodeNumber}',
                                      style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: _togglePlayPause,
                                icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
                                tooltip: kReleaseMode ? null : 'Toggle Play/Pause (sinkronisasi)'
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  GlobalChatInputBar(
                    chatCtrl: _chatCtrl,
                    autoScroll: _autoScrollChat,
                    onSend: _sendChat,
                    onTap: () {
                      if (_autoScrollChat) {
                        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollChatToBottom());
                      }
                    },
                  ),
                  const TabBar(
                    tabs: [
                      Tab(text: 'Chat'),
                      Tab(text: 'People'),
                      Tab(text: 'Options'),
                    ],
                    indicatorColor: Colors.pinkAccent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        WatchPartyChatPane(
                          messages: _messages,
                          chatScrollCtrl: _chatScrollCtrl,
                          autoScrollChat: _autoScrollChat,
                          onToggleAutoScroll: _toggleAutoScrollChat,
                          onScrollToBottom: _scrollChatToBottom,
                          userDir: _userDir,
                          me: _me,
                        ),
                        WatchPartyParticipantsPane(
                          participants: _participants,
                          userDir: _userDir,
                        ),
                        WatchPartyOptionsPane(
                          isPaused: _isPaused,
                          onSyncToCurrent: _syncToCurrent,
                          onTogglePlayPause: _togglePlayPause,
                          isHost: _isHost,
                          onPrepareStart: _prepareStart,
                          readyCount: _readyCount,
                          nonHostCount: _nonHostCount,
                          allNonHostReady: _allNonHostReady,
                          onRefreshReadiness: _refreshReadiness,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _scrollChatToBottom() {
    if (!_chatScrollCtrl.hasClients) return;
    final position = _chatScrollCtrl.position.maxScrollExtent;
    _chatScrollCtrl.animateTo(
      position,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }
}
