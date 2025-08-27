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
import 'anime_grid_screen.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

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

  Future<bool> _onWillPop() async {
    // If any input has focus (e.g., search), dismiss keyboard first
    FocusScope.of(context).unfocus();

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.pinkAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.exit_to_app, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Keluar Aplikasi?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: const Text(
            'Apakah kamu yakin ingin keluar dari aplikasi?',
            style: TextStyle(color: Colors.white, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    return shouldExit ?? false;
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: AnimeGridScreen(
                            title: 'Sedang Populer',
                            gridType: AnimeGridType.popular,
                            animeList: popularAnimeList,
                          ),
                          withNavBar: true,
                          pageTransitionAnimation: PageTransitionAnimation.cupertino,
                        );
                      },
                      animeList: popularAnimeList,
                      isLoading: isLoadingPopular,
                    ),

                    const SizedBox(height: 30),

                    // Latest Anime
                    HomeSectionAnime(
                      title: 'Anime Terbaru',
                      onSeeAll: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: AnimeGridScreen(
                            title: 'Anime Terbaru',
                            gridType: AnimeGridType.latest,
                            animeList: latestAnimeList,
                          ),
                          withNavBar: true,
                          pageTransitionAnimation: PageTransitionAnimation.cupertino,
                        );
                      },
                      animeList: latestAnimeList,
                      isLoading: isLoadingLatest,
                    ),

                    const SizedBox(height: 30),

                    // Anime Movies
                    HomeSectionAnime(
                      title: 'Anime Movie',
                      onSeeAll: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: AnimeGridScreen(
                            title: 'Anime Movie',
                            gridType: AnimeGridType.movie,
                            animeList: movieAnimeList,
                          ),
                          withNavBar: true,
                          pageTransitionAnimation: PageTransitionAnimation.cupertino,
                        );
                      },
                      animeList: movieAnimeList,
                      isLoading: isLoadingMovies,
                    ),

                    const SizedBox(height: 30),

                    // Genre List - Static, tidak perlu skeleton
                    HomeGenreList(
                      genres: genreList,
                      onGenreTap: (genre) {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: AnimeGridScreen(
                            title: 'Genre: $genre',
                            gridType: AnimeGridType.genre,
                            genre: genre,
                          ),
                          withNavBar: true,
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    // Recommended Anime
                    HomeSectionAnime(
                      title: 'Rekomendasi',
                      onSeeAll: () {
                        PersistentNavBarNavigator.pushNewScreen(
                          context,
                          screen: AnimeGridScreen(
                            title: 'Rekomendasi',
                            gridType: AnimeGridType.recommended,
                            animeList: recommendedAnimeList,
                          ),
                          withNavBar: true,
                          pageTransitionAnimation: PageTransitionAnimation.cupertino,
                        );
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
      ),
    );
  }
}
