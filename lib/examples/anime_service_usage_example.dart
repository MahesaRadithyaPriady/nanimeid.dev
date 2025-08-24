import 'package:flutter/material.dart';
import '../services/anime_service.dart';
import '../models/anime_detail_model.dart';
import '../models/episode_model.dart';

class AnimeServiceUsageExample extends StatefulWidget {
  const AnimeServiceUsageExample({super.key});

  @override
  State<AnimeServiceUsageExample> createState() => _AnimeServiceUsageExampleState();
}

class _AnimeServiceUsageExampleState extends State<AnimeServiceUsageExample> {
  AnimeDetailModel? animeDetail;
  List<EpisodeModel> episodes = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnimeData();
  }

  Future<void> _loadAnimeData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Load anime detail and episodes concurrently
      final results = await Future.wait([
        AnimeService.getAnimeDetail(1), // Example anime ID
        AnimeService.getEpisodesByAnimeId(1),
      ]);

      setState(() {
        animeDetail = results[0] as AnimeDetailModel;
        episodes = results[1] as List<EpisodeModel>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime Service Usage Example'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $errorMessage'),
                      ElevatedButton(
                        onPressed: _loadAnimeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (animeDetail != null) ...[
                        _buildAnimeDetailSection(),
                        const SizedBox(height: 24),
                      ],
                      if (episodes.isNotEmpty) ...[
                        _buildEpisodesSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildServiceMethodsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAnimeDetailSection() {
    final anime = animeDetail!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anime Detail',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('ID: ${anime.id}'),
            Text('Title: ${anime.namaAnime}'),
            Text('Rating: ${anime.ratingAnime}'),
            Text('Views: ${anime.formattedViews}'),
            Text('Status: ${anime.statusAnime}'),
            Text('Genres: ${anime.genreAnime.join(', ')}'),
            Text('Studios: ${anime.studioAnime.join(', ')}'),
            Text('Facts: ${anime.faktaMenarik.join(', ')}'),
          ],
        ),
      ),
    );
  }

  Widget _buildEpisodesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Episodes (${episodes.length})',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...episodes.take(5).map((episode) => ListTile(
              title: Text(episode.judulEpisode),
              subtitle: Text('Episode ${episode.nomorEpisode} - ${episode.formattedDuration}'),
              trailing: Text('${episode.qualities.length} qualities'),
            )),
            if (episodes.length > 5)
              Text('... and ${episodes.length - 5} more episodes'),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceMethodsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Service Methods',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildMethodButton(
              'Get Latest Episode',
              () async {
                try {
                  final latest = await AnimeService.getLatestEpisode(1);
                  _showResult('Latest Episode', latest?.judulEpisode ?? 'No episodes found');
                } catch (e) {
                  _showResult('Error', e.toString());
                }
              },
            ),
            _buildMethodButton(
              'Get First Episode',
              () async {
                try {
                  final first = await AnimeService.getFirstEpisode(1);
                  _showResult('First Episode', first?.judulEpisode ?? 'No episodes found');
                } catch (e) {
                  _showResult('Error', e.toString());
                }
              },
            ),
            _buildMethodButton(
              'Get Episode Statistics',
              () async {
                try {
                  final stats = await AnimeService.getEpisodeStatistics(1);
                  _showResult('Statistics', stats.toString());
                } catch (e) {
                  _showResult('Error', e.toString());
                }
              },
            ),
            _buildMethodButton(
              'Get Episodes with 720p Quality',
              () async {
                try {
                  final episodes720p = await AnimeService.getEpisodesWithQuality(1, '720p');
                  _showResult('720p Episodes', '${episodes720p.length} episodes found');
                } catch (e) {
                  _showResult('Error', e.toString());
                }
              },
            ),
            _buildMethodButton(
              'Search Episodes',
              () async {
                try {
                  final searchResults = await AnimeService.searchEpisodes(1, 'petualangan');
                  _showResult('Search Results', '${searchResults.length} episodes found');
                } catch (e) {
                  _showResult('Error', e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton(String title, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
        ),
        child: Text(title),
      ),
    );
  }

  void _showResult(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// Example of how to use the service in a widget
class AnimeDetailWidget extends StatelessWidget {
  final int animeId;

  const AnimeDetailWidget({super.key, required this.animeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AnimeDetailModel>(
      future: AnimeService.getAnimeDetail(animeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No data available'));
        }

        final anime = snapshot.data!;
        return Card(
          child: ListTile(
            leading: Image.network(
              anime.gambarAnime,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            ),
            title: Text(anime.namaAnime),
            subtitle: Text('Rating: ${anime.ratingAnime}'),
            trailing: Text(anime.statusAnime),
          ),
        );
      },
    );
  }
}

// Example of how to use episodes service
class EpisodesListWidget extends StatelessWidget {
  final int animeId;

  const EpisodesListWidget({super.key, required this.animeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EpisodeModel>>(
      future: AnimeService.getEpisodesByAnimeId(animeId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No episodes available'));
        }

        final episodes = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final episode = episodes[index];
            return ListTile(
              title: Text(episode.judulEpisode),
              subtitle: Text('Episode ${episode.nomorEpisode} - ${episode.formattedDuration}'),
              trailing: episode.bestQuality != null
                  ? Chip(label: Text(episode.bestQuality!.namaQuality))
                  : null,
            );
          },
        );
      },
    );
  }
}
