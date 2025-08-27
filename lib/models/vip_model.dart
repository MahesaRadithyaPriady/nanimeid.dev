class VipModel {
  final int id;
  final int userId;
  final String vipLevel;
  final DateTime? startAt;
  final DateTime? endAt;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime? lastPaymentAt;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  VipModel({
    required this.id,
    required this.userId,
    required this.vipLevel,
    this.startAt,
    this.endAt,
    required this.autoRenew,
    this.paymentMethod,
    this.lastPaymentAt,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory VipModel.fromJson(Map<String, dynamic> json) {
    return VipModel(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      vipLevel: (json['vip_level'] ?? '').toString(),
      startAt: _parseDate(json['start_at']),
      endAt: _parseDate(json['end_at']),
      autoRenew: _asBool(json['auto_renew']),
      paymentMethod: json['payment_method']?.toString(),
      lastPaymentAt: _parseDate(json['last_payment_at']),
      status: (json['status'] ?? '').toString(),
      notes: json['notes']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vip_level': vipLevel,
        'start_at': _formatDate(startAt),
        'end_at': _formatDate(endAt),
        'auto_renew': autoRenew,
        'payment_method': paymentMethod,
        'last_payment_at': _formatDate(lastPaymentAt),
        'status': status,
        'notes': notes,
        'createdAt': _formatDate(createdAt),
        'updatedAt': _formatDate(updatedAt),
      };

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _asBool(dynamic v) {
    if (v is bool) return v;
    if (v == null) return false;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  static String? _formatDate(DateTime? d) => d?.toIso8601String();
}

class VipResponseModel {
  final String message;
  final int status;
  final VipModel? vip;

  VipResponseModel({
    required this.message,
    required this.status,
    required this.vip,
  });

  factory VipResponseModel.fromJson(Map<String, dynamic> json) {
    return VipResponseModel(
      message: (json['message'] ?? '').toString(),
      status: VipModel._asInt(json['status']),
      vip: json['vip'] is Map<String, dynamic>
          ? VipModel.fromJson(json['vip'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isActive => status == 200 && vip != null;

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
        'vip': vip?.toJson(),
      };
}
