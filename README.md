# Leventa — Flutter Mobile Documentation

Dokumentasi ini adalah sumber acuan untuk membangun mobile app Property Management System (PMS) menggunakan Flutter. Backend companion: Go + Fiber + PostgreSQL.

> **Nama produk kerja: Leventa.** Nama ini dipakai konsisten di aplikasi, app title, README, package metadata yang relevan, dan mock/demo data. Nama dapat diganti jika user meminta. Ini belum merupakan pemeriksaan merek dagang.

## Mulai dari sini

1. `CLAUDE.md` — instruksi khusus Claude Code, termasuk skill wajib.
2. `AGENTS.md` — instruksi umum coding agent.
3. `docs/PRODUCT_SCOPE.md` — tujuan produk, role, batasan mobile.
4. `docs/SCREEN_SPEC.md` — screen dan user flow.
5. `docs/DESIGN_SYSTEM.md` — brand, theme, tokens, responsive.
6. `docs/APP_ARCHITECTURE.md` — Flutter architecture dan package policy.
7. `docs/API_INTEGRATION.md` — integrasi dengan Go backend.
8. `docs/STATE_AND_ROUTING.md` — state, auth, role-based navigation.
9. `docs/SECURITY_PRIVACY.md` — perlindungan data dan akses.
10. `docs/IMPLEMENTATION_PLAN.md` — urutan implementasi.
11. `docs/TESTING_QA.md` — pengujian dan Definition of Done.
12. `docs/DECISIONS.md` — keputusan yang sudah diketahui dan hal yang belum dikonfirmasi.

## Prinsip utama

- Sistem bersifat internal: customer adalah guest tanpa akun, user login hanya Marketing (`sales`) dan Admin. Tidak ada chat; komunikasi lewat WhatsApp.
- Jangan membuat ulang desain yang sudah ada tanpa audit terlebih dahulu.
- Aplikasi otomatis masuk mode guest; Marketing dan Admin login dari dalam aplikasi. Akun hanya dibuat oleh Admin.
- Screen untuk alur yang sudah dihapus backend (registrasi, favorites, inquiry, notifikasi customer, lead, follow-up, survey) dihapus (sudah disetujui).
- Hormati rate limit backend: debounce pencarian, jangan retry otomatis saat 429.
- Jangan mengarang endpoint atau payload. Cocokkan dengan backend OpenAPI/Swagger aktual.
- Backend adalah sumber kebenaran untuk authorization dan data privacy.
- Implementasi bertahap, satu vertical slice yang dapat diuji setiap tahap.
- Tidak melakukan overengineering.

## Menjalankan aplikasi

```bash
flutter pub get
# Emulator Android → backend lokal di port 8080 (default)
flutter run
# Backend lain (HTTPS untuk staging/production)
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

- Token login hanya disimpan di `flutter_secure_storage` (Keychain / Android Keystore). Guest tidak menyimpan token.
- Cache: memori dengan TTL per sesi (`lib/core/cache`), master data publik juga di disk (`shared_preferences`), foto listing di cache gambar (`cached_network_image`). Data owner dan dokumen kepemilikan tidak pernah di-cache.
- HTTP tanpa TLS hanya diizinkan ke `10.0.2.2`/`localhost` (Android `network_security_config.xml`).

## Struktur

```text
lib/
  app/        theme (token Leventa), routes + session watcher
  core/       config, network (ApiClient), cache, storage, utils, widgets bersama
  features/   auth, guest, properties, marketing, documents, deals, admin, master_data
```

Cek kualitas: `dart format .`, `flutter analyze`, `flutter test`.
