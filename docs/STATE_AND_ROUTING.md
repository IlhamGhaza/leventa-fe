# State Management and Routing

## Authentication state
Model at least: unknown/initializing, **guest (no session)**, authenticated with user identity and backend role, refreshing/expired session, logout in progress.

Do not infer role from email, local preferences, route parameters or user input.

## Role routing
- No session → **Guest shell** automatically (browse, search, detail, WhatsApp). A "Login" entry inside the app (e.g. profile tab) leads to the login screen; there is no registration.
- `sales` → Marketing shell (UI label Marketing).
- `admin` → Admin shell (D-032).
- Any other role value (including the retired `customer` and `staff`) → unsupported-role screen with sign out. Never guess.

## Navigation
- Predictable back behavior; few bottom-nav destinations.
- Guard protected routes for UX; the backend remains the security boundary.
- On logout or role change, clear session-scoped state (including downloaded documents and cached owner/address data) and return to the guest shell.
- A 401 after one failed refresh returns to login; a 403 shows a permission-denied state, not an empty list.

## Abuse protection (client side)
- Debounce search input (about 400 ms) and cancel the previous request when the query changes.
- Never retry automatically on 429; show "too many requests" and allow a retry only after `Retry-After` seconds.
- Retry other failures at most once, only for idempotent GET requests, with backoff.
- Disable submit buttons while a request is in flight (login, uploads, Deal/Cancel) to prevent double submits.
- Keep search input within 100 characters and stop infinite scroll before offset 10 000 (ask the user to narrow filters).

## State behavior
- Separate loading, loaded, empty, failure and permission-denied states.
- Prevent stale data from one user/role appearing after an account switch.
- Invalidate relevant caches after mutations (e.g. a listing's status after an Admin outcome); full rules in `docs/APP_ARCHITECTURE.md` → Caching.
- Do not keep mutable copies of backend truth such as deal status or commission amount without refresh.
- Documents: never write them to shared or cache directories; delete the temporary file after sharing.
