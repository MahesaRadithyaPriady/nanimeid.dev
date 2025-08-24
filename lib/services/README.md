# Anime Service Documentation

## Overview

Service ini menyediakan method untuk mengambil data anime dan episode dari API. Service ini menggunakan Dio untuk HTTP requests dan memiliki error handling yang komprehensif.

## Models

### AnimeDetailModel

Model untuk detail anime yang berisi informasi lengkap tentang anime.

**Properties:**

- `id`: ID anime
- `namaAnime`: Nama anime
- `gambarAnime`: URL gambar anime
- `tagsAnime`: List tag anime
- `ratingAnime`: Rating anime
- `viewAnime`: Jumlah view
- `tanggalRilisAnime`: Tanggal rilis
- `statusAnime`: Status anime (ongoing, completed, upcoming)
- `genreAnime`: List genre
- `sinopsisAnime`: Sinopsis anime
- `labelAnime`: Label anime
- `studioAnime`: List studio
- `faktaMenarik`: List fakta menarik

**Helper Methods:**

- `ratingAsDouble`: Rating dalam bentuk double
- `formattedViews`: View yang sudah diformat (K, M)
- `displayGenres`: Genre untuk display (maksimal 2)
- `isOngoing`, `isCompleted`, `isUpcoming`: Status check

### EpisodeModel

Model untuk episode anime.

**Properties:**

- `id`: ID episode
- `animeId`: ID anime
- `judulEpisode`: Judul episode
- `nomorEpisode`: Nomor episode
- `thumbnailEpisode`: URL thumbnail episode
- `deskripsiEpisode`: Deskripsi episode
- `durasiEpisode`: Durasi dalam menit
- `tanggalRilisEpisode`: Tanggal rilis episode
- `qualities`: List kualitas video
- `anime`: Info anime

**Helper Methods:**

- `formattedDuration`: Durasi yang sudah diformat
- `bestQuality`: Kualitas terbaik (prioritas: 1080p > 720p > 480p)
- `getQualityByName(String)`: Ambil kualitas berdasarkan nama
- `hasQuality(String)`: Cek apakah episode memiliki kualitas tertentu

### QualityModel

Model untuk kualitas video episode.

**Properties:**

- `id`: ID kualitas
- `episodeId`: ID episode
- `namaQuality`: Nama kualitas (480p, 720p, 1080p)
- `sourceQuality`: URL video

### EpisodeProgressModel

Model untuk progress episode user.

**Properties:**

- `id`: ID progress
- `userId`: ID user
- `episodeId`: ID episode
- `progressWatching`: Progress menonton dalam detik
- `isCompleted`: Status selesai menonton
- `lastWatched`: Waktu terakhir menonton
- `episode`: Info episode

**Helper Methods:**

- `progressPercentage`: Persentase progress (0.0 - 1.0)
- `formattedProgressTime`: Waktu progress yang diformat (MM:SS)
- `formattedLastWatched`: Waktu terakhir menonton yang diformat
- `isPartiallyWatched`: Cek apakah episode sedang ditonton
- `isNotStarted`: Cek apakah episode belum dimulai
- `progressStatus`: Status progress (Selesai/Sedang ditonton/Belum ditonton)

### EpisodeProgressInfoModel

Model untuk info episode dalam progress.

**Properties:**

- `id`: ID episode
- `nomorEpisode`: Nomor episode
- `judulEpisode`: Judul episode
- `thumbnailEpisode`: URL thumbnail episode

### EpisodeProgressResponseModel

Model untuk response episode progress.

**Helper Methods:**

- `completedEpisodes`: List episode yang selesai
- `partiallyWatchedEpisodes`: List episode yang sedang ditonton
- `notStartedEpisodes`: List episode yang belum dimulai
- `totalProgressPercentage`: Persentase progress total
- `totalCompletedEpisodes`: Jumlah episode selesai
- `totalEpisodes`: Total episode
- `getProgressByEpisodeNumber(int)`: Ambil progress berdasarkan nomor episode
- `latestWatchedEpisode`: Episode terakhir yang ditonton
- `nextEpisodeToWatch`: Episode selanjutnya yang harus ditonton
- `totalWatchTimeMinutes`: Total waktu tonton dalam menit
- `formattedTotalWatchTime`: Total waktu tonton yang diformat

## Service Methods

### Anime Detail Methods

#### `getAnimeDetail(int animeId)`

Mengambil detail anime berdasarkan ID.

```dart
try {
  final animeDetail = await AnimeService.getAnimeDetail(1);
  print('Anime: ${animeDetail.namaAnime}');
} catch (e) {
  print('Error: $e');
}
```

### Episode Methods

#### `getEpisodesByAnimeId(int animeId)`

Mengambil semua episode anime berdasarkan ID anime.

```dart
try {
  final episodes = await AnimeService.getEpisodesByAnimeId(1);
  print('Total episodes: ${episodes.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `getEpisodeByNumber(int animeId, int episodeNumber)`

Mengambil episode berdasarkan nomor episode.

```dart
try {
  final episode = await AnimeService.getEpisodeByNumber(1, 5);
  if (episode != null) {
    print('Episode: ${episode.judulEpisode}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### `getLatestEpisode(int animeId)`

Mengambil episode terbaru.

```dart
try {
  final latest = await AnimeService.getLatestEpisode(1);
  if (latest != null) {
    print('Latest: Episode ${latest.nomorEpisode}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### `getFirstEpisode(int animeId)`

Mengambil episode pertama.

```dart
try {
  final first = await AnimeService.getFirstEpisode(1);
  if (first != null) {
    print('First: Episode ${first.nomorEpisode}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### `getTotalEpisodes(int animeId)`

Mengambil total jumlah episode.

```dart
try {
  final total = await AnimeService.getTotalEpisodes(1);
  print('Total episodes: $total');
} catch (e) {
  print('Error: $e');
}
```

#### `hasEpisodes(int animeId)`

Mengecek apakah anime memiliki episode.

```dart
try {
  final hasEpisodes = await AnimeService.hasEpisodes(1);
  print('Has episodes: $hasEpisodes');
} catch (e) {
  print('Error: $e');
}
```

#### `getEpisodesWithQuality(int animeId, String quality)`

Mengambil episode dengan kualitas tertentu.

```dart
try {
  final episodes720p = await AnimeService.getEpisodesWithQuality(1, '720p');
  print('720p episodes: ${episodes720p.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `getEpisodesRange(int animeId, int startEpisode, int endEpisode)`

Mengambil episode dalam range tertentu.

```dart
try {
  final episodes = await AnimeService.getEpisodesRange(1, 1, 10);
  print('Episodes 1-10: ${episodes.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `searchEpisodes(int animeId, String searchQuery)`

Mencari episode berdasarkan judul atau deskripsi.

```dart
try {
  final results = await AnimeService.searchEpisodes(1, 'petualangan');
  print('Search results: ${results.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `getEpisodesWithBestQuality(int animeId)`

Mengambil episode yang memiliki kualitas terbaik.

```dart
try {
  final episodes = await AnimeService.getEpisodesWithBestQuality(1);
  print('Episodes with best quality: ${episodes.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `getEpisodeStatistics(int animeId)`

Mengambil statistik episode.

```dart
try {
  final stats = await AnimeService.getEpisodeStatistics(1);
  print('Total episodes: ${stats['total_episodes']}');
  print('Average duration: ${stats['average_duration']} minutes');
  print('Available qualities: ${stats['available_qualities']}');
} catch (e) {
  print('Error: $e');
}
```

### Episode Progress Methods

**⚠️ Semua method episode progress memerlukan token autentikasi dari SecureStorage.**

#### `getEpisodeProgress(int animeId)`

Mengambil progress episode user untuk anime tertentu. **Memerlukan token autentikasi.**

```dart
try {
  final progressList = await AnimeService.getEpisodeProgress(1);
  print('Total progress: ${progressList.length}');
} catch (e) {
  if (e.toString().contains('Token tidak ditemukan')) {
    print('Silakan login terlebih dahulu');
  } else if (e.toString().contains('Token tidak valid')) {
    print('Token expired, silakan login ulang');
  } else {
    print('Error: $e');
  }
}
```

#### `getEpisodeProgressStatistics(int animeId)`

Mengambil statistik progress episode.

```dart
try {
  final stats = await AnimeService.getEpisodeProgressStatistics(1);
  print('Completed episodes: ${stats['completed_episodes']}');
  print('Total progress: ${stats['total_progress_percentage']}%');
  print('Total watch time: ${stats['total_watch_time']}');
} catch (e) {
  print('Error: $e');
}
```

#### `getProgressByEpisodeNumber(int animeId, int episodeNumber)`

Mengambil progress episode berdasarkan nomor episode.

```dart
try {
  final progress = await AnimeService.getProgressByEpisodeNumber(1, 5);
  if (progress != null) {
    print('Episode 5 status: ${progress.progressStatus}');
    print('Progress time: ${progress.formattedProgressTime}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### `getLatestWatchedEpisodeProgress(int animeId)`

Mengambil episode terakhir yang ditonton.

```dart
try {
  final latest = await AnimeService.getLatestWatchedEpisodeProgress(1);
  if (latest != null) {
    print('Latest watched: Episode ${latest.episode.nomorEpisode}');
    print('Last watched: ${latest.formattedLastWatched}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### `getNextEpisodeToWatchProgress(int animeId)`

Mengambil episode selanjutnya yang harus ditonton.

```dart
try {
  final next = await AnimeService.getNextEpisodeToWatchProgress(1);
  if (next != null) {
    print('Next episode: Episode ${next.episode.nomorEpisode}');
  }
} catch (e) {
  print('Error: $e');
}
```

#### `getCompletedEpisodesProgress(int animeId)`

Mengambil list episode yang sudah selesai ditonton.

```dart
try {
  final completed = await AnimeService.getCompletedEpisodesProgress(1);
  print('Completed episodes: ${completed.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `getPartiallyWatchedEpisodesProgress(int animeId)`

Mengambil list episode yang sedang ditonton.

```dart
try {
  final partial = await AnimeService.getPartiallyWatchedEpisodesProgress(1);
  print('Partially watched: ${partial.length}');
} catch (e) {
  print('Error: $e');
}
```

#### `hasEpisodeProgress(int animeId)`

Mengecek apakah user memiliki progress untuk anime.

```dart
try {
  final hasProgress = await AnimeService.hasEpisodeProgress(1);
  print('Has progress: $hasProgress');
} catch (e) {
  print('Error: $e');
}
```

#### `getTotalWatchTime(int animeId)`

Mengambil total waktu tonton untuk anime.

```dart
try {
  final watchTime = await AnimeService.getTotalWatchTime(1);
  print('Total watch time: $watchTime');
} catch (e) {
  print('Error: $e');
}
```

## Usage Examples

### Basic Usage

```dart
// Load anime detail
final animeDetail = await AnimeService.getAnimeDetail(1);

// Load episodes
final episodes = await AnimeService.getEpisodesByAnimeId(1);

// Get latest episode
final latest = await AnimeService.getLatestEpisode(1);
```

### With Error Handling

```dart
try {
  final animeDetail = await AnimeService.getAnimeDetail(1);
  // Use animeDetail
} on DioException catch (e) {
  print('Network error: ${e.message}');
} catch (e) {
  print('Unexpected error: $e');
}
```

### Using FutureBuilder

```dart
FutureBuilder<AnimeDetailModel>(
  future: AnimeService.getAnimeDetail(1),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }

    if (!snapshot.hasData) {
      return Text('No data available');
    }

    final anime = snapshot.data!;
    return Text(anime.namaAnime);
  },
)
```

### Loading Multiple Data Concurrently

```dart
try {
  final results = await Future.wait([
    AnimeService.getAnimeDetail(1),
    AnimeService.getEpisodesByAnimeId(1),
  ]);

  final animeDetail = results[0] as AnimeDetailModel;
  final episodes = results[1] as List<EpisodeModel>;

  // Use both data
} catch (e) {
  print('Error: $e');
}
```

## Error Handling

Service ini menggunakan exception handling yang konsisten:

- **DioException**: Untuk network errors
- **Exception**: Untuk business logic errors
- **Custom messages**: Pesan error dalam bahasa Indonesia

## Response Format

Semua response mengikuti format:

```json
{
  "status": 200,
  "message": "Success message",
  "data": {...}
}
```

## Authentication

### Token Management

Service episode progress menggunakan token JWT yang disimpan di SecureStorage:

```dart
// Token akan otomatis diambil dari SecureStorage
final progress = await AnimeService.getEpisodeProgress(1);

// Token disimpan saat login
await SecureStorage.saveToken(token);

// Token dihapus saat logout
await SecureStorage.deleteToken();

// Cek status login
final isLoggedIn = await AuthService.isLoggedIn();
```

### Error Handling untuk Token

- **401 Unauthorized**: Token tidak valid atau expired
- **403 Forbidden**: Akses ditolak
- **Token tidak ditemukan**: User belum login

### Best Practices

1. Selalu cek status login sebelum memanggil method episode progress
2. Handle error token dengan graceful fallback
3. Redirect ke login screen jika token invalid
4. Gunakan try-catch untuk menangani error autentikasi

## Notes

- Semua method adalah static untuk kemudahan penggunaan
- Episode diurutkan berdasarkan nomor episode
- Kualitas video diprioritaskan: 1080p > 720p > 480p
- Error handling sudah diimplementasikan di setiap method
- Service menggunakan Dio untuk HTTP requests
- Episode progress memerlukan autentikasi token
