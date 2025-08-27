import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

import '../../models/anime_model.dart';
import '../../services/anime_service.dart';
import 'detail_anime_screen.dart';

enum AnimeGridType { popular, latest, movie, recommended, schedule, genre }

class AnimeGridScreen extends StatefulWidget {
  final String title;
  final AnimeGridType gridType;
  final List<AnimeModel> animeList; // initial list if already available
  final String? scheduleDay; // used when gridType is schedule
  final String? genre; // used when gridType is genre

  const AnimeGridScreen({
    super.key,
    required this.title,
    required this.gridType,
    this.animeList = const [],
    this.scheduleDay,
    this.genre,
  });

  @override
  State<AnimeGridScreen> createState() => _AnimeGridScreenState();
}

class _AnimeGridScreenState extends State<AnimeGridScreen> {
  List<AnimeModel> items = const [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Start with any provided items to avoid blank screen
    if (widget.animeList.isNotEmpty) {
      items = widget.animeList;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      List<AnimeModel> fetched;
      switch (widget.gridType) {
        case AnimeGridType.popular:
          fetched = await AnimeService.getPopularAnime();
          break;
        case AnimeGridType.latest:
          fetched = await AnimeService.getLatestAnime();
          break;
        case AnimeGridType.movie:
          fetched = await AnimeService.getAnimeMovies();
          break;
        case AnimeGridType.recommended:
          fetched = await AnimeService.getRecommendedAnime();
          break;
        case AnimeGridType.schedule:
          final schedule = await AnimeService.getAnimeSchedule(limitPerDay: 50);
          final day = widget.scheduleDay;
          if (day != null && schedule.data.containsKey(day)) {
            fetched = schedule.data[day] ?? [];
          } else {
            // If no specific day provided, flatten all days
            fetched = schedule.data.values.expand((e) => e).toList();
          }
          break;
        case AnimeGridType.genre:
          final selected = widget.genre;
          if (selected == null || selected.isEmpty) {
            throw Exception('Genre tidak valid');
          }
          fetched = await AnimeService.getAnimeByGenrePath(selected);
          break;
      }
      setState(() {
        items = fetched;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        final msg = e.toString();
        // Remove technical prefix like 'Exception: '
        errorMessage = msg.replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent),
              )
            : errorMessage != null
            ? Center(
                child: Text(
                  errorMessage!,
                  style: GoogleFonts.poppins(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              )
            : items.isEmpty
            ? Center(
                child: Text(
                  'Tidak ada data',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 200,
                  mainAxisExtent: 245,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final anime = items[index];
                  return _AnimeGridCard(anime: anime);
                },
              ),
      ),
    );
  }
}

class _AnimeGridCard extends StatelessWidget {
  final AnimeModel anime;

  const _AnimeGridCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        PersistentNavBarNavigator.pushNewScreen(
          context,
          screen: DetailAnimeScreen(
            animeId: anime.id,
            animeData: anime.toMap(),
          ),
          withNavBar: false,
          pageTransitionAnimation: PageTransitionAnimation.cupertino,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade800.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with fixed height to match grid's mainAxisExtent
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Image.network(
                  anime.gambarAnime,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      anime.namaAnime,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Synopsis
                    if (anime.sinopsisAnime.isNotEmpty)
                      Text(
                        anime.sinopsisAnime,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 10.5,
                          height: 1.2,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Genres
                    if (anime.displayGenres.isNotEmpty)
                      Text(
                        anime.displayGenres.join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white60,
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Rating and Views
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  anime.ratingAnime,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                color: Colors.lightBlueAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  anime.formattedViews,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Status
                    Text(
                      anime.statusAnime,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.pinkAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
