# Flutter App Architecture

## Stack
- Flutter / Dart. REST integration with the existing Go + Fiber backend.
- Use the state-management and routing approach already in the repository if sound; do not migrate frameworks without need.
- If starting from an empty repository, use a feature-first modular structure and one consistent state-management approach (Bloc is the preferred default).
- Maintained packages only; check maintenance, compatibility and license first.

## Suggested structure (adapt to the repository)
```text
lib/
  app/
    app.dart
    router/
    theme/
  core/
    config/
    network/
    error/
    storage/
    widgets/
    utils/
  features/
    auth/
    guest/
      home/
      properties/        # public list, detail, WhatsApp
    marketing/
      dashboard/
      listings/          # create, edit, status, images
      documents/         # ownership documents
      deals/             # read-only own deals
      commissions/       # read-only own commissions
    admin/               # users, team/transfer, deal/cancel, commissions, audit
    profile/
```

Do not create empty folders or abstractions for hypothetical modules. There are no `customer`, `favorites`, `inquiries`, `leads`, `follow_ups`, `surveys` or `notifications` features: the backend removed them.

## Layering
- Presentation: screens, widgets, state management.
- Domain: entities, repository contracts, use cases where they clarify business logic.
- Data: DTOs, API data sources, repository implementations, mappers.
- Keep separate DTO/UI models for the public, primary/co-listing and admin projections.
- Avoid giant widgets, giant BLoCs, hidden service locators and generic frameworks.

## Network
- Centralized API client, environment base URL, auth interceptor, timeouts, error mapping.
- Parse the envelope `{success, message, data, meta}` and read `X-Request-ID` on every response.
- Handle access-token expiry with a single in-flight refresh; retry only safe/idempotent requests.
- Multipart uploads: images (`image`) and documents (`doc_type` + `file`).
- No production secrets in the app.

## Local persistence
- Persist only session tokens (secure storage), safe preferences and the public caches listed below.
- Do not persist owner data, exact addresses or ownership documents in general-purpose caches.
- No local database until offline requirements justify it.

## Caching
The backend sends no cache headers (`Cache-Control`, `ETag`) and no 304, so the app owns caching. Goal: fewer calls (rate limit 300/min per IP), faster screens, no privacy leak.

One small cache layer in the data/repository layer (in-memory map with TTL; no new database). Every entry key = endpoint + full query + **session key** (`guest`, or user ID + role). Data of one session is never served to another.

| Data | Where | TTL | Notes |
|---|---|---|---|
| Master data (`/master-data/*`) | memory + disk (public) | 24 h | Refresh on pull-to-refresh; invalidate after an Admin master-data write. |
| Public list pages (`GET /properties` without `scope`) | memory | 5 min | Show cached page, refresh in background (stale-while-revalidate). |
| Public detail (`PublicProperty`) | memory | 5 min | Same. |
| Property images (`/uploads/...`) | disk image cache | by cache package | Public files. Use the repository's existing image cache; otherwise one maintained package (e.g. `cached_network_image`). |
| `scope=mine` / `scope=co_listing` lists, `PrimaryProperty`, `InternalProperty`, team | memory, current session | 1 min | Never on disk. |
| Deals, commissions, users, audit logs | memory, current session | 1 min | Never on disk. Always refetch after an Admin mutation. |
| `GET /auth/me` | memory, current session | session | Refetch after `PATCH /auth/me`, token refresh and app resume. |
| Owner (`/properties/{id}/owner`) | **not cached** | – | Fetch every time the screen opens. |
| Ownership documents and their list | **not cached** | – | Download to app-private temp, delete after use. |

Rules:
- Pull-to-refresh and retry always bypass the cache.
- After a mutation, drop the related entries: listing changes → that detail + all list pages; status/Deal/Cancel → detail, lists, deals, commissions; co-listing/transfer → detail, team, both Marketing scopes; user changes → users list; `PATCH /auth/me` → profile and every cached detail where this user is the contact.
- A 401, 403 or 404 removes the entry for that request; never show the cached copy as if still allowed.
- Logout, account switch, role change and a failed refresh clear every session cache (memory) and temp files. Public caches (master data, images) may stay.
- Never cache error responses or 429 responses.
- The backend stays the source of truth: money values (deal price, commission) are only displayed, never edited in the cache.

## Images
- Use backend-provided image URLs; include loading, error and placeholder states. Do not fabricate URLs.
