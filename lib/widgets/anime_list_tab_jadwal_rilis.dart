import 'package:flutter/material.dart';
import '../../widgets/home_section_anime.dart';

class JadwalRilisTab extends StatelessWidget {
  const JadwalRilisTab({super.key});

  @override
  Widget build(BuildContext context) {
    final jadwalRilis = {
      'Senin': [
        {
          'title': 'Blue Lock',
          'image': 'https://picsum.photos/600/400',
          'genre': 'Sports',
          'status': 'Ongoing',
          'rating': 8.5,
          'views': '1.2M',
          'releaseDate': 'Senin',
        },
        {
          'title': 'One Piece',
          'image': 'https://picsum.photos/600/400',
          'genre': 'Adventure',
          'status': 'Ongoing',
          'rating': 9.2,
          'views': '3.5M',
          'releaseDate': 'Senin',
        },
      ],
      'Selasa': [
        {
          'title': 'Solo Leveling',
          'image': 'https://picsum.photos/600/400',
          'genre': 'Isekai',
          'status': 'Completed',
          'rating': 8.9,
          'views': '2.1M',
          'releaseDate': 'Selasa',
        },
      ],
      'Rabu': [
        {
          'title': 'Jujutsu Kaisen',
          'image': 'https://picsum.photos/600/400',
          'genre': 'Supernatural',
          'status': 'Ongoing',
          'rating': 8.8,
          'views': '2.4M',
          'releaseDate': 'Rabu',
        },
        {
          'title': 'Boruto: Next Gen',
          'image': 'https://picsum.photos/600/400',
          'genre': 'Ninja',
          'status': 'Ongoing',
          'rating': 7.1,
          'views': '1.3M',
          'releaseDate': 'Rabu',
        },
        {
          'title': 'My Hero Academia',
          'image': 'https://picsum.photos/600/400',
          'genre': 'Superhero',
          'status': 'Ongoing',
          'rating': 8.0,
          'views': '1.8M',
          'releaseDate': 'Rabu',
        },
      ],
      // Tambahkan hari lain jika perlu
    };

    return Container(
      color: const Color(0xFF101014),
      child: ListView(
        children: jadwalRilis.entries.map((entry) {
          final day = entry.key;
          final animes = entry.value;

          return HomeSectionAnime(
            title: day,
            onSeeAll: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lihat semua anime hari $day')),
              );
            },
            animeList: animes,
          );
        }).toList(),
      ),
    );
  }
}
