# Screen Specification

Mobile feature map aligned with the backend (D-026 to D-032). Before implementation, compare it with the existing Figma and Flutter repository.

> Scope change (D-032, approved): the former Customer screens (registration, favorites, inquiry form, my inquiries, customer notifications) and the Marketing lead screens (lead inbox, lead detail, follow-ups, surveys) are removed. Screens that still fit the flow (home, property list/detail, login, profile, listing management) are kept and adapted.

## Shared
- Splash / session restoration.
- The app opens in guest mode automatically; a Login entry inside the app leads to email/password login. No role selector, **no registration** (Admin creates accounts).
- Profile (from `GET /auth/me`), sign out. Logged-in users can edit **their own WhatsApp number** (`PATCH /auth/me`, D-033); name, email and role are read-only (Admin-managed).
- Error screens show the `X-Request-ID` of the failed call so support can find it in the server log.

## Guest screens (no login)
Default shell when nobody is logged in.
- Home: search, recent listings, property-type entry points (house, apartment, ruko, factory).
- List: search and filters: transaction type, property type, price range, land and building area, province / city / district, facilities, bedrooms/bathrooms, sort; pagination.
- Detail: gallery, price, sale/rent, status badge for sold/rented, short description, all structured sections (data, ownership documents as checkmarks, rooms, facilities, outdoor, distances), general location (province, city, district, sub-district, area label), Marketing contact card (name + WhatsApp; photo optional, initials when absent). The public response has no coordinates: a map, if shown, is placed from the general location only, never an exact pin.
- WhatsApp button: opens `contact.whatsapp_url` from the response; if no number is available, show a clear state instead of a dead button.
- Sold/Rented history section (`history=true`) with badge.

Guest restrictions: no favorites, no inquiry form, no owner data, no exact address, no coordinates, no downloads.

## Marketing screens
- Dashboard: own listings by status, own deals, own commissions summary.
- My listings: tabs "Primary" (`scope=mine`) and "Co-listing" (`scope=co_listing`), clearly distinguished.
- Create listing: type, sale/rent, price, general location (province → city → district), facilities, all detail sections, description, images, restricted address, owner details (private form).
- Listing detail: Primary sees edit actions, exact address, owner (via owner endpoint), documents and team; co-listing sees the same view without owner data and without edit actions except the status toggle (available / reserved / maintenance). Role-specific fields come from the detail endpoint; list items are always the public shape.
- Ownership documents: list, upload (PDF/JPEG/PNG; only when the matching checkbox is on), replace, delete (Primary only), download or share (Primary and co-listing). A checkbox cannot be turned off while its document exists.
- Deals and commissions: read-only lists and detail of own records (official backend values).
- Profile: edit own WhatsApp number (this number is the public contact on every listing where the user is Primary). Show the normalized number returned by the backend.

Marketing restrictions: no deal recording, no commission editing, no co-listing or ownership transfer, never another Marketing user's owner data or documents.

## Admin screens (D-032)
- Users: list, detail, **add user** (the only way to create Marketing or Admin accounts), edit (name, email, phone, **WhatsApp number**), activate/deactivate, change role (never own role), delete (soft).
- Listing team: view, add, replace and remove co-listing members; transfer Primary Marketing.
- Record outcome on a property: Deal form (type, price, buyer/tenant name, date, notes) or Cancellation (optional note).
- Commissions: list, change percentage, mark paid/cancelled while pending.
- Audit log viewer.
Admin never sees owner data, exact address or ownership documents.

## Required states for every data-driven screen
Loading · success · empty with a next action · recoverable error with retry · offline/timeout · validation error (422) · unauthorized (401) → login · too many requests (429) → wait for `Retry-After`, no automatic retry · forbidden (403) · not found (404) · conflict (409, e.g. a second deal on the same property) · pull-to-refresh or pagination where applicable.
