import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/home_header.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoriteList = [
      {
        'title': 'Naruto',
        'image': 'https://picsum.photos/600/400',
        'genre': 'Ninja',
        'synopsis': 'Perjalanan Naruto menjadi Hokage dan diakui oleh desanya.',
        'dateAdded': '12 Juli 2025',
      },
      {
        'title': 'One Piece',
        'image': 'https://picsum.photos/600/400',
        'genre': 'Adventure',
        'synopsis': 'Petualangan Luffy dan kru topi jerami mencari One Piece.',
        'dateAdded': '18 Juli 2025',
      },
      {
        'title': 'Demon Slayer',
        'image': 'https://picsum.photos/600/400',
        'genre': 'Action',
        'synopsis':
            'Tanjiro menjadi pembasmi iblis demi menyelamatkan adiknya.',
        'dateAdded': '27 Juli 2025',
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
                    'Favorit Saya',
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
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                ),
                itemCount: favoriteList.length,
                itemBuilder: (context, index) {
                  final anime = favoriteList[index];

                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            anime['image']!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                anime['title']!,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                anime['genre']!,
                                style: GoogleFonts.poppins(
                                  color: Colors.pinkAccent,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                anime['synopsis']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Ditambahkan: ${anime['dateAdded']!}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
