import 'package:flutter/material.dart';

class SpotlightOverlay extends StatelessWidget {
  final Rect targetRect;
  final double radius;
  final Color overlayColor;
  final VoidCallback onTap;

  final Widget? sampleIcon;
  final Offset? sampleIconTopLeft;

  final String? description;
  final Offset? descriptionTopLeft;
  final double? descriptionMaxWidth;

  const SpotlightOverlay({
    super.key,
    required this.targetRect,
    required this.onTap,
    this.radius = 12,
    this.overlayColor = const Color(0x99000000),
    this.sampleIcon,
    this.sampleIconTopLeft,
    this.description,
    this.descriptionTopLeft,
    this.descriptionMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: SpotlightPainter(
                  targetRect: targetRect,
                  radius: radius,
                  overlayColor: overlayColor,
                ),
              ),
            ),
            if (sampleIcon != null && sampleIconTopLeft != null)
              Positioned(
                left: sampleIconTopLeft!.dx,
                top: sampleIconTopLeft!.dy,
                child: sampleIcon!,
              ),
            if (description != null && descriptionTopLeft != null)
              Positioned(
                left: descriptionTopLeft!.dx,
                top: descriptionTopLeft!.dy,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: descriptionMaxWidth ?? MediaQuery.of(context).size.width * 0.6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double radius;
  final Color overlayColor;

  SpotlightPainter({
    required this.targetRect,
    this.radius = 8,
    this.overlayColor = const Color(0xAA000000),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Offset.zero & size);
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(targetRect, Radius.circular(radius)));
    final diff = Path.combine(PathOperation.difference, overlayPath, holePath);
    canvas.drawPath(diff, Paint()..color = overlayColor);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.radius != radius ||
        oldDelegate.overlayColor != overlayColor;
  }
}
