# Profile API

Dokumentasi endpoint Profile publik untuk mengambil profil user by ID beserta statistik dan melakukan pencarian user berdasarkan nama (full_name).

- Base path: `/profile` (lihat mounting di `src/app.js`)
- Autentikasi: Public (tidak memerlukan token) untuk endpoint di dokumen ini
- Terkait: `src/routes/profile.routes.js`, `src/controllers/profile.controller.js`, `src/services/profile.service.js`

## GET /profile/search

Cari user berdasarkan `profile.full_name` saja (pencarian case-insensitive). Tidak melakukan pencarian berdasarkan `username`.

- Method: GET
- Path: `/profile/search`
- Query Params:
  - `q` (wajib) – kata kunci yang dicocokkan ke `profile.full_name`
  - `page` (opsional, default 1)
  - `limit` (opsional, default 20, maksimum 100)
- Auth: Public

Contoh request:
```bash
curl -X GET "http://localhost:3000/profile/search?q=ichigo&page=1&limit=10"
```

Respons sukses (200):
```json
{
  "message": "OK",
  "status": 200,
  "items": [
    {
      "user": { "id": 42, "username": "ichigo" },
      "profile": {
        "id": 11,
        "user_id": 42,
        "full_name": "Ichigo Kurosaki",
        "avatar_url": null,
        "bio": "New user profile",
        "birthdate": null,
        "gender": null,
        "createdAt": "2025-09-05T07:20:00.000Z",
        "updatedAt": "2025-09-05T07:20:00.000Z"
      },
      "vip": { "status": "ACTIVE", "vip_level": "Gold", "endAt": "2025-12-31T00:00:00.000Z" },
      "xp": { "current_xp": 120, "level_id": 2 },
      "level": { "id": 2, "level_number": 2, "xp_required_total": 200, "title": "Bronze" }
    }
  ],
  "page": 1,
  "limit": 10,
  "total": 1
}
```

Kesalahan umum:
- 200 dengan `items: []` jika `q` kosong (akan dikembalikan kosong oleh service)
- 400 jika terjadi kesalahan tak terduga

## GET /profile/:userId

Ambil profil publik user beserta statistik agregat.

- Method: GET
- Path: `/profile/:userId`
- Params:
  - `userId` (wajib) – ID user
- Auth: Public

Data yang dikembalikan:
- `user`: `{ id, username }`
- `profile`: seluruh bidang `UserProfile`
- `vip`: `{ status, endAt } | null`
- `xp`: `{ current_xp, level_id }` (ringkas)
- `level`: `{ id, level_number, xp_required_total, title } | null`
- `stats`:
  - `comments_count`: jumlah komentar yang dibuat user
  - `likes_received`: jumlah like pada komentar milik user
  - `likes_given`: jumlah like yang diberikan user
  - `minutes_watched`: total menit ditonton (dari penjumlahan `UserEpisodeProgress.total_watched_seconds`)

Contoh request:
```bash
curl -X GET "http://localhost:3000/profile/42"
```

Respons sukses (200):
```json
{
  "message": "OK",
  "status": 200,
  "profile": {
    "user": { "id": 42, "username": "ichigo" },
    "profile": {
      "id": 11,
      "user_id": 42,
      "full_name": "Ichigo Kurosaki",
      "avatar_url": "https://cdn.example/avatar.png",
      "bio": "New user profile",
      "birthdate": null,
      "gender": null,
      "createdAt": "2025-09-05T07:20:00.000Z",
      "updatedAt": "2025-09-05T07:20:00.000Z"
    },
    "vip": { "status": "ACTIVE", "vip_level": "Gold", "endAt": "2025-12-31T00:00:00.000Z" },
    "xp": { "current_xp": 120, "level_id": 2 },
    "level": { "id": 2, "level_number": 2, "xp_required_total": 200, "title": "Bronze" },
    "stats": {
      "comments_count": 15,
      "likes_received": 55,
      "likes_given": 23,
      "minutes_watched": 842
    }
  }
}
```

Kesalahan umum:
- 404 jika user tidak ditemukan
- 400 jika `userId` tidak valid atau error tak terduga

## Implementasi (Referensi Kode)

- Routes: `src/routes/profile.routes.js`
  - `GET /profile/search` → `searchUsersPublic`
  - `GET /profile/:userId` → `getProfilePublicById`
- Controller: `src/controllers/profile.controller.js`
  - `searchUsersPublic(req, res)`
  - `getProfilePublicById(req, res)`
- Service: `src/services/profile.service.js`
  - `searchUsersByName({ query, page, limit })`
  - `getPublicProfileWithStats(userId)`

## Catatan
- Pencarian hanya menggunakan `UserProfile.full_name` (mode `insensitive`).
- Total menit ditonton dihitung dari agregasi Prisma pada `UserEpisodeProgress.total_watched_seconds` lalu dibagi 60 dan dibulatkan ke bawah.
- Struktur respons mengikuti pola umum proyek: mengandung `message` dan `status` di root.
