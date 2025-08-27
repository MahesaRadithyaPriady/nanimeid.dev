class EpisodeModel {
  final int id;
  final int animeId;
  final String judulEpisode;
  final int nomorEpisode;
  final String thumbnailEpisode;
  final String deskripsiEpisode;
  final int durasiEpisode;
  final String tanggalRilisEpisode;
  final List<QualityModel> qualities;
  final AnimeInfoModel anime;

  EpisodeModel({
    required this.id,
    required this.animeId,
    required this.judulEpisode,
    required this.nomorEpisode,
    required this.thumbnailEpisode,
    required this.deskripsiEpisode,
    required this.durasiEpisode,
    required this.tanggalRilisEpisode,
    required this.qualities,
    required this.anime,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> json) {
    try {
      return EpisodeModel(
        id: json['id'] ?? 0,
        animeId: json['anime_id'] ?? 0,
        judulEpisode: json['judul_episode'] ?? '',
        nomorEpisode: json['nomor_episode'] ?? 0,
        thumbnailEpisode: json['thumbnail_episode'] ?? '',
        deskripsiEpisode: json['deskripsi_episode'] ?? '',
        durasiEpisode: json['durasi_episode'] ?? 0,
        tanggalRilisEpisode: json['tanggal_rilis_episode'] ?? '',
        qualities: (json['qualities'] as List<dynamic>?)
                ?.map((item) => QualityModel.fromJson(item))
                .toList() ??
            [],
        anime: AnimeInfoModel.fromJson(json['anime'] ?? {}),
      );
    } catch (e) {
      print('Error parsing EpisodeModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  // Convert to Map for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'anime_id': animeId,
      'judul_episode': judulEpisode,
      'nomor_episode': nomorEpisode,
      'thumbnail_episode': thumbnailEpisode,
      'deskripsi_episode': deskripsiEpisode,
      'durasi_episode': durasiEpisode,
      'tanggal_rilis_episode': tanggalRilisEpisode,
      'qualities': qualities.map((q) => q.toMap()).toList(),
      'anime': anime.toMap(),

      // Backward compatibility fields
      'title': judulEpisode,
      'episode_number': nomorEpisode,
      'thumbnail': thumbnailEpisode,
      'description': deskripsiEpisode,
      'duration': durasiEpisode,
      'release_date': tanggalRilisEpisode,
    };
  }

  // Get formatted duration
  String get formattedDuration {
    final hours = durasiEpisode ~/ 60;
    final minutes = durasiEpisode % 60;
    
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Get best quality (prioritize 1080p, then 720p, then 480p)
  QualityModel? get bestQuality {
    if (qualities.isEmpty) return null;
    
    // Sort by quality preference
    final sortedQualities = List<QualityModel>.from(qualities);
    sortedQualities.sort((a, b) {
      final aPriority = _getQualityPriority(a.namaQuality);
      final bPriority = _getQualityPriority(b.namaQuality);
      return aPriority.compareTo(bPriority);
    });
    
    return sortedQualities.first;
  }

  // Get quality by name
  QualityModel? getQualityByName(String qualityName) {
    try {
      return qualities.firstWhere(
        (quality) => quality.namaQuality.toLowerCase() == qualityName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Helper method to get quality priority
  int _getQualityPriority(String quality) {
    switch (quality.toLowerCase()) {
      case '1080p':
        return 1;
      case '720p':
        return 2;
      case '480p':
        return 3;
      default:
        return 999;
    }
  }

  // Check if episode has specific quality
  bool hasQuality(String qualityName) {
    return qualities.any(
      (quality) => quality.namaQuality.toLowerCase() == qualityName.toLowerCase(),
    );
  }
}

class QualityModel {
  final int id;
  final int episodeId;
  final String namaQuality;
  final String sourceQuality;

  QualityModel({
    required this.id,
    required this.episodeId,
    required this.namaQuality,
    required this.sourceQuality,
  });

  factory QualityModel.fromJson(Map<String, dynamic> json) {
    try {
      return QualityModel(
        id: json['id'] ?? 0,
        episodeId: json['episode_id'] ?? 0,
        namaQuality: json['nama_quality'] ?? '',
        sourceQuality: json['source_quality'] ?? '',
      );
    } catch (e) {
      print('Error parsing QualityModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'episode_id': episodeId,
      'nama_quality': namaQuality,
      'source_quality': sourceQuality,
    };
  }
}

class AnimeInfoModel {
  final int id;
  final String namaAnime;
  final String gambarAnime;

  AnimeInfoModel({
    required this.id,
    required this.namaAnime,
    required this.gambarAnime,
  });

  factory AnimeInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      return AnimeInfoModel(
        id: json['id'] ?? 0,
        namaAnime: json['nama_anime'] ?? '',
        gambarAnime: json['gambar_anime'] ?? '',
      );
    } catch (e) {
      print('Error parsing AnimeInfoModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_anime': namaAnime,
      'gambar_anime': gambarAnime,
    };
  }
}

class EpisodeResponseModel {
  final int status;
  final String message;
  final List<EpisodeModel> data;

  EpisodeResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EpisodeResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      // data dari API dapat berupa List atau Map (objek tunggal)
      final dynamic rawData = json['data'];

      List<EpisodeModel> parsedData = [];
      if (rawData is List) {
        parsedData = rawData
            .map((item) => EpisodeModel.fromJson(
                  item is Map<String, dynamic> ? item : <String, dynamic>{},
                ))
            .toList();
      } else if (rawData is Map<String, dynamic>) {
        parsedData = [EpisodeModel.fromJson(rawData)];
      } else {
        parsedData = [];
      }

      return EpisodeResponseModel(
        status: json['status'] ?? 0,
        message: json['message'] ?? '',
        data: parsedData,
      );
    } catch (e) {
      print('Error parsing EpisodeResponseModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isSuccess => status == 200;
  bool get hasData => data.isNotEmpty;

  // Get episodes sorted by episode number
  List<EpisodeModel> get sortedEpisodes {
    final sorted = List<EpisodeModel>.from(data);
    sorted.sort((a, b) => a.nomorEpisode.compareTo(b.nomorEpisode));
    return sorted;
  }

  // Get episode by number
  EpisodeModel? getEpisodeByNumber(int episodeNumber) {
    try {
      return data.firstWhere((episode) => episode.nomorEpisode == episodeNumber);
    } catch (e) {
      return null;
    }
  }

  // Get total episodes count
  int get totalEpisodes => data.length;

  // Get latest episode
  EpisodeModel? get latestEpisode {
    if (data.isEmpty) return null;
    return sortedEpisodes.last;
  }

  // Get first episode
  EpisodeModel? get firstEpisode {
    if (data.isEmpty) return null;
    return sortedEpisodes.first;
  }
}
