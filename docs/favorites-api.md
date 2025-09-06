# Favorites API

Dokumentasi endpoint Favorites (Anime & Episode).

Base URL: sesuai server. Routes dimount di root (`src/app.js`: `app.use("/", favoritesRoutes);`).

## Autentikasi

- Header: `Authorization: Bearer <JWT>`
- Diperlukan untuk semua endpoint kecuali jika route ditandai "Public". Saat ini, kamu menjadikan stats episode authenticated juga.

## Endpoints

### 1) Tambah Anime ke Favorit
- Method: POST
- Path: `/anime/:id/favorite`
- Auth: Wajib
- Path Params:
  - `id` (number) — `Anime.id`
- Response 200
```json
{ "message": "Ditambahkan ke favorit anime", "status": 200 }
```

### 2) Hapus Anime dari Favorit
- Method: DELETE
- Path: `/anime/:id/favorite`
- Auth: Wajib
- Response 200
```json
{ "message": "Dihapus dari favorit anime", "status": 200 }
```

### 3) Daftar Favorit Anime Saya
- Method: GET
- Path: `/me/favorites/anime`
- Auth: Wajib
- Query (opsional):
  - `status` (string) — filter berdasarkan `anime.status_anime`
- Response 200
```json
{
  "message": "OK",
  "status": 200,
  "items": [
    {
      "id": 123, // id tabel AnimeFavorite
      "user_id": 1,
      "anime_id": 5,
      "createdAt": "2025-08-30T00:00:00.000Z",
      "anime": {
        "id": 5,
        "nama_anime": "...",
        "gambar_anime": "...",
        "rating_anime": "...",
        "status_anime": "Ongoing|Completed",
        "sinopsis_anime": "...",
        "genre_anime": ["..."]
      }
    }
  ],
  "filter": { "status": null }
}
```

### 4) Status Favorit Anime (user saat ini)
- Method: GET
- Path: `/anime/:id/favorite/status`
- Auth: Wajib
- Response 200
```json
{ "message": "OK", "status": 200, "isFavorited": true }
```

### 5) Tambah Episode ke Favorit
- Method: POST
- Path: `/episode/:id/favorite`
- Auth: Wajib
- Response 200
```json
{ "message": "Ditambahkan ke favorit episode", "status": 200 }
```

### 6) Hapus Episode dari Favorit
- Method: DELETE
- Path: `/episode/:id/favorite`
- Auth: Wajib
- Response 200
```json
{ "message": "Dihapus dari favorit episode", "status": 200 }
```

### 7) Daftar Favorit Episode Saya
- Method: GET
- Path: `/me/favorites/episodes`
- Auth: Wajib
- Response 200
```json
{
  "message": "OK",
  "status": 200,
  "items": [
    {
      "id": 99, // id tabel EpisodeFavorite
      "user_id": 1,
      "episode_id": 2,
      "createdAt": "2025-08-30T00:00:00.000Z",
      "episode": {
        "id": 2,
        "judul_episode": "...",
        "nomor_episode": 1,
        "anime": { "id": 5, "nama_anime": "..." }
      }
    }
  ]
}
```

### 8) Status Favorit Episode (user saat ini)
- Method: GET
- Path: `/episode/:id/favorite/status`
- Auth: Wajib
- Response 200
```json
{ "message": "OK", "status": 200, "isFavorited": false }
```

### 9) Statistik Favorit Episode (count, formattedCount, isFavorited)
- Method: GET
- Path: `/episode/:id/favorite`
- Auth: Saat ini Wajib (di `src/routes/favorites.routes.js`)
- Catatan: `src/controllers/favorite.controller.js` meneruskan `req.user?.id` ke `getEpisodeFavoriteStats(id, userId)`, sehingga `isFavorited` akan `true|false` untuk user terautentikasi.
- Response 200
```json
{
  "message": "OK",
  "status": 200,
  "count": 12,
  "formattedCount": "12",
  "isFavorited": true
}
```

## Contoh cURL

- Tambah anime ke favorit
```bash
curl -X POST \
  -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/anime/5/favorite
```

- Cek status favorit anime
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/anime/5/favorite/status
```

- Statistik favorit episode (auth)
```bash
curl -H "Authorization: Bearer <TOKEN>" \
  https://api.example.com/episode/2/favorite
```

## Error Codes
- 401 Unauthorized — token hilang/tidak valid.
- 400 Bad Request — validasi/operasi gagal.
- 403 Forbidden — token kadaluarsa/tidak valid saat verifikasi (dari middleware).

## Catatan Implementasi
- `isFavorited` dihitung dengan pencarian di `AnimeFavorite`/`EpisodeFavorite` berdasarkan `user_id` dan `anime_id`/`episode_id`.
- Unik per user-item: tidak bisa duplikat (lihat `@@unique([user_id, anime_id])` dan `@@unique([user_id, episode_id])` di `prisma/schema.prisma`).
- Jika ingin endpoint statistik episode tetap public tapi `isFavorited` muncul saat token tersedia, ubah route menjadi public dan gunakan middleware auth opsional; controller sudah siap menerima `userId` opsional.
