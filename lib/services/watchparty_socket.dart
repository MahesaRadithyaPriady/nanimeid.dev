import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../services/api_service.dart';
import '../utils/secure_storage.dart';

class WatchPartySocket {
  IO.Socket? _socket;
  bool _logEnabled = true; // default on for easier debugging

  void setLogging(bool enabled) {
    _logEnabled = enabled;
  }

  void _log(String label, [Object? payload]) {
    if (!_logEnabled) return;
    if (payload != null) {
      debugPrint('[WS] $label -> ${payload.toString()}');
    } else {
      debugPrint('[WS] $label');
    }
  }

  // Streams for consumers
  final _roomJoinedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _presenceJoinCtrl =
      StreamController<Map<String, dynamic>>.broadcast(); // user
  final _presenceLeaveCtrl =
      StreamController<Map<String, dynamic>>.broadcast(); // user
  final _participantsResultCtrl =
      StreamController<
        Map<String, dynamic>
      >.broadcast(); // { participants, host }
  final _chatNewCtrl =
      StreamController<
        Map<String, dynamic>
      >.broadcast(); // { id, user, message, createdAt }
  final _playerSyncCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  final _readyUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _readyStateCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _bufferUpdatedCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _bufferStateCtrl = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onRoomJoined =>
      _roomJoinedCtrl.stream; // { session, recentMessages }
  Stream<Map<String, dynamic>> get onPresenceJoin =>
      _presenceJoinCtrl.stream; // user
  Stream<Map<String, dynamic>> get onPresenceLeave =>
      _presenceLeaveCtrl.stream; // user
  Stream<Map<String, dynamic>> get onParticipantsResult =>
      _participantsResultCtrl.stream; // { participants, host }
  Stream<Map<String, dynamic>> get onChatNew =>
      _chatNewCtrl.stream; // { id, user, message, createdAt }
  Stream<Map<String, dynamic>> get onPlayerSync =>
      _playerSyncCtrl.stream; // { currentTime, isPaused, by }
  Stream<String> get onError => _errorCtrl.stream; // message
  Stream<Map<String, dynamic>> get onReadyUpdated =>
      _readyUpdatedCtrl.stream; // { sessionId, totalParticipants, nonHostCount, readyCount, allNonHostReady, pendingUserIds }
  Stream<Map<String, dynamic>> get onReadyState =>
      _readyStateCtrl.stream; // same as above
  Stream<Map<String, dynamic>> get onBufferUpdated =>
      _bufferUpdatedCtrl.stream; // { userId, isReady }
  Stream<Map<String, dynamic>> get onBufferState =>
      _bufferStateCtrl.stream; // { readyUserIds: number[] }

  bool get isConnected => _socket?.connected == true;

  Future<void> connect() async {
    if (isConnected) return;

    // Derive base URL from ApiService
    String base =
        ApiService.dio.options.baseUrl; // e.g., http://192.168.1.8:3000/
    if (base.endsWith('/')) base = base.substring(0, base.length - 1);

    final token = await SecureStorage.getToken();

    final url = '$base/watchparty'; // namespace in path
    final opts = IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect() // we'll call connect() manually
        .setTimeout(8000)
        .setExtraHeaders({if (token != null) 'Authorization': 'Bearer $token'})
        .build();

    final socket = IO.io(url, opts);

    // Wire events
    socket.onConnect((_) => _log('connected', {'url': url}));
    socket.onConnecting((_) => _log('connecting', {'url': url}));
    socket.onConnectError((e) => _log('connect_error', e));
    socket.onConnectTimeout((e) => _log('connect_timeout', e));
    socket.onReconnect((_) => _log('reconnect'));
    socket.onReconnectAttempt((a) => _log('reconnect_attempt', a));
    socket.onReconnectError((e) => _log('reconnect_error', e));
    socket.onReconnectFailed((_) => _log('reconnect_failed'));
    socket.onDisconnect((why) => _log('disconnected', why));

    socket.on('room:joined', (data) {
      _log('<- room:joined', data);
      if (data is Map) _roomJoinedCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('presence:join', (data) {
      _log('<- presence:join', data);
      try {
        if (data is Map && data['user'] is Map) {
          _presenceJoinCtrl.add(Map<String, dynamic>.from(data['user']));
        }
      } catch (_) {}
    });

    socket.on('presence:leave', (data) {
      _log('<- presence:leave', data);
      try {
        if (data is Map && data['user'] is Map) {
          _presenceLeaveCtrl.add(Map<String, dynamic>.from(data['user']));
        }
      } catch (_) {}
    });

    socket.on('chat:new', (data) {
      _log('<- chat:new', data);
      if (data is Map) _chatNewCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('player:sync', (data) {
      _log('<- player:sync', data);
      if (data is Map) _playerSyncCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('room:participants:result', (data) {
      _log('<- room:participants:result', data);
      if (data is Map) _participantsResultCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('ready:updated', (data) {
      _log('<- ready:updated', data);
      if (data is Map) _readyUpdatedCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('ready:state', (data) {
      _log('<- ready:state', data);
      if (data is Map) _readyStateCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('buffer:updated', (data) {
      _log('<- buffer:updated', data);
      if (data is Map) _bufferUpdatedCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('buffer:state', (data) {
      _log('<- buffer:state', data);
      if (data is Map) _bufferStateCtrl.add(Map<String, dynamic>.from(data));
    });

    socket.on('error', (data) {
      _log('<- error', data);
      String msg;
      if (data is Map && data['message'] != null) {
        msg = data['message'].toString();
      } else {
        msg = data?.toString() ?? 'Unknown error';
      }
      _errorCtrl.add(msg);
    });

    _log('connect()', {'url': url});
    socket.connect();
    _socket = socket;
  }

  Future<void> disconnect() async {
    final s = _socket;
    if (s != null) {
      s.dispose();
    }
    _socket = null;
  }

  void joinRoom({required String code}) {
    if (!isConnected) return;
    final payload = {'code': code};
    _log('-> room:join', payload);
    _socket!.emit('room:join', payload);
  }

  void requestParticipants() {
    if (!isConnected) return;
    _log('-> room:participants', {});
    _socket!.emit('room:participants', {});
  }

  void sendChat(String message) {
    if (!isConnected) return;
    final payload = {'message': message};
    _log('-> chat:send', payload);
    _socket!.emit('chat:send', payload);
  }

  void updatePlayer({double? currentTime, bool? isPaused}) {
    if (!isConnected) return;
    final payload = <String, dynamic>{};
    if (currentTime != null) payload['currentTime'] = currentTime;
    if (isPaused != null) payload['isPaused'] = isPaused;
    if (payload.isEmpty) return;
    _log('-> player:update', payload);
    _socket!.emit('player:update', payload);
  }

  void setReady(bool isReady) {
    if (!isConnected) return;
    final payload = {'isReady': isReady};
    _log('-> ready:set', payload);
    _socket!.emit('ready:set', payload);
  }

  void setBufferReady(bool isReady) {
    if (!isConnected) return;
    final payload = {'isReady': isReady};
    _log('-> buffer:set', payload);
    _socket!.emit('buffer:set', payload);
  }

  void getReady() {
    if (!isConnected) return;
    _log('-> ready:get', {});
    _socket!.emit('ready:get', {});
  }

  void dispose() {
    disconnect();
    _roomJoinedCtrl.close();
    _presenceJoinCtrl.close();
    _presenceLeaveCtrl.close();
    _participantsResultCtrl.close();
    _chatNewCtrl.close();
    _playerSyncCtrl.close();
    _errorCtrl.close();
    _readyUpdatedCtrl.close();
    _readyStateCtrl.close();
    _bufferUpdatedCtrl.close();
    _bufferStateCtrl.close();
  }

  int? _asIntFromMap(dynamic data, String key) {
    try {
      if (data is Map && data[key] != null) {
        final v = data[key];
        if (v is int) return v;
        return int.tryParse(v.toString());
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
