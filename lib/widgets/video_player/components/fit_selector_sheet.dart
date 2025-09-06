import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FitSelectorSheet {
  static Future<void> show(
    BuildContext context, {
    required BoxFit selectedFit,
    required List<Map<String, dynamic>> options,
    required void Function(BoxFit fit) onSelect,
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
          minChildSize: 0.3,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
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
                  'Video Fit Mode',
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
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final mode = options[index];
                      final BoxFit fit = mode['fit'] as BoxFit;
                      final IconData? icon = mode['icon'] as IconData?;
                      final String label = mode['label']?.toString() ?? '';
                      return ListTile(
                        leading: icon != null
                            ? Icon(icon, color: Colors.white)
                            : const SizedBox.shrink(),
                        title: Text(
                          label,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        trailing: selectedFit == fit
                            ? const Icon(Icons.check, color: Colors.pinkAccent)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(fit);
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
