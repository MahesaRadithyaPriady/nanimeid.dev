import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlobalChatInputBar extends StatelessWidget {
  final TextEditingController chatCtrl;
  final bool autoScroll;
  final VoidCallback onSend;
  final VoidCallback? onTap;

  const GlobalChatInputBar({
    super.key,
    required this.chatCtrl,
    required this.autoScroll,
    required this.onSend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: chatCtrl,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
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
              onSubmitted: (_) => onSend(),
              onTap: onTap,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onSend,
            icon: const Icon(Icons.send, color: Colors.pinkAccent),
          ),
        ],
      ),
    );
  }
}
