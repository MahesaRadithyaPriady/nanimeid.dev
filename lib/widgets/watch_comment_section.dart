import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WatchCommentSection extends StatefulWidget {
  final List<Map<String, String>> allComments;

  const WatchCommentSection({super.key, required this.allComments});

  @override
  State<WatchCommentSection> createState() => _WatchCommentSectionState();
}

class _WatchCommentSectionState extends State<WatchCommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _commentScrollController = ScrollController();

  List<Map<String, String>> _displayedComments = [];
  bool _isLoadingComments = false;
  int _currentPage = 0;
  final int _commentsPerPage = 10;

  bool _isLatestFirst = true;

  @override
  void initState() {
    super.initState();
    _loadInitialComments();
    _commentScrollController.addListener(_onCommentScroll);
  }

  @override
  void dispose() {
    _commentScrollController.removeListener(_onCommentScroll);
    _commentScrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _loadInitialComments() {
    final sorted = _isLatestFirst
        ? List.from(widget.allComments.reversed)
        : widget.allComments;

    setState(() {
      _displayedComments = sorted
          .take(_commentsPerPage)
          .toList()
          .cast<Map<String, String>>();
      _currentPage = 1;
    });
  }

  void _onCommentScroll() {
    if (_commentScrollController.position.pixels >=
        _commentScrollController.position.maxScrollExtent - 100) {
      _loadMoreComments();
    }
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingComments ||
        _displayedComments.length >= widget.allComments.length)
      return;

    setState(() => _isLoadingComments = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final sortedComments = _isLatestFirst
        ? List.from(widget.allComments.reversed)
        : widget.allComments;

    final startIndex = _currentPage * _commentsPerPage;
    final endIndex = (startIndex + _commentsPerPage).clamp(
      0,
      sortedComments.length,
    );

    if (startIndex < sortedComments.length) {
      setState(() {
        _displayedComments.addAll(
          sortedComments
              .sublist(startIndex, endIndex)
              .cast<Map<String, String>>(),
        );
        _currentPage++;
      });
    }

    setState(() => _isLoadingComments = false);
  }

  void _addComment() {
    final newComment = {
      'user': 'Kamu',
      'text': _commentController.text.trim(),
      'timestamp': 'Baru saja',
    };

    if (_commentController.text.trim().isNotEmpty) {
      setState(() {
        if (_isLatestFirst) {
          _displayedComments.insert(0, newComment);
        } else {
          _displayedComments.add(newComment);
        }
        _commentController.clear();
      });
    }
  }

  void _toggleSortUI() {
    setState(() {
      _isLatestFirst = !_isLatestFirst;
      _displayedComments = List.from(_displayedComments.reversed);
    });
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
              const Icon(
                LucideIcons.messageCircle,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Komentar Pengguna',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _toggleSortUI,
                tooltip: _isLatestFirst ? 'Urut Terbaru' : 'Urut Terlama',
                icon: Icon(
                  _isLatestFirst
                      ? LucideIcons.arrowDownWideNarrow
                      : LucideIcons.arrowUpNarrowWide,
                  color: Colors.pinkAccent,
                  size: 20,
                ),
              ),
              Text(
                '${widget.allComments.length}',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
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
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
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
                  controller: _commentScrollController,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(12),
                  itemCount:
                      _displayedComments.length + (_isLoadingComments ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _displayedComments.length) {
                      return _buildLoadingIndicator();
                    }
                    final comment = _displayedComments[index];
                    return _buildCommentItem(comment);
                  },
                ),
                if (_displayedComments.length >= widget.allComments.length &&
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

  Widget _buildCommentItem(Map<String, String> comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.pinkAccent,
            child: Text(
              comment['user']![0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment['user']!,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      comment['timestamp'] ?? '',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment['text']!,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
