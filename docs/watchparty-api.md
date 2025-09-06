# Dokumentasi API Nobar (Watch Party)

Fitur Nobar memungkinkan pengguna membuat sesi nonton bareng, bergabung via kode, chat realtime, dan sinkronisasi player via Socket.IO.

- REST Routes: `src/routes/watchparty.routes.js`
- Controller: `src/controllers/watchparty.controller.js`
- Service: `src/services/watchparty.service.js`
- Namespace Socket.IO: `/watchparty`

## Prasyarat

1. Install Socket.IO (server):
```
npm i socket.io
```
2. Jalankan Prisma:
```
npx prisma validate
npx prisma generate
npx prisma migrate dev --name add_watchparty_tables
```
3. Jalankan server dev:
```
npm run dev
```

---

## REST API

Semua respons JSON. Semua endpoint membutuhkan autentikasi JWT via header `Authorization: Bearer <token>`.
Catatan: WebSocket adalah jalur utama untuk realtime. HTTP di bawah ini tersedia sebagai fallback short/long polling.

### 1) Buat Sesi Nobar
- Method: POST
- Path: `/watchparty/sessions`
- Headers:
  - `Authorization: Bearer <JWT>`
- Body:
```json
{ "hostUserId": 1, "episodeId": 123 }
```
- 201 Created (contoh):
```json
{
  "id": 10,
  "code": "AB2CDE",
  "host_user_id": 1,
  "episode_id": 123,
  "is_active": true,
  "current_time": 0,
  "is_paused": true,
  "createdAt": "...",
  "updatedAt": "..."
}
```
- Catatan: host otomatis menjadi participant dengan `role: "host"`.

### 2) Ambil Detail Sesi Berdasarkan Kode
- Method: GET
- Path: `/watchparty/sessions/:code`
- Headers:
  - `Authorization: Bearer <JWT>`
- 200 OK (contoh ringkas):
```json
{
  "id": 10,
  "code": "AB2CDE",
  "host_user_id": 1,
  "episode_id": 123,
  "is_active": true,
  "current_time": 0,
  "is_paused": true,
  "createdAt": "...",
  "updatedAt": "...",
  "participants": [
    { "id": 1, "session_id": 10, "user_id": 1, "role": "host", "joinedAt": "...", "last_seen": "...", "user": { /* user */ } }
  ],
  "episode": { /* episode */ }
}
```
- 404 Not Found jika kode tidak valid.

### 3) Join Sesi via Kode
- Method: POST
- Path: `/watchparty/sessions/:code/join`
- Headers:
  - `Authorization: Bearer <JWT>`
- Body:
```json
{ "userId": 2 }
```
- 200 OK:
```json
{ "message": "joined", "session": { /* session */ } }
```

### 4) Ambil Riwayat Chat
- Method: GET
- Path: `/watchparty/sessions/:code/messages?take=30`
- Headers:
  - `Authorization: Bearer <JWT>`
- 200 OK (array pesan terbaru, desc):
```json
[
  {
    "id": 5,
    "session_id": 10,
    "user_id": 2,
    "message": "Halo!",
    "createdAt": "...",
    "user": { /* user */ }
  }
]
```

### 5) Polling Pesan Baru (HTTP Fallback)
- Method: GET
- Path: `/watchparty/sessions/:code/messages/since?sinceId=0&limit=50`
- Headers: `Authorization: Bearer <JWT>`
- 200 OK:
```json
{
  "items": [ { "id": 6, "message": "Hai", "user": { /* ... */ } } ],
  "lastId": 6
}
```
- Pola: simpan `lastId` lalu panggil ulang endpoint dengan `sinceId=<lastId>`.

### 6) Kirim Pesan via HTTP (Fallback)
- Method: POST
- Path: `/watchparty/sessions/:code/messages`
- Headers: `Authorization: Bearer <JWT>`
- Body:
```json
{ "message": "Hai semua" }
```
- 201 Created: mengembalikan objek pesan yang tersimpan.

### 7) Ambil State Player via HTTP
- Method: GET
- Path: `/watchparty/sessions/:code/player`
- Headers: `Authorization: Bearer <JWT>`
- 200 OK:
```json
{ "currentTime": 123, "isPaused": false, "updatedAt": "..." }
```

### 8) Update State Player via HTTP
- Method: POST
- Path: `/watchparty/sessions/:code/player`
- Headers: `Authorization: Bearer <JWT>`
- Body (opsional):
```json
{ "currentTime": 456, "isPaused": true }
```
- 200 OK: `{ "message": "updated" }`
- 409 Conflict: bila host mencoba start (unpause) pertama kali sementara peserta non-host belum siap.
  - Contoh respon:
  ```json
  {
    "message": "Belum semua peserta siap",
    "pendingUserIds": [2,3],
    "readyCount": 1,
    "nonHostCount": 3
  }
  ```

### 9) Set/Unset Ready (HTTP)
- Method: POST
- Path: `/watchparty/sessions/:code/ready`
- Headers: `Authorization: Bearer <JWT>`
- Body:
```json
{ "isReady": true }
```
- 200 OK:
```json
{ "message": "ok", "readiness": { "sessionId": 10, "totalParticipants": 4, "nonHostCount": 3, "readyCount": 3, "allNonHostReady": true, "pendingUserIds": [] } }
```

### 10) Get Readiness (HTTP)
- Method: GET
- Path: `/watchparty/sessions/:code/readiness`
- Headers: `Authorization: Bearer <JWT>`
- 200 OK:
```json
{ "sessionId": 10, "totalParticipants": 4, "nonHostCount": 3, "readyCount": 2, "allNonHostReady": false, "pendingUserIds": [3] }
```

### 11) Daftar Peserta via HTTP
- Method: GET
- Path: `/watchparty/sessions/:code/participants`
- Headers: `Authorization: Bearer <JWT>`
- 200 OK:
```json
{
  "participants": [
    { "userId": 1, "username": "host", "fullName": null, "avatarUrl": null, "vip": null, "role": "host", "isHost": true }
  ],
  "host": { "userId": 1, "username": "host", "isHost": true }
}
```

### 12) Status Sesi (HTTP Polling)
- Method: GET
- Path: `/watchparty/sessions/:code/status`
- Headers: `Authorization: Bearer <JWT>`
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
    "updatedAt": "...",
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
Catatan: gunakan endpoint ini untuk polling berkala status player (apakah sudah play, menit ke berapa) sekaligus status kesiapan peserta.

---

## Socket.IO

- Namespace: `/watchparty`
- Koneksi klien:
```html
<script src="https://cdn.socket.io/4.7.5/socket.io.min.js"></script>
<script>
  const token = 'JWT_TOKEN';
  const socket = io('/watchparty', {
    transports: ['websocket'],
    auth: { token },
    extraHeaders: { Authorization: `Bearer ${token}` },
  });
</script>
```

### Events

- Client -> Server: `room:join`
  - Payload: `{ code: string }` (user diambil dari token)
  - Efek: gabung room `room:<code>`, upsert participant.
  - Server -> Client (pengirim): `room:joined` `{ session, recentMessages }`
    - `recentMessages[i].user` berisi `{ id, username, fullName, avatarUrl, vip? }`
  - Server -> Room: `presence:join` `{ user }`

- Client -> Server: `chat:send`
  - Payload: `{ message: string }` (maks 500 char)
  - Server -> Room: `chat:new` `{ id, user, message, createdAt }`
    - `user` berisi `{ id, username, fullName, avatarUrl, vip? }`

- Client -> Server: `chat:list`
  - Payload: `{ take?: number }`
  - Server -> Client: `chat:list:result` `Message[]`

- Client -> Server: `player:update`
  - Payload: `{ currentTime?: number, isPaused?: boolean }`
  - Catatan: Unpause pertama kali akan ditolak (error) bila peserta non-host belum siap (lihat event readiness). Server akan emit `error` ke pengirim dengan payload `{ message, pendingUserIds, readyCount, nonHostCount }`.
  - Server -> Room: `player:sync` `{ currentTime, isPaused, by }`

- Client -> Server: `player:get`
  - Payload: `{} | null`
  - Server -> Client: `player:state` `{ currentTime, isPaused }`

- Client -> Server: `room:participants`
  - Payload: `{} | null`
  - Server -> Client: `room:participants:result` `{ participants: [{ userId, username, role, isHost }], host }`

- Client -> Server: `sessions:list`
  - Payload: `{ isActive?, episodeId?, hostUserId?, page?, limit?, q? }`
  - Server -> Client: `sessions:list:result` `{ items, pagination }`

- Client -> Server: `ready:set`
  - Payload: `{ isReady: boolean }`
  - Efek: set/unset siap untuk user saat ini pada sesi.
  - Server -> Room: `ready:updated` `{ sessionId, totalParticipants, nonHostCount, readyCount, allNonHostReady, pendingUserIds }`
  - Server -> Client (peminta): `ready:state` format sama dengan di atas.

- Client -> Server: `ready:get`
  - Payload: `{}`
  - Server -> Client: `ready:state` `{ sessionId, totalParticipants, nonHostCount, readyCount, allNonHostReady, pendingUserIds }`

- Server -> Client (error umum): `error` `{ message: string }`

- Disconnect
  - Server -> Room: `presence:leave` `{ user }`

### Contoh Penggunaan Klien
```html
<script>
  const token = 'JWT_TOKEN';
  const socket = io('/watchparty', {
    transports: ['websocket'],
    auth: { token },
    extraHeaders: { Authorization: `Bearer ${token}` },
  });

  socket.on('connect', () => {
    socket.emit('room:join', { code: 'AB2CDE' });
    socket.emit('room:participants');
    socket.emit('player:get');
  });

  socket.on('room:joined', ({ session, recentMessages }) => {
    console.log('Joined', session, recentMessages);
  });

  socket.on('presence:join', ({ user }) => console.log('User join', user));
  socket.on('presence:leave', ({ user }) => console.log('User leave', user));

  socket.on('chat:new', (msg) => {
    // msg: { id, user: { id, username, fullName, avatarUrl, vip }, message, createdAt }
    console.log('Chat', msg);
  });
  socket.on('player:sync', (state) => console.log('Sync', state));
  socket.on('player:state', (state) => console.log('Player state', state));
  // Readiness events
  socket.on('ready:updated', (r) => console.log('Readiness updated', r));
  socket.on('ready:state', (r) => console.log('Readiness state', r));
  socket.on('room:participants:result', (payload) => console.log('Participants', payload));
  socket.on('sessions:list:result', (payload) => console.log('Sessions', payload));
  socket.on('chat:list:result', (msgs) => console.log('Chat list', msgs));

  function sendChat(text) {
    socket.emit('chat:send', { message: text });
  }

  function updatePlayer(currentTime, isPaused) {
    socket.emit('player:update', { currentTime, isPaused });
  }

  function setReady(isReady) {
    socket.emit('ready:set', { isReady });
  }

  function getReady() {
    socket.emit('ready:get');
  }

  function listSessions() {
    socket.emit('sessions:list', { page: 1, limit: 20 });
  }

  function listChats() {
    socket.emit('chat:list', { take: 30 });
  }

  socket.on('error', (e) => console.warn('Error', e));
</script>
```

---

## Sinkronisasi Player

- Server menyimpan `current_time` (detik) dan `is_paused` pada `WatchPartySession`.
- Klien mengirim `player:update` saat play/pause/seek; server broadcast `player:sync`.
- Rekomendasi klien:
  - Jitter buffer 100–300ms.
  - Self-heal periodic (mis. 10 detik sinkron dengan server).

---

## Keamanan & Best Practices

- Socket.IO mewajibkan autentikasi (JWT) di handshake (`auth.token` atau header Authorization).
- REST endpoint wajib `Authorization: Bearer <token>`.
- Rate limit `chat:send` untuk mencegah spam.
- Validasi panjang pesan (server sudah memotong 500 char).
- Siapkan role host/moderator untuk fitur kick/mute/lock jika dibutuhkan.

---

## Troubleshooting

- "Cannot read properties of undefined (reading 'create')":
  - Jalankan `npx prisma generate` dan migrasi, restart server.
- 404 sesi: pastikan kode benar dan sesi masih aktif (`is_active: true`).

---

## Alur Contoh

1) Host membuat sesi via REST `POST /watchparty/sessions` → dapat `code`.
2) User join via REST atau Socket `room:join` dengan `code`.
3) Chat via `chat:send` → semua klien menerima `chat:new`.
4) Kontrol player via `player:update` → broadcast `player:sync`.
