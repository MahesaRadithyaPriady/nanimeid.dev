import 'anime_model.dart';

class AnimeScheduleResponseModel {
  final int status;
  final String message;
  final Map<String, List<AnimeModel>> data;
  final String dateFormat;
  final int limitPerDay;
  final Map<String, String> availableFormats;

  AnimeScheduleResponseModel({
    required this.status,
    required this.message,
    required this.data,
    required this.dateFormat,
    required this.limitPerDay,
    required this.availableFormats,
  });

  factory AnimeScheduleResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      final rawData = json['data'] as Map<String, dynamic>? ?? {};
      final Map<String, List<AnimeModel>> parsedData = {};

      for (final entry in rawData.entries) {
        final day = entry.key;
        final list = entry.value as List<dynamic>? ?? [];
        parsedData[day] = list
            .map((e) => AnimeModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return AnimeScheduleResponseModel(
        status: json['status'] ?? 0,
        message: json['message'] ?? '',
        data: parsedData,
        dateFormat: json['dateFormat']?.toString() ?? 'default',
        limitPerDay: json['limitPerDay'] is int
            ? json['limitPerDay'] as int
            : int.tryParse(json['limitPerDay']?.toString() ?? '0') ?? 0,
        availableFormats: Map<String, String>.from(
          json['availableFormats'] ?? {},
        ),
      );
    } catch (e) {
      print('Error parsing AnimeScheduleResponseModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isSuccess => status == 200;
}
