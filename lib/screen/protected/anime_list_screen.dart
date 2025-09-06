import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../widgets/home_header.dart';
import '../../widgets/anime_list_tab_animelist.dart';
import '../../widgets/anime_list_tab_jadwal_rilis.dart';
import '../../models/anime_model.dart';
import '../../services/anime_service.dart';
import '../../widgets/exit_confirmation.dart';

class AnimeListScreen extends StatelessWidget {
  const AnimeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AnimeListPage();
  }
}

class AnimeListPage extends StatefulWidget {
  const AnimeListPage({super.key});

  @override
  State<AnimeListPage> createState() => _AnimeListPageState();
}

class _AnimeListPageState extends State<AnimeListPage> {
  String selectedGenre = 'Semua';
  String selectedStudio = 'Semua';
  String selectedAZ = 'A-Z';
  bool isLoading = true;
  String? errorMessage;
  List<AnimeModel> animes = [];

  final genreOptions = ['Semua', 'Action', 'Romance', 'Isekai', 'Comedy'];
  final studioOptions = ['Semua', 'MAPPA', 'Ufotable', 'CloverWorks'];
  final azOptions = ['A-Z', 'Z-A'];

  @override
  void initState() {
    super.initState();
    _fetchAnimeAZ();
  }

  Future<void> _fetchAnimeAZ() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await AnimeService.getAnimeAZ(
        letter: null, // optional letter filter can be added to UI later
        genre: selectedGenre != 'Semua' ? selectedGenre : null,
        studio: selectedStudio != 'Semua' ? selectedStudio : null,
        page: 1,
        limit: 24,
        order: selectedAZ == 'A-Z' ? 'asc' : 'desc',
      );
      setState(() {
        animes = response.data;
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
    // Membuat Status Bar & Navigation Bar Hitam
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    return WillPopScope(
      onWillPop: () => showExitConfirmationDialog(context),
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Column(
              children: [
                const HomeHeader(coinBalance: 1000, isVip: true),
                Container(
                  color: Colors.black,
                  child: TabBar(
                    indicatorColor: Colors.pinkAccent,
                    labelColor: Colors.pinkAccent,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(text: 'Anime List'),
                      Tab(text: 'Jadwal Rilis'),
                    ],
                  ),
                ),
              
              Expanded(
                child: TabBarView(
                  children: [
                    Builder(builder: (context) {
                      if (isLoading) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.pinkAccent,
                          ),
                        );
                      }
                      if (errorMessage != null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent),
                                const SizedBox(height: 8),
                                Text(
                                  'Gagal memuat data:\n$errorMessage',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _fetchAnimeAZ,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.pinkAccent,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Coba lagi'),
                                )
                              ],
                            ),
                          ),
                        );
                      }
                      return AnimeListSection(
                        animeList: animes,
                        selectedGenre: selectedGenre,
                        selectedStudio: selectedStudio,
                        selectedAZ: selectedAZ,
                        genreOptions: genreOptions,
                        studioOptions: studioOptions,
                        azOptions: azOptions,
                        onGenreChanged: (val) {
                          setState(() => selectedGenre = val);
                          _fetchAnimeAZ();
                        },
                        onStudioChanged: (val) {
                          setState(() => selectedStudio = val);
                          _fetchAnimeAZ();
                        },
                        onAZChanged: (val) {
                          setState(() => selectedAZ = val);
                          _fetchAnimeAZ();
                        },
                      );
                    }),
                    const JadwalRilisTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
