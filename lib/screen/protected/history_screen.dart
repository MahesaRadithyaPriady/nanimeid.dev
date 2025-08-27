import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/home_header.dart';
import '../../services/anime_service.dart';
import '../../models/episode_progress_model.dart';
import 'watch_anime_screen.dart';
import '../../widgets/exit_confirmation.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => showExitConfirmationDialog(context),
      child: Scaffold(
        backgroundColor: Colors.black,
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
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<EpisodeProgressModel>>(
                future: AnimeService.getUserEpisodeProgress(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    final err = snapshot.error.toString();
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.redAccent),
                            const SizedBox(height: 8),
                            Text(
                              'Terjadi kesalahan:\n$err',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(color: Colors.white70),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                // Trigger rebuild
                                (context as Element);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.pinkAccent,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Coba Lagi'),
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        'Belum ada riwayat ditonton',
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      final progress = data[index];
                      final episode = progress.episode;
                      final anime = episode.anime;
                      final imageUrl = (anime?.gambarAnime.isNotEmpty == true)
                          ? anime!.gambarAnime
                          : (episode.thumbnailEpisode.isNotEmpty
                              ? episode.thumbnailEpisode
                              : '');
                      final percentage = (progress.progressPercentage * 100).toInt();

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(
                              builder: (_) => WatchAnimeScreen(
                                episodeId: episode.id,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(12),
                                ),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        height: 140,
                                        width: 120,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 140,
                                        width: 120,
                                        color: Colors.white10,
                                        child: const Icon(
                                          Icons.image_not_supported_outlined,
                                          color: Colors.white38,
                                        ),
                                      ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        anime?.namaAnime.isNotEmpty == true
                                            ? anime!.namaAnime
                                            : episode.judulEpisode,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Episode ${episode.nomorEpisode} · ${progress.progressStatus}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.poppins(
                                          color: Colors.pinkAccent,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        (anime?.sinopsisAnime.isNotEmpty == true)
                                            ? anime!.sinopsisAnime
                                            : 'Terakhir ditonton: ${progress.formattedLastWatched}',
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
                                          value: progress.progressPercentage,
                                          minHeight: 8,
                                          backgroundColor: Colors.white12,
                                          valueColor: const AlwaysStoppedAnimation<Color>(
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
