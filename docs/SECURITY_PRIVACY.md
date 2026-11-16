# Mobile Security and Privacy

## Authentication
- Use secure platform storage for tokens (guests store none).
- Never print tokens, passwords or sensitive payloads in logs or crash reports.
- Handle refresh/revocation as the backend defines; clear user-scoped state and session caches on logout or account switch.
- Only public data (master data, public listings, property images) may be cached on disk. Role-specific projections stay in memory for the current session; owner data and documents are never cached.
- Show the `X-Request-ID` of failed calls (not tokens, not bodies) so support can trace a problem in the server log.

## Role and ownership
- Role comes from the verified backend auth context. Client-side guards are not authorization.
- Primary Marketing edits only listings where they are primary owner.
- Co-listing Marketing is read-only (plus the availability toggle) and never gets owner data.
- Admin never edits listings and never receives owner data, exact address or ownership documents.

## Owner data and address privacy
- Owner name, phone, email and private address: Primary Marketing only, for that user's own listing.
- Exact block, cluster, street, house number, floor, room and coordinates: Primary and co-listing Marketing of that listing.
- Guests, other Marketing and Admin never receive them; never rely on widget visibility, the API response itself is scoped.
- The guest map must not show an exact pin.

## Ownership documents (D-029)
- Visible only to Primary (upload, replace, delete, view, download) and co-listing (view, download). Admin and guests are denied.
- Download with the bearer header, store in an app-private location, share through the system share sheet only on the user's explicit action, then remove the temporary file.
- Do not keep documents in image/file caches, thumbnails, backups or analytics. Do not log file names or contents.
- Allowed types: PDF, JPEG, PNG, up to the backend upload limit (`UPLOAD_MAX_SIZE`, default 5 MB).

## External intents
- WhatsApp opens with `contact.whatsapp_url`, which uses the representing Marketing user's number and a public-safe prefilled message (title/code, price, general location). Never the owner's number.
- Validate/encode external URLs and handle WhatsApp not being installed.

## General
- Validate forms on the client for usability; the backend decides.
- No PII in analytics or crash breadcrumbs unless explicitly approved and protected.
- Handle permission denial for image/file pickers gracefully.
