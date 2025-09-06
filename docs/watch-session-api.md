# Watch Session API (Frontend Guide)

Dokumen ini menjelaskan alur dan contoh request untuk integrasi frontend terhadap sistem sesi nonton dengan anti-skip serta awarding XP. Endpoint berikut membutuhkan autentikasi JWT seperti route lain di aplikasi ini.

- Base path API mengikuti konfigurasi server Anda. Contoh: `https://api.nanimeid.dev` atau `http://localhost:4000` saat development.
- Semua request perlu header Authorization: `Bearer <JWT>`.
- Tiga endpoint utama:
  - `POST /watch/session/start`
  - `POST /watch/progress`
  - `POST /watch/session/complete`

## 1) Start Session
Mulai sesi nonton untuk 1 episode. Server menghasilkan `sessionToken` yang harus dikirim pada progress/complete berikutnya.

- Method: POST
- Path: `/watch/session/start`
- Auth: Required (Bearer JWT)
- Body JSON:
```json
{
  "episodeId": 123
}
```
- Response 201 JSON:
```json
{
  "status": 201,
  "message": "Session started",
  "data": {
    "sessionToken": "<token>",
    "sessionId": 456
  }
}
```

Contoh curl
```bash
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"episodeId":123}' \
  "$BASE_URL/watch/session/start"
```

Contoh fetch (JS)
```js
const res = await fetch(`${BASE_URL}/watch/session/start`, {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ episodeId })
});
const { data } = await res.json();
const sessionToken = data.sessionToken;
```

## 2) Progress Heartbeat
Kirim heartbeat progress setiap 15–30 detik. Server akan menghitung durasi tonton sah dengan anti-skip (delta progress sah per ping ≤ 60 detik).

- Method: POST
- Path: `/watch/progress`
- Auth: Required (Bearer JWT)
- Body JSON:
```json
{
  "sessionToken": "<token>",
  "positionSec": 120,
  "playbackRate": 1.0
}
```
- Response 200 JSON:
```json
{ "status": 200, "message": "Progress accepted", "data": { "ok": true } }
```

Catatan
- `positionSec` adalah posisi currentTime player (dalam detik, integer/float ok).
- Jika delta posisi terlalu besar (>60s per ping), server menganggap skip (tidak menambah waktu tonton sah).
- Frontend tidak perlu mengatur anti-skip; cukup kirim heartbeat teratur dan posisi aktual.

Contoh setInterval (JS)
```js
const HEARTBEAT_INTERVAL = 20000; // 20s
const heartbeat = async () => {
  const positionSec = Math.floor(player.currentTime);
  const playbackRate = player.playbackRate;
  await fetch(`${BASE_URL}/watch/progress`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionToken, positionSec, playbackRate })
  });
};
const interval = setInterval(heartbeat, HEARTBEAT_INTERVAL);
```

## 3) Complete Session
Panggil saat user menyelesaikan episode (misal mencapai mendekati akhir, atau user menekan tombol selesai). Server memverifikasi coverage dan mencairkan XP jika lolos.

- Method: POST
- Path: `/watch/session/complete`
- Auth: Required (Bearer JWT)
- Body JSON:
```json
{ "sessionToken": "<token>" }
```
- Response 200 JSON:
```json
{
  "status": 200,
  "message": "XP granted" | "No XP granted",
  "data": {
    "granted": true,
    "xp": 10,
    "duration": 1420
  }
}
```

Aturan verifikasi minimal (tahap awal)
- __totalWatchedSeconds__ ≥ 85% dari durasi episode.
- __lastPositionSec__ ≥ 95% dari durasi episode.
- __realElapsedSec__ ≥ 70% dari durasi episode (waktu nyata dari start ke complete).
- Dedup: XP hanya cair 1x per user per episode.

## Nilai XP (VIP vs non-VIP)
- Non‑VIP: 10 XP per episode selesai.
- VIP aktif: multiplier 2x → 20 XP per episode selesai.
  - VIP dinilai aktif jika `UserVIP.status == "ACTIVE"` dan `end_at` masih di masa depan.

## Rekomendasi UX Frontend
- __Start__: panggil start saat player benar-benar mulai main.
- __Heartbeat__: kirim tiap 15–30 detik. Hentikan saat video di-pause lama atau tab tidak visible (opsional).
- __Complete__: panggil ketika playback berada di near-end atau saat user menekan tombol selesai.
- __Feedback__: Jika response `granted: true`, tampilkan notifikasi "+10 XP" atau "+20 XP (VIP)".

## Error Handling
- 401 Unauthorized → token tidak valid/expired. Minta user login ulang.
- 400 Bad Request → missing field (episodeId/sessionToken/positionSec). Perbaiki payload.
- 404/500 → tampilkan pesan umum dan opsi retry.

## Alur Singkat
1. __Start__ → server kirim `sessionToken`.
2. __Progress (loop)__ → kirim posisi, server hitung durasi sah.
3. __Complete__ → server verifikasi coverage → cairkan XP (10/20) jika lolos → return hasil.

## Contoh Integrasi Sederhana
```js
// 1) Start
const startRes = await fetch(`${BASE_URL}/watch/session/start`, {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ episodeId })
});
const { data: startData } = await startRes.json();
const sessionToken = startData.sessionToken;

// 2) Heartbeat tiap 20 detik
const intervalId = setInterval(async () => {
  const positionSec = Math.floor(player.currentTime);
  await fetch(`${BASE_URL}/watch/progress`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionToken, positionSec, playbackRate: player.playbackRate })
  });
}, 20000);

// 3) Complete saat near-end
player.addEventListener('ended', async () => {
  clearInterval(intervalId);
  const completeRes = await fetch(`${BASE_URL}/watch/session/complete`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionToken })
  });
  const { data } = await completeRes.json();
  if (data.granted) {
    // Tampilkan notifikasi XP
    const xpText = data.xp === 20 ? "+20 XP (VIP)" : `+${data.xp} XP`;
    showToast(`Selamat! ${xpText}`);
  }
});
```

## Catatan Tambahan
- Progress agregat untuk UI tetap disinkronkan ke `UserEpisodeProgress`, jadi UI progress Anda tidak perlu diubah.
- Jika heartbeat berhenti lama (tab di-background), total watched mungkin tidak cukup untuk meloloskan verifikasi. Pastikan heartbeat aktif saat playback aktif.
