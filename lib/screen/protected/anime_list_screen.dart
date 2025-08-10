import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/home_header.dart';
import '../../widgets/anime_list_tab_animelist.dart';
import 'package:flutter/services.dart';
import '../../widgets/anime_list_tab_jadwal_rilis.dart';

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

  final genreOptions = ['Semua', 'Action', 'Romance', 'Isekai', 'Comedy'];
  final studioOptions = ['Semua', 'MAPPA', 'Ufotable', 'CloverWorks'];
  final azOptions = ['A-Z', 'Z-A'];

  final animeList = [
    {
      'title': 'Attack on Titan',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Action',
      'status': 'Completed',
      'sinopsis':
          'Manusia melawan para raksasa demi bertahan hidup dalam dunia penuh misteri dan kehancuran.',
    },
    {
      'title': 'Bleach',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Action',
      'status': 'Completed',
      'sinopsis':
          'Ichigo mendapat kekuatan Shinigami dan melawan roh jahat dalam pertempuran antar dunia.',
    },
    {
      'title': 'Blue Lock',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Sports',
      'status': 'Ongoing',
      'sinopsis':
          'Jepang membuat proyek gila untuk mencetak striker egois terbaik dalam dunia sepak bola.',
    },
    {
      'title': 'Demon Slayer',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Action',
      'status': 'Ongoing',
      'sinopsis':
          'Tanjiro menjadi pembasmi iblis untuk menyelamatkan adiknya dan membalas dendam keluarganya.',
    },
    {
      'title': 'Dragon Ball',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Action',
      'status': 'Completed',
      'sinopsis':
          'Petualangan Goku mengumpulkan bola naga dan bertarung demi melindungi bumi.',
    },
    {
      'title': 'Jujutsu Kaisen',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Supernatural',
      'status': 'Ongoing',
      'sinopsis':
          'Itadori Yuji terlibat dunia kutukan dan menjadi wadah dari roh terkutuk Sukuna.',
    },
    {
      'title': 'My Hero Academia',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Superhero',
      'status': 'Ongoing',
      'sinopsis':
          'Izuku bercita-cita menjadi pahlawan dalam dunia penuh kekuatan super yang disebut quirk.',
    },
    {
      'title': 'Naruto',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Ninja',
      'status': 'Completed',
      'sinopsis':
          'Perjalanan bocah nakal bernama Naruto menjadi Hokage yang diakui oleh desanya.',
    },
    {
      'title': 'One Piece',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Adventure',
      'status': 'Ongoing',
      'sinopsis':
          'Petualangan Luffy dan kru topi jerami untuk menemukan harta karun terbesar: One Piece.',
    },
    {
      'title': 'Solo Leveling',
      'image': 'https://picsum.photos/600/400',
      'genre': 'Isekai',
      'status': 'Completed',
      'sinopsis':
          'Hunter lemah Jin-Woo berubah menjadi hunter terkuat setelah menemukan sistem misterius.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Membuat Status Bar Hitam
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return SafeArea(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: const Color(0xFF101014),
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
                    AnimeListSection(
                      animeList: animeList,
                      selectedGenre: selectedGenre,
                      selectedStudio: selectedStudio,
                      selectedAZ: selectedAZ,
                      genreOptions: genreOptions,
                      studioOptions: studioOptions,
                      azOptions: azOptions,
                      onGenreChanged: (val) =>
                          setState(() => selectedGenre = val),
                      onStudioChanged: (val) =>
                          setState(() => selectedStudio = val),
                      onAZChanged: (val) => setState(() => selectedAZ = val),
                    ),
                    const JadwalRilisTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
