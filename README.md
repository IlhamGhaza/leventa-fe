<div align="center">

<img src="assets/logo/leventa_icon.png" alt="Leventa logo" width="96" />

# Leventa

**Mobile app for an internal property listing system.**
Guests browse listings, Marketing manages them, Admin runs the whole operation.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
![Backend](https://img.shields.io/badge/Backend-Go%20%2B%20Fiber-00ADD8?logo=go&logoColor=white)

</div>

## About

Leventa is the mobile front end of a property listing system used by an agency. Customers browse available properties without an account and reach the responsible Marketing agent through WhatsApp. Staff log in as **Marketing** or **Admin** to manage listings, owners, ownership documents, deals and commissions.

It consumes a Go + Fiber + PostgreSQL REST API. Authorization and privacy are enforced by the backend; the app only reflects what the backend returns.

<!-- Add screenshots here, e.g. a table of 3-4 images from docs/screenshots/ -->

## Features

**Guest (no account)**
- Browse and search properties with filters (type, sale/rent, location, price, area, bedrooms, facilities) and sorting
- Property detail with photo gallery
- Contact the listing's Marketing agent via WhatsApp

**Marketing**
- Create and edit own listings, upload photos, change listing status
- Manage owner details and ownership documents (PDF/JPEG/PNG)
- Read-only view of co-listed properties, with availability toggle and document download
- Read-only view of own deals and commissions
- Update own WhatsApp number

**Admin**
- Create and manage user accounts, roles and status
- Assign co-listing Marketing and transfer ownership
- Record Deal / Cancel outcomes and manage commissions
- Manage master data (provinces, cities, districts, facilities)

## Highlights

- **One login, no role picker.** The role comes from the backend session, never from user input.
- **Privacy by design.** Owner data, exact addresses and ownership documents are never cached or logged, and the backend only sends them to authorized roles.
- **Token handling.** Access/refresh tokens are kept in secure storage (Keychain / Keystore); expired tokens are refreshed once, then the user is returned to login.
- **Caching with TTL.** In-memory cache per session, public master data also on disk, stale-while-revalidate for public lists.
- **Rate-limit aware.** Debounced search, no automatic retry on `429`.
- **Responsive.** Phone and tablet layouts.

## Tech stack

| Area | Choice |
|---|---|
| Framework | Flutter, Dart `^3.12.2` |
| State & routing | [GetX](https://pub.dev/packages/get) |
| Networking | [Dio](https://pub.dev/packages/dio) |
| Secure storage | `flutter_secure_storage` |
| Local preferences | `shared_preferences` |
| Images & files | `cached_network_image`, `image_picker`, `file_picker`, `share_plus` |
| Other | `url_launcher`, `intl`, `lucide_icons_flutter` |

## Project structure

```text
lib/
├── main.dart
├── app/            # theme (design tokens), routes, session guard
├── core/           # config, network client, cache, storage, utils, shared widgets
└── features/
    ├── auth/           # login, session
    ├── guest/          # guest shell, filters
    ├── properties/     # models, query, repository, detail
    ├── marketing/      # listings, owner, photos
    ├── documents/      # ownership documents
    ├── deals/          # deals & commissions
    ├── admin/          # users, master data, listing panel
    └── master_data/    # provinces, cities, districts, facilities
```

Product, API and architecture notes are in [`docs/`](docs/).

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `^3.12.2`)
- Android Studio / Android SDK, or Xcode for iOS
- A running Leventa backend

### Install

```bash
git clone https://github.com/IlhamGhaza/leventa-fe
cd leventa-fe
flutter pub get
```

### Run

```bash
# Android emulator with the backend on localhost:8080 (default)
flutter run

# Any other backend (use HTTPS outside local development)
flutter run --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

The default `API_BASE_URL` is `http://10.0.2.2:8080/api/v1` (the emulator's alias for the host machine). On a physical device, use your machine's LAN IP. Plain HTTP is only allowed for `10.0.2.2` and `localhost`.

Postman collection and environment for the API are in [`docs/`](docs/).

### Build

```bash
flutter build apk --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

### Test

```bash
dart format .
flutter analyze
flutter test
```

## Author

**Ilham Ghazali** — [@IlhamGhaza](https://github.com/IlhamGhaza)
