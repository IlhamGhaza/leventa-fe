# Mobile Implementation Plan

Work incrementally; no unreviewed code dumps. Aligned with the backend (D-026 to D-032).

## Phase 0 — Repository and Figma audit
- Inspect the Flutter repository: versions, architecture, state, routing, theme, API status.
- Compare the Guest, Marketing and Admin screens with Figma.
- Remove screens of the removed flows (registration, favorites, inquiries, customer notifications, leads, follow-ups, surveys) and their routes, state, API calls and tests (D-032).

## Phase 1 — Foundation
Leventa identity, theme tokens, responsive foundation, routing, environment config, API client (envelope, `X-Request-ID`, error mapping), cache layer (TTL, per-session keys, invalidation; see APP_ARCHITECTURE → Caching), shared components, app shell.

## Phase 2 — Auth and role routing
Session restoration, automatic guest mode, login from inside the app (no registration), refresh/logout (clears session caches), Profile with own WhatsApp number edit (`PATCH /auth/me`), Guest / Marketing / Admin routing, unsupported-role screen for unknown or retired roles, 429/`Retry-After` handling and search debounce.

## Phase 3 — Guest discovery
Home, list with search/filters/pagination, detail with all structured sections, sold/rented history badge, WhatsApp action from `contact.whatsapp_url`, privacy-safe public projection.

## Phase 4 — Marketing listings
Dashboard, My listings (primary / co-listing), create and edit own listing, images, owner form and exact address for Primary only, co-listing read-only view and availability toggle.

## Phase 5 — Ownership documents
Checkbox per property type, upload/replace/delete (Primary), list/download/share (Primary and co-listing), private storage and cleanup, 409/422 handling.

## Phase 6 — Deals and commissions (read-only for Marketing)
Own deals and commissions with backend values, no client calculation.

## Phase 7 — Admin
Users (add, edit incl. WhatsApp number, activate/deactivate, role, delete), all deals and commissions, co-listing and ownership transfer, record Deal or Cancellation, commission management, audit log.

## Phase 8 — Polish and release readiness
Tablet adaptation, accessibility, loading/empty/error/offline/permission states, performance and pagination, tests, analysis, docs.

Each phase ends with `dart format`, `flutter analyze` and relevant tests. Do not continue while critical authorization or privacy failures remain.
