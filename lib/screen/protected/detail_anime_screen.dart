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
import '../../models/anime_model.dart';
import '../../widgets/skeleton_components.dart';

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
  List<AnimeModel> similarAnime = [];
  bool isLoadingSimilar = false;

  @override
  void initState() {
    super.initState();
    _loadAnimeData();
  }

  Future<void> _loadSimilarAnime() async {
    try {
      setState(() => isLoadingSimilar = true);
      // Prefer fetching by first genre if available, otherwise use recommended list
      List<AnimeModel> fetched;
      final genres = animeDetail?.genreAnime ?? [];
      if (genres.isNotEmpty) {
        fetched = await AnimeService.getAnimeByGenre(genres.first);
      } else {
        fetched = await AnimeService.getRecommendedAnime();
      }

      // Filter out current anime and limit to a handful
      final filtered = fetched
          .where((a) => a.id != widget.animeId)
          .take(12)
          .toList();

      if (mounted) {
        setState(() {
          similarAnime = filtered;
          isLoadingSimilar = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingSimilar = false);
    }
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
        await _loadSimilarAnime();
      } else {
        // Load only anime detail and episodes if not logged in
        await Future.wait([_loadAnimeDetail(), _loadEpisodes()]);
        await _loadSimilarAnime();
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
    // similarAnime is prepared asynchronously

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

              // Rekomendasi Serupa (match HomeSection header style)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Rekomendasi Serupa',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (isLoadingSimilar)
                const AnimeListSkeleton(itemCount: 3, cardHeight: 300)
              else if (similarAnime.isNotEmpty)
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: similarAnime.length,
                    itemBuilder: (context, index) {
                      final rec = similarAnime[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailAnimeScreen(animeId: rec.id),
                            ),
                          );
                        },
                        child: Container(
                          width: 170,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade900,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.pinkAccent.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 0),
                                spreadRadius: 0,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey.shade800.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image with overlays (views, rating, status)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.network(
                                      rec.gambarAnime,
                                      width: 170,
                                      height: 130,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 170,
                                          height: 130,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.grey.shade800,
                                                Colors.grey.shade700,
                                              ],
                                            ),
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(16),
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.image_not_supported,
                                            color: Colors.white54,
                                            size: 40,
                                          ),
                                        );
                                      },
                                    ),
                                  ),

                                  // Gradient overlay
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.8),
                                          ],
                                          stops: const [0.5, 1.0],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Views badge
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.remove_red_eye,
                                            size: 14,
                                            color: Colors.blue.shade300,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rec.formattedViews,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Rating badge
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.shade600,
                                            Colors.orange.shade600,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.amber.shade400,
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber.withOpacity(0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.star,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            rec.ratingAnime,
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Status badge at bottom right of image
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.pinkAccent.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        rec.statusAnime,
                                        style: GoogleFonts.poppins(
                                          color: Colors.pinkAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Content area
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        rec.namaAnime,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          height: 1.3,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (rec.sinopsisAnime.isNotEmpty)
                                        Text(
                                          rec.sinopsisAnime,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey.shade400,
                                            fontSize: 11,
                                            height: 1.4,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      // Genre chips (limit 3) with rotating colors like HomeSectionAnime
                                      Builder(builder: (context) {
                                        final displayGenres = rec.genreAnime.take(3).toList();
                                        final colors = [
                                          Colors.blue.shade600,
                                          Colors.purple.shade600,
                                          Colors.green.shade600,
                                        ];
                                        final borderColors = [
                                          Colors.blue.shade400,
                                          Colors.purple.shade400,
                                          Colors.green.shade400,
                                        ];
                                        return Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: displayGenres.asMap().entries.map((entry) {
                                            final idx = entry.key;
                                            final genre = entry.value;
                                            return Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    colors[idx % colors.length],
                                                    colors[idx % colors.length].withOpacity(0.8),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: borderColors[idx % borderColors.length]
                                                      .withOpacity(0.6),
                                                  width: 1,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: colors[idx % colors.length]
                                                        .withOpacity(0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (idx == 0) ...[
                                                    Icon(
                                                      Icons.category,
                                                      size: 12,
                                                      color: Colors.white.withOpacity(0.9),
                                                    ),
                                                    const SizedBox(width: 4),
                                                  ],
                                                  Text(
                                                    genre,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              ,

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
