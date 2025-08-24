class AnimeModel {
  final int id;
  final String namaAnime;
  final String gambarAnime;
  final List<String> tagsAnime;
  final String ratingAnime;
  final String viewAnime;
  final String tanggalRilisAnime;
  final String statusAnime;
  final List<String> genreAnime;
  final String sinopsisAnime;
  final String labelAnime;
  final List<String> studioAnime;
  final List<String> faktaMenarik;

  AnimeModel({
    required this.id,
    required this.namaAnime,
    required this.gambarAnime,
    required this.tagsAnime,
    required this.ratingAnime,
    required this.viewAnime,
    required this.tanggalRilisAnime,
    required this.statusAnime,
    required this.genreAnime,
    required this.sinopsisAnime,
    required this.labelAnime,
    required this.studioAnime,
    required this.faktaMenarik,
  });

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    try {
      return AnimeModel(
        id: json['id'] ?? 0,
        namaAnime: json['nama_anime'] ?? '',
        gambarAnime: json['gambar_anime'] ?? '',
        tagsAnime: _parseStringList(json['tags_anime']),
        ratingAnime: json['rating_anime'] ?? '0.0',
        viewAnime: json['view_anime'] ?? '0',
        tanggalRilisAnime: json['tanggal_rilis_anime'] ?? '',
        statusAnime: json['status_anime'] ?? '',
        genreAnime: _parseStringList(json['genre_anime']),
        sinopsisAnime: json['sinopsis_anime'] ?? '',
        labelAnime: json['label_anime'] ?? '',
        studioAnime: _parseStringList(json['studio_anime']),
        faktaMenarik: _parseStringList(json['fakta_menarik']),
      );
    } catch (e) {
      print('Error parsing AnimeModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Helper method to parse string list safely
  static List<String> _parseStringList(dynamic data) {
    try {
      if (data == null) return [];

      if (data is List) {
        return data.map((item) => item?.toString() ?? '').toList();
      }

      if (data is String) {
        // Handle comma-separated string
        if (data.isEmpty) return [];
        return data
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }

      // If it's any other type, try to convert to string first
      return [data.toString()];
    } catch (e) {
      print('Error parsing string list: $e, data: $data');
      return [];
    }
  }

  // Convert to Map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_anime': namaAnime,
      'gambar_anime': gambarAnime,
      'tags_anime': tagsAnime,
      'rating_anime': ratingAnime,
      'view_anime': viewAnime,
      'tanggal_rilis_anime': tanggalRilisAnime,
      'status_anime': statusAnime,
      'genre_anime': genreAnime,
      'sinopsis_anime': sinopsisAnime,
      'label_anime': labelAnime,
      'studio_anime': studioAnime,
      'fakta_menarik': faktaMenarik,

      // Backward compatibility fields
      'title': namaAnime,
      'image': gambarAnime,
      'synopsis': sinopsisAnime,
      'rating': ratingAnime,
      'views': viewAnime,
      'releaseDate': tanggalRilisAnime,
      'status': statusAnime,
      'genre': genreAnime.join(', '),
      'tags': tagsAnime,
      'label': labelAnime,
      'studio': studioAnime,
      'faktaMenarik': faktaMenarik,
    };
  }

  // Get formatted rating as double
  double get ratingAsDouble {
    try {
      return double.parse(ratingAnime);
    } catch (e) {
      return 0.0;
    }
  }

  // Get formatted views
  String get formattedViews {
    if (viewAnime.contains('M') || viewAnime.contains('K')) {
      return viewAnime;
    }

    try {
      int viewCount = int.parse(viewAnime);
      if (viewCount >= 1000000) {
        return '${(viewCount / 1000000).toStringAsFixed(1)}M';
      } else if (viewCount >= 1000) {
        return '${(viewCount / 1000).toStringAsFixed(1)}K';
      } else {
        return viewCount.toString();
      }
    } catch (e) {
      return viewAnime;
    }
  }

  // Get first two genres for display
  List<String> get displayGenres {
    if (genreAnime.length <= 2) return genreAnime;
    return genreAnime.take(2).toList();
  }

  // Check if anime is ongoing
  bool get isOngoing {
    return statusAnime.toLowerCase() == 'ongoing';
  }

  // Check if anime is completed
  bool get isCompleted {
    return statusAnime.toLowerCase() == 'completed';
  }

  // Check if anime is upcoming
  bool get isUpcoming {
    return statusAnime.toLowerCase() == 'upcoming';
  }
}

class AnimeResponseModel {
  final int status;
  final String message;
  final List<AnimeModel> data;
  final String dateFormat;
  final Map<String, String> availableFormats;

  AnimeResponseModel({
    required this.status,
    required this.message,
    required this.data,
    required this.dateFormat,
    required this.availableFormats,
  });

  factory AnimeResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      return AnimeResponseModel(
        status: json['status'] ?? 0,
        message: json['message'] ?? '',
        data:
            (json['data'] as List<dynamic>?)
                ?.map((item) => AnimeModel.fromJson(item))
                .toList() ??
            [],
        dateFormat: json['dateFormat'] ?? 'default',
        availableFormats: Map<String, String>.from(
          json['availableFormats'] ?? {},
        ),
      );
    } catch (e) {
      print('Error parsing AnimeResponseModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isSuccess => status == 200;
  bool get hasData => data.isNotEmpty;
}
