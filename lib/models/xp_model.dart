class XpLevelModel {
  final int id;
  final int levelNumber;
  final int xpRequiredTotal;
  final String title;

  XpLevelModel({
    required this.id,
    required this.levelNumber,
    required this.xpRequiredTotal,
    required this.title,
  });

  factory XpLevelModel.fromJson(Map<String, dynamic> json) => XpLevelModel(
        id: _asInt(json['id']),
        levelNumber: _asInt(json['level_number']),
        xpRequiredTotal: _asInt(json['xp_required_total']),
        title: (json['title'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'level_number': levelNumber,
        'xp_required_total': xpRequiredTotal,
        'title': title,
      };

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class XpProgressModel {
  final int currentLevelXpRequired;
  final int? nextLevelXpRequired;
  final int xpToNext;
  final int percent; // 0..100

  XpProgressModel({
    required this.currentLevelXpRequired,
    required this.nextLevelXpRequired,
    required this.xpToNext,
    required this.percent,
  });

  factory XpProgressModel.fromJson(Map<String, dynamic> json) => XpProgressModel(
        currentLevelXpRequired: XpLevelModel._asInt(json['currentLevelXpRequired']),
        nextLevelXpRequired: json['nextLevelXpRequired'] == null
            ? null
            : XpLevelModel._asInt(json['nextLevelXpRequired']),
        xpToNext: XpLevelModel._asInt(json['xpToNext']),
        percent: XpLevelModel._asInt(json['percent']).clamp(0, 100),
      );

  Map<String, dynamic> toJson() => {
        'currentLevelXpRequired': currentLevelXpRequired,
        'nextLevelXpRequired': nextLevelXpRequired,
        'xpToNext': xpToNext,
        'percent': percent,
      };
}

class XpDataModel {
  final int userId;
  final int currentXp;
  final int levelId;
  final XpLevelModel level;
  final XpProgressModel progress;

  // Fields only present on POST /xp/add
  final int? added;
  final int? multiplier;
  final bool? isVip;

  XpDataModel({
    required this.userId,
    required this.currentXp,
    required this.levelId,
    required this.level,
    required this.progress,
    this.added,
    this.multiplier,
    this.isVip,
  });

  factory XpDataModel.fromJson(Map<String, dynamic> json) => XpDataModel(
        userId: XpLevelModel._asInt(json['user_id']),
        currentXp: XpLevelModel._asInt(json['current_xp']),
        levelId: XpLevelModel._asInt(json['level_id']),
        level: XpLevelModel.fromJson(json['level'] ?? {}),
        progress: XpProgressModel.fromJson(json['progress'] ?? {}),
        added: json.containsKey('added') ? XpLevelModel._asInt(json['added']) : null,
        multiplier: json.containsKey('multiplier') ? XpLevelModel._asInt(json['multiplier']) : null,
        isVip: json['isVip'] is bool ? json['isVip'] as bool : null,
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'current_xp': currentXp,
        'level_id': levelId,
        'level': level.toJson(),
        'progress': progress.toJson(),
        if (added != null) 'added': added,
        if (multiplier != null) 'multiplier': multiplier,
        if (isVip != null) 'isVip': isVip,
      };
}

class XpResponseModel {
  final String message;
  final int code;
  final XpDataModel? data;

  XpResponseModel({
    required this.message,
    required this.code,
    required this.data,
  });

  factory XpResponseModel.fromJson(Map<String, dynamic> json) => XpResponseModel(
        message: (json['message'] ?? '').toString(),
        code: XpLevelModel._asInt(json['code']),
        data: json['data'] is Map<String, dynamic>
            ? XpDataModel.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  bool get isSuccess => code == 200 && data != null;

  Map<String, dynamic> toJson() => {
        'message': message,
        'code': code,
        'data': data?.toJson(),
      };
}
