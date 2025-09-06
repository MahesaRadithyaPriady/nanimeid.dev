import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PurchaseVipScreen extends StatefulWidget {
  final String tier; // Bronze, Gold, Diamond
  final int basePrice; // in IDR, e.g., 5000 for Bronze
  const PurchaseVipScreen({super.key, required this.tier, required this.basePrice});

  @override
  State<PurchaseVipScreen> createState() => _PurchaseVipScreenState();
}

class _PurchaseVipScreenState extends State<PurchaseVipScreen> {
  bool _processing = false;
  String _duration = '30 Hari';
  String? _paymentMethod; // e.g., DANA, OVO, GOPAY, Bank Transfer, Kartu Kredit
  bool get _isMaster => widget.tier.toLowerCase() == 'master';
  final TextEditingController _voucherCtrl = TextEditingController();
  int _discountPercent = 0; // 0..100

  int get _multiplier {
    switch (_duration) {
      case '90 Hari':
        return 3;
      case '1 Tahun':
        return 12;
      default:
        return 1;
    }
  }

  int get _totalPrice => widget.basePrice * _multiplier;
  int get _payable => (_totalPrice * (100 - _discountPercent) / 100).round();

  void _applyVoucher() {
    final code = _voucherCtrl.text.trim().toUpperCase();
    int? percent;
    if (code.isEmpty) {
      percent = 0;
    } else if (code == 'VIP10') {
      percent = 10;
    } else if (code == 'VIP25') {
      percent = 25;
    } else if (code == 'VIP50') {
      percent = 50;
    }

    if (percent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voucher tidak valid')),
      );
      return;
    }
    setState(() => _discountPercent = percent!);
    if (_discountPercent > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voucher terpakai: $_discountPercent%')),
      );
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

  Color get _accent {
    switch (widget.tier.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return const Color(0xFF9C27B0);
      default:
        return Colors.pinkAccent;
    }
  }

  Future<void> _buy() async {
    if (_isMaster) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tier Master hanya bisa di-gift oleh Admin')),
      );
      return;
    }
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih metode pembayaran terlebih dahulu')),
      );
      return;
    }
    setState(() => _processing = true);
    await Future.delayed(const Duration(milliseconds: 900)); // mock API
    if (!mounted) return;
    setState(() => _processing = false);
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Beli VIP',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF000000), Color(0xFF0F0F0F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.hourglass_empty, color: Colors.white24, size: 56),
              const SizedBox(height: 16),
              Text(
                'Coming soon',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hubungi Admin untuk beli VIP',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Silakan hubungi Admin untuk pembelian VIP')),
                  );
                },
                icon: const Icon(Icons.support_agent),
                label: Text('Hubungi Admin', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
