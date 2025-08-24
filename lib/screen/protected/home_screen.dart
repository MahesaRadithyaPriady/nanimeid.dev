import 'package:flutter/material.dart';
import '../../widgets/home_header.dart';
import '../../widgets/home_slider.dart';
import '../../widgets/home_search_field.dart';
import '../../widgets/home_tab_section.dart';
import '../../widgets/home_section_anime.dart';
import '../../widgets/home_genre_list.dart';
import '../../widgets/skeleton_components.dart';
import '../../services/anime_service.dart';
import '../../models/anime_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final bool isVip = false;
  final int coinBalance = 1200;

  List<AnimeModel> popularAnimeList = [];
  List<AnimeModel> latestAnimeList = [];
  List<AnimeModel> movieAnimeList = [];
  List<AnimeModel> recommendedAnimeList = [];

  bool isLoadingPopular = true;
  bool isLoadingLatest = true;
  bool isLoadingMovies = true;
  bool isLoadingRecommended = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnimeData();
  }

  Future<void> _loadAnimeData() async {
    try {
      print('Loading anime data...');
      setState(() {
        isLoadingPopular = true;
        isLoadingLatest = true;
        isLoadingMovies = true;
        isLoadingRecommended = true;
        errorMessage = null;
      });

      // Fetch data in parallel for better performance
      final results = await Future.wait([
        AnimeService.getPopularAnime(),
        AnimeService.getLatestAnime(),
        AnimeService.getAnimeMovies(),
        AnimeService.getRecommendedAnime(),
      ]);

      print('All anime data fetched successfully');
      print('Popular anime count: ${results[0].length}');
      print('Latest anime count: ${results[1].length}');
      print('Movie anime count: ${results[2].length}');
      print('Recommended anime count: ${results[3].length}');

      setState(() {
        popularAnimeList = results[0];
        latestAnimeList = results[1];
        movieAnimeList = results[2];
        recommendedAnimeList = results[3];
        isLoadingPopular = false;
        isLoadingLatest = false;
        isLoadingMovies = false;
        isLoadingRecommended = false;
      });

      print('State updated successfully');
    } catch (e) {
      print('Error loading anime data: $e');
      setState(() {
        errorMessage = e.toString();
        isLoadingPopular = false;
        isLoadingLatest = false;
        isLoadingMovies = false;
        isLoadingRecommended = false;
      });
      debugPrint('Error loading anime data: $e');
    }
  }

  Future<void> _refreshData() async {
    await _loadAnimeData();
  }

  @override
  Widget build(BuildContext context) {
    print('Building HomeScreen...');
    print('Popular anime list type: ${popularAnimeList.runtimeType}');
    print('Popular anime list length: ${popularAnimeList.length}');
    print('Is loading popular: $isLoadingPopular');

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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SafeArea(
          child: DefaultTabController(
            length: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header - Static, tidak perlu skeleton
                  HomeHeader(coinBalance: coinBalance, isVip: isVip),

                  // Carousel - Skeleton hanya untuk bagian yang loading
                  isLoadingPopular
                      ? const CarouselSkeleton(height: 200)
                      : HomeSlider(
                          animeList: popularAnimeList.isNotEmpty
                              ? popularAnimeList
                              : [],
                        ),

                  const SizedBox(height: 16),

                  // Search bar - Static, tidak perlu skeleton
                  const HomeSearchField(),

                  const SizedBox(height: 16),

                  // Tabs - Static, tidak perlu skeleton
                  const HomeTabSection(),

                  // Section header - Popular Anime
                  HomeSectionAnime(
                    title: 'Sedang Populer',
                    onSeeAll: () {
                      debugPrint("selengkapnya di klik");
                    },
                    animeList: popularAnimeList,
                    isLoading: isLoadingPopular,
                  ),

                  const SizedBox(height: 30),

                  // Latest Anime
                  HomeSectionAnime(
                    title: 'Anime Terbaru',
                    onSeeAll: () {
                      debugPrint("selengkapnya di klik");
                    },
                    animeList: latestAnimeList,
                    isLoading: isLoadingLatest,
                  ),

                  const SizedBox(height: 30),

                  // Anime Movies
                  HomeSectionAnime(
                    title: 'Anime Movie',
                    onSeeAll: () {
                      debugPrint("selengkapnya di klik");
                    },
                    animeList: movieAnimeList,
                    isLoading: isLoadingMovies,
                  ),

                  const SizedBox(height: 30),

                  // Genre List - Static, tidak perlu skeleton
                  HomeGenreList(
                    genres: genreList,
                    onGenreTap: (genre) async {
                      debugPrint('Genre dipilih: $genre');
                      try {
                        final genreAnime = await AnimeService.getAnimeByGenre(
                          genre,
                        );
                        debugPrint(
                          'Found ${genreAnime.length} anime for genre: $genre',
                        );
                      } catch (e) {
                        debugPrint('Error fetching genre anime: $e');
                      }
                    },
                  ),

                  const SizedBox(height: 20),

                  // Recommended Anime
                  HomeSectionAnime(
                    title: 'Rekomendasi',
                    onSeeAll: () {
                      debugPrint("selengkapnya di klik");
                    },
                    animeList: recommendedAnimeList,
                    isLoading: isLoadingRecommended,
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
