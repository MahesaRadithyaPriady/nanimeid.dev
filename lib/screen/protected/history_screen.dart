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

                  // Group by anime_id
                  final Map<int, List<EpisodeProgressModel>> grouped = {};
                  for (final p in data) {
                    final animeId = p.episode.anime?.id ?? 0;
                    grouped.putIfAbsent(animeId, () => <EpisodeProgressModel>[]).add(p);
                  }
                  final groups = grouped.entries.toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groups.length,
                    itemBuilder: (context, index) {
                      final entry = groups[index];
                      final animeGroup = entry.value;
                      // sort episodes by nomorEpisode
                      animeGroup.sort((a, b) => a.episode.nomorEpisode.compareTo(b.episode.nomorEpisode));
                      final first = animeGroup.first;
                      final anime = first.episode.anime;
                      final imageUrl = (anime?.gambarAnime.isNotEmpty == true)
                          ? anime!.gambarAnime
                          : (first.episode.thumbnailEpisode.isNotEmpty
                              ? first.episode.thumbnailEpisode
                              : '');
                      final title = anime?.namaAnime.isNotEmpty == true
                          ? anime!.namaAnime
                          : 'Tanpa Judul';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D0D0D),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            splashColor: Colors.white10,
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            collapsedIconColor: Colors.white70,
                            iconColor: Colors.white,
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover)
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      color: Colors.white10,
                                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white38),
                                    ),
                            ),
                            title: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${animeGroup.length} episode',
                              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                            ),
                            childrenPadding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
                            children: [
                              for (final progress in animeGroup)
                                _EpisodeRow(progress: progress),
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

class _EpisodeRow extends StatelessWidget {
  final EpisodeProgressModel progress;
  const _EpisodeRow({required this.progress});

  @override
  Widget build(BuildContext context) {
    final episode = progress.episode;
    final percentage = (progress.progressPercentage * 100).toInt();
    return InkWell(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (_) => WatchAnimeScreen(episodeId: episode.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Episode ${episode.nomorEpisode}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '· ${progress.progressStatus}',
                  style: GoogleFonts.poppins(
                    color: Colors.pinkAccent,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                Text(
                  progress.formattedProgressTime,
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
                )
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.progressPercentage,
                minHeight: 8,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
