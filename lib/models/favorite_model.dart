class FavoriteAnimeModel {
  final int id;
  final String namaAnime;
  final String gambarAnime;
  final String ratingAnime;
  final String statusAnime;
  final String sinopsisAnime;
  final List<String> genreAnime;

  FavoriteAnimeModel({
    required this.id,
    required this.namaAnime,
    required this.gambarAnime,
    required this.ratingAnime,
    required this.statusAnime,
    required this.sinopsisAnime,
    required this.genreAnime,
  });

  factory FavoriteAnimeModel.fromJson(Map<String, dynamic> json) {
    return FavoriteAnimeModel(
      id: _asInt(json['id']),
      namaAnime: (json['nama_anime'] ?? '').toString(),
      gambarAnime: (json['gambar_anime'] ?? '').toString(),
      ratingAnime: (json['rating_anime'] ?? '').toString(),
      statusAnime: (json['status_anime'] ?? '').toString(),
      sinopsisAnime: (json['sinopsis_anime'] ?? '').toString(),
      genreAnime: (json['genre_anime'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_anime': namaAnime,
        'gambar_anime': gambarAnime,
        'rating_anime': ratingAnime,
        'status_anime': statusAnime,
        'sinopsis_anime': sinopsisAnime,
        'genre_anime': genreAnime,
      };

  // Convert to Map for UI compatibility (keys used by DetailAnimeScreen)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama_anime': namaAnime,
      'gambar_anime': gambarAnime,
      'rating_anime': ratingAnime,
      'status_anime': statusAnime,
      'sinopsis_anime': sinopsisAnime,
      'genre_anime': genreAnime,

      // Backward-compatible keys expected by some screens
      'title': namaAnime,
      'image': gambarAnime,
      'synopsis': sinopsisAnime,
      'rating': ratingAnime,
      // Views and releaseDate are not present in FavoriteAnimeModel; provide safe defaults
      'views': '0',
      'releaseDate': '',
      'status': statusAnime,
      'genre': genreAnime.join(', '),
    };
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class FavoriteItemModel {
  final int id;
  final int userId;
  final int animeId;
  final DateTime? createdAt;
  final FavoriteAnimeModel anime;

  FavoriteItemModel({
    required this.id,
    required this.userId,
    required this.animeId,
    required this.createdAt,
    required this.anime,
  });

  factory FavoriteItemModel.fromJson(Map<String, dynamic> json) {
    return FavoriteItemModel(
      id: FavoriteAnimeModel._asInt(json['id']),
      userId: FavoriteAnimeModel._asInt(json['user_id']),
      animeId: FavoriteAnimeModel._asInt(json['anime_id']),
      createdAt: _parseDate(json['createdAt']),
      anime: FavoriteAnimeModel.fromJson(
        (json['anime'] as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'anime_id': animeId,
        'createdAt': createdAt?.toIso8601String(),
        'anime': anime.toJson(),
      };

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }
}

class FavoriteResponseModel {
  final String message;
  final int status;
  final List<FavoriteItemModel> items;
  final String? filterStatus;

  FavoriteResponseModel({
    required this.message,
    required this.status,
    required this.items,
    required this.filterStatus,
  });

  factory FavoriteResponseModel.fromJson(Map<String, dynamic> json) {
    return FavoriteResponseModel(
      message: (json['message'] ?? '').toString(),
      status: FavoriteAnimeModel._asInt(json['status']),
      items: (json['items'] as List?)
              ?.map((e) => FavoriteItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList() ??
          <FavoriteItemModel>[],
      filterStatus: (json['filter'] is Map && (json['filter'] as Map).containsKey('status'))
          ? (json['filter']['status']?.toString())
          : null,
    );
  }

  bool get isSuccess => status == 200;

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
        'filter': {
          'status': filterStatus,
        },
      };
}

// ===================== EPISODE FAVORITES MODELS =====================

class FavoriteEpisodeAnimeRefModel {
  final int id;
  final String namaAnime;

  FavoriteEpisodeAnimeRefModel({
    required this.id,
    required this.namaAnime,
  });

  factory FavoriteEpisodeAnimeRefModel.fromJson(Map<String, dynamic> json) {
    return FavoriteEpisodeAnimeRefModel(
      id: FavoriteAnimeModel._asInt(json['id']),
      namaAnime: (json['nama_anime'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_anime': namaAnime,
      };
}

class FavoriteEpisodeModel {
  final int id;
  final String judulEpisode;
  final int nomorEpisode;
  final FavoriteEpisodeAnimeRefModel anime;

  FavoriteEpisodeModel({
    required this.id,
    required this.judulEpisode,
    required this.nomorEpisode,
    required this.anime,
  });

  factory FavoriteEpisodeModel.fromJson(Map<String, dynamic> json) {
    return FavoriteEpisodeModel(
      id: FavoriteAnimeModel._asInt(json['id']),
      judulEpisode: (json['judul_episode'] ?? '').toString(),
      nomorEpisode: FavoriteAnimeModel._asInt(json['nomor_episode']),
      anime: FavoriteEpisodeAnimeRefModel.fromJson(
        (json['anime'] as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'judul_episode': judulEpisode,
        'nomor_episode': nomorEpisode,
        'anime': anime.toJson(),
      };
}

class FavoriteEpisodeItemModel {
  final int id;
  final int userId;
  final int episodeId;
  final DateTime? createdAt;
  final FavoriteEpisodeModel episode;

  FavoriteEpisodeItemModel({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.createdAt,
    required this.episode,
  });

  factory FavoriteEpisodeItemModel.fromJson(Map<String, dynamic> json) {
    return FavoriteEpisodeItemModel(
      id: FavoriteAnimeModel._asInt(json['id']),
      userId: FavoriteAnimeModel._asInt(json['user_id']),
      episodeId: FavoriteAnimeModel._asInt(json['episode_id']),
      createdAt: FavoriteItemModel._parseDate(json['createdAt']),
      episode: FavoriteEpisodeModel.fromJson(
        (json['episode'] as Map<String, dynamic>),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'episode_id': episodeId,
        'createdAt': createdAt?.toIso8601String(),
        'episode': episode.toJson(),
      };
}

class FavoriteEpisodeResponseModel {
  final String message;
  final int status;
  final List<FavoriteEpisodeItemModel> items;

  FavoriteEpisodeResponseModel({
    required this.message,
    required this.status,
    required this.items,
  });

  factory FavoriteEpisodeResponseModel.fromJson(Map<String, dynamic> json) {
    return FavoriteEpisodeResponseModel(
      message: (json['message'] ?? '').toString(),
      status: FavoriteAnimeModel._asInt(json['status']),
      items: (json['items'] as List?)
              ?.map((e) => FavoriteEpisodeItemModel.fromJson(
                    e as Map<String, dynamic>,
                  ))
              .toList() ??
          <FavoriteEpisodeItemModel>[],
    );
  }

  bool get isSuccess => status == 200;

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class EpisodeFavoriteStatsModel {
  final String message;
  final int status;
  final int count;
  final String formattedCount;
  final bool isFavorited;

  EpisodeFavoriteStatsModel({
    required this.message,
    required this.status,
    required this.count,
    required this.formattedCount,
    required this.isFavorited,
  });

  factory EpisodeFavoriteStatsModel.fromJson(Map<String, dynamic> json) {
    final status = FavoriteAnimeModel._asInt(json['status']);
    final count = FavoriteAnimeModel._asInt(json['count']);
    final formatted = (json['formattedCount'] ?? count.toString()).toString();
    final isFavRaw = json['isFavorited'];
    final isFav = (isFavRaw == true) ||
        (isFavRaw?.toString().toLowerCase() == 'true');
    return EpisodeFavoriteStatsModel(
      message: (json['message'] ?? '').toString(),
      status: status,
      count: count,
      formattedCount: formatted,
      isFavorited: isFav,
    );
  }

  bool get isSuccess => status == 200;

  Map<String, dynamic> toJson() => {
        'message': message,
        'status': status,
        'count': count,
        'formattedCount': formattedCount,
        'isFavorited': isFavorited,
      };
}
