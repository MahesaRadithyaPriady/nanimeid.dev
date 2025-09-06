import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SpeedSelectorSheet {
  static Future<void> show(
    BuildContext context, {
    required double selectedSpeed,
    required void Function(double speed) onSelect,
    List<double> speeds = const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
    bool isScrollControlled = true,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: isScrollControlled,
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
                        trailing: selectedSpeed == speed
                            ? const Icon(Icons.check, color: Colors.pinkAccent)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(speed);
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
}
