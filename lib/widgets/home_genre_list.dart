import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeGenreList extends StatelessWidget {
  final List<String> genres;
  final void Function(String) onGenreTap;

  const HomeGenreList({
    super.key,
    required this.genres,
    required this.onGenreTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: genres.length,
        itemBuilder: (context, index) {
          final genre = genres[index];
          return GestureDetector(
            onTap: () => onGenreTap(genre),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.pinkAccent, width: 1),
              ),
              child: Text(
                genre,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}
