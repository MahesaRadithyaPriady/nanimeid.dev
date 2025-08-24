import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/anime_service.dart';
import '../models/episode_model.dart';
import '../screen/protected/watch_anime_screen.dart';

class WatchEpisodeList extends StatefulWidget {
  final int animeId;
  final int currentEpisodeId;

  const WatchEpisodeList({
    super.key,
    required this.animeId,
    required this.currentEpisodeId,
  });

  @override
  State<WatchEpisodeList> createState() => _WatchEpisodeListState();
}

class _WatchEpisodeListState extends State<WatchEpisodeList> {
  bool _isAscending = true;
  List<EpisodeModel> episodes = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEpisodes();
  }

  Future<void> _loadEpisodes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final episodeList = await AnimeService.getEpisodesByAnimeId(
        widget.animeId,
      );
      setState(() {
        episodes = episodeList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: CircularProgressIndicator(color: Colors.pinkAccent),
        ),
      );
    }

    if (errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: Text(
            'Gagal memuat episode: $errorMessage',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    List<EpisodeModel> displayedEpisodes = [...episodes];
    if (!_isAscending) {
      displayedEpisodes = displayedEpisodes.reversed.toList();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayedEpisodes.length,
            itemBuilder: (context, index) {
              final episode = displayedEpisodes[index];
              final isActive = episode.id == widget.currentEpisodeId;

              return GestureDetector(
                onTap: () {
                  // Navigate to watch screen with this episode
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WatchAnimeScreen(episodeId: episode.id),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.pinkAccent : Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? Colors.pinkAccent
                          : Colors.pinkAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Episode ${episode.nomorEpisode}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(LucideIcons.listVideo, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'Daftar Episode',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _isAscending = !_isAscending;
              });
            },
            icon: Icon(
              _isAscending
                  ? LucideIcons.arrowDownWideNarrow
                  : LucideIcons.arrowUpNarrowWide,
              color: Colors.pinkAccent,
              size: 20,
            ),
            tooltip: _isAscending ? 'Urutkan Terbaru' : 'Urutkan Terlama',
          ),
        ],
      ),
    );
  }
}
