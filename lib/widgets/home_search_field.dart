import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/anime_service.dart';
import '../models/anime_model.dart';
import '../screen/protected/detail_anime_screen.dart';

class HomeSearchField extends StatefulWidget {
  const HomeSearchField({super.key});

  @override
  State<HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<HomeSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _loading = false;
  String _error = '';
  List<AnimeModel> _suggestions = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _error = '';
        _loading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      await _search(value.trim());
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final res = await AnimeService.getLiveSearch(query: query, limit: 10);
      if (!mounted) return;
      setState(() {
        _suggestions = res.data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _suggestions = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onChanged,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            onTapOutside: (_) => _focusNode.unfocus(),
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.pinkAccent,
            decoration: InputDecoration(
              hintText: 'Cari anime',
              hintStyle:
                  GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () {
                        _controller.clear();
                        _onChanged('');
                        FocusScope.of(context).requestFocus(_focusNode);
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade900,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_focusNode.hasFocus && (_loading || _error.isNotEmpty || _suggestions.isNotEmpty))
            const SizedBox(height: 8),
          if (_focusNode.hasFocus && (_loading || _error.isNotEmpty || _suggestions.isNotEmpty))
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 300),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.pinkAccent,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Mencari...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  : _error.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Terjadi kesalahan saat mencari',
                            style: GoogleFonts.poppins(color: Colors.redAccent, fontSize: 12),
                          ),
                        )
                      : _suggestions.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Tidak ada hasil',
                                style: GoogleFonts.poppins(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _suggestions.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.white10,
                              ),
                              itemBuilder: (context, index) {
                                final item = _suggestions[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.gambarAnime,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.white10,
                                        child: const Icon(Icons.image_not_supported, color: Colors.white30, size: 20),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    item.namaAnime,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    (item.genreAnime.isNotEmpty ? item.genreAnime.take(3).join(', ') : item.labelAnime).toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
                                  ),
                                  trailing: const Icon(Icons.north_east, color: Colors.white30, size: 18),
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    Navigator.of(context, rootNavigator: true).push(
                                      MaterialPageRoute(
                                        builder: (context) => DetailAnimeScreen(
                                          animeId: item.id,
                                          animeData: item.toMap(),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
            ),
        ],
      ),
    );
  }
}
