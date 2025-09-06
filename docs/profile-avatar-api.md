# Profile Avatar API

Dokumentasi untuk fitur avatar profil, mencakup update dengan link (non‑premium) dan upload file (premium).

## Autentikasi
- Semua endpoint membutuhkan Bearer JWT.

## 1) Dapatkan Profil Saya
- Method: GET
- Path: `/profile/me`
- Response:
  - 200 OK: `{ message, status, profile }`

## 2) Update Profil via JSON (Non‑Premium: link saja)
- Method: PUT
- Path: `/profile/me`
- Content-Type: `application/json`
- Deskripsi:
  - Hanya menerima `avatar_url` berbentuk URL http(s).
  - Tidak menerima upload file di endpoint ini.
  - Field lain (misal `full_name`, `bio`, dsb.) mengikuti schema profil yang ada.
- Validasi:
  - Jika `avatar_url` bukan http(s), server akan balas 400.
  - Jika mengirim file (field `avatar`), server balas 400.
- Body contoh:
```json
{
  "avatar_url": "https://cdn.example.com/avatars/abc.png",
  "full_name": "John Doe",
  "bio": "Hi there!"
}
```
- Response:
  - 200 OK: `{ message: "Profil disimpan", status: 200, profile }`
  - 400 Bad Request: `avatar_url harus berupa URL http(s)...`

Catatan implementasi:
- Validasi ada di `src/controllers/profile.controller.js` fungsi `upsertMyProfile()`

## 3) Upload Avatar (Premium Only)
- Method: PUT
- Path: `/profile/me/avatar`
- Content-Type: `multipart/form-data`
- Field file: `avatar`
- Deskripsi:
  - Hanya untuk user VIP aktif.
  - Server menyimpan file ke `static/uploads/avatars/` dan mengembalikan URL publik, disimpan pada `profile.avatar_url`.
- Batasan:
  - Tipe: `image/*` (jpg, png, webp, dsb.)
  - Maksimal ukuran: 2 MB
- Response:
  - 200 OK: `{ message: "Avatar diperbarui", status: 200, profile }`
  - 400 Bad Request: jika field file tidak ada
  - 403 Forbidden: jika VIP tidak aktif
  - 401 Unauthorized: jika token tidak valid
- Contoh cURL:
```bash
curl -X PUT "https://api.example.com/profile/me/avatar" \
  -H "Authorization: Bearer <JWT_TOKEN>" \
  -F "avatar=@/path/to/image.png"
```

Catatan implementasi:
- Middleware upload: `src/middlewares/upload.js` (Multer)
  - Direktori: `static/uploads/avatars/`
  - Limits: 2MB, hanya `image/*`
  - Helper URL publik: `publicAvatarUrl(req, filename)`
- Controller: `src/controllers/profile.controller.js` fungsi `uploadMyAvatar()`
  - Cek VIP via Prisma: `user.vip.status` dan `end_at`
  - Status aktif diterima: `true`, `"active"`, `"ACTIVE"`, dan `end_at` > sekarang
  - Simpan profil via `upsertProfile()`

## 4) VIP Trial Otomatis saat Register (Uji Coba)
- Endpoint: `POST /auth/register`
- Setelah user dibuat, sistem mengaktifkan VIP level `Diamond` selama 1 hari.
- Implementasi: `src/controllers/auth.controller.js`
  - Memanggil `activateVIP(user.id, { vip_level: "Diamond", durationDays: 1 })`
  - Jika gagal, tidak memblokir proses register.

## 5) Contoh Integrasi Mobile

Android (OkHttp, Kotlin):
```kotlin
val client = OkHttpClient()
val file = File(localPath)
val body = MultipartBody.Builder()
  .setType(MultipartBody.FORM)
  .addFormDataPart("avatar", file.name, file.asRequestBody("image/*".toMediaType()))
  .build()

val request = Request.Builder()
  .url("$API_BASE/profile/me/avatar")
  .addHeader("Authorization", "Bearer $jwt")
  .put(body)
  .build()

client.newCall(request).enqueue(object : Callback {
  override fun onFailure(call: Call, e: IOException) {}
  override fun onResponse(call: Call, response: Response) {
    val json = response.body?.string()
    // Parse -> profile.avatar_url
  }
})
```

Flutter (http):
```dart
import 'package:http/http.dart' as http;

Future<void> uploadAvatar(String filePath, String jwt) async {
  final uri = Uri.parse('$API_BASE/profile/me/avatar');
  final req = http.MultipartRequest('PUT', uri)
    ..headers['Authorization'] = 'Bearer $jwt'
    ..files.add(await http.MultipartFile.fromPath('avatar', filePath));
  final resp = await req.send();
  final body = await resp.stream.bytesToString();
  // Parse -> profile.avatar_url
}
```

## 6) Error & Perilaku
- Non‑premium mencoba upload di `/profile/me/avatar` -> 403.
- `avatar_url` bukan http(s) di `/profile/me` -> 400.
- Path lokal device (contoh Android `/data/user/0/.../cache/...png`) ditolak di `/profile/me`.
- File valid akan tersedia di URL publik: `https://<host>/static/uploads/avatars/<filename>`.
