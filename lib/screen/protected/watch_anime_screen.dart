import 'package:flutter/material.dart';
import '../../widgets/watch_video_player.dart';
import '../../widgets/watch_episode_info.dart';
import '../../widgets/watch_episode_list.dart';
import '../../widgets/watch_progress_bar.dart';
import '../../widgets/watch_comment_section.dart';
import '../../widgets/watch_recommendation_section.dart';

class WatchAnimeScreen extends StatefulWidget {
  WatchAnimeScreen({super.key});

  @override
  State<WatchAnimeScreen> createState() => _WatchAnimeScreenState();
}

class _WatchAnimeScreenState extends State<WatchAnimeScreen> {
  final List<String> episodes = List.generate(12, (i) => 'Ep ${i + 1}');

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WatchVideoPlayer(),
              const SizedBox(height: 16),
              const WatchEpisodeInfo(),
              const SizedBox(height: 24),
              WatchEpisodeList(episodes: episodes),
              const SizedBox(height: 24),
              const WatchProgressBar(),
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
