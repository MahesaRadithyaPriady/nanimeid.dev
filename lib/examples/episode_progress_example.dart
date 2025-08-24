import 'package:flutter/material.dart';
import '../services/anime_service.dart';
import '../models/episode_progress_model.dart';

class EpisodeProgressExample extends StatefulWidget {
  const EpisodeProgressExample({super.key});

  @override
  State<EpisodeProgressExample> createState() => _EpisodeProgressExampleState();
}

class _EpisodeProgressExampleState extends State<EpisodeProgressExample> {
  List<EpisodeProgressModel> progressList = [];
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final progress = await AnimeService.getEpisodeProgress(
        1,
      ); // Example anime ID
      setState(() {
        progressList = progress;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });

      // Show specific message for token errors
      if (e.toString().contains('Token tidak ditemukan') ||
          e.toString().contains('Token tidak valid') ||
          e.toString().contains('Akses ditolak')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Silakan login terlebih dahulu untuk melihat progress episode',
            ),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Login',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to login screen
                // Navigator.pushNamed(context, '/login');
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Progress Example'),
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
                    onPressed: _loadProgressData,
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
                  _buildProgressStatistics(),
                  const SizedBox(height: 24),
                  _buildProgressList(),
                  const SizedBox(height: 24),
                  _buildServiceMethods(),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressStatistics() {
    if (progressList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Tidak ada data progress'),
        ),
      );
    }

    final progressResponse = EpisodeProgressResponseModel(
      status: 200,
      message: 'Success',
      data: progressList,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistik Progress',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildStatItem(
              'Total Episode',
              '${progressResponse.totalEpisodes}',
            ),
            _buildStatItem(
              'Episode Selesai',
              '${progressResponse.totalCompletedEpisodes}',
            ),
            _buildStatItem(
              'Sedang Ditonton',
              '${progressResponse.partiallyWatchedEpisodes.length}',
            ),
            _buildStatItem(
              'Belum Ditonton',
              '${progressResponse.notStartedEpisodes.length}',
            ),
            _buildStatItem(
              'Progress Total',
              '${(progressResponse.totalProgressPercentage * 100).toStringAsFixed(1)}%',
            ),
            _buildStatItem(
              'Total Waktu Tonton',
              progressResponse.formattedTotalWatchTime,
            ),
            if (progressResponse.latestWatchedEpisode != null)
              _buildStatItem(
                'Episode Terakhir',
                'Episode ${progressResponse.latestWatchedEpisode!.episode.nomorEpisode}',
              ),
            if (progressResponse.nextEpisodeToWatch != null)
              _buildStatItem(
                'Episode Selanjutnya',
                'Episode ${progressResponse.nextEpisodeToWatch!.episode.nomorEpisode}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.pinkAccent)),
        ],
      ),
    );
  }

  Widget _buildProgressList() {
    if (progressList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Progress Episode',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ...progressList.map((progress) => _buildProgressItem(progress)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(EpisodeProgressModel progress) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: progress.isCompleted
              ? Colors.green
              : progress.isPartiallyWatched
              ? Colors.orange
              : Colors.grey,
          child: Text(
            '${progress.episode.nomorEpisode}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(progress.episode.judulEpisode),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${progress.progressStatus}'),
            if (progress.isPartiallyWatched)
              Text('Progress: ${progress.formattedProgressTime}'),
            Text('Terakhir ditonton: ${progress.formattedLastWatched}'),
          ],
        ),
        trailing: progress.isPartiallyWatched
            ? LinearProgressIndicator(
                value: progress.progressPercentage,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
              )
            : null,
      ),
    );
  }

  Widget _buildServiceMethods() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Methods',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildMethodButton('Get Progress Statistics', () async {
              try {
                final stats = await AnimeService.getEpisodeProgressStatistics(
                  1,
                );
                _showResult('Progress Statistics', stats.toString());
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Get Progress by Episode 1', () async {
              try {
                final progress = await AnimeService.getProgressByEpisodeNumber(
                  1,
                  1,
                );
                _showResult(
                  'Episode 1 Progress',
                  progress?.progressStatus ?? 'No progress',
                );
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Get Latest Watched Episode', () async {
              try {
                final latest =
                    await AnimeService.getLatestWatchedEpisodeProgress(1);
                _showResult(
                  'Latest Watched',
                  latest?.episode.judulEpisode ?? 'No data',
                );
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Get Next Episode to Watch', () async {
              try {
                final next = await AnimeService.getNextEpisodeToWatchProgress(
                  1,
                );
                _showResult(
                  'Next Episode',
                  next?.episode.judulEpisode ?? 'No data',
                );
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Get Completed Episodes', () async {
              try {
                final completed =
                    await AnimeService.getCompletedEpisodesProgress(1);
                _showResult(
                  'Completed Episodes',
                  '${completed.length} episodes',
                );
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Get Partially Watched Episodes', () async {
              try {
                final partial =
                    await AnimeService.getPartiallyWatchedEpisodesProgress(1);
                _showResult('Partially Watched', '${partial.length} episodes');
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Get Total Watch Time', () async {
              try {
                final watchTime = await AnimeService.getTotalWatchTime(1);
                _showResult('Total Watch Time', watchTime);
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
            _buildMethodButton('Check Has Progress', () async {
              try {
                final hasProgress = await AnimeService.hasEpisodeProgress(1);
                _showResult('Has Progress', hasProgress.toString());
              } catch (e) {
                _showResult('Error', e.toString());
              }
            }),
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
        content: SingleChildScrollView(child: Text(message)),
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

// Example widget for displaying episode progress
class EpisodeProgressWidget extends StatelessWidget {
  final int animeId;

  const EpisodeProgressWidget({super.key, required this.animeId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<EpisodeProgressModel>>(
      future: AnimeService.getEpisodeProgress(animeId),
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
          return const Center(child: Text('Tidak ada progress episode'));
        }

        final progressList = snapshot.data!;
        final progressResponse = EpisodeProgressResponseModel(
          status: 200,
          message: 'Success',
          data: progressList,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar
            LinearProgressIndicator(
              value: progressResponse.totalProgressPercentage,
              backgroundColor: Colors.grey.shade300,
              valueColor: const AlwaysStoppedAnimation(Colors.pinkAccent),
            ),
            const SizedBox(height: 8),
            Text(
              '${progressResponse.totalCompletedEpisodes} / ${progressResponse.totalEpisodes} Episode selesai',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Progress list
            ...progressList.map(
              (progress) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: progress.isCompleted
                      ? Colors.green
                      : progress.isPartiallyWatched
                      ? Colors.orange
                      : Colors.grey,
                  child: Text(
                    '${progress.episode.nomorEpisode}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(progress.episode.judulEpisode),
                subtitle: Text(progress.progressStatus),
                trailing: progress.isPartiallyWatched
                    ? Text(progress.formattedProgressTime)
                    : null,
              ),
            ),
          ],
        );
      },
    );
  }
}
