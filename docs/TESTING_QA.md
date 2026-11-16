# Testing and QA

## Commands
```bash
dart format .
flutter analyze
flutter test
```

## Unit tests
- Auth/session transitions, including the guest state.
- Role mapping: no session → Guest shell; `sales` → Marketing shell; `admin` → Admin shell; `customer`, `staff` and unknown values → unsupported-role screen.
- 429 handling waits for `Retry-After` and never auto-retries; search is debounced.
- DTO mapping and null/optional fields for the public, primary/co-listing and admin projections.
- Filter/query serialization (`type`, `transaction_type`, `facility_ids`, `history`, `include_history`, `scope`, pagination).
- Error mapping (401/403/404/409/422/429/5xx) and `X-Request-ID` capture.
- `contact.whatsapp_url` handling, including a missing number.
- Document type rules per property type; upload blocked when the matching flag is off.
- Commission and deal values are shown as returned, never recalculated.
- Cache: keys include the session key; TTL expiry; pull-to-refresh bypasses; mutations invalidate the related entries; 401/403/404 drop the entry; logout/role change clear all session entries; owner data and documents are never cached; private projections never reach disk.
- Profile WhatsApp edit: sends only `whatsapp_number`, shows the normalized value, maps 422 to a field error.

## Widget tests
- Login has no role selector and no registration entry.
- App opens in guest mode and shows the guest shell without a token.
- Guest detail shows all detail sections, SOLD/RENTED badge, no owner fields, no exact address, no document download.
- Marketing: Primary sees edit actions; co-listing view is read-only (status toggle only); owner fields and exact address are not rendered when absent.
- Documents: Primary can upload/delete; co-listing can only view/download; flag-off state explains why upload is unavailable.
- Admin shell shows users (add user), team management, Deal/Cancel and commission screens; unsupported roles see the unsupported screen.
- Removed screens (registration, favorites, inquiries, leads, surveys, customer notifications) are unreachable.
- Loading, empty, error with retry, permission-denied and conflict states.
- No horizontal overflow at small phone and tablet widths.

## Integration tests
- Guest browse → detail → WhatsApp.
- Login → Marketing shell; sign out → guest shell with session data and session caches cleared.
- Marketing changes own WhatsApp number → a fresh listing detail shows the new `contact.whatsapp_url`.
- Log in as user A, log out, log in as user B → no data of A appears (cache isolation).
- Marketing creates a listing → it appears in My listings; another Marketing cannot edit it.
- Marketing sets a flag, uploads a document, downloads it; co-listing can download; another Marketing and Admin get 403.
- Admin records a Deal → listing shows SOLD and the commission appears for the Primary Marketing; a Cancellation removes the listing from lists; a second outcome shows the 409 message.

## Manual QA sizes
360×800, 390×844, 430×932, 768×1024, 1024×768 logical px.

## Definition of Done
- No critical analyzer errors; tests pass or failures are reported.
- No horizontal overflow in supported layouts.
- No sensitive field or document leaks in unauthorized views, caches or logs.
- Approved screens remain intact except the removed flows, retired only with confirmation.
- API behavior matches the current backend Swagger.
- UI work uses all four mandatory skills and records their actual use in the completion report.
