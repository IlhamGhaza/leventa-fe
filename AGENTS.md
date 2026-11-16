# Agent Instructions — Leventa Mobile

## Product identity
Leventa is the mobile app of an internal property listing system. Guests (customers) browse without an account; staff log in as Marketing (backend role `sales`) or Admin (`admin`). There is no chat and no customer account.

## Required reading
Read `README.md`, then the relevant files in `docs/`. For UI work, `CLAUDE.md` contains mandatory skill requirements for Claude Code.

## Fixed decisions
- Flutter + Dart.
- Integrate with the existing Go + Fiber backend; do not invent a second backend.
- One login experience; no role picker and no registration. Backend identity determines role.
- Existing Figma designs must be audited before changing. Screens of the flows the backend removed (registration, favorites, inquiries, customer notifications, leads, follow-ups, surveys) are removed (approved, D-032).
- Theme tokens are specified in `docs/DESIGN_SYSTEM.md`.
- Responsive mobile and tablet layouts are required.
- Modular, maintainable Flutter structure; no overengineering.

## Authorization vocabulary
- Guest (no account): public property discovery and the Marketing WhatsApp contact only.
- Marketing / Sales: own listings, co-listing read-only view, ownership documents of listings they work on, own deals and commissions (read-only).
- Primary Marketing: listing creator/owner; only this user edits listing details, owner details and documents.
- Co-listing Marketing: read-only view including exact address (never owner data), availability toggle, document download; no edit and no ownership transfer.
- Admin: co-listing, ownership transfer, Deal/Cancel recording, commission, users (only Admin creates accounts). Fully in the mobile app (D-032).
- The app opens as guest automatically; Marketing and Admin log in from inside the app.
- `customer` and `staff` roles no longer exist.

## Security and privacy
- Role and user identity come from verified auth response/session, never a user-editable field.
- UI guards improve UX only; backend authorization remains authoritative.
- Never expose owner name/contact/private address or exact property address to unauthorized roles.
- Never use owner's WhatsApp number as the Marketing contact action.
- The WhatsApp action uses `contact.whatsapp_url` from the backend (the representing Marketing user's own number, edited by that user in Profile or by Admin).
- Ownership documents are private files: never cache, log or expose them outside authorized users.
- Caching follows `docs/APP_ARCHITECTURE.md` → Caching: public data may be cached; private data stays in memory for the current session only (owner data and documents never).
- Co-listing does not grant edit rights.
- Do not log tokens, passwords, owner PII, or sensitive payloads.

## Implementation
1. Inspect before editing.
2. Preserve existing features and visual decisions.
3. Implement one complete vertical slice.
4. Handle loading, empty, error, success, offline/network and permission-denied states.
5. Add tests for business-sensitive behavior.
6. Run `dart format`, `flutter analyze`, and `flutter test` (or relevant targeted tests).
7. Update docs when API contracts or app behavior change.

## Completion report
Summarize changes, screens affected, API endpoints used, permissions respected, tests and analysis results, and unresolved decisions.
