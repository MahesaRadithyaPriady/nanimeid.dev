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

// Lightweight skeleton widget helper (no external deps)
class _Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;
  const _Skeleton.box({
    required this.width,
    required this.height,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
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
      // Skeleton loading UI (no dependency)
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Video skeleton
                Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.white10,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title line
                      _Skeleton.box(width: double.infinity, height: 18),
                      const SizedBox(height: 12),
                      // Meta row
                      Row(
                        children: const [
                          _Skeleton.box(width: 80, height: 14),
                          SizedBox(width: 16),
                          _Skeleton.box(width: 60, height: 14),
                          SizedBox(width: 16),
                          _Skeleton.box(width: 70, height: 14),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action buttons
                      Row(
                        children: const [
                          _Skeleton.box(width: 90, height: 36, radius: 8),
                          SizedBox(width: 12),
                          _Skeleton.box(width: 90, height: 36, radius: 8),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Episode list skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Skeleton.box(width: 140, height: 16),
                      const SizedBox(height: 12),
                      Column(
                        children: List.generate(
                          3,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: const [
                                _Skeleton.box(width: 64, height: 64, radius: 8),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Skeleton.box(
                                        width: double.infinity,
                                        height: 14,
                                      ),
                                      SizedBox(height: 8),
                                      _Skeleton.box(width: 180, height: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Progress bar skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _Skeleton.box(width: 160, height: 16),
                      SizedBox(height: 12),
                      _Skeleton.box(
                        width: double.infinity,
                        height: 8,
                        radius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Recommendation skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Skeleton.box(width: 180, height: 16),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(
                            4,
                            (i) => const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: _Skeleton.box(
                                width: 120,
                                height: 160,
                                radius: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Comment skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      3,
                      (i) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _Skeleton.box(
                          width: double.infinity,
                          height: 60,
                          radius: 8,
                        ),
                      ),
                    ),
                  ),
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
