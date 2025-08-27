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
    _voucherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(_isMaster ? 'Tier ${widget.tier} (Gift Admin)' : 'Beli ${widget.tier}', style: GoogleFonts.poppins(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _accent.withOpacity(0.6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.workspace_premium, color: _accent),
                      const SizedBox(width: 8),
                      Text(widget.tier.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const Spacer(),
                      if (_isMaster)
                        Text('Gift Admin', style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600))
                      else
                        Text(_formatRupiah(_payable), style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  if (_isMaster) ...[
                    const SizedBox(height: 12),
                    Text('Tier ini eksklusif dan hanya bisa diberikan oleh Admin (Gift). Hubungi Admin untuk mendapatkannya.',
                        style: GoogleFonts.poppins(color: Colors.white70)),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text('Pilih durasi:', style: GoogleFonts.poppins(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final d in ['30 Hari', '90 Hari', '1 Tahun'])
                          ChoiceChip(
                            label: Text(d, style: GoogleFonts.poppins(color: Colors.white)),
                            selectedColor: _accent.withOpacity(0.35),
                            backgroundColor: const Color(0xFF1A1A1A),
                            shape: StadiumBorder(side: BorderSide(color: _accent.withOpacity(0.7))),
                            selected: _duration == d,
                            onSelected: (_) => setState(() => _duration = d),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Voucher:', style: GoogleFonts.poppins(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherCtrl,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Masukkan kode voucher (contoh: VIP10)',
                              hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
                              filled: true,
                              fillColor: const Color(0xFF1A1A1A),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: _accent),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _applyVoucher,
                          child: Text('Pakai', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (_discountPercent > 0) ...[
                      const SizedBox(height: 8),
                      Text('-$_discountPercent% diterapkan • Total: ${_formatRupiah(_payable)}', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                    ],
                    const SizedBox(height: 16),
                    Text('Metode Pembayaran:', style: GoogleFonts.poppins(color: Colors.white70)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final m in ['DANA', 'OVO', 'GoPay', 'ShopeePay', 'Transfer Bank', 'Kartu Kredit'])
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(m, style: GoogleFonts.poppins(color: Colors.white)),
                                selected: _paymentMethod == m,
                                onSelected: (_) => setState(() => _paymentMethod = m),
                                selectedColor: _accent.withOpacity(0.35),
                                backgroundColor: const Color(0xFF1A1A1A),
                                shape: StadiumBorder(side: BorderSide(color: _accent.withOpacity(0.7))),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMaster ? Colors.white10 : _accent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _processing || _isMaster ? null : _buy,
                child: _processing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        _isMaster ? 'Hanya Gift Admin' : 'Bayar ${_formatRupiah(_payable)}',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
