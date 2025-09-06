class WalletModel {
  final int id;
  final int userId;
  final int balanceCoins;
  final DateTime updatedAt;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balanceCoins,
    required this.updatedAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    // Handle possible string/int types gracefully
    int parseInt(dynamic v) => (v is int)
        ? v
        : int.tryParse(v?.toString() ?? '') ?? 0;

    DateTime parseDate(dynamic v) {
      if (v is DateTime) return v;
      final s = v?.toString();
      if (s == null || s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
      try {
        return DateTime.parse(s);
      } catch (_) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
    }

    return WalletModel(
      id: parseInt(json['id']),
      userId: parseInt(json['user_id']),
      balanceCoins: parseInt(json['balance_coins']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}
