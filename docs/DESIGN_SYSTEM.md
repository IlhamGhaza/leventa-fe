# Leventa Design System

## Brand direction
Leventa should feel like a trustworthy, modern property platform: professional, clear, calm, practical, and premium without looking like a luxury-hotel template. Prioritize property photography, readable specifications, clear prices, location hierarchy, and strong information organization.

Do not replace the established palette with generic AI gradients or unrelated colors. Design skills may recommend refinements, but preserve these brand tokens unless the user explicitly approves a brand change.

## Existing palette
| Token | Value | Usage |
|---|---|---|
| Primary | `#2563EB` | Main actions, active navigation, links |
| Secondary | `#22C55E` | Positive secondary actions, selected accents |
| Success | `#16A34A` | Success states, available/complete status |
| Warning | `#F59E0B` | Pending/attention states |
| Danger | `#DC2626` | Destructive actions, errors, sold/rented status where appropriate |
| Background | `#F8FAFC` | App background |
| Surface | `#FFFFFF` | Cards, sheets, dialogs |
| Text primary | `#0F172A` | Main text |
| Text secondary | `#64748B` | Supporting text |
| Border | `#E2E8F0` | Dividers, outlines |
| Typography | Inter | Primary font family |

## Visual principles
- Material 3 foundation with a tailored Leventa visual identity.
- Clean layouts, generous but efficient whitespace, consistent 8pt spacing rhythm.
- Rounded cards and controls; subtle borders/elevation, not heavy shadows everywhere.
- Property photos are prominent, use consistent aspect ratios and graceful loading/error placeholders.
- Price and property status must be easy to scan.
- Use semantic color tokens; do not scatter raw hex values through widgets.
- Use icon assets/icons consistently; do not use emoji as UI icons.
- Avoid excessive gradients, glassmorphism, decorative animation, dense dashboard clutter, and generic template layouts.
- Use clear labels; do not rely on placeholders alone.
- Touch targets should be comfortable and accessible.

## Responsive requirements
Support:
- Small phones: 360–389 logical px.
- Standard phones: 390–430 logical px.
- Tablets: 768–1024 logical px.
- Larger tablet layouts where applicable.

Responsive behavior:
- Mobile-first single-column layouts.
- Tablet may use two-column master/detail, wider cards, adaptive navigation or navigation rail.
- Forms should adapt into columns only when space supports it.
- Images, grids, typography and spacing must adapt to available width.
- No horizontal overflow or clipped critical content.
- Test portrait and landscape where relevant.

## Component foundations
Create/reuse theme extensions and shared components for:
- Color and typography tokens.
- Buttons, text fields, dropdowns, chips, badges.
- Property card and property gallery.
- Price display and property specification rows.
- Empty/loading/error states.
- Form sections and validation messages.
- Confirmation dialogs and bottom sheets.
- Role-aware navigation shell.

## Accessibility
- Maintain readable contrast.
- Respect system text scaling.
- Support screen readers with semantic labels.
- Focus order and keyboard interaction for tablet/keyboard use.
- Do not communicate status by color alone.
- Respect reduced-motion preferences where applicable.

## Brand name usage
Display **Leventa** consistently in splash/onboarding, login branding, app metadata where appropriate, and documentation. Do not invent a logo asset; use a clean text wordmark until an approved logo exists.
