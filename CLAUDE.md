# Claude Code — Leventa Mobile

**Baca `AGENTS.md` dan seluruh dokumen `docs/` yang relevan sebelum mengubah kode.**

## Mandatory skills — wajib digunakan untuk task UI/UX

Sebelum mendesain, membuat, mengubah, atau mereview UI, verifikasi dan gunakan keempat skill berikut:

1. **Ponytail** — pendekatan minimal-change/YAGNI; implementasi sekecil mungkin tanpa mengorbankan validasi, security, dan tests.
2. **Frontend Design** — skill resmi Anthropic untuk art direction dan visual implementation.
3. **Design Taste Frontend** — `design-taste-frontend` dari Leonxlnx/Taste Skill.
4. **UI UX Pro Max** — design intelligence, design-system reasoning, responsive, accessibility, dan Flutter-specific guidance.

Jangan mengaku telah menggunakan skill jika skill belum terpasang atau tidak tersedia pada session. Periksa daftar skill aktif terlebih dahulu. Jika salah satu tidak tersedia, hentikan pekerjaan UI/visual dan laporkan skill mana yang belum tersedia beserta perintah instalasinya; jangan menggantinya diam-diam dengan prompt biasa.

### Instalasi Claude Code (jalankan sebagai perintah terpisah)

Ponytail:
```text
/plugin marketplace add DietrichGebert/ponytail
/plugin install ponytail@ponytail
```

Frontend Design (Anthropic):
```text
/plugin install frontend-design@claude-plugins-official
```

Design Taste Frontend:
```text
/plugin marketplace add Leonxlnx/taste-skill
/plugin install taste-skill@taste-skill
```

UI UX Pro Max:
```text
/plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill
/plugin install ui-ux-pro-max@ui-ux-pro-max-skill
```

Setelah instalasi, mulai session Claude Code baru bila diperlukan dan verifikasi skill terdeteksi. Skill/plugin marketplace dapat berubah; jika command gagal, periksa instruksi resmi repository masing-masing dan jangan mengarang command alternatif.

## Workflow wajib

1. Inspect repository dan identifikasi Flutter version, struktur, routing, state management, dependency, theme, tests, serta screen yang sudah ada.
2. Baca requirement yang berkaitan dengan task.
3. Untuk UI/UX: jalankan keempat skill wajib, lalu buat/audit keputusan visual sebelum coding. Pertahankan design tokens Leventa dari `docs/DESIGN_SYSTEM.md`; skill tidak boleh mengganti brand/theme tanpa alasan dan persetujuan.
4. Tulis rencana singkat untuk task multi-file.
5. Implementasikan satu vertical slice end-to-end.
6. Jalankan `dart format`, `flutter analyze`, dan test relevan.
7. Laporkan file berubah, skill yang benar-benar digunakan, keputusan, hasil test, serta gap.

## Non-negotiable

- Flutter/Dart.
- Jangan mengganti theme/brand secara sepihak.
- Jangan membuat role selector di login.
- Jangan percaya role, user ID, owner ID, atau marketing ID dari input UI untuk menentukan izin.
- Jangan menampilkan owner PII atau exact private address kepada role yang tidak berhak.
- Jangan memberi co-listing Marketing hak edit listing.
- Jangan menampilkan data sensitif lalu hanya menyembunyikannya secara visual; backend harus tidak mengirim data tersebut.
- Jangan membuat fake API behavior yang seolah-olah production.
- Jangan menghapus screen/fitur lama tanpa persetujuan eksplisit.
- Jangan menambahkan dependency hanya untuk kenyamanan jika solusi Flutter bawaan atau dependency yang sudah ada mencukupi.

## Ambiguity

Jika scope role/screen, business rule, atau payload belum jelas, jangan menebak. Catat pertanyaan yang paling penting dan minta klarifikasi sebelum implementasi yang berdampak pada bisnis, uang, privacy, atau authorization.
