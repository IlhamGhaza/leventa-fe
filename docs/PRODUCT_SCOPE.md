# Product Scope

Mirrors the backend decisions D-026 to D-032 (`docs/DECISIONS.md` in the backend repository). The backend is authoritative.

## Product
**Leventa** — mobile app of an **internal** property listing system for one company. It is not an e-commerce marketplace and not a customer portal. There is no chat inside the app: people talk on WhatsApp and by phone.

## Main workflow
Property owner calls a Marketing user or the office → that Marketing user creates the listing (house, apartment, shop/ruko, factory) → the listing is public (owner data and exact address hidden) → a guest taps the WhatsApp button and talks to the Marketing user outside the app → when a deal or a cancellation happens, Marketing tells Admin outside the app → Admin records **Deal** (property becomes sold/rented, commission created) or **Cancelled** (owner no longer sells; property is hidden from lists).

## Who uses the app
### Guest (no account)
Customers are guests. They have no login, no role, no favorites, no inquiries and no notifications.
- Browse, search, filter and view public listings.
- Tap the WhatsApp button of the representing Marketing user (`contact` in the property response).
- Cannot see owner data or the exact address.

### Marketing (backend role: `sales`)
- Create listings (creator becomes Primary Marketing); edit only own primary listings, images and owner details.
- Upload, view and download ownership documents of own listings (Primary); co-listing Marketing can view and download them (D-029).
- Co-listing Marketing: read-only view of the listing including the exact address, never owner data; may toggle availability (available / reserved / maintenance).
- View own deals and own commissions.
- Public contact is the Marketing user's own WhatsApp number, editable by the user in Profile (D-033) and by Admin.
- Cannot record deals, edit commissions or touch another Marketing user's listing, owner data or documents.

### Admin (backend role: `admin`)
All of these are in the mobile app (D-032):
- Create and manage Marketing and Admin accounts (the only way to get an account), including each Marketing user's WhatsApp number.
- View all deals and all commissions.
- Manage co-listing members (max 3 Marketing per listing including primary) and transfer the primary Marketing (audited).
- Record a Deal (type sale/rent, final price, buyer/tenant name, date, notes) or a Cancellation on a property.
- Manage commission: default 2.5%, override percentage and set paid/cancelled while pending.
- Read audit logs and manage master data.
- Never edits listing content, never sees owner data, exact address or ownership documents.

The `staff` and `customer` roles no longer exist. The app opens as guest automatically; Marketing and Admin log in from inside the app.

## Property privacy
- Guest and Admin views show general location only (province, city, district, sub-district, area label).
- Restricted address fields: block, cluster, street, house number, floor, room, and exact coordinates.
- Owner name, phone, email and private address: Primary Marketing only, through the owner endpoint.
- Exact address and coordinates: Primary and co-listing Marketing of that listing.
- Ownership documents: Primary and co-listing Marketing only.
- The public response has no coordinates. A guest map, if shown, uses the general location only, never an exact pin.

## Listing status
- `available` and `reserved` are shown as available. `sold` and `rented` stay visible as history with a SOLD/RENTED badge and are never presented as available or offered as availability filters.
- `archived` (cancelled) listings are hidden from every list and return 404 for guests.
- `draft` and `maintenance` listings are visible only to the people who work on them (Primary, co-listing) and Admin.
- Primary sets `draft`/`available`/`reserved`/`maintenance`/`archived`; co-listing sets `available`/`reserved`/`maintenance`; `sold`/`rented` come only from an Admin Deal.

## Listing content (reference: Cluster Mawar page)
Header (title, price, sale/rent, short description, area label, gallery) · Data & Keterangan (kelurahan, postal code, land and building area, orientation, maintenance fee) · Ownership documents (checkboxes per property type) · Room specification · Facilities (electricity, AC, TV, water, furnishing) · Outdoor (pool, garage, front/back yard, balcony) · Distance to public facilities (school, bus terminal, MRT/LRT, toll, hospital) · Map · Marketing contact card (name, WhatsApp, optional photo with initials fallback; no email).
The reference page's owner phone and its inquiry form are not part of the app.

## Business rules surfaced in the UI
- One Primary Marketing per listing; at most two co-listing Marketing users.
- Admin manages co-listing and ownership transfer only; this never grants listing-edit or owner-data rights.
- One outcome (deal or cancellation) per property.
- Deal finalization and commission amounts are computed by the backend. The app displays returned values only and must not calculate or change them.
