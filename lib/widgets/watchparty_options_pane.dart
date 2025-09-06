import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

class WatchPartyOptionsPane extends StatelessWidget {
  final bool isPaused;
  final VoidCallback onSyncToCurrent;
  final VoidCallback onTogglePlayPause;
  final bool isHost;
  final VoidCallback onPrepareStart;
  // Readiness summary (initialization state of participants)
  final int readyCount;
  final int nonHostCount;
  final bool allNonHostReady;
  final VoidCallback onRefreshReadiness;

  const WatchPartyOptionsPane({
    super.key,
    required this.isPaused,
    required this.onSyncToCurrent,
    required this.onTogglePlayPause,
    required this.isHost,
    required this.onPrepareStart,
    required this.readyCount,
    required this.nonHostCount,
    required this.allNonHostReady,
    required this.onRefreshReadiness,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (isHost) ...[
          ListTile(
            leading: const Icon(Icons.play_circle_outline, color: Colors.white),
            title: Text('Mulai Nobar (Inisialisasi)', style: GoogleFonts.poppins(color: Colors.white)),
            subtitle: Text('Siapkan video semua peserta hingga siap diputar', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
            onTap: onPrepareStart,
          ),
          const Divider(color: Colors.white10),
        ],
        ListTile(
          leading: const Icon(Icons.people_alt, color: Colors.white),
          title: Text('Inisialisasi Video Peserta', style: GoogleFonts.poppins(color: Colors.white)),
          subtitle: Text(
            allNonHostReady
              ? 'Semua peserta sudah menginisialisasi video ($readyCount/$nonHostCount)'
              : 'Sudah inisialisasi: $readyCount dari $nonHostCount non-host',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: onRefreshReadiness,
            tooltip: kReleaseMode ? null : 'Perbarui status kesiapan',
          ),
        ),
        const Divider(color: Colors.white10),
        ListTile(
          leading: const Icon(Icons.sync, color: Colors.white),
          title: Text('Sinkronkan waktu & status', style: GoogleFonts.poppins(color: Colors.white)),
          subtitle: Text('Kirim posisi saat ini ke semua peserta', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
          onTap: onSyncToCurrent,
        ),
        const Divider(color: Colors.white10),
        ListTile(
          leading: Icon(isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white),
          title: Text(isPaused ? 'Broadcast Play' : 'Broadcast Pause', style: GoogleFonts.poppins(color: Colors.white)),
          subtitle: Text('Kirim status ${isPaused ? 'play' : 'pause'} ke peserta', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
          onTap: onTogglePlayPause,
        ),
      ],
    );
  }
}
