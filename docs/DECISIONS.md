# Decisions and Open Questions

## Known decisions
- Product working name: **Leventa**. Flutter/Dart mobile app.
- Existing theme palette: primary `#2563EB`, secondary `#22C55E`, success `#16A34A`, warning `#F59E0B`, danger `#DC2626`, background `#F8FAFC`, white surface, text `#0F172A`, secondary text `#64748B`, border `#E2E8F0`, Inter. Responsive mobile and tablet are mandatory.
- The system is **internal** (backend D-026). Roles: `sales` (UI label Marketing) and `admin`. Customers are guests without an account; `customer` and `staff` roles do not exist.
- Login has no role selector and **no registration**; Admin creates accounts.
- Guests browse the public catalog and contact Marketing on WhatsApp. No chat, no favorites, no inquiries, no notifications.
- No leads, follow-ups or surveys (backend D-027). Marketing reports deals to Admin outside the app; Admin records **Deal** or **Cancelled** on the property.
- Cancelled → property `archived` and hidden from all lists. Deal → `sold`/`rented` kept as history with a badge, plus a pending commission for the Primary Marketing.
- Commission: backend default 2.5% (D-016), Admin may override/mark paid while pending; the app never calculates it. The final commission scheme is not decided.
- Primary Marketing alone edits a listing and sees owner PII. Primary and co-listing see the exact address. Co-listing is read-only (plus availability toggle) and never sees owner data.
- The WhatsApp contact is the representing Marketing user's own number, public via `contact`; never the owner's number (D-023). The user edits their own number in Profile (`PATCH /auth/me`, D-033); Admin can also set it.
- Property types: `house`, `apartment`, `shop_house` (ruko), `factory`. Listing fields follow the Cluster Mawar reference (D-028).
- Ownership documents (D-029): flag true → the document can be uploaded; Primary writes, Primary and co-listing read; Admin and guests none.
- Troubleshooting (D-030): every response carries `X-Request-ID`; show it on error screens.
- **All roles use the mobile app (D-032):** guest by default, Marketing and Admin after login. The app opens in guest mode automatically; login is reachable from inside the app.
- **Accounts are created only by Admin** (Admin "add user" screen); there is no self-registration.
- **Screens of removed flows are removed:** customer registration, favorites, inquiry form, my inquiries, customer notifications, leads, follow-ups, surveys.
- **Marketing photo on the contact card is optional:** the API currently returns none; show initials. Show a photo only if the backend provides one.
- **Self-service WhatsApp number (D-033):** every logged-in user may change only their own WhatsApp number in Profile.
- **Client-side caching:** see `docs/APP_ARCHITECTURE.md` → Caching. Public data may be cached; private data is memory-only per session or not cached.
- **Abuse protection (D-031):** the backend rate limits per IP (429 + `Retry-After`) and caps search input. The app must debounce search, avoid automatic retry loops, and respect `Retry-After`.

## Not yet confirmed
1. **App name:** Leventa is a working name, not yet approved.
2. **Figma inventory and Flutter repository architecture:** audit the real files (Phase 0).
3. **Final commission scheme** and which Marketing users see which commission records (backend currently: Marketing own records only, Admin all).

Image and document limits are already defined by the backend: `UPLOAD_MAX_SIZE` (default 5 MB); images JPEG/PNG/GIF/WebP; documents PDF/JPEG/PNG.

Do not silently resolve questions that affect business rules, privacy, money or role access.
