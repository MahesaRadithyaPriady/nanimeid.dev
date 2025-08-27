import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'watch_anime_screen.dart';
import '../../models/anime_detail_model.dart';
import '../../models/episode_model.dart';
import '../../models/episode_progress_model.dart';
import '../../services/anime_service.dart';
import '../../services/auth_service.dart';
import '../../services/favorite_service.dart';

class DetailAnimeScreen extends StatefulWidget {
  final int animeId;
  final Map<String, dynamic>? animeData; // For backward compatibility

  const DetailAnimeScreen({super.key, required this.animeId, this.animeData});

  @override
  State<DetailAnimeScreen> createState() => _DetailAnimeScreenState();
}

class _DetailAnimeScreenState extends State<DetailAnimeScreen> {
  AnimeDetailModel? animeDetail;
  List<EpisodeModel> episodes = [];
  List<EpisodeProgressModel> episodeProgress = [];
  int _progressPercentage = 0;
  bool isLoadingDetail = true;
  bool isLoadingEpisodes = true;
  bool isLoadingProgress = true;
  String? errorMessage;
  bool isFavorite = false;
  bool isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadAnimeData();
  }

  Future<void> _loadAnimeData() async {
    try {
      setState(() {
        isLoadingDetail = true;
        isLoadingEpisodes = true;
        isLoadingProgress = true;
        errorMessage = null;
      });

      // Check if user is logged in before loading progress
      final isLoggedIn = await AuthService.isLoggedIn();

      if (isLoggedIn) {
        // Load anime detail, episodes, progress, and favorite status concurrently
        await Future.wait([
          _loadAnimeDetail(),
          _loadEpisodes(),
          _loadEpisodeProgress(),
          _loadFavoriteStatus(),
        ]);
      } else {
        // Load only anime detail and episodes if not logged in
        await Future.wait([_loadAnimeDetail(), _loadEpisodes()]);
        setState(() {
          isLoadingProgress = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoadingDetail = false;
        isLoadingEpisodes = false;
        isLoadingProgress = false;
      });
    }
  }

  Future<void> _loadAnimeDetail() async {
    try {
      final detail = await AnimeService.getAnimeDetail(widget.animeId);
      setState(() {
        animeDetail = detail;
        isLoadingDetail = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat detail anime: $e';
        isLoadingDetail = false;
      });
    }
  }

  Future<void> _loadEpisodes() async {
    try {
      final episodeList = await AnimeService.getEpisodesByAnimeId(
        widget.animeId,
      );
      setState(() {
        episodes = episodeList;
        isLoadingEpisodes = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Gagal memuat episode: $e';
        isLoadingEpisodes = false;
      });
    }
  }

  Future<void> _loadEpisodeProgress() async {
    try {
      final progressPercentage = await AnimeService.getTotalProgressPercentage(
        widget.animeId,
      );
      setState(() {
        // Store progress percentage for later use
        _progressPercentage = progressPercentage;
        isLoadingProgress = false;
      });
    } catch (e) {
      setState(() {
        // Don't show error for progress, just set to 0
        // But log the error for debugging
        print('Progress loading error: $e');
        _progressPercentage = 0;
        isLoadingProgress = false;
      });
    }
  }

  // Loading screen with skeleton
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image skeleton
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(color: Colors.grey.shade800),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.pinkAccent),
                ),
              ),
              const SizedBox(height: 12),

              // Title skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 24,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: List.generate(
                    4,
                    (index) => Container(
                      margin: const EdgeInsets.only(right: 16),
                      height: 16,
                      width: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Progress skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Synopsis skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 16,
                      width: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Terjadi Kesalahan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  errorMessage ?? 'Gagal memuat data anime',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadAnimeData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onFavoritePressed() async {
    if (isTogglingFavorite) return;
    setState(() => isTogglingFavorite = true);
    try {
      bool ok = false;
      if (isFavorite) {
        // Already favorited -> delete
        ok = await FavoriteService.deleteAnimeFavorite(widget.animeId);
        if (ok) {
          setState(() => isFavorite = false);
        }
      } else {
        // Not favorited -> add
        ok = await FavoriteService.toggleAnimeFavorite(widget.animeId);
        if (ok) {
          setState(() => isFavorite = true);
        }
      }
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Status favorit diperbarui'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menambahkan ke favorit'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isTogglingFavorite = false);
    }
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final status = await FavoriteService.getAnimeFavoriteStatus(widget.animeId);
      if (mounted) {
        setState(() {
          isFavorite = status;
        });
      }
    } catch (e) {
      // ignore error silently, keep default false
      // print('Favorite status error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading skeleton if still loading
    if (isLoadingDetail) {
      return _buildLoadingScreen();
    }

    // Show error screen if there's an error
    if (errorMessage != null) {
      return _buildErrorScreen();
    }

    // Use animeDetail if available, otherwise fallback to animeData
    final anime = animeDetail?.toMap() ?? widget.animeData ?? {};
    // Use progress percentage from API
    double progress =
        _progressPercentage / 100.0; // Convert percentage to decimal
    final List<String> facts =
        animeDetail?.faktaMenarik ??
        [
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
                    IconButton(
                      onPressed: isTogglingFavorite ? null : _onFavoritePressed,
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.pinkAccent : Colors.white70,
                      ),
                    ),
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
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children:
                      animeDetail?.tagsAnime
                          .take(3)
                          .map((tag) => _buildBadge(tag))
                          .toList() ??
                      [_buildBadge('🔥 Top 10'), _buildBadge('🆕 New Season')],
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
                    Text(
                      '$_progressPercentage% Selesai',
                      style: _smallTextStyle(),
                    ),
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
                          // Get first episode ID if available
                          if (episodes.isNotEmpty) {
                            final firstEpisode = episodes.first;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WatchAnimeScreen(
                                  episodeId: firstEpisode.id,
                                ),
                              ),
                            );
                          } else {
                            // Show error if no episodes available
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Belum ada episode tersedia'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
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
              if (isLoadingEpisodes)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 5,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade800,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const SizedBox(width: 60, height: 16),
                      );
                    },
                  ),
                )
              else if (episodes.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: episodes.length,
                    itemBuilder: (context, index) {
                      final episode = episodes[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WatchAnimeScreen(episodeId: episode.id),
                            ),
                          );
                        },
                        child: Container(
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
                              'Episode ${episode.nomorEpisode}',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Belum ada episode tersedia',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
