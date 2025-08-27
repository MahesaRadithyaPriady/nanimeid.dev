import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './purchase_vip_screen.dart';

class MembershipInfoScreen extends StatefulWidget {
  const MembershipInfoScreen({super.key});

  @override
  State<MembershipInfoScreen> createState() => _MembershipInfoScreenState();
}

class _MembershipInfoScreenState extends State<MembershipInfoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _diamondCtrl;

  @override
  void initState() {
    super.initState();
    _diamondCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  int _tierPrice(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return 5000;
      case 'gold':
        return 15000;
      case 'diamond':
        return 25000;
      default:
        return 0;
    }
  }

  String _formatRupiah(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final indexFromEnd = s.length - i;
      buf.write(s[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) buf.write('.');
    }
    return 'Rp ${buf.toString()}';
  }

  @override
  void dispose() {
    _diamondCtrl.dispose();
    super.dispose();
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return const Color(0xFF9C27B0);
      default:
        return Colors.white24;
    }
  }

  List<Widget> _benefits(String tier, Color color) {
    // Benefits per request:
    // Bronze: Unlock 1080p & 2K, Unlock VIP Badge, Tidak dibatasi saat Diskusi
    // Gold: Bronze + Server Khusus
    // Diamond: Sisanya (tambahan) -> Akses Fitur Beta lebih awal, Sign untuk dapat Koin
    final bronze = [
      'Unlock 1080p dan 2K',
      'Unlock VIP Badge',
      'Tidak dibatasi dalam Diskusi',
    ];
    final gold = [
      ...bronze,
      'Level bertambah 2x lebih cepat',
      'Server Khusus',
    ];
    final diamond = [
      ...gold,
      'Akses Fitur Beta lebih awal',
      'Sign untuk dapat Koin',
    ];

    final items = switch (tier.toLowerCase()) {
      'bronze' => bronze,
      'gold' => gold,
      'diamond' => diamond,
      _ => bronze,
    };

    return items
        .map((e) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(e,
                      style: GoogleFonts.poppins(color: Colors.white70, height: 1.25)),
                ),
              ],
            ))
        .toList();
  }

  Widget _tierCard(BuildContext context, String tier, String desc) {
    final color = _tierColor(tier);
    final price = _tierPrice(tier);
    Widget inner() => Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.workspace_premium, color: color),
                  const SizedBox(width: 8),
                  Text(
                    tier.toUpperCase(),
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text('Mulai dari', style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(_formatRupiah(price), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Text(desc, style: GoogleFonts.poppins(color: Colors.white70)),
              const SizedBox(height: 12),
              ..._benefits(tier, color),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => PurchaseVipScreen(tier: tier, basePrice: price)),
                    );
                    if (result == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pembelian $tier berhasil', style: GoogleFonts.poppins())),
                      );
                    }
                  },
                  child: Text('Beli $tier', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );

    if (tier.toLowerCase() == 'diamond') {
      return AnimatedBuilder(
        animation: _diamondCtrl,
        builder: (context, _) {
          final angle = _diamondCtrl.value * 2 * math.pi;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF9C27B0), // purple
                  Color(0xFFE040FB), // purple accent
                  Color(0xFF7E57C2), // deep purple
                  Color(0xFF9C27B0),
                ],
                transform: GradientRotation(angle),
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: inner(),
            ),
          );
        },
      );
    }

    return inner();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('VIP / Membership', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pilih Paket', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _tierCard(context, 'Bronze', 'Paket hemat untuk mulai menikmati fitur VIP.'),
            const SizedBox(height: 12),
            _tierCard(context, 'Gold', 'Paket populer dengan benefit lebih lengkap.'),
            const SizedBox(height: 12),
            _tierCard(context, 'Diamond', 'Paket premium dengan prioritas dan kemewahan penuh.'),
          ],
        ),
      ),
    );
  }
}
