import 'package:flutter/material.dart';
import '../services/episode_service.dart';
import '../models/episode_detail_model.dart';

class EpisodeServiceUsageExample extends StatefulWidget {
  const EpisodeServiceUsageExample({super.key});

  @override
  State<EpisodeServiceUsageExample> createState() =>
      _EpisodeServiceUsageExampleState();
}

class _EpisodeServiceUsageExampleState
    extends State<EpisodeServiceUsageExample> {
  EpisodeDetailModel? episodeDetail;
  bool isLoading = false;
  String? errorMessage;
  int episodeId = 4; // Example episode ID

  @override
  void initState() {
    super.initState();
    _loadEpisodeDetail();
  }

  Future<void> _loadEpisodeDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final detail = await EpisodeService.getEpisodeDetail(episodeId);
      setState(() {
        episodeDetail = detail;
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
        title: const Text('Episode Service Example'),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? _buildErrorWidget()
          : episodeDetail != null
          ? _buildEpisodeDetailWidget()
          : const Center(child: Text('No data available')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error: $errorMessage',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadEpisodeDetail,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeDetailWidget() {
    final episode = episodeDetail!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Episode thumbnail
          if (episode.thumbnailEpisode.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                episode.thumbnailEpisode,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // Episode title
          Text(
            episode.judulEpisode,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // Episode info
          Row(
            children: [
              Icon(Icons.play_circle_outline, color: Colors.pinkAccent),
              const SizedBox(width: 8),
              Text(
                'Episode ${episode.nomorEpisode}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                episode.formattedDuration,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Anime info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Anime Info',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Title: ${episode.anime.namaAnime}'),
                  Text('Genres: ${episode.anime.genreAnime.join(', ')}'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Episode description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(episode.deskripsiEpisode),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Available qualities
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Qualities',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: episode.availableQualityNames.map((quality) {
                      return Chip(
                        label: Text(quality),
                        backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                        labelStyle: TextStyle(color: Colors.pinkAccent),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Best quality info
          if (episode.bestQuality != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Best Quality',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Quality: ${episode.bestQuality!.namaQuality}'),
                    Text(
                      'Source: ${episode.bestQuality!.sourceQuality}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Release date
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Release Info',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Release Date: ${episode.formattedReleaseDate}'),
                  if (episode.isRecentlyReleased)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Recently Released',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showVideoSource(episode.bestQuality?.sourceQuality),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Play Best Quality'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showQualitySelector(episode),
                  icon: const Icon(Icons.settings),
                  label: const Text('Select Quality'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showVideoSource(String? source) {
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No video source available')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Source'),
        content: SelectableText(source),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showQualitySelector(EpisodeDetailModel episode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: episode.qualities.map((quality) {
            return ListTile(
              title: Text(quality.namaQuality),
              subtitle: Text(quality.sourceQuality),
              onTap: () {
                Navigator.pop(context);
                _showVideoSource(quality.sourceQuality);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
