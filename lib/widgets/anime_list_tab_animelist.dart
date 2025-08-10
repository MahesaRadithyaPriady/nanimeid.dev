import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnimeListSection extends StatelessWidget {
  final List<Map<String, String>> animeList;
  final String selectedGenre;
  final String selectedStudio;
  final String selectedAZ;
  final List<String> genreOptions;
  final List<String> studioOptions;
  final List<String> azOptions;
  final void Function(String) onGenreChanged;
  final void Function(String) onStudioChanged;
  final void Function(String) onAZChanged;

  const AnimeListSection({
    super.key,
    required this.animeList,
    required this.selectedGenre,
    required this.selectedStudio,
    required this.selectedAZ,
    required this.genreOptions,
    required this.studioOptions,
    required this.azOptions,
    required this.onGenreChanged,
    required this.onStudioChanged,
    required this.onAZChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortedAnime = List<Map<String, String>>.from(animeList);
    sortedAnime.sort(
      (a, b) => selectedAZ == 'A-Z'
          ? a['title']!.compareTo(b['title']!)
          : b['title']!.compareTo(a['title']!),
    );

    final groupedAnime = <String, List<Map<String, String>>>{};
    for (var anime in sortedAnime) {
      final firstLetter = anime['title']![0].toUpperCase();
      groupedAnime.putIfAbsent(firstLetter, () => []).add(anime);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari anime...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: buildDropdown(
                    genreOptions,
                    selectedGenre,
                    onGenreChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 100,
                  child: buildDropdown(
                    studioOptions,
                    selectedStudio,
                    onStudioChanged,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: buildDropdown(azOptions, selectedAZ, onAZChanged),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: groupedAnime.keys.length,
              itemBuilder: (context, index) {
                final letter = groupedAnime.keys.elementAt(index);
                final animes = groupedAnime[letter]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      letter,
                      style: GoogleFonts.poppins(
                        color: Colors.pinkAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...animes.map(
                      (anime) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                anime['image']!,
                                width: 80,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    anime['title']!,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.tags,
                                        size: 14,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        anime['genre']!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                        LucideIcons.clock,
                                        size: 14,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        anime['status']!,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        LucideIcons.fileText,
                                        size: 14,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          anime['sinopsis']!,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white60,
                                            fontSize: 12,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              LucideIcons.chevronRight,
                              color: Colors.white30,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdown(
    List<String> items,
    String value,
    Function(String) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: const Color(0xFF1E1E2C),
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          isExpanded: true,
          items: items
              .map(
                (item) => DropdownMenuItem(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}
