import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_slider.dart';
import '../../widgets/home_search_field.dart';
import '../../widgets/home_tab_section.dart';
import '../../widgets/home_section_anime.dart';
import '../../widgets/home_genre_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final bool isVip = false;
  final int coinBalance = 1200;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> animeList = [
      {
        'title': 'The Shiunji Family Children',
        'image':
            'https://a.storyblok.com/f/178900/750x422/6442446db9/the-shiunji-family-children.jpg/m/filters:quality(95)format(webp)',
        'synopsis':
            'A heartwarming romantic comedy about an unexpected reunion with childhood friends and new family bonds.',
        'rating': 8.3,
        'genre': 'Romance, Comedy',
        'views': '1.2M',
        'status': 'Ongoing',
        'releaseDate': 'April 2024',
      },
      {
        'title': 'Demon Slayer',
        'image':
            'https://cdn.rri.co.id/berita/Palembang/o/1720683518348-filters_quality(95)format(webp)/wjr3uy31wg0s7lx.jpeg',
        'synopsis':
            'Tanjiro sets out to become a demon slayer to avenge his family and cure his sister.',
        'rating': 9.1,
        'genre': 'Action, Fantasy',
        'views': '3.5M',
        'status': 'Completed',
      },
      {
        'title': 'Solo Leveling',
        'image': 'https://placehold.co/750x422?text=Solo+Leveling',
        'synopsis':
            'Jin-Woo rises from the weakest hunter to the strongest by leveling up like in a game.',
        'rating': 8.9,
        'genre': 'Action, Supernatural',
        'views': '2.8M',
        'status': 'Hiatus',
      },
      {
        'title': 'Blue Lock',
        'image': 'https://placehold.co/750x422?text=Blue+Lock',
        'synopsis':
            'Japan builds an extreme training camp to create the world’s best striker.',
        'rating': 8.2,
        'genre': 'Sports, Drama',
        'views': '1.1M',
        'status': 'Ongoing',
      },
      {
        'title': 'Code: Horizon',
        'image': 'https://placehold.co/750x422?text=Code+Horizon',
        'synopsis':
            'A mysterious code launches a new virtual world where reality and game intertwine.',
        'rating': 7.6,
        'genre': 'Sci-Fi, Mystery',
        'views': '600K',
        'status': 'Upcoming',
      },
    ];

    final List<String> genreList = [
      'Action',
      'Romance',
      'Comedy',
      'Drama',
      'Fantasy',
      'Sci-Fi',
      'Slice of Life',
      'Sports',
      'Horror',
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                HomeHeader(coinBalance: coinBalance, isVip: isVip),

                // Carousel
                HomeSlider(animeList: animeList),

                const SizedBox(height: 16),

                // Search bar
                const HomeSearchField(),

                const SizedBox(height: 16),

                // Tabs
                const HomeTabSection(),

                // Section header
                HomeSectionAnime(
                  title: 'Sedang Populer 🔥',
                  onSeeAll: () {
                    // Aksi ketika tombol "Selengkapnya >" ditekan
                    // Misalnya: Navigator.push ke halaman AnimeList
                    debugPrint("selengkapnya di klik");
                  },
                  animeList: animeList,
                ),

                const SizedBox(height: 30),

                HomeSectionAnime(
                  title: 'Anime Terbaru',
                  onSeeAll: () {
                    // Aksi ketika tombol "Selengkapnya >" ditekan
                    // Misalnya: Navigator.push ke halaman AnimeList
                    debugPrint("selengkapnya di klik");
                  },
                  animeList: animeList,
                ),

                const SizedBox(height: 30),

                HomeSectionAnime(
                  title: 'Anime Movie',
                  onSeeAll: () {
                    // Aksi ketika tombol "Selengkapnya >" ditekan
                    // Misalnya: Navigator.push ke halaman AnimeList
                    debugPrint("selengkapnya di klik");
                  },
                  animeList: animeList,
                ),

                const SizedBox(height: 30),

                HomeGenreList(
                  genres: genreList,
                  onGenreTap: (genre) {
                    debugPrint('Genre dipilih: $genre');
                    // TODO: Filter animeList atau navigasi ke halaman genre
                  },
                ),

                const SizedBox(height: 20),

                HomeSectionAnime(
                  title: 'Rekomendasi Anime',
                  onSeeAll: () {
                    // Aksi ketika tombol "Selengkapnya >" ditekan
                    // Misalnya: Navigator.push ke halaman AnimeList
                    debugPrint("selengkapnya di klik");
                  },
                  animeList: animeList,
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
