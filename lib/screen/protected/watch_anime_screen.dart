import 'package:flutter/material.dart';
import '../../widgets/watch_video_player.dart';
import '../../widgets/watch_episode_info.dart';
import '../../widgets/watch_episode_list.dart';
import '../../widgets/watch_progress_bar.dart';
import '../../widgets/watch_comment_section.dart';
import '../../widgets/watch_recommendation_section.dart';
import '../../services/episode_service.dart';
import '../../models/episode_detail_model.dart';

class WatchAnimeScreen extends StatefulWidget {
  final int episodeId;

  const WatchAnimeScreen({super.key, required this.episodeId});

  @override
  State<WatchAnimeScreen> createState() => _WatchAnimeScreenState();
}

class _WatchAnimeScreenState extends State<WatchAnimeScreen> {
  EpisodeDetailModel? episodeDetail;
  bool isLoading = true;
  String? errorMessage;

  // Simulasi data komentar yang banyak
  final List<Map<String, String>> _allComments = List.generate(
    1000,
    (i) => {
      'user': 'User${i + 1}',
      'text': i % 5 == 0
          ? 'Wah makin seru di episode ini! Episode terbaik sejauh ini 🔥'
          : i % 5 == 1
          ? 'Marin kawaii banget 😍'
          : i % 5 == 2
          ? 'Animasinya bagus banget, studio CLOVERWORKS mantap!'
          : i % 5 == 3
          ? 'Kapan episode selanjutnya rilis?'
          : 'Anime ini bikin baper terus deh',
      'timestamp': '${(i ~/ 10) + 1} jam yang lalu',
    },
  );

  @override
  void initState() {
    super.initState();
    _loadEpisodeDetail();
  }

  Future<void> _loadEpisodeDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final detail = await EpisodeService.getEpisodeDetail(widget.episodeId);
      setState(() {
        episodeDetail = detail;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  final List<Map<String, String>> recommendations = [
    {
      'title': 'Horimiya',
      'image':
          'https://i1.sndcdn.com/artworks-000144407116-1t7bd3-t500x500.jpg',
      'genre': 'Romance, Slice of Life',
      'releaseDate': '2021',
    },
    {
      'title': 'Kubo-san wa Mob wo Yurusanai',
      'image':
          'https://i1.sndcdn.com/artworks-000144407116-1t7bd3-t500x500.jpg',
      'genre': 'Comedy, Romance',
      'releaseDate': '2023',
    },
    {
      'title': 'Kaguya-sama: Love is War',
      'image':
          'https://i1.sndcdn.com/artworks-000144407116-1t7bd3-t500x500.jpg',
      'genre': 'Comedy, Romance',
      'releaseDate': '2019',
    },
    {
      'title': 'Toradora!',
      'image':
          'https://i1.sndcdn.com/artworks-000144407116-1t7bd3-t500x500.jpg',
      'genre': 'Romance, Drama',
      'releaseDate': '2008',
    },
    {
      'title': 'Rent-A-Girlfriend',
      'image':
          'https://i1.sndcdn.com/artworks-000144407116-1t7bd3-t500x500.jpg',
      'genre': 'Romance, Comedy',
      'releaseDate': '2020',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Colors.pinkAccent),
                const SizedBox(height: 16),
                Text(
                  'Memuat episode...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi Kesalahan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadEpisodeDetail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pinkAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WatchVideoPlayer(episodeDetail: episodeDetail),
              const SizedBox(height: 16),
              WatchEpisodeInfo(episodeDetail: episodeDetail),
              const SizedBox(height: 24),
              WatchEpisodeList(
                animeId: episodeDetail?.animeId ?? 0,
                currentEpisodeId: widget.episodeId,
              ),
              const SizedBox(height: 24),
              WatchProgressBar(episodeDetail: episodeDetail),
              const SizedBox(height: 32),
              WatchRecommendationSection(recommendations: recommendations),
              const SizedBox(height: 32),
              WatchCommentSection(allComments: _allComments),
            ],
          ),
        ),
      ),
    );
  }
}
