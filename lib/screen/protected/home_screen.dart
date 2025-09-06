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
import 'nobar_screen.dart';
import 'leaderboard_screen.dart';

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

  void _showLeaderboardBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final mockLeaders = [
          {'name': 'Kazuma', 'level': 28, 'xp': 4200},
          {'name': 'Aqua', 'level': 25, 'xp': 3900},
          {'name': 'Megumin', 'level': 24, 'xp': 3720},
          {'name': 'Darkness', 'level': 23, 'xp': 3600},
          {'name': 'Yunyun', 'level': 22, 'xp': 3450},
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.emoji_events, color: Colors.amber),
                    SizedBox(width: 8),
                    Text(
                      'Leaderboard Level (Mock)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: mockLeaders.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white12),
                    itemBuilder: (context, index) {
                      final item = mockLeaders[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.white24,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          item['name'] as String,
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Lv ${item['level']} • ${item['xp']} XP',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                        onTap: () {},
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
              style: TextButton.styleFrom(foregroundColor: Colors.white),
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

                    // Nobar banner (temporarily disabled for maintenance)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Fitur Nobar sedang dalam perbaikan. Mohon tunggu pembaruan selanjutnya.',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7E57C2), Color(0xFFE040FB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.groups_2,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Nobar (Nonton Bareng)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Bikin room dan nonton anime bareng temanmu. (Sedang dalam perbaikan)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Info',
                                  style: TextStyle(
                                    color: Color(0xFF7E57C2),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
                        );
                      },
                      animeList: popularAnimeList,
                      isLoading: isLoadingPopular,
                    ),

                    const SizedBox(height: 20),

                    // Banner: Leaderboard Level (mock)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          PersistentNavBarNavigator.pushNewScreen(
                            context,
                            screen: const LeaderboardScreen(),
                            withNavBar: true,
                            pageTransitionAnimation:
                                PageTransitionAnimation.cupertino,
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.emoji_events,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Leaderboard Level',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Lihat peringkat level pengguna.',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Lihat',
                                  style: TextStyle(
                                    color: Color(0xFFFF8F00),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

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
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
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
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
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
                          pageTransitionAnimation:
                              PageTransitionAnimation.cupertino,
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
