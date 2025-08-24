class EpisodeProgressModel {
  final int id;
  final int userId;
  final int episodeId;
  final int progressWatching;
  final bool isCompleted;
  final String lastWatched;
  final EpisodeProgressInfoModel episode;

  EpisodeProgressModel({
    required this.id,
    required this.userId,
    required this.episodeId,
    required this.progressWatching,
    required this.isCompleted,
    required this.lastWatched,
    required this.episode,
  });

  factory EpisodeProgressModel.fromJson(Map<String, dynamic> json) {
    try {
      return EpisodeProgressModel(
        id: json['id'] ?? 0,
        userId: json['user_id'] ?? 0,
        episodeId: json['episode_id'] ?? 0,
        progressWatching: json['progress_watching'] ?? 0,
        isCompleted: json['is_completed'] ?? false,
        lastWatched: json['last_watched'] ?? '',
        episode: EpisodeProgressInfoModel.fromJson(json['episode'] ?? {}),
      );
    } catch (e) {
      print('Error parsing EpisodeProgressModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'episode_id': episodeId,
      'progress_watching': progressWatching,
      'is_completed': isCompleted,
      'last_watched': lastWatched,
      'episode': episode.toMap(),
    };
  }

  // Get progress percentage (assuming episode duration is 24 minutes = 1440 seconds)
  double get progressPercentage {
    // Default episode duration is 24 minutes (1440 seconds)
    const defaultDuration = 1440;
    return (progressWatching / defaultDuration).clamp(0.0, 1.0);
  }

  // Get formatted progress time
  String get formattedProgressTime {
    final minutes = progressWatching ~/ 60;
    final seconds = progressWatching % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  // Get formatted last watched time
  String get formattedLastWatched {
    try {
      final dateTime = DateTime.parse(lastWatched);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} hari yang lalu';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} jam yang lalu';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} menit yang lalu';
      } else {
        return 'Baru saja';
      }
    } catch (e) {
      return 'Tidak diketahui';
    }
  }

  // Check if episode is partially watched
  bool get isPartiallyWatched {
    return progressWatching > 0 && !isCompleted;
  }

  // Check if episode is not started
  bool get isNotStarted {
    return progressWatching == 0;
  }

  // Get progress status
  String get progressStatus {
    if (isCompleted) return 'Selesai';
    if (isPartiallyWatched) return 'Sedang ditonton';
    return 'Belum ditonton';
  }
}

class EpisodeProgressInfoModel {
  final int id;
  final int nomorEpisode;
  final String judulEpisode;
  final String thumbnailEpisode;

  EpisodeProgressInfoModel({
    required this.id,
    required this.nomorEpisode,
    required this.judulEpisode,
    required this.thumbnailEpisode,
  });

  factory EpisodeProgressInfoModel.fromJson(Map<String, dynamic> json) {
    try {
      return EpisodeProgressInfoModel(
        id: json['id'] ?? 0,
        nomorEpisode: json['nomor_episode'] ?? 0,
        judulEpisode: json['judul_episode'] ?? '',
        thumbnailEpisode: json['thumbnail_episode'] ?? '',
      );
    } catch (e) {
      print('Error parsing EpisodeProgressInfoModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nomor_episode': nomorEpisode,
      'judul_episode': judulEpisode,
      'thumbnail_episode': thumbnailEpisode,
    };
  }
}

class EpisodeProgressResponseModel {
  final int status;
  final String message;
  final List<EpisodeProgressModel> data;

  EpisodeProgressResponseModel({
    required this.status,
    required this.message,
    required this.data,
  });

  factory EpisodeProgressResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      return EpisodeProgressResponseModel(
        status: json['status'] ?? 0,
        message: json['message'] ?? '',
        data: (json['data'] as List<dynamic>?)
                ?.map((item) => EpisodeProgressModel.fromJson(item))
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing EpisodeProgressResponseModel: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  bool get isSuccess => status == 200;
  bool get hasData => data.isNotEmpty;

  // Get completed episodes
  List<EpisodeProgressModel> get completedEpisodes {
    return data.where((progress) => progress.isCompleted).toList();
  }

  // Get partially watched episodes
  List<EpisodeProgressModel> get partiallyWatchedEpisodes {
    return data.where((progress) => progress.isPartiallyWatched).toList();
  }

  // Get not started episodes
  List<EpisodeProgressModel> get notStartedEpisodes {
    return data.where((progress) => progress.isNotStarted).toList();
  }

  // Get total progress percentage
  double get totalProgressPercentage {
    if (data.isEmpty) return 0.0;
    
    final totalProgress = data.fold<double>(0.0, (sum, progress) => sum + progress.progressPercentage);
    return totalProgress / data.length;
  }

  // Get total completed episodes count
  int get totalCompletedEpisodes {
    return completedEpisodes.length;
  }

  // Get total episodes count
  int get totalEpisodes {
    return data.length;
  }

  // Get progress by episode number
  EpisodeProgressModel? getProgressByEpisodeNumber(int episodeNumber) {
    try {
      return data.firstWhere((progress) => progress.episode.nomorEpisode == episodeNumber);
    } catch (e) {
      return null;
    }
  }

  // Get latest watched episode
  EpisodeProgressModel? get latestWatchedEpisode {
    if (data.isEmpty) return null;
    
    // Sort by last_watched descending
    final sorted = List<EpisodeProgressModel>.from(data);
    sorted.sort((a, b) => b.lastWatched.compareTo(a.lastWatched));
    
    return sorted.first;
  }

  // Get next episode to watch
  EpisodeProgressModel? get nextEpisodeToWatch {
    // Find the first episode that is not completed
    try {
      return data.firstWhere((progress) => !progress.isCompleted);
    } catch (e) {
      return null;
    }
  }

  // Get total watch time in minutes
  int get totalWatchTimeMinutes {
    return data.fold<int>(0, (sum, progress) => sum + progress.progressWatching) ~/ 60;
  }

  // Get formatted total watch time
  String get formattedTotalWatchTime {
    final hours = totalWatchTimeMinutes ~/ 60;
    final minutes = totalWatchTimeMinutes % 60;
    
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
