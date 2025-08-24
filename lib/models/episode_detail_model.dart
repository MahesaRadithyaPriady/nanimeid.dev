import 'episode_model.dart';
import 'anime_model.dart';

class EpisodeDetailModel {
  final int id;
  final int animeId;
  final String judulEpisode;
  final int nomorEpisode;
  final String thumbnailEpisode;
  final String deskripsiEpisode;
  final int durasiEpisode;
  final String tanggalRilisEpisode;
  final List<QualityModel> qualities;
  final AnimeModel anime;

  EpisodeDetailModel({
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

  factory EpisodeDetailModel.fromJson(Map<String, dynamic> json) {
    try {
      return EpisodeDetailModel(
        id: json['id'] ?? 0,
        animeId: json['anime_id'] ?? 0,
        judulEpisode: json['judul_episode'] ?? '',
        nomorEpisode: json['nomor_episode'] ?? 0,
        thumbnailEpisode: json['thumbnail_episode'] ?? '',
        deskripsiEpisode: json['deskripsi_episode'] ?? '',
        durasiEpisode: json['durasi_episode'] ?? 0,
        tanggalRilisEpisode: json['tanggal_rilis_episode'] ?? '',
        qualities: _parseQualities(json['qualities']),
        anime: AnimeModel.fromJson(json['anime'] ?? {}),
      );
    } catch (e) {
      print('Error parsing EpisodeDetailModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static List<QualityModel> _parseQualities(dynamic data) {
    try {
      if (data == null) return [];

      if (data is List) {
        return data
            .map((item) => QualityModel.fromJson(item))
            .where((quality) => quality.id != 0)
            .toList();
      }

      return [];
    } catch (e) {
      print('Error parsing qualities: $e, data: $data');
      return [];
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
    final hours = durasiEpisode ~/ 3600;
    final minutes = (durasiEpisode % 3600) ~/ 60;
    final seconds = durasiEpisode % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Get duration in minutes
  int get durationInMinutes {
    return durasiEpisode ~/ 60;
  }

  // Get best quality available
  QualityModel? get bestQuality {
    if (qualities.isEmpty) return null;

    // Priority: 1080p > 720p > 480p > others
    final qualityOrder = ['1080p', '720p', '480p', '360p', '240p'];

    for (final qualityName in qualityOrder) {
      final quality = qualities.firstWhere(
        (q) => q.namaQuality.toLowerCase() == qualityName.toLowerCase(),
        orElse: () => QualityModel(
          id: 0,
          episodeId: 0,
          namaQuality: '',
          sourceQuality: '',
        ),
      );
      if (quality.id != 0) return quality;
    }

    // If no preferred quality found, return the first one
    return qualities.first;
  }

  // Get quality by name
  QualityModel? getQualityByName(String qualityName) {
    try {
      return qualities.firstWhere(
        (q) => q.namaQuality.toLowerCase() == qualityName.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  // Check if episode has specific quality
  bool hasQuality(String qualityName) {
    return qualities.any(
      (q) => q.namaQuality.toLowerCase() == qualityName.toLowerCase(),
    );
  }

  // Get available quality names
  List<String> get availableQualityNames {
    return qualities.map((q) => q.namaQuality).toList();
  }

  // Get formatted release date
  String get formattedReleaseDate {
    try {
      final date = DateTime.parse(tanggalRilisEpisode);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return tanggalRilisEpisode;
    }
  }

  // Check if episode is recently released (within 7 days)
  bool get isRecentlyReleased {
    try {
      final releaseDate = DateTime.parse(tanggalRilisEpisode);
      final now = DateTime.now();
      final difference = now.difference(releaseDate).inDays;
      return difference <= 7;
    } catch (e) {
      return false;
    }
  }
}

class EpisodeDetailResponseModel {
  final int status;
  final String message;
  final EpisodeDetailModel data;

  EpisodeDetailResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EpisodeDetailResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      return EpisodeDetailResponseModel(
        status: json['status'] ?? 0,
        message: json['message'] ?? '',
        data: EpisodeDetailModel.fromJson(json['data'] ?? {}),
      );
    } catch (e) {
      print('Error parsing EpisodeDetailResponseModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isSuccess => status == 200;
  bool get hasData => data.id != 0;
}
