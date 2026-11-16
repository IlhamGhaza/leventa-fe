# API Integration Contract

The backend `docs/openapi.yaml` (served at `/swagger` and `/openapi.yaml`) and the running backend are authoritative. Base path: `/api/v1`. Confirm exact fields there before coding.

## Envelope and errors
- Success: `{ "success": true, "message": "...", "data": ..., "meta": { "page", "limit", "total", "total_pages" } }` (`meta` on lists).
- Error: `{ "success": false, "message": "...", "errors": [...] }`.
- Treat 400, 401, 403, 404, 409, 422, 429 and 5xx distinctly. Never turn a 403 into an empty success.
- 429: per-IP rate limit (all requests 300/min, login/refresh 5/min, uploads 30/min). Respect `Retry-After`; never retry in a loop.
- Search limits: `search` > 100 characters, more than 20 `facility_ids`, `(page-1)*limit` > 10 000, an unknown `sort`/`type`/`transaction_type`, or min > max return 422. A malformed ID or number in the query returns 400. `limit` outside 1–100 does **not** fail: the backend silently uses 20, so always read `meta.limit`.
- 404 can mean "hidden from you" (draft/archived listing, another Marketing user's deal or commission).
- Every response has `X-Request-ID`. Keep it with the error and show it on the error screen.

## Auth
- `POST /auth/login` (email + password only), `POST /auth/refresh`, `POST /auth/logout`, `GET /auth/me`.
- `PATCH /auth/me` body `{ "whatsapp_number" }` (D-033): the logged-in user changes **only their own** WhatsApp number. Empty string clears it. The backend normalizes it (e.g. `0812-3456-7890` → `6281234567890`); invalid → 422. Name, email, role and status stay Admin-managed.
- **There is no `/auth/register`.** Accounts are created by Admin.
- Roles: `sales` (Marketing) and `admin`. Guests have no token.
- Access tokens are short-lived; the backend re-reads role and status on every request, so a role change or deactivation applies immediately. Handle 401 by refreshing once, then returning to login.
- Login failures: 401 wrong credentials, 403 inactive account, 429 locked or rate limited.

## Public (no token)
- `GET /properties` and `GET /properties/{id}` return the public projection.
- `GET /master-data/provinces`, `/cities`, `/districts`, `/facilities` for filters.

Property list parameters: `search`, `type` (`house`, `apartment`, `shop_house` = ruko, `factory`), `transaction_type` (`sale`, `rent`), `province_id`, `city_id`, `district_id`, `facility_ids` (comma separated, listing must have all), `min_price`, `max_price`, `min_land_area`, `max_land_area`, `min_building_area`, `max_building_area`, `bedrooms`, `bathrooms`, `sort` (`newest`, `oldest`, `price_asc`, `price_desc`, `name_asc`, `name_desc`), `page`, `limit` (max 100), `history=true` (sold/rented only), `include_history=true` (available plus history; each item has `is_available` and `status_badge`). Marketing may add `scope=mine|co_listing` (optionally with `status`); Admin may add `status`. Without `scope`, Marketing gets the same available-only list as guests. `history`/`include_history` apply only to that default list (not with `scope` or for Admin).

**List items always use the `PublicProperty` shape**, for every role. Role-specific fields (`access_level`, `address`, coordinates, `marketing_team`) come only from `GET /properties/{id}`.

## Property projections (detail endpoint)
- `PublicProperty` (guests, Marketing without a relation to the listing): no owner data, no restricted address, no coordinates.
- `PrimaryProperty` (Primary and co-listing Marketing; `access_level` = `primary` or `co_listing`): adds `address` (`block_number`, `cluster_name`, `street_name`, `house_number`, `floor_number`, `room_number`), `latitude`, `longitude`, `marketing_team`; never owner data.
- `InternalProperty` (Admin): adds `access_level` (`admin`) and `marketing_team` only. No address, no coordinates.
- Detail sections come from `PropertyDetails` fields (`cert_*`, room counts, `has_*`, `dist_*`, ...). Use separate DTOs per projection; do not add private fields to the public model.
- `contact`: `{ name, whatsapp_number, whatsapp_url }` of the Primary Marketing of the listing. The URL is ready to open (prefilled, URL-encoded). The owner's number is never returned. `whatsapp_number`/`whatsapp_url` are absent when that user has no valid number. **Photo is optional**: the API currently returns no photo, so the card must work without one (initials). If a photo field is added later, show it only when present.

## Marketing endpoints
- `POST /properties` (owner nested in `owner`), `PATCH /properties/{id}` (Primary only), `DELETE /properties/{id}` (archives when a deal exists), `PUT /properties/{id}/status` body `{ "status" }`:
  - Primary: `draft`, `available`, `reserved`, `maintenance`, `archived`.
  - Co-listing: only `available`, `reserved`, `maintenance`, and not while the listing is `draft` or `archived`.
  - `sold`/`rented` come only from an Admin Deal. A `sold`/`rented` listing can only be moved to `archived`.
  - `POST /properties` accepts `status` `draft` or `available` (default `available`).
- Images: `POST /properties/{id}/images` (multipart field `image`; JPEG/PNG/GIF/WebP), `DELETE /properties/{id}/images/{imageId}` (Primary only). Image URLs are served by the backend under `/uploads`.
- Upload size limit for images and documents: `UPLOAD_MAX_SIZE` (default 5 MB).
- Owner: `GET|PATCH /properties/{id}/owner` (Primary only).
- Ownership documents (D-029): `GET /properties/{id}/documents`, `POST /properties/{id}/documents` (multipart `doc_type` + `file`; PDF/JPEG/PNG; the matching `cert_*` must be true; one per type, re-upload replaces), `GET /properties/{id}/documents/{docId}/download` (needs the bearer header; save the bytes to a private app location), `DELETE /properties/{id}/documents/{docId}`. Document types per property type: house shm/hgb/imb/pbb/girik/other; apartment shmsrs/hgb/imb/pbb/slf/other; shop_house shm/hgb/imb/pbb/slf/other; factory shm/hgb/hgu/imb/pbb/slf/other. File paths are never returned.
- `GET /deals`, `GET /deals/{id}`, `GET /commissions` (optional `status` filter), `GET /commissions/{id}`: Marketing gets only own records; Admin gets all.
- `GET /properties/{id}/co-listings` read-only team (Primary, co-listing and Admin).

## Admin endpoints
- Users: `POST /users` (the only way to create accounts; `name`, `email`, `password`, `role`, optional `phone`, `whatsapp_number`), `GET /users`, `GET /users/{id}`, `PUT /users/{id}` (`name`, `email`, optional `phone`, `whatsapp_number`), `DELETE /users/{id}` (soft delete), `PATCH /users/{id}/status` (`active`/`inactive`), `PATCH /users/{id}/role` (`sales` or `admin`; nobody changes their own role).
- Co-listing: `POST /properties/{id}/co-listings` and `PUT /properties/{id}/co-listings/{marketingId}` with body `{ "marketing_id" }`, `DELETE /properties/{id}/co-listings/{marketingId}`; `POST /properties/{id}/transfer-ownership` with body `{ "marketing_id" }` (new Primary).
- Outcome: `POST /properties/{id}/deal` (`type` `sale`/`rent`, `price` > 0, `buyer_name`, optional `deal_date` `YYYY-MM-DD` (default today), `notes`; `type` must match the listing) and `POST /properties/{id}/cancel` (optional `notes`). A second outcome returns 409.
- Commission: `PATCH /commissions/{id}` (`percentage` 0–100, pending only), `PATCH /commissions/{id}/status` (`paid` or `cancelled`, pending only).
- `GET /audit-logs`, master-data writes.

## Removed from the backend (do not call)
`/auth/register`, `/favorites`, `/inquiries`, `/leads` (incl. follow-ups, surveys, win/lost), `/units`, `/tenants`, `/notifications`, `/reports/*`.

## WhatsApp
Open `contact.whatsapp_url`. Never build a link from the owner's phone. Hide or disable the action when no URL is returned and say why.

## Commission
Backend owns percentage, amount and status. The app only displays them; it never calculates, edits or infers them (Admin changes go through the endpoints above).

## Data handling
Use server-side pagination, search and filters. Do not assume all roles get the same DTO. Do not cache owner data, exact addresses or documents in general-purpose caches.

## HTTP caching
The backend sends no `Cache-Control`, `ETag` or `Last-Modified` and does not answer 304. All caching is client-side and follows `docs/APP_ARCHITECTURE.md` → Caching. Property images under `/uploads` are public static files and may be cached on disk.
