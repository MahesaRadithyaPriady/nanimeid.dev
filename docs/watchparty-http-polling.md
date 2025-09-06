# Watch Party - HTTP Polling Only

Dokumen ini merangkum endpoint HTTP yang dapat dipakai untuk melakukan polling status sesi tanpa Socket.IO.

Semua endpoint memerlukan header Authorization: `Authorization: Bearer <JWT>`.

## Ringkasan Endpoint
- GET `/watchparty/sessions/:code/status` — status komposit sesi (state player + readiness + hitung peserta)
- GET `/watchparty/sessions/:code/readiness` — ringkasan kesiapan peserta
- GET `/watchparty/sessions/:code/participants` — daftar peserta (opsional untuk polling identitas)
- POST `/watchparty/sessions/:code/join` — bergabung ke sesi via HTTP

Rekomendasi interval polling: 1–3 detik saat menunggu start, 3–10 detik saat playback berjalan stabil.

---

## 1) Status Sesi (Komposit)
- Method: GET
- Path: `/watchparty/sessions/:code/status`
- Header: `Authorization: Bearer <JWT>`
- 200 OK:
```json
{
  "session": {
    "id": 10,
    "code": "AB2CDE",
    "isActive": true,
    "startedAt": null,
    "currentTime": 0,
    "isPaused": true,
    "updatedAt": "2025-09-02T00:00:00.000Z",
    "episodeId": 123,
    "hostUserId": 1
  },
  "readiness": {
    "sessionId": 10,
    "totalParticipants": 4,
    "nonHostCount": 3,
    "readyCount": 2,
    "allNonHostReady": false,
    "pendingUserIds": [3]
  },
  "participantsCount": 4
}
```
- Catatan:
  - `startedAt` akan terisi saat unpause pertama berhasil.
  - `currentTime` dan `isPaused` mencerminkan state server terakhir.
  - `readiness.allNonHostReady` `true` menandakan semua non-host sudah siap.

### Contoh cURL
```bash
curl -H "Authorization: Bearer $JWT" \
  http://localhost:3000/watchparty/sessions/AB2CDE/status
```

---

## 2) Join Sesi via HTTP
- Method: POST
- Path: `/watchparty/sessions/:code/join`
- Header: `Authorization: Bearer <JWT>`
- Body: kosong
- 200 OK:
```json
{
  "session": { "id": 10, "code": "AB2CDE", "is_active": true },
  "participant": { "user_id": 5, "role": "member" }
}
```

### Contoh cURL
```bash
curl -X POST -H "Authorization: Bearer $JWT" \
  http://localhost:3000/watchparty/sessions/AB2CDE/join
```

---

## 3) Readiness (Opsional, jika perlu terpisah)
- Method: GET
- Path: `/watchparty/sessions/:code/readiness`
- 200 OK:
```json
{
  "sessionId": 10,
  "totalParticipants": 4,
  "nonHostCount": 3,
  "readyCount": 2,
  "allNonHostReady": false,
  "pendingUserIds": [3]
}
```

### Contoh cURL
```bash
curl -H "Authorization: Bearer $JWT" \
  http://localhost:3000/watchparty/sessions/AB2CDE/readiness
```

---

## 4) Daftar Peserta (Opsional)
- Method: GET
- Path: `/watchparty/sessions/:code/participants`
- 200 OK:
```json
{
  "participants": [
    { "userId": 1, "username": "host", "fullName": null, "avatarUrl": null, "vip": null, "role": "host", "isHost": true }
  ],
  "host": { "userId": 1, "username": "host", "isHost": true }
}
```

---

## Pola Polling yang Direkomendasikan
- Saat awal join dan loading: poll `/status` setiap 1–2 detik hingga `readiness.allNonHostReady` true.
- Host sebelum start (unpause pertama):
  - Cek `/status` → jika `allNonHostReady` true, lakukan start melalui HTTP atau UI host (unpause via endpoint/aksi host).
- Saat playback berjalan: poll `/status` setiap 3–10 detik untuk sinkronisasi ringan.

Contoh logika sederhana (pseudo):
```js
async function pollStatus(code, token) {
  const res = await fetch(`/watchparty/sessions/${code}/status`, {
    headers: { Authorization: `Bearer ${token}` }
  });
  const data = await res.json();
  const { session, readiness } = data;
  // sinkronisasi player lokal
  // - Jika state server berbeda jauh, lakukan seek/pause sesuai `session`
  return { session, readiness };
}
```

---

## Error & Tanggapan
- 401 Unauthorized: token tidak valid / tidak ada.
- 404 Not Found: kode sesi salah atau sesi tidak aktif.
- 500 Internal Server Error: kesalahan server.

---

## Catatan Tambahan
- Gating start playback (unpause pertama) juga berlaku untuk HTTP API non-polling: jika belum semua siap, host akan mendapat 409 Conflict saat mencoba start via endpoint terkait player.
- Jika Anda ingin menurunkan beban polling, pertimbangkan ETag/If-None-Match atau menambahkan query `?since=<ISO>` di masa depan untuk delta update.
