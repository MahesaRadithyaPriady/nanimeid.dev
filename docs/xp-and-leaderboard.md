# XP & Leaderboard API Documentation

Base paths are mounted in `src/app.js` as follows:

- XP routes mounted at: `/xp` (from `src/routes/xp.routes.js`)
- Leaderboard routes mounted at: `/leaderboard` (from `src/routes/leaderboard.routes.js`)

Authentication for XP endpoints uses the `authenticate` middleware. Include a valid JWT in `Authorization: Bearer <token>`.

## XP API

- Path prefix: `/xp`
- Auth: Required for all endpoints

### Tambah XP Manual
- Method: POST
- Path: `/xp/add`
- Header: `Authorization: Bearer <JWT>`
- Body: none (server menambah XP dengan base 10, VIP mendapatkan multiplier otomatis)

Contoh request:
```bash
curl -X POST \
  -H "Authorization: Bearer <JWT>" \
  https://your-domain/api/xp/add
```

Contoh response 200:
```json
{
  "message": "XP ditambahkan",
  "code": 200,
  "data": {
    "user_id": 123,
    "added": 20,
    "multiplier": 2,
    "isVip": true,
    "current_xp": 140,
    "level_id": 3,
    "level": {
      "id": 3,
      "level_number": 3,
      "xp_required_total": 100,
      "title": "Chunin"
    },
    "progress": {
      "currentLevelXpRequired": 100,
      "nextLevelXpRequired": 200,
      "xpToNext": 60,
      "percent": 40
    }
  }
}
```

- Error 401: `{ "message": "Unauthorized", "code": 401, "data": null }`
- Error 400: `{ "message": "<alasan>", "code": 400, "data": null }`

### Lihat XP Saya
- Method: GET
- Path: `/xp/me`
- Header: `Authorization: Bearer <JWT>`

Contoh request:
```bash
curl -H "Authorization: Bearer <JWT>" \
  https://your-domain/api/xp/me
```

Contoh response 200:
```json
{
  "message": "OK",
  "code": 200,
  "data": {
    "user_id": 123,
    "current_xp": 140,
    "level_id": 3,
    "level": {
      "id": 3,
      "level_number": 3,
      "xp_required_total": 100,
      "title": "Chunin"
    },
    "progress": {
      "currentLevelXpRequired": 100,
      "nextLevelXpRequired": 200,
      "xpToNext": 60,
      "percent": 40
    }
  }
}
```

- Error 401: `{ "message": "Unauthorized", "code": 401, "data": null }`
- Error 400: `{ "message": "<alasan>", "code": 400, "data": null }`

## Leaderboard API

- Path prefix: `/leaderboard`
- Auth: Public (tidak menggunakan middleware `authenticate`)

### Ambil Leaderboard Default (daily)
- Method: GET
- Path: `/leaderboard`
- Query params:
  - `limit` (opsional, default 50) – jumlah maksimum entri

Contoh:
```bash
curl "https://your-domain/api/leaderboard?limit=20"
```

### Ambil Leaderboard Berdasarkan Periode
- Method: GET
- Path: `/leaderboard/:period`
- Params:
  - `period` – salah satu dari: `daily`, `weekly`, `monthly`
- Query params:
  - `limit` (opsional, default 50)

Contoh:
```bash
curl "https://your-domain/api/leaderboard/weekly?limit=100"
```

Contoh response 200:
```json
{
  "message": "OK",
  "code": 200,
  "data": {
    "period": "weekly",
    "period_start": "2025-09-01T00:00:00.000Z",
    "period_end": "2025-09-08T00:00:00.000Z",
    "entries": [
      {
        "rank": 1,
        "user": {
          "id": 123,
          "username": "naruto",
          "fullName": "Naruto Uzumaki",
          "avatarUrl": "https://...",
          "vip": { "status": "ACTIVE", "endAt": "2025-12-31T00:00:00.000Z" }
        },
        "total_xp": 240
      }
    ]
  }
}
```

- Error 400: `{ "message": "period invalid", "code": 400, "data": null }`

## Mekanisme XP

Implementasi terdapat di `src/services/xp.service.js` dan digunakan oleh controller `src/controllers/xp.controller.js`. Ringkasan mekanisme:

- Base XP aksi manual: `10` (endpoint POST `/xp/add`).
- VIP Multiplier: `x2` jika user memiliki VIP aktif (`userVIP.status === "ACTIVE"` dan `end_at` > now), dicek oleh fungsi `isVipActiveRecord`.
- Perubahan XP disimpan di tabel `userXP` dengan transaksi.
- Leveling: Mengacu pada tabel `xpLevel`, field `xp_required_total`.
  - Saat XP bertambah, service mencari level tertinggi yang `xp_required_total <= current_xp` dan set `userXP.level_id` jika berubah.
- Event XP untuk Leaderboard: Setiap penambahan XP menghasilkan record `xpEvent` dengan `{ user_id, amount }`.
- Progress ke level berikutnya dihitung dari:
  - `currentLevelXpRequired` (xp_required_total level saat ini)
  - `nextLevelXpRequired` (xp_required_total level selanjutnya atau null jika sudah maksimum)
  - `xpToNext` (sisa XP menuju level berikutnya)
  - `percent` (0..100 % menuju level berikutnya; jika tidak ada next level maka 100)

### XP dari Menyelesaikan Episode

Service `src/services/episode.service.js` fungsi `saveUserProgress()` memberikan XP penyelesaian episode secara otomatis:

- Basis XP per episode selesai: `20` (variabel `baseXpPerEpisode`).
- Syarat grant XP (dalam transaksi):
  - Durasi episode > 0
  - Total waktu tonton akumulatif `total_watched_seconds >= 80%` dari durasi
  - Posisi progress terbaru `progress_watching >= 90%` dari durasi
  - Waktu berlalu sejak pertama kali menonton `>= 50%` dari durasi (menghindari skip cepat)
  - Belum pernah menerima grant XP untuk episode itu (`episodeXPGrant` tidak ada untuk `(user_id, episode_id)`).
- Saat syarat terpenuhi:
  - Memanggil `addUserXP({ userId, baseAmount: 20 })` (VIP multiplier juga berlaku di sini)
  - Mencatat `episodeXPGrant` dan menandai `userEpisodeProgress.is_completed = true`.

### Proteksi Progress Episode (Rewatch)

- Jika `userEpisodeProgress.is_completed = true`, saat user rewatch dan mengirim progress kecil (mis. 5 detik), system TIDAK akan me-reset progress ke awal. Field `progress_watching` dipertahankan di durasi penuh episode dan hanya `last_watched` yang diperbarui.
- Untuk episode yang belum selesai, progress bersifat monotonic: nilai `progress_watching` tidak akan berkurang walaupun klien mengirim nilai yang lebih kecil. Sistem juga mendeteksi lompatan besar dan mencatatnya sebagai `skips_count`.

## Lokasi Kode

- XP
  - Route: `src/routes/xp.routes.js`
  - Controller: `src/controllers/xp.controller.js`
  - Service: `src/services/xp.service.js`
- Leaderboard
  - Route: `src/routes/leaderboard.routes.js`
  - Controller: `src/controllers/leaderboard.controller.js`
  - Service: `src/services/leaderboard.service.js`
- Episode Progress & XP Grant: `src/services/episode.service.js` (fungsi `saveUserProgress`)
