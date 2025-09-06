import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WatchPartyParticipantsPane extends StatelessWidget {
  final Set<int> participants;
  final Map<int, Map<String, dynamic>> userDir;

  const WatchPartyParticipantsPane({
    super.key,
    required this.participants,
    required this.userDir,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              const Icon(Icons.group, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              Text('People (${participants.length})',
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const Divider(height: 1, color: Colors.white10),
        Expanded(
          child: participants.isEmpty
              ? Center(
                  child: Text('Belum ada peserta lain',
                      style: GoogleFonts.poppins(color: Colors.white54)))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, i) {
                    final id = participants.elementAt(i);
                    final info = userDir[id] ?? const {};
                    final username = (info['username'] ?? 'User #$id').toString();
                    final avatarUrl = info['avatar_url']?.toString();
                    return ListTile(
                      leading: avatarUrl != null && avatarUrl.isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                avatarUrl,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => CircleAvatar(
                                  backgroundColor: Colors.pinkAccent,
                                  child: Text(
                                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.pinkAccent,
                              child: Text(
                                username.isNotEmpty ? username[0].toUpperCase() : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                      title: Text(username, style: GoogleFonts.poppins(color: Colors.white)),
                      subtitle: Text('ID: $id',
                          style:
                              GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                  itemCount: participants.length,
                ),
        ),
      ],
    );
  }
}
