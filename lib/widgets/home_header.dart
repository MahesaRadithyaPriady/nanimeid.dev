import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HomeHeader extends StatelessWidget {
  final int coinBalance;
  final bool isVip;

  const HomeHeader({super.key, required this.coinBalance, required this.isVip});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Warna background hitam
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Koin
          Row(
            children: [
              Icon(LucideIcons.coins, color: Colors.yellow[700]),
              const SizedBox(width: 6),
              Text(
                '$coinBalance',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          // Judul Tengah
          Text(
            'NanimeID',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.2,
            ),
          ),
          // Status VIP
          Icon(Icons.diamond, color: isVip ? Colors.pinkAccent : Colors.grey),
        ],
      ),
    );
  }
}
