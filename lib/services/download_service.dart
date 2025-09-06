import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/episode_detail_model.dart';

class DownloadEntry {
  final int episodeId;
  final int animeId;
  final String title;
  final int episodeNumber;
  final String thumbnail;
  final String quality;
  final String filePath;
  final int fileSize;

  DownloadEntry({
    required this.episodeId,
    required this.animeId,
    required this.title,
    required this.episodeNumber,
    required this.thumbnail,
    required this.quality,
    required this.filePath,
    required this.fileSize,
  });

  Map<String, dynamic> toJson() => {
        'episode_id': episodeId,
        'anime_id': animeId,
        'title': title,
        'episode_number': episodeNumber,
        'thumbnail': thumbnail,
        'quality': quality,
        'file_path': filePath,
        'file_size': fileSize,
      };

  static DownloadEntry fromJson(Map<String, dynamic> json) => DownloadEntry(
        episodeId: json['episode_id'] ?? 0,
        animeId: json['anime_id'] ?? 0,
        title: json['title'] ?? '',
        episodeNumber: json['episode_number'] ?? 0,
        thumbnail: json['thumbnail'] ?? '',
        quality: json['quality'] ?? '',
        filePath: json['file_path'] ?? '',
        fileSize: json['file_size'] ?? 0,
      );
}

class DownloadTask {
  final int episodeId;
  final int animeId;
  final String title;
  final int episodeNumber;
  final String thumbnail;
  final String quality;
  final String filePath;
  final double progress; // 0.0 - 1.0
  final String status; // downloading | complete | failed

  DownloadTask({
    required this.episodeId,
    required this.animeId,
    required this.title,
    required this.episodeNumber,
    required this.thumbnail,
    required this.quality,
    required this.filePath,
    required this.progress,
    required this.status,
  });

  DownloadTask copyWith({
    double? progress,
    String? status,
  }) => DownloadTask(
        episodeId: episodeId,
        animeId: animeId,
        title: title,
        episodeNumber: episodeNumber,
        thumbnail: thumbnail,
        quality: quality,
        filePath: filePath,
        progress: progress ?? this.progress,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'episode_id': episodeId,
        'anime_id': animeId,
        'title': title,
        'episode_number': episodeNumber,
        'thumbnail': thumbnail,
        'quality': quality,
        'file_path': filePath,
        'progress': progress,
        'status': status,
      };

  static DownloadTask fromJson(Map<String, dynamic> json) => DownloadTask(
        episodeId: json['episode_id'] ?? 0,
        animeId: json['anime_id'] ?? 0,
        title: json['title'] ?? '',
        episodeNumber: json['episode_number'] ?? 0,
        thumbnail: json['thumbnail'] ?? '',
        quality: json['quality'] ?? '',
        filePath: json['file_path'] ?? '',
        progress: (json['progress'] is int)
            ? (json['progress'] as int).toDouble()
            : (json['progress'] is String)
                ? double.tryParse(json['progress']) ?? 0.0
                : (json['progress'] ?? 0.0) as double,
        status: json['status'] ?? 'downloading',
      );
}

class DownloadService {
  // ---- Active tasks tracking (progress/state) ----
  // We maintain a separate tasks.json to track in-progress downloads with progress and status
  // status: downloading | complete | failed
  static Future<File> _tasksFile() async {
    final dir = await _baseDir();
    return File('${dir.path}/tasks.json');
  }

  static Future<List<DownloadTask>> listTasks() async {
    try {
      final f = await _tasksFile();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      if (raw.isEmpty) return [];
      final data = json.decode(raw);
      if (data is List) {
        return data.map((e) => DownloadTask.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveTasks(List<DownloadTask> tasks) async {
    final f = await _tasksFile();
    final raw = json.encode(tasks.map((e) => e.toJson()).toList());
    await f.writeAsString(raw);
  }

  static Future<void> _upsertTask(DownloadTask task) async {
    final tasks = await listTasks();
    final idx = tasks.indexWhere((t) => t.episodeId == task.episodeId && t.quality == task.quality);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      tasks.add(task);
    }
    await _saveTasks(tasks);
  }

  static Future<void> _removeTask(int episodeId, String quality) async {
    final tasks = await listTasks();
    tasks.removeWhere((t) => t.episodeId == episodeId && t.quality == quality);
    await _saveTasks(tasks);
  }

  static Future<Directory> _baseDir() async {
    // Prefer app-specific external storage on Android so files appear under
    // /storage/emulated/0/Android/data/<package>/files/downloads
    Directory base;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      base = ext ?? await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final target = Directory('${base.path}/downloads');
    if (!(await target.exists())) {
      await target.create(recursive: true);
    }
    return target;
  }

  static Future<File> _indexFile() async {
    final dir = await _baseDir();
    return File('${dir.path}/index.json');
  }

  static Future<List<DownloadEntry>> listDownloads() async {
    try {
      final f = await _indexFile();
      if (!await f.exists()) return [];
      final raw = await f.readAsString();
      if (raw.isEmpty) return [];
      final data = json.decode(raw);
      if (data is List) {
        return data.map((e) => DownloadEntry.fromJson(e)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveIndex(List<DownloadEntry> entries) async {
    final f = await _indexFile();
    final raw = json.encode(entries.map((e) => e.toJson()).toList());
    await f.writeAsString(raw);
  }

  static Future<DownloadEntry> downloadEpisode({
    required EpisodeDetailModel episode,
    required String qualityName,
    ProgressCallback? onProgress,
    CancelToken? cancelToken,
  }) async {
    final q = episode.getQualityByName(qualityName) ?? episode.bestQuality;
    if (q == null || q.sourceQuality.isEmpty) {
      throw Exception('Sumber video tidak tersedia untuk kualitas $qualityName');
    }

    final dir = await _baseDir();
    final safeTitle = episode.judulEpisode.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filePath = '${dir.path}/${episode.id}_${qualityName}_$safeTitle.mp4';

    final dio = Dio();
    int total = 0;
    // Initialize task entry
    final task = DownloadTask(
      episodeId: episode.id,
      animeId: episode.animeId,
      title: episode.judulEpisode,
      episodeNumber: episode.nomorEpisode,
      thumbnail: episode.thumbnailEpisode,
      quality: qualityName,
      filePath: filePath,
      progress: 0.0,
      status: 'downloading',
    );
    await _upsertTask(task);

    await dio.download(
      q.sourceQuality,
      filePath,
      onReceiveProgress: (received, totalBytes) {
        total = totalBytes;
        if (onProgress != null && totalBytes > 0) {
          onProgress(received, totalBytes);
        }
        if (totalBytes > 0) {
          final p = (received / totalBytes).clamp(0.0, 1.0);
          // fire-and-forget: update tasks.json for UI polling
          final updated = task.copyWith(progress: p, status: 'downloading');
          _upsertTask(updated);
        }
      },
      cancelToken: cancelToken,
      options: Options(responseType: ResponseType.bytes, followRedirects: true),
    );

    final file = File(filePath);
    final size = await file.length();

    final entry = DownloadEntry(
      episodeId: episode.id,
      animeId: episode.animeId,
      title: episode.judulEpisode,
      episodeNumber: episode.nomorEpisode,
      thumbnail: episode.thumbnailEpisode,
      quality: qualityName,
      filePath: filePath,
      fileSize: size,
    );

    // update index
    final current = await listDownloads();
    // replace if exists same episodeId & quality
    final idx = current.indexWhere((e) => e.episodeId == entry.episodeId && e.quality == entry.quality);
    if (idx >= 0) {
      current[idx] = entry;
    } else {
      current.add(entry);
    }
    await _saveIndex(current);

    // save metadata beside video
    final meta = File(filePath.replaceAll('.mp4', '.json'));
    await meta.writeAsString(json.encode(episode.toMap()));

    // mark task complete and set progress to 1.0, then optionally remove to avoid duplication
    await _upsertTask(task.copyWith(progress: 1.0, status: 'complete'));

    return entry;
  }

  static Future<void> removeDownload(DownloadEntry entry) async {
    try {
      final f = File(entry.filePath);
      if (await f.exists()) {
        await f.delete();
      }
      final meta = File(entry.filePath.replaceAll('.mp4', '.json'));
      if (await meta.exists()) {
        await meta.delete();
      }
    } catch (_) {}

    final current = await listDownloads();
    current.removeWhere((e) => e.episodeId == entry.episodeId && e.quality == entry.quality);
    await _saveIndex(current);
  }
}
