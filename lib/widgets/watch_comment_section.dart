import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/comment_model.dart';
import '../services/comment_service.dart';
import '../services/profile_service.dart';
import './comment_item.dart';
import '../screen/public/user_profile_mock.dart';

class WatchCommentSection extends StatefulWidget {
  /// Backward-compat mock data (will be ignored when [animeId] provided)
  final List<Map<String, String>> allComments;

  /// If provided, widget will fetch from API using these params
  final int? animeId;
  final int? episodeId;

  const WatchCommentSection({
    super.key,
    required this.allComments,
    this.animeId,
    this.episodeId,
  });

  @override
  State<WatchCommentSection> createState() => _WatchCommentSectionState();
}

class _WatchCommentSectionState extends State<WatchCommentSection>
    with SingleTickerProviderStateMixin {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentScrollController = ScrollController();

  List<CommentModel> _sourceComments = [];
  List<CommentModel> _displayedComments = [];
  bool _isLoadingComments = false;
  int _currentPage = 0;
  final int _commentsPerPage = 10;

  bool _isLatestFirst = true;

  late final AnimationController _vipCtrl;
  int? _currentUserId;

  Color _vipAccent(String level) {
    switch (level.toLowerCase()) {
      case 'bronze':
        return const Color(0xFF8B4513);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return Colors.amber;
      case 'diamond':
        return const Color(0xFF9C27B0);
      case 'master':
        return Colors.redAccent;
      default:
        return Colors.white12;
    }

  }

  Future<void> _handleEditComment(CommentModel original) async {
    // permission guard: only own comment
    if (_currentUserId == null || original.userId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda hanya dapat mengedit komentar Anda sendiri')),
      );
      return;
    }
    final controller = TextEditingController(text: original.content);
    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Edit Komentar', style: GoogleFonts.poppins(color: Colors.white)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            cursorColor: Colors.pinkAccent,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Ubah komentar...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (newText == null) return;
    if (newText.isEmpty || newText == original.content) return;

    try {
      final updated = await CommentService.updateComment(
        commentId: original.id,
        content: newText,
      );

      setState(() {
        // replace in displayed
        final idxDisp = _displayedComments.indexWhere((c) => c.id == original.id);
        if (idxDisp != -1) _displayedComments[idxDisp] = updated;
        // replace in source
        final idxSrc = _sourceComments.indexWhere((c) => c.id == original.id);
        if (idxSrc != -1) _sourceComments[idxSrc] = updated;
      });

      // Refresh from API to ensure latest server state
      if (widget.animeId != null) {
        try {
          final res = await CommentService.getComments(
            animeId: widget.animeId!,
            episodeId: widget.episodeId,
          );
          _sourceComments = res.comments;
          _applyPaginationReset();
        } catch (_) {
          // ignore refresh error; local optimistic update remains
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengedit komentar')),
      );
    }

  }

  Future<void> _handleDeleteComment(CommentModel target) async {
    // permission guard: only own comment
    if (_currentUserId == null || target.userId != _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda hanya dapat menghapus komentar Anda sendiri')),
      );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text('Hapus Komentar', style: GoogleFonts.poppins(color: Colors.white)),
          content: Text(
            'Yakin ingin menghapus komentar ini?',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await CommentService.deleteComment(target.id);
      setState(() {
        _displayedComments.removeWhere((c) => c.id == target.id);
        _sourceComments.removeWhere((c) => c.id == target.id);
      });

      // Refresh from API to ensure latest server state
      if (widget.animeId != null) {
        try {
          final res = await CommentService.getComments(
            animeId: widget.animeId!,
            episodeId: widget.episodeId,
          );
          _sourceComments = res.comments;
          _applyPaginationReset();
        } catch (_) {
          // ignore refresh error; local removal remains
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus komentar')),
      );
    }
  }

  Widget _buildVipBadge(String level) {
    if (level.isEmpty) return const SizedBox.shrink();
    final l = level.toLowerCase();
    final label = 'VIP ${level[0].toUpperCase()}${level.substring(1)}';
    if (l == 'diamond') {
      return AnimatedBuilder(
        animation: _vipCtrl,
        builder: (context, _) {
          final angle = _vipCtrl.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFF9C27B0),
                  Color(0xFFE040FB),
                  Color(0xFF7E57C2),
                  Color(0xFF9C27B0),
                ],
                transform: GradientRotation(angle),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }
    if (l == 'master') {
      return AnimatedBuilder(
        animation: _vipCtrl,
        builder: (context, _) {
          final angle = _vipCtrl.value * 2 * math.pi;
          return Container(
            padding: const EdgeInsets.all(1.2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFE53935),
                  Color(0xFFFF7043),
                  Color(0xFFD81B60),
                  Color(0xFFE53935),
                ],
                transform: GradientRotation(angle),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.35),
                  blurRadius: 6,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      );
    }

    final color = _vipAccent(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color is MaterialColor ? color.shade200 : color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _initLoad();
    _commentScrollController.addListener(_onCommentScroll);
    _vipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _commentScrollController.removeListener(_onCommentScroll);
    _commentScrollController.dispose();
    _commentController.dispose();
    _vipCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      final me = await ProfileService.getMyProfile();
      if (!mounted) return;
      setState(() {
        _currentUserId = me.profile?.userId;
      });
    } catch (_) {
      // Not logged in or failed to fetch; keep null
    }
  }

  Future<void> _initLoad() async {
    setState(() => _isLoadingComments = true);
    try {
      if (widget.animeId != null) {
        final res = await CommentService.getComments(
          animeId: widget.animeId!,
          episodeId: widget.episodeId,
        );
        _sourceComments = res.comments;
      } else {
        // Map legacy mock into CommentModel minimal
        _sourceComments = widget.allComments.map((m) {
          final fullName = (m['user'] ?? 'User');
          return CommentModel(
            id: 0,
            userId: 0,
            animeId: widget.animeId ?? 0,
            episodeId: widget.episodeId,
            content: m['text'] ?? '',
            isEdited: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: CommentUserModel(
              id: 0,
              userID: 0,
              username: fullName, // keep populated but will not be shown
              email: '',
              password: '',
              createdAt: DateTime.now(),
              profile: CommentUserProfileModel(
                id: 0,
                userId: 0,
                fullName: fullName,
                avatarUrl: null,
                bio: null,
                birthdate: null,
                gender: null,
                createdAt: null,
                updatedAt: null,
              ),
              vip: null,
            ),
            count: CommentCountModel(likes: 0),
            likedByMe: false,
          );
        }).toList();
      }
      _applyPaginationReset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat komentar')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  void _applyPaginationReset() {
    final sorted = _isLatestFirst
        ? List<CommentModel>.from(_sourceComments.reversed)
        : _sourceComments;
    _displayedComments = sorted.take(_commentsPerPage).toList();
    _currentPage = 1;
    setState(() {});
  }

  void _onCommentScroll() {
    if (_commentScrollController.position.pixels >=
        _commentScrollController.position.maxScrollExtent - 100) {
      _loadMoreComments();
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingComments ||
        _displayedComments.length >= _sourceComments.length) {
      return;
    }

    setState(() => _isLoadingComments = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final sortedComments = _isLatestFirst
        ? List<CommentModel>.from(_sourceComments.reversed)
        : _sourceComments;

    final startIndex = _currentPage * _commentsPerPage;
    final endIndex = (startIndex + _commentsPerPage).clamp(
      0,
      sortedComments.length,
    );

    if (startIndex < sortedComments.length) {
      setState(() {
        _displayedComments
            .addAll(sortedComments.sublist(startIndex, endIndex).toList());
        _currentPage++;
      });
    }

    setState(() => _isLoadingComments = false);
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final tempComment = CommentModel(
      id: 0, // 0 indicates local/unsynced; will replace with server id
      userId: 0,
      animeId: widget.animeId ?? 0,
      episodeId: widget.episodeId,
      content: text,
      isEdited: false,
      createdAt: now,
      updatedAt: now,
      user: null, // do not show placeholder username; wait for server data
      count: CommentCountModel(likes: 0),
      likedByMe: false,
    );

    // Optimistic insert
    setState(() {
      _sourceComments.add(tempComment);
      if (_isLatestFirst) {
        _displayedComments.insert(0, tempComment);
      } else {
        _displayedComments.add(tempComment);
      }
      _commentController.clear();
    });

    try {
      // Send to API if animeId available; otherwise keep local only
      if (widget.animeId != null) {
        final created = await CommentService.createComment(
          animeId: widget.animeId!,
          episodeId: widget.episodeId,
          content: text,
        );

        // Replace temp with server result in both lists
        setState(() {
          final iDisp = _displayedComments.indexOf(tempComment);
          if (iDisp != -1) _displayedComments[iDisp] = created;
          final iSrc = _sourceComments.indexOf(tempComment);
          if (iSrc != -1) _sourceComments[iSrc] = created;
        });

        // Refresh list to hydrate with full server data (user, vip, timestamps, etc.)
        try {
          final res = await CommentService.getComments(
            animeId: widget.animeId!,
            episodeId: widget.episodeId,
          );
          _sourceComments = res.comments;
          _applyPaginationReset();
        } catch (_) {
          // ignore refresh error; keep optimistic-replaced data
        }
      }
    } catch (e) {
      if (!mounted) return;
      // Revert optimistic insert on failure
      setState(() {
        _displayedComments.remove(tempComment);
        _sourceComments.remove(tempComment);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim komentar')),
      );
    }
  }

  void _toggleSortUI() {
    setState(() {
      _isLatestFirst = !_isLatestFirst;
      _displayedComments = List<CommentModel>.from(_displayedComments.reversed);
    });
  }

  Future<void> _toggleLike(int index) async {
    final current = _displayedComments[index];
    final prevLiked = current.likedByMe;
    final prevLikes = current.count?.likes ?? 0;

    // optimistic update
    setState(() {
      _displayedComments[index] = CommentModel(
        id: current.id,
        userId: current.userId,
        animeId: current.animeId,
        episodeId: current.episodeId,
        content: current.content,
        isEdited: current.isEdited,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
        user: current.user,
        count: CommentCountModel(likes: prevLiked ? (prevLikes - 1) : (prevLikes + 1)),
        likedByMe: !prevLiked,
      );
    });

    try {
      if (current.id != 0) {
        if (prevLiked) {
          await CommentService.unlikeComment(current.id);
        } else {
          await CommentService.likeComment(current.id);
        }
      }
    } catch (e) {
      // revert on failure
      if (!mounted) return;
      setState(() {
        _displayedComments[index] = CommentModel(
          id: current.id,
          userId: current.userId,
          animeId: current.animeId,
          episodeId: current.episodeId,
          content: current.content,
          isEdited: current.isEdited,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
          user: current.user,
          count: CommentCountModel(likes: prevLikes),
          likedByMe: prevLiked,
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengubah like')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.pinkAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.messageCircle,
                  color: Colors.pinkAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Komentar Pengguna',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_sourceComments.length} komentar',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _toggleSortUI,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.pinkAccent),
                  foregroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: Icon(
                  _isLatestFirst
                      ? LucideIcons.arrowDownWideNarrow
                      : LucideIcons.arrowUpNarrowWide,
                  size: 16,
                ),
                label: Text(_isLatestFirst ? 'Terbaru' : 'Terlama'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Input Komentar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  cursorColor: Colors.pinkAccent,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.pinkAccent, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addComment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                child: const Text('Kirim'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Komentar List
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (_displayedComments.isEmpty && !_isLoadingComments)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Belum ada komentar.\nJadilah yang pertama!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ListView.builder(
                  // Non-scrollable list so whole section/page scrolls together
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount: _displayedComments.length,
                  itemBuilder: (context, index) => _buildCommentItem(index),
                ),
                // Manual load more button (since internal scroll is disabled)
                if (_displayedComments.length < _sourceComments.length)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isLoadingComments ? null : _loadMoreComments,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: _isLoadingComments
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.pinkAccent,
                                ),
                              )
                            : const Icon(Icons.expand_more, color: Colors.white70, size: 18),
                        label: Text(
                          _isLoadingComments ? 'Memuat…' : 'Muat lebih banyak',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                if (_displayedComments.length >= _sourceComments.length &&
                    _displayedComments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Semua komentar telah dimuat',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(int index) {
    final comment = _displayedComments[index];
    return CommentItem(
      comment: comment,
      index: index,
      canModerate: _currentUserId != null && comment.userId == _currentUserId,
      onEdit: () => _handleEditComment(comment),
      onDelete: () => _handleDeleteComment(comment),
      onLike: () => _toggleLike(index),
      onUserTap: () {
        final user = comment.user;
        if (user == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserProfileMockScreen(
              userId: user.id,
              username: user.profile?.fullName ?? user.username,
              avatarUrl: user.profile?.avatarUrl,
              vipLevel: (user.vip?.vipLevel ?? '').toLowerCase(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.pinkAccent),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Memuat komentar...',
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
