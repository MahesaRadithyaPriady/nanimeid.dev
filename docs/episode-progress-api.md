# Episode Progress API

Dokumentasi endpoint Progress Menonton Episode oleh user.

Base URL: sesuai server. Routes dimount di `app.use("/episode", episodeRoutes)`.

Semua endpoint progress memerlukan autentikasi JWT: `Authorization: Bearer <TOKEN>`.

## Endpoints

### 1) Simpan/Update Progress Episode
- Method: POST
- Path: `/episode/:episodeId/progress`
- Auth: Wajib
- Path Params:
  - `episodeId` (number)
- Request Body (JSON):
```json
{
  "progress_watching": 1200, // detik
  "is_completed": false      // opsional, default false
}
```
- Response 200
```json
{
  "status": 200,
  "message": "Progress berhasil disimpan",
  "data": {
    "id": 10,
    "user_id": 1,
    "episode_id": 2,
    "progress_watching": 1200,
    "is_completed": false,
    "last_watched": "2025-08-30T12:00:00.000Z"
  }
}
```

### 2) Ambil Progress Episode Tertentu (user saat ini)
- Method: GET
- Path: `/episode/:episodeId/progress`
- Auth: Wajib
- Response 200 (jika ada progress)
```json
{
  "status": 200,
  "message": "Berhasil Mengambil Data Progress",
  "data": {
    "id": 10,
    "user_id": 1,
    "episode_id": 2,
    "progress_watching": 1200,
    "is_completed": false,
    "last_watched": "2025-08-30T12:00:00.000Z"
  }
}
```
- Response 200 (jika belum ada progress, akan dikembalikan default)
```json
{
  "status": 200,
  "message": "Berhasil Mengambil Data Progress",
  "data": {
    "id": null,
    "user_id": 1,
    "episode_id": 2,
    "progress_watching": 0,
    "is_completed": false,
    "last_watched": null
  }
}
```

### 3) Ambil Semua Progress User (terbaru di atas)
- Method: GET
- Path: `/episode/user/progress`
- Auth: Wajib
- Response 200
```json
{
  "status": 200,
  "message": "Berhasil Mengambil Data Progress",
  "data": [
    {
      "id": 10,
      "user_id": 1,
      "episode_id": 2,
      "progress_watching": 1200,
      "is_completed": false,
      "last_watched": "2025-08-30T12:00:00.000Z",
      "episode": {
        "id": 2,
        "anime_id": 5,
        "judul_episode": "...",
        "nomor_episode": 1,
        "thumbnail_episode": "...",
        "deskripsi_episode": "...",
        "durasi_episode": 1440,
        "anime": {
          "id": 5,
          "nama_anime": "...",
          "gambar_anime": "...",
          "sinopsis_anime": "..."
        }
      }
    }
  ]
}
```

### 4) Ambil Progress User per Anime
- Method: GET
- Path: `/episode/user/progress/anime/:animeId`
- Auth: Wajib
- Path Params:
  - `animeId` (number)
- Response 200
```json
{
  "status": 200,
  "message": "Berhasil Mengambil Data Progress",
  "data": [
    {
      "id": 21,
      "user_id": 1,
      "episode_id": 2,
      "progress_watching": 1200,
      "is_completed": false,
      "last_watched": "2025-08-30T12:00:00.000Z",
      "episode": {
        "id": 2,
        "nomor_episode": 1,
        "judul_episode": "...",
        "thumbnail_episode": "..."
      }
    }
  ]
}
```

### 5) Ambil Total Progress User per Anime
- Method: GET
- Path: `/episode/user/progress/anime/:animeId/total`
- Auth: Wajib
- Path Params:
  - `animeId` (number)
- Response 200
```json
{
  "status": 200,
  "message": "Berhasil Mengambil Data Total Progress",
  "data": {
    "anime_id": 5,
    "total_episodes": 12,
    "completed_episodes": 3,
    "total_episode_duration": 21600,      // detik
    "total_watched_duration": 7200,       // detik
    "progress_percentage": 33,            // dibulatkan
    "episodes_progress": [
      {
        "episode_id": 2,
        "episode_number": 1,
        "progress_watching": 1200,
        "is_completed": false,
        "episode_duration": 1800,
        "last_watched": "2025-08-30T12:00:00.000Z"
      }
    ]
  }
}
```

## cURL Examples

- Simpan progress episode
```bash
curl -X POST \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{"progress_watching": 1200, "is_completed": false}' \
  https://api.example.com/episode/2/progress
```

- Ambil progress episode tertentu
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/episode/2/progress
```

- Ambil semua progress user
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/episode/user/progress
```

- Ambil progress user per anime
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/episode/user/progress/anime/5
```

- Ambil total progress user per anime
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/episode/user/progress/anime/5/total
```

## Error Codes
- 401 Unauthorized — token hilang/tidak valid.
- 400 Bad Request — parameter/body kurang.
- 404 Not Found — episode tidak ditemukan (untuk GET by id di controller lain).
- 500 Internal Server Error — kesalahan server.

## Catatan Implementasi
- Progress disimpan di tabel `UserEpisodeProgress` (lihat `prisma/schema.prisma`).
- `saveUserProgress()` menggunakan upsert per kombinasi unik `user_id + episode_id`.
- `progress_watching` dalam detik. `is_completed` opsional, default false.
- `getUserProgress()` akan mengembalikan default object (progress 0) jika belum ada data.
