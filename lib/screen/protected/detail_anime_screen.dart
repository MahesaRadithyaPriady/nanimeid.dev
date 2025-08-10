import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'watch_anime_screen.dart';


class DetailAnimeScreen extends StatelessWidget {
  final Map<String, dynamic> anime;

  const DetailAnimeScreen({super.key, required this.anime});

  @override
  Widget build(BuildContext context) {
    final double progress = 8 / 12;
    final List<String> episodes = List.generate(12, (i) => 'Episode ${i + 1}');
    final List<String> facts = [
      'Adaptasi dari manga karya ABC',
      'Studio: CloverWorks',
      'Opening song trending di TikTok',
    ];
    final List<Map<String, dynamic>> recommendations = [
      {
        'title': 'Kubo Won’t Let Me Be Invisible',
        'image':
            'https://a.storyblok.com/f/178900/1414x2000/38661856b0/the-shiunji-family-children-ouka-date-visual.jpg/m/filters:quality(95)format(webp)',
        'releaseDate': 'Jan 2023',
        'genre': 'Romance, Comedy',
      },
      {
        'title': 'My Dress-Up Darling',
        'image':
            'https://a.storyblok.com/f/178900/1414x2000/38661856b0/the-shiunji-family-children-ouka-date-visual.jpg/m/filters:quality(95)format(webp)',
        'releaseDate': 'Winter 2022',
        'genre': 'Romance, Slice of Life',
      },
      {
        'title': 'Horimiya',
        'image':
            'https://a.storyblok.com/f/178900/1414x2000/38661856b0/the-shiunji-family-children-ouka-date-visual.jpg/m/filters:quality(95)format(webp)',
        'releaseDate': 'Spring 2021',
        'genre': 'Drama, Romance',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Stack(
                children: [
                  Image.network(
                    anime['image'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Judul dan aksi
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        anime['title'],
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(Icons.favorite_border, color: Colors.white70),
                    const SizedBox(width: 12),
                    const Icon(Icons.bookmark_border, color: Colors.white70),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    _buildBadge('🔥 Top 10'),
                    const SizedBox(width: 8),
                    _buildBadge('🆕 New Season'),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Info ringkas
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildInfoIcon(
                      Icons.star,
                      '${anime['rating']}',
                      Colors.amber,
                    ),
                    _buildInfoIcon(
                      Icons.remove_red_eye,
                      anime['views'],
                      Colors.white,
                    ),
                    _buildInfoIcon(
                      LucideIcons.calendar,
                      anime['releaseDate'] ?? 'Unknown',
                      Colors.white,
                    ),
                    _buildInfoIcon(
                      LucideIcons.badgeCheck,
                      anime['status'],
                      Colors.pinkAccent,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Genre
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.film,
                      size: 14,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        anime['genre'],
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Progress Menonton', style: _sectionTitleStyle()),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.pinkAccent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('8 / 12 Episode', style: _smallTextStyle()),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sinopsis
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Sinopsis', style: _sectionTitleStyle()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                child: Text(
                  anime['synopsis'],
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),

              // Tombol tonton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WatchAnimeScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Tonton Sekarang'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.bookmark_add, color: Colors.white),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Episode list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Daftar Episode', style: _sectionTitleStyle()),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: episodes.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.pinkAccent.withOpacity(0.4),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          episodes[index],
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Fakta Menarik
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Fakta Menarik', style: _sectionTitleStyle()),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: facts.map((fact) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(color: Colors.white70),
                          ),
                          Expanded(
                            child: Text(
                              fact,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // Rekomendasi Serupa
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Rekomendasi Serupa', style: _sectionTitleStyle()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: recommendations.length,
                  itemBuilder: (context, index) {
                    final rec = recommendations[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.network(
                              rec['image'],
                              width: 140,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              rec['title'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.calendar,
                                  color: Colors.white54,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    rec['releaseDate'] ?? "TBA",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.film,
                                  color: Colors.white54,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    rec['genre'] ?? "Genre tidak tersedia",
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
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

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionTitleStyle() => GoogleFonts.poppins(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  TextStyle _smallTextStyle() =>
      GoogleFonts.poppins(color: Colors.white70, fontSize: 12);

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.pinkAccent.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: Colors.pinkAccent,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildInfoIcon(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
