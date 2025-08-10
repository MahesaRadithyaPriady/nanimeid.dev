import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/home_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final watchedList = [
      {
        'title': 'Attack on Titan',
        'image': 'https://picsum.photos/600/400',
        'genre': 'Action',
        'episode': 'Episode 12',
        'sinopsis':
            'Manusia melawan para raksasa demi bertahan hidup dalam dunia penuh misteri.',
        'progress': 0.75,
      },
      {
        'title': 'Jujutsu Kaisen',
        'image': 'https://picsum.photos/600/400',
        'genre': 'Supernatural',
        'episode': 'Episode 8',
        'sinopsis':
            'Itadori Yuji terlibat dunia kutukan dan menjadi wadah dari roh terkutuk Sukuna.',
        'progress': 0.4,
      },
      {
        'title': 'Solo Leveling',
        'image': 'https://picsum.photos/600/400',
        'genre': 'Isekai',
        'episode': 'Episode 4',
        'sinopsis':
            'Hunter lemah Jin-Woo berubah menjadi hunter terkuat setelah menemukan sistem misterius.',
        'progress': 0.25,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(coinBalance: 1000, isVip: true),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Text(
                    'Riwayat Ditonton',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: watchedList.length,
                itemBuilder: (context, index) {
                  final anime = watchedList[index];
                  final progress = anime['progress'] as double;
                  final percentage = (progress * 100).toInt();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                          child: Image.network(
                            anime['image']! as String,
                            height: 140,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  anime['title']! as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  anime['genre']! as String,
                                  style: GoogleFonts.poppins(
                                    color: Colors.pinkAccent,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  anime['sinopsis']! as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: Colors.white12,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.pinkAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$percentage%',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
