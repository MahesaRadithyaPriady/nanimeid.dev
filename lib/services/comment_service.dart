import 'package:dio/dio.dart';
import 'api_service.dart';
import '../models/comment_model.dart';

class CommentService {
  /// GET /comments?animeId=<id>&episode_id=<id|null>
  /// episode_id is optional; if omitted, returns anime-level comments
  static Future<CommentListResponseModel> getComments({
    required int animeId,
    int? episodeId,
  }) async {
    final Response res = await ApiService.dio.get(
      '/comments',
      queryParameters: {
        'animeId': animeId,
        if (episodeId != null) 'episodeId': episodeId,
      },
    );
    final data = res.data;
    if (data is Map<String, dynamic>) {
      return CommentListResponseModel.fromJson(data);
    }
    // Fallback to empty list on unexpected response shape
    return CommentListResponseModel(
      message: 'Invalid response',
      status: res.statusCode ?? 0,
      comments: const [],
    );
  }

  /// LIKE a comment: POST /comments/{id}/like
  static Future<void> likeComment(int commentId) async {
    await ApiService.dio.post('/comments/$commentId/like');
  }

  /// UNLIKE a comment: DELETE /comments/{id}/like
  static Future<void> unlikeComment(int commentId) async {
    await ApiService.dio.delete('/comments/$commentId/like');
  }

  /// CREATE a comment: POST /comments
  /// Body: { animeId, episode_id?, content }
  /// Returns created CommentModel (accepts either full object or wrapped as { comment: {...} })
  static Future<CommentModel> createComment({
    required int animeId,
    int? episodeId,
    required String content,
  }) async {
    final Response res = await ApiService.dio.post(
      '/comments',
      data: {
        'anime_id': animeId,
        if (episodeId != null) 'episode_id': episodeId,
        'content': content,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final payload = data['comment'] is Map<String, dynamic>
          ? data['comment']
          : data;
      if (payload is Map<String, dynamic>) {
        return CommentModel.fromJson(payload);
      }
    }
    // Fallback to an empty model on unexpected shape
    return CommentModel(
      id: 0,
      userId: 0,
      animeId: animeId,
      episodeId: episodeId,
      content: content,
      isEdited: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      user: null,
      count: CommentCountModel(likes: 0),
      likedByMe: false,
    );
  }

  /// UPDATE a comment: PUT /comments/{id}
  /// Body: { content }
  /// Response: { message, status, comment: { ... } }
  static Future<CommentModel> updateComment({
    required int commentId,
    required String content,
  }) async {
    final Response res = await ApiService.dio.put(
      '/comments/$commentId',
      data: {
        'content': content,
      },
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final payload = data['comment'] is Map<String, dynamic>
          ? data['comment']
          : data;
      if (payload is Map<String, dynamic>) {
        return CommentModel.fromJson(payload);
      }
    }
    // Fallback minimal – mark as edited
    return CommentModel(
      id: commentId,
      userId: 0,
      animeId: 0,
      episodeId: null,
      content: content,
      isEdited: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      user: null,
      count: CommentCountModel(likes: 0),
      likedByMe: false,
    );
  }

  /// DELETE a comment: DELETE /comments/{id}
  /// Response: { message, status }
  static Future<void> deleteComment(int commentId) async {
    await ApiService.dio.delete('/comments/$commentId');
  }
}
