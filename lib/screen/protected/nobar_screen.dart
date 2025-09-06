import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/watchparty_service.dart';
import '../../services/watchparty_socket.dart';
import '../../models/watchparty_session_model.dart';
import 'watchparty_lobby_screen.dart';

class NobarScreen extends StatefulWidget {
  const NobarScreen({super.key});

  @override
  State<NobarScreen> createState() => _NobarScreenState();
}

class _NobarScreenState extends State<NobarScreen> {
  final _joinCodeCtrl = TextEditingController();
  final _episodeIdCtrl = TextEditingController();
  final _socket = WatchPartySocket();

  bool _creating = false;
  bool _joining = false;
  bool _loadingRooms = false;
  List<WatchPartySessionModel> _rooms = const [];
  bool _useSocket = false; // paksa HTTP (socket dimatikan karena stabilitas)

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _joinCodeCtrl.dispose();
    _episodeIdCtrl.dispose();
    _socket.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() => _loadingRooms = true);
    try {
      final res = await WatchPartyService.listSessions(page: 1, limit: 20);
      final data = res.data;
      List<dynamic> rawList = const [];
      if (data is Map<String, dynamic>) {
        final raw = data['items'] ?? data['data'];
        if (raw is List) rawList = raw;
      } else if (data is List) {
        rawList = data;
      }
      final parsed = rawList
          .whereType<Map>()
          .map((e) => WatchPartySessionModel.fromJson(e.cast<String, dynamic>()))
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _rooms = parsed);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat room: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingRooms = false);
    }
  }

  Future<void> _createRoom() async {
    final episodeIdStr = _episodeIdCtrl.text.trim();
    final episodeId = int.tryParse(episodeIdStr);
    if (episodeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan Episode ID yang valid')),
      );
      return;
    }
    setState(() => _creating = true);
    try {
      final res = await WatchPartyService.createSession(
        hostUserId: 1, // TODO: replace with real current user id
        episodeId: episodeId,
      );
      final data = res.data as Map<String, dynamic>;
      final code = data['code']?.toString() ?? '';
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text('Room Dibuat', style: GoogleFonts.poppins(color: Colors.white)),
          content: Text('Kode: $code', style: GoogleFonts.poppins(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: Colors.pinkAccent)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat room: $e')),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _joinCodeCtrl.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode room')), 
      );
      return;
    }
    setState(() => _joining = true);
    try {
      await WatchPartyService.joinSession(code: code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil bergabung ke room')), 
      );
      await _navigateToLobby(code);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal bergabung: $e')),
      );
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _navigateToLobby(String code) async {
    try {
      // Fetch typed session detail to obtain episodeId
      final detail = await WatchPartyService.getSessionDetailTyped(code);
      final int episodeId = detail.episodeId;
      if (!mounted) return;
      if (episodeId == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Episode ID tidak ditemukan untuk room ini')),
        );
        return;
      }
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => WatchPartyLobbyScreen(
            roomCode: code,
            episodeId: episodeId,
            socket: _socket,
            session: null,
            useSocket: false, // paksa HTTP-only pada lobby
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka lobby: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Nobar', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transport Settings
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings_ethernet, color: Colors.lightBlueAccent),
                      const SizedBox(width: 8),
                      Text('Pengaturan Transport', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Pilih cara sinkronisasi Nobar:', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text('Socket (Realtime) · Dinonaktifkan', style: GoogleFonts.poppins(color: Colors.white38)),
                        selected: false,
                        selectedColor: Colors.pinkAccent,
                        backgroundColor: const Color(0xFF1A1A1A),
                        onSelected: (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Mode socket sementara dimatikan karena masalah stabilitas', style: GoogleFonts.poppins())),
                          );
                        },
                      ),
                      ChoiceChip(
                        label: Text('HTTP (Polling)', style: GoogleFonts.poppins(color: !_useSocket ? Colors.white : Colors.white70)),
                        selected: !_useSocket,
                        selectedColor: Colors.pinkAccent,
                        backgroundColor: const Color(0xFF1A1A1A),
                        onSelected: (v) {
                          if (!v) return;
                          setState(() => _useSocket = false);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Mode HTTP polling aktif. Socket dimatikan sementara karena stabilitas.',
                      style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
            // Create Room Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, color: Colors.pinkAccent),
                      const SizedBox(width: 8),
                      Text('Buat Room', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Mulai nobar dengan membuat room baru.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _episodeIdCtrl,
                    keyboardType: TextInputType.number,
                    cursorColor: Colors.pinkAccent,
                    style: GoogleFonts.poppins(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Episode ID',
                      hintStyle: GoogleFonts.poppins(color: Colors.white38),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.pinkAccent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _creating ? null : _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _creating
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Buat Room'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Join Room Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.meeting_room, color: Colors.amber),
                      const SizedBox(width: 8),
                      Text('Gabung Room', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Masukkan kode room untuk bergabung.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _joinCodeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          cursorColor: Colors.pinkAccent,
                          style: GoogleFonts.poppins(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Kode Room (contoh: AB2CDE)',
                            hintStyle: GoogleFonts.poppins(color: Colors.white38),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.white10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Colors.pinkAccent),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _joining ? null : _joinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.pinkAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _joining
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Gabung'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Popular rooms (from API)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Room Populer', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_loadingRooms)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: CircularProgressIndicator(color: Colors.pinkAccent),
                      ),
                    )
                  else if (_rooms.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text('Belum ada room aktif', style: GoogleFonts.poppins(color: Colors.white54)),
                    )
                  else
                    ListView.separated(
                      itemCount: _rooms.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                      itemBuilder: (context, i) {
                        final item = _rooms[i];
                        final code = item.code;
                        final viewers = item.participants.toString();
                        final title = item.episode.judulEpisode.isEmpty ? 'Episode' : item.episode.judulEpisode;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          leading: CircleAvatar(
                            backgroundColor: Colors.pinkAccent,
                            child: Text(
                              item.episode.nomorEpisode == 0 ? 'E' : item.episode.nomorEpisode.toString(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            title,
                            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Host: ${(item.host.username?.isNotEmpty ?? false) ? item.host.username! : '-'} · ${viewers} orang · Kode: $code',
                            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: ElevatedButton(
                            onPressed: _joining
                                ? null
                                : () {
                                    _joinCodeCtrl.text = code;
                                    _joinRoom();
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pinkAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            ),
                            child: const Text('Join'),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
