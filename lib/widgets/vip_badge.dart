import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VipBadge extends StatefulWidget {
  final String level; // e.g., bronze, silver, gold, diamond, master
  const VipBadge({super.key, required this.level});

  @override
  State<VipBadge> createState() => _VipBadgeState();
}

class _VipBadgeState extends State<VipBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _vipAccent(String level) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return const Color(0xFF9C27B0);
      case 'master':
        return Colors.redAccent;
      default:
        return Colors.white12;
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.level;
    if (level.isEmpty) return const SizedBox.shrink();
    final l = level.toLowerCase();
    final label = 'VIP ${level[0].toUpperCase()}${level.substring(1)}';

    if (l == 'diamond') {
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final angle = _ctrl.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF9C27B0),
                  Color(0xFFE040FB),
                  Color(0xFF7E57C2),
                  Color(0xFF9C27B0),
                ],
                transform: GradientRotation(angle),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }

    if (l == 'master') {
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final angle = _ctrl.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFE53935),
                  Color(0xFFFF7043),
                  Color(0xFFD81B60),
                  Color(0xFFE53935),
                ],
                transform: GradientRotation(angle),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.35),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }

    final color = _vipAccent(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color is MaterialColor ? color.shade200 : color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
