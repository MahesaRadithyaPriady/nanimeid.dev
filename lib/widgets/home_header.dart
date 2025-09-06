import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/store_service.dart';
import '../services/vip_service.dart';
import '../screen/protected/user_search_screen.dart';

class HomeHeader extends StatefulWidget {
  // Optional initial values (if parent still passes them). Component will fetch fresh data itself.
  final int? coinBalance;
  final bool? isVip;

  const HomeHeader({super.key, this.coinBalance, this.isVip});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader>
    with SingleTickerProviderStateMixin {
  int _coinBalance = 0;
  bool _isVip = false;
  String _vipLevel = '';
  bool _loading = true;
  late final AnimationController _badgeCtrl;

  @override
  void initState() {
    super.initState();
    // Use any provided initial values immediately
    _coinBalance = widget.coinBalance ?? 0;
    _isVip = widget.isVip ?? false;
    _badgeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _fetchData();
  }

  Color _vipAccent() {
    switch (_vipLevel.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return const Color(0xFF9C27B0);
      case 'master':
        return Colors.pinkAccent;
      default:
        return Colors.grey; // for FREE or unknown
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      // Await separately to preserve concrete types and avoid List<Object?> from Future.wait
      final wallet = await StoreService.getWallet();
      final vip = await VipService.getMyVip();
      if (!mounted) return;
      setState(() {
        _coinBalance = wallet.balanceCoins;
        _isVip = vip.isActive;
        _vipLevel = (vip.vip?.vipLevel ?? '').toString();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black, // Hitam elegan
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // User search button (replaces coin)
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserSearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_search,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cari User',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Title

          // VIP Badge styled to match profile_screen.dart (RGB for diamond/master)
          (_vipLevel.toLowerCase() == 'diamond')
              ? AnimatedBuilder(
                  animation: _badgeCtrl,
                  builder: (context, _) {
                    final angle = _badgeCtrl.value * 2 * math.pi;
                    return Container(
                      padding: const EdgeInsets.all(1.5),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: Color(0xFF9C27B0),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _loading
                                  ? '...'
                                  : (_isVip ? _vipLevel.toUpperCase() : 'FREE'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : (_vipLevel.toLowerCase() == 'master')
              ? AnimatedBuilder(
                  animation: _badgeCtrl,
                  builder: (context, _) {
                    final angle = _badgeCtrl.value * 2 * math.pi;
                    final glow = 10 + 6 * (0.5 + 0.5 * math.sin(angle));
                    return Container(
                      padding: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: SweepGradient(
                          colors: const [
                            Color(0xFFE53935), // red
                            Color(0xFFFF7043), // deep orange
                            Color(0xFFD81B60), // pink
                            Color(0xFFE53935),
                          ],
                          transform: GradientRotation(angle),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.35),
                            blurRadius: glow,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF121212),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _loading
                                  ? '...'
                                  : (_isVip ? _vipLevel.toUpperCase() : 'FREE'),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _vipAccent().withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: _vipAccent(),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _loading
                            ? '...'
                            : (_isVip ? _vipLevel.toUpperCase() : 'FREE'),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _badgeCtrl.dispose();
    super.dispose();
  }
}
