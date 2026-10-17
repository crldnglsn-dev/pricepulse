# PricePulse — UI/UX Design Specification

**Part 1 · Design Rationale & Information Architecture**

App: PricePulse · Flutter + Firebase · Android prototype
Scope: 50 curated products · Shopee / Lazada / TikTok Shop · recorded (not live) prices
Spec version: 1.0

---

## 1. Product experience

### 1.1 Who we are designing for

| Persona | Profile | What they need from PricePulse |
|---|---|---|
| Angela, 21 — college student | Buys daily necessities and gadgets on Shopee; bargain-driven; uses TikTok Shop for trends | To prove she is getting the cheapest price before checkout, without opening three apps |
| Marco, 28 — young professional | Compares tech purchases (laptops, audio, accessories); values speed and trust | A quick, honest comparison that tells him which store wins and how much he saves |
| The professor | Evaluates the prototype's completeness, polish, and honest scope discipline | A coherent app that demonstrates real engineering, clear flows, and no fake "live" claims |

Primary demo context: one Android device/emulator, in front of a class. Every screen must look complete, every state must behave gracefully, and the comparison logic must be visibly correct.

### 1.2 Core tasks (ranked)

1. **Compare** — find the cheapest recorded price for a product across Shopee, Lazada, TikTok Shop.
2. **Act** — open the winning store's listing with one tap.
3. **Keep** — save a favorite and find it later on any signed-in device.
4. **Discover** — search and browse by category.
5. **Identify** — recognize their account, sign out, understand what the app does with data.

### 1.3 Design priorities

1. **Decision speed on the comparison screen.** The details screen must answer "which store, how much, what do I save" within one glance — before any scrolling interaction is required.
2. **Honesty and trust.** Every price carries a recorded/checked date. Nothing announces itself as "live" or auto-updating. Savings figures are only shown between comparable offers of the same product.
3. **Consistency.** One design system, one component library, zero per-screen reinvention. This is the strongest signal of production quality in a class-demo app.
4. **Craft over spectacle.** No gratuitous gradients, glassmorphism, or oversized empty space. Precision, alignment, and restraint communicate "shopping utility".
5. **Resilience.** Loading, empty, error, and offline states are designed as first-class citizens — a demo is judged heavily on how the app fails.

### 1.4 Visual direction (rationale)

A **premium dark interface**:

- Price-comparison and price-tracking utilities read as neutral, "smart third-party tools" in dark mode. Mainstream PH shopping apps are light and brand-colored (Shopee orange, Lazada blue); a dark charcoal UI positions PricePulse as the *reference app*, not another storefront.
- Dark backgrounds make the three marketplace identifiers and the green savings signals pop with high contrast, focusing the eye on what matters (price).
- Deep charcoal `#121318` with purple `#7C4DFF` as primary keeps us distinct from every marketplace brand — purple implies "unbiased smart comparison" rather than competing with orange/blue/red store identities.
- **Green is semantically reserved** for lowest-price and savings signals only. Marketplace brand tints are used sparingly (small dots/badges, always adjacent to the store name) so brand colors assist recognition without overpowering the layout.

### 1.5 Design principles (decision filter for every screen)

1. Show the price first; show an offer only if it's actionable.
2. Never claim live data. (Freshness label on every price; a dedicated note on the comparison screen.)
3. Savings require comparable offers; represent gaps honestly (missing store = visible "no recorded offer" row).
4. Every control has four visible states: pressed, selected, disabled, loading.
5. Design for the demo moment: first-run, signed-out, offline, and empty states must all look intentional.

### 1.6 Assumptions (documented, not blocking)

- **Online-first, offline-tolerant.** Firestore is required for auth + sync; the UI handles unreachable network with cached data, banners, and retry states. (If the demo venue has no internet, we must decide with the client whether to pre-seed a local fallback — flagged in Part 5's open questions.)
- **Store linking, not account linking.** Marketplace CTAs open product URLs via `url_launcher`; no Shopee/Lazada/TikTok OAuth is implied.
- **Images:** bundled asset paths per product (`assets/products/<id>.jpg`) with a designed missing-image placeholder. If the client delivers permitted image URLs, the same product card renders them via network image with the identical placeholder fallback.
- **Dataset:** 10 categories × 5 products = 50 records. URLs and prices are curated sample data, verified before the demo (Milestone 5).
- **No ratings, stock, or invented social proof.** Only fields the product model actually has appear on screen.

---

## 2. Information architecture

### 2.1 Sitemap

```
Splash
└─ Main Shell — bottom navigation (3 tabs)
   ├── Home
   │    ├── Search bar (read-only surface) ──────────► Search Results
   │    ├── Category chips (single-select) ──────────► Search Results (category mode)
   │    ├── "Top picks" carousel ────────────────────► Product Details
   │    └── All-products grid ───────────────────────► Product Details
   │
   ├── Favorites
   │    ├── signed out ──► sign-in prompt (empty state + CTA)
   │    └── signed in ───► favorites grid ───────────► Product Details
   │
   └── Account
        ├── signed out ──► Welcome ──► Login / Create account / Forgot password
        └── signed in ───► Profile · preferences · app info · sign out

Full-screen pushed routes (no bottom nav — deeper context)
   ├── Search Results (query or category mode, sort + filter)
   ├── Product Details / Price Comparison  ← primary screen
   └── Auth stack: Welcome · Login · Register · Forgot Password
```

### 2.2 Navigation rules

- **Bottom nav = 3 fixed tabs**: Home (pulse), Favorites (heart), Account (person). Standard Material bar, ≥48dp touch height, safe-area aware, labels always visible.
- **Product Details is always a pushed route** on top of the tab shell — it owns a full app bar (back + favorite), preserves scroll context of the grid, and returns predictably. It is never a tab.
- **Search Results is a pushed route.** One screen serves two entry modes: *query mode* (from the search field) and *category mode* (from a chip). This avoids duplicating the results grid twice and keeps Home stable when filters change.
- Every pushed route supports the system back gesture; bottom-nav tab switches use crossfade, route pushes use slide-up-right (~250ms).
- Favorite toggling while **signed out** interrupts with an auth-prompt bottom sheet (never a dead tap).

### 2.3 User journeys

**Journey 1 — Compare & open the cheapest listing (primary)**
Home → tap search bar (or category chip) → Search Results → tap a product card → Product Details → (optionally re-sort) read the savings banner and price summary → tap "Open cheapest · Shopee · ₱1,150" in the sticky footer → external store listing opens.

**Journey 2 — Save a product for later**
Home → Product Details → tap ♥ in the app bar → (if signed out: auth-prompt sheet → sign in/register → session continues) → heart fills with pop animation → Favorites tab shows the saved item → tap it to reopen details.

**Journey 3 — Manage an account**
Account tab → signed out: tap "Create account" → register (inline validation) → lands in Account, profile visible → Favorites tab shows "synced" chip → sign out (confirm dialog) → welcome state with cached favorites clearly marked as hidden until sign-in.

### 2.4 Cross-cutting behavior

- **Keyboard:** auth and search screens are `Scrollable` + keyboard-aware; primary CTA lifts above keyboard; no fields are ever obscured.
- **Safe areas:** bottom nav, sticky comparison footer, and sheets respect system insets.
- **App lifecycle:** favorites state is always driven by the auth + Firestore stream — restart and re-login reproduce the same UI.