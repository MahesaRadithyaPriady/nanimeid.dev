import 'package:flutter/material.dart';
import 'home_section_anime.dart';
import '../models/anime_model.dart';
import '../services/anime_service.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import '../screen/protected/anime_grid_screen.dart';

class JadwalRilisTab extends StatefulWidget {
  const JadwalRilisTab({super.key});

  @override
  State<JadwalRilisTab> createState() => _JadwalRilisTabState();
}

class _JadwalRilisTabState extends State<JadwalRilisTab> {
  final List<String> _daysOrder = const [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  Map<String, List<AnimeModel>> _schedule = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchSchedule();
  }

  Future<void> _fetchSchedule() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await AnimeService.getAnimeSchedule(limitPerDay: 10);
      setState(() {
        _schedule = res.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: ListView(
          children: _daysOrder.map((day) {
            return HomeSectionAnime(
              title: day,
              onSeeAll: () {},
              animeList: const [],
              isLoading: true,
            );
          }).toList(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat jadwal. Coba lagi.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fetchSchedule,
                child: const Text('Muat Ulang'),
              )
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      child: ListView(
        children: _daysOrder.map((day) {
          final list = _schedule[day] ?? [];
          return HomeSectionAnime(
            title: day,
            onSeeAll: () {
              final list = _schedule[day] ?? [];
              PersistentNavBarNavigator.pushNewScreen(
                context,
                screen: AnimeGridScreen(
                  title: 'Jadwal $day',
                  gridType: AnimeGridType.schedule,
                  scheduleDay: day,
                  animeList: list,
                ),
                withNavBar: true,
                pageTransitionAnimation: PageTransitionAnimation.cupertino,
              );
            },
            animeList: list,
          );
        }).toList(),
      ),
    );
  }
}
