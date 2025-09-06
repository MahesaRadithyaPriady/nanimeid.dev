import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef QualityTapCallback = Future<void> Function(String quality);

class QualitySelectorSheet {
  static void show(
    BuildContext context, {
    required List<String> qualities,
    required String selectedQuality,
    required bool Function(String quality) isLocked,
    required QualityTapCallback onSelect,
    bool isScrollControlled = false,
  }) {
    if (!isScrollControlled) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.grey.shade900,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _SheetContent(
          qualities: qualities,
          selectedQuality: selectedQuality,
          isLocked: isLocked,
          onSelect: onSelect,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.6,
          minChildSize: 0.3,
          initialChildSize: 0.4,
          builder: (context, scrollController) {
            return _SheetContent(
              qualities: qualities,
              selectedQuality: selectedQuality,
              isLocked: isLocked,
              onSelect: onSelect,
              scrollController: scrollController,
            );
          },
        );
      },
    );
  }
}

class _SheetContent extends StatelessWidget {
  final List<String> qualities;
  final String selectedQuality;
  final bool Function(String) isLocked;
  final QualityTapCallback onSelect;
  final ScrollController? scrollController;

  const _SheetContent({
    required this.qualities,
    required this.selectedQuality,
    required this.isLocked,
    required this.onSelect,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final list = ListView.builder(
      controller: scrollController,
      itemCount: qualities.length,
      itemBuilder: (context, index) {
        final quality = qualities[index];
        final locked = isLocked(quality);
        return ListTile(
          leading: Icon(
            selectedQuality == quality && !locked
                ? Icons.check_circle
                : locked
                    ? Icons.lock
                    : Icons.radio_button_unchecked,
            color: locked
                ? Colors.grey
                : selectedQuality == quality
                    ? Colors.pinkAccent
                    : Colors.white70,
          ),
          title: Text(
            quality,
            style: GoogleFonts.poppins(
              color: locked ? Colors.grey : Colors.white,
            ),
          ),
          onTap: locked
              ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Upgrade ke VIP untuk menonton dalam $quality',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.pinkAccent,
                    ),
                  );
                }
              : () async {
                  Navigator.pop(context);
                  await onSelect(quality);
                },
        );
      },
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Quality',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: list),
          ],
        ),
      ),
    );
  }
}
