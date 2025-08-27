import 'anime_model.dart';

class LiveSearchResponseModel {
  final int status;
  final String message;
  final List<AnimeModel> data;
  final Map<String, dynamic> searchOptions;
  final Map<String, String> availableFormats;

  LiveSearchResponseModel({
    required this.status,
    required this.message,
    required this.data,
    required this.searchOptions,
    required this.availableFormats,
  });

  factory LiveSearchResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> list = json['data'] ?? [];
    return LiveSearchResponseModel(
      status: json['status'] ?? 0,
      message: json['message'] ?? '',
      data: list.map((e) => AnimeModel.fromJson(e as Map<String, dynamic>)).toList(),
      searchOptions: Map<String, dynamic>.from(json['searchOptions'] ?? {}),
      availableFormats: Map<String, String>.from(
        (json['availableFormats'] ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())),
      ),
    );
  }
}
