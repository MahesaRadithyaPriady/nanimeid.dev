import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/profile_model.dart';

class WatchPartyChatPane extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController chatScrollCtrl;
  final bool autoScrollChat;
  final VoidCallback onToggleAutoScroll;
  final VoidCallback onScrollToBottom;
  final Map<int, Map<String, dynamic>> userDir;
  final ProfileModel? me;

  const WatchPartyChatPane({
    super.key,
    required this.messages,
    required this.chatScrollCtrl,
    required this.autoScrollChat,
    required this.onToggleAutoScroll,
    required this.onScrollToBottom,
    required this.userDir,
    required this.me,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.pinkAccent),
                const SizedBox(width: 8),
                Text('Chat', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  tooltip: kReleaseMode ? null : (autoScrollChat ? 'Auto-scroll aktif (klik untuk matikan)' : 'Auto-scroll mati (klik untuk aktifkan)'),
                  icon: Icon(Icons.arrow_downward, color: autoScrollChat ? Colors.pinkAccent : Colors.white38),
                  onPressed: onToggleAutoScroll,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  controller: chatScrollCtrl,
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final Map<String, dynamic>? userMap =
                        m['user'] is Map ? Map<String, dynamic>.from(m['user']) : null;
                    final int userId = () {
                      int extractId(dynamic v) {
                        if (v == null) return 0;
                        if (v is int) return v;
                        return int.tryParse(v.toString()) ?? 0;
                      }
                      final raw1 = m['userId'];
                      final raw2 = m['user_id'];
                      final id1 = extractId(raw1);
                      if (id1 != 0) return id1;
                      final id2 = extractId(raw2);
                      if (id2 != 0) return id2;
                      if (m['user'] is Map) {
                        return extractId((m['user'] as Map)['id']);
                      }
                      return 0;
                    }();

                    String displayName = '';
                    if (userMap != null) {
                      displayName = (userMap['username'] ??
                              userMap['full_name'] ??
                              userMap['fullName'] ??
                              userMap['name'] ??
                              userMap['displayName'] ??
                              '')
                          .toString();
                    } else if (userDir.containsKey(userId)) {
                      displayName = (userDir[userId]!['username'] ?? '').toString();
                    }
                    if (displayName.isEmpty) {
                      if (me != null && me!.userId == userId) {
                        displayName = me!.fullName;
                      } else if (userId != 0) {
                        displayName = 'User #$userId';
                      } else {
                        displayName = 'User';
                      }
                    }

                    String? avatarUrl;
                    if (userMap != null) {
                      avatarUrl = (userMap['avatar_url'] ??
                              userMap['avatarUrl'] ??
                              userMap['avatar'] ??
                              userMap['photo_url'])
                          ?.toString();
                    } else if (userDir.containsKey(userId)) {
                      avatarUrl = userDir[userId]!['avatar_url']?.toString();
                    }
                    if ((avatarUrl == null || avatarUrl.isEmpty) && me != null && me!.userId == userId) {
                      avatarUrl = me!.avatarUrl;
                    }

                    final msg = (m['message'] ?? '').toString();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          avatarUrl != null && avatarUrl.isNotEmpty
                              ? CircleAvatar(
                                  radius: 14,
                                  backgroundImage: NetworkImage(avatarUrl),
                                  backgroundColor: Colors.transparent,
                                )
                              : CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.pinkAccent,
                                  child: Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(displayName, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(msg, style: GoogleFonts.poppins(color: Colors.white)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Builder(builder: (context) {
                    try {
                      if (!chatScrollCtrl.hasClients) return const SizedBox.shrink();
                      final pos = chatScrollCtrl.position;
                      if (!pos.hasPixels || !pos.hasViewportDimension) {
                        return const SizedBox.shrink();
                      }
                      final max = pos.maxScrollExtent;
                      final offset = pos.pixels;
                      final nearBottom = (max - offset) < 80;
                      final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                      final shouldShow = !nearBottom || keyboardOpen;
                      if (!shouldShow) return const SizedBox.shrink();
                    } catch (_) {
                      return const SizedBox.shrink();
                    }
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onScrollToBottom,
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_downward, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text('Baru', style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
