# PricePulse — UI/UX Design Specification

**Part 4 · States catalog · Sample content · Design QA · Handoff plan**

---

## 1. Global state catalog (every screen × every state)

| Screen | Loading | Empty | Error | Success |
|---|---|---|---|---|
| Home | Skeleton rows + grid | "No products yet" | `ErrorState` + "Try again"; cached → `OfflineChip` | Grid fades in staggered |
| Search Results | Skeleton grid | Query → "No results for …" + suggestions; category empty → "Nothing here yet" | `ErrorState` + "Try again" | Caption "12 of 50 products" |
| Product Details | Full-screen skeleton | — (not found handled as error) | Not found / deleted → "Product not found" + Home | Savings banner + offer rows |
| Favorites | Skeleton grid | Signed out → sign-in prompt; empty → "No favorites yet" + Discover CTA | Offline → cached + `OfflineChip`; stream error with no cache → `ErrorState` | Synced chip visible |
| Account | Profile skeleton | — | Auth flows bubble errors inline | Profile + dialogs available |
| Auth (all 4) | Button loading spinners | — | Inline `errorContainer` banner / field errors | Welcome snackbar + pop |
| URL launch | — | — | `LinkUnavailableDialog` (+ snackbar when offline) | Info snackbar "Opening Shopee…" |
| Global offline | — | — | All reads fall back to cache; writes queue | Badges: `StatusChip`/`OfflineChip` |

---

## 2. Sample content — 50-product dataset skeleton

**Rule:** prices below are *sample seed data*, formatted exactly like the Firestore documents. URLs are **placeholders** — every `productUrl` must be replaced with a verified, working listing before the demo (Milestone 5). Records in the sample marked `[SEED]` are realistic but **not verified**; the shipped dataset must go through the QA in §4.

**10 categories × 5 products = 50.** Shown here: one representative record per category (10 of 50) + the full naming scheme.

| id | name | category | Shopee ₱ | Lazada ₱ | TikTok ₱ | notes |
|---|---|---|---|---|---|---|
| `keyboard_001` | RGB Wireless Mechanical Keyboard | PC Parts | 1299 | 1250 | 1150 | [SEED] |
| `redmi_013` | Xiaomi Redmi Note 13 8/256GB | Smartphones | 8999 | 9249 | 8849 | [SEED] |
| `ace_ack_001` | Anker Soundcore Life Q20 Headphones | Audio | 1899 | 1829 | 1799 | [SEED] |
| `band_9_001` | Huawei Band 9 | Wearables | 1799 | 1750 | 1830 | [SEED] |
| `switch_lite` | Nintendo Switch Lite (Turquoise) | Gaming | 9985 | 9790 | 10150 | [SEED] |
| `ssd_t7_1tb` | Samsung T7 Portable SSD 1TB | PC Parts | 4495 | 4390 | 4550 | [SEED] |
| `rice_cooker` | Hanabishi 1.8L Rice Cooker | Kitchen | 1499 | 1599 | 1449 | [SEED] |
| `robot_vac_01` | Dreame D10 Plus Robot Vacuum | Home & Living | 15999 | 16950 | 15900 | [SEED] |
| `kettle_3l` | Imarflex Electric Kettle 1.7L | Kitchen | 899 | 950 | 875 | [SEED] |
| `fitme_cone` | Maybelline Fit Me Concealer | Beauty | 259 | 275 | 249 | [SEED] |

Each record (Firestore shape, matches Part 2 of the plan doc):

```json
{
  "id": "keyboard_001",
  "name": "RGB Wireless Mechanical Keyboard",
  "category": "PC Parts",
  "brand": "[optional]",                      // only if truly known
  "description": "…2–3 honest sentences…",
  "imageUrl": "assets/products/keyboard_001.jpg",
  "featured": true,
  "comparable": true,                          // false when variant mixing would mislead
  "offers": [
    { "store": "Shopee",     "price": 1299.00, "productUrl": "[PLACEHOLDER — replace]", "lastCheckedAt": "2026-10-16" },
    { "store": "Lazada",     "price": 1250.00, "productUrl": "[PLACEHOLDER — replace]", "lastCheckedAt": "2026-10-16" },
    { "store": "TikTok Shop","price": 1150.00, "productUrl": "[PLACEHOLDER — replace]", "lastCheckedAt": "2026-10-16" }
  ]
}
```

**Dataset rules**
- Every product must have ≥1 offer; gaps (a store with no listing) are encoded by simply omitting that store from `offers` → the UI renders the `OfferRow.disabled` state.
- Duplicate detection: two records never share the same `name` + `category`.
- Diversity rule for the demo: ≥6 of the 50 records have all 3 stores, ≥10 have exactly 1 store, and ≥2 have `comparable: false` with a clear caption — so every UI state is exercised in the demo.
- Prices must be plausible today and formatted as ₱; cents only when real.

---

## 3. Design QA checklist

Run against the running app on a real Android device/emulator.

### 3.1 Visual & hierarchy
- [ ] Screen padding is uniformly 16; sections separated by 24; card internals 12–16 (no broken grid).
- [ ] No two screens implement the same component differently (product card grid identical on Home/Favorites/Results).
- [ ] Every price uses tabular figures; `₱1,150` / `₱1,299` columns align in offer rows.
- [ ] Marketplace accents never used as full control backgrounds; store name always adjacent to its dot.
- [ ] Green appears only for savings/lowest/success — zero green on non-saving UI.
- [ ] No gratuitous gradients/glass effects anywhere.

### 3.2 Functionality journeys
- [ ] J1 Compare: Home → search → card → details → offers sorted cheap→high → banner/sticky CTA correct → opens cheapest listing (or honest unavailable state).
- [ ] J2 Save: signed-out heart → prompt → register → favorite applied → Favorites tab shows it → restart app → still there → different device sign-in → still there (Firestore).
- [ ] J3 Account: register → welcome → profile shows name/email → log out confirm → signed-out states correct.
- [ ] Sort (low→high) matches lowest-price computation; savings = max−min; correct when 2 vs 3 offers.

### 3.3 States coverage
- [ ] Airplane-mode mid-session: Home cached + banner; Favorites chips; details price still visible; URL tap shows offline snackbar.
- [ ] Kill Firestore data (dev rule) → Home error state; Details not-found for bad id; deleted-while-open no crash.
- [ ] Empty favorites, empty search, single-offer details, disabled offer row — all render deliberately.

### 3.4 Accessibility & robustness
- [ ] Touch targets ≥ 48dp for icons/rows; ≥ 44 minimum.
- [ ] Android font scale 200% → no price/button clipping; long titles wrap; sticky CTA grows.
- [ ] Contrast scan: `textSecondary`/`textMuted` pass 4.5:1; UI chrome ≥ 3:1 (adjust tokens if a label fails).
- [ ] Cheapest is identifiable without color (pill + icon + "Lowest" text).
- [ ] TalkBack sample-announces: cards, offer rows ("TikTok Shop, ₱1,150, lowest"), heart toggles, nav tabs.
- [ ] Keyboard: auth submit order, search results update per keystroke, keyboard never covers the primary button.
- [ ] Hardware back from every pushed route; predictive-back friendly.
- [ ] Landscape/tablet: content centered ≤ 480dp; grid 3-col at ≥ 600dp.

### 3.5 Honesty / scope
- [ ] Freshness label present on all price surfaces.
- [ ] No "live", "auto-updating", or "price drop alert" UI anywhere.
- [ ] No social login chrome.
- [ ] Savings never computed across `comparable: false` records.
- [ ] Privacy dialog matches stored data exactly.

---

## 4. Implementation-ready handoff plan

### 4.1 File map (Flutter)

```
lib/
  main.dart                       // MaterialApp, theme wiring, initial route
  theme/
    app_theme.dart                // ThemeData, dark scheme, component themes
    app_colors.dart               // tokens from Part 2 · §1.1
    app_typography.dart           // text theme + tabular helper
    app_spacing.dart              // gap/radius/elevation tokens
  models/
    product.dart                  // Product + Offer, minPrice, savings, sorting
  data/
    product_repository.dart       // Firestore products stream + local cache
  services/
    auth_service.dart             // register/login/logout/reset wrappers
    favorites_service.dart        // per-user favorites stream + writes
  providers/
    app_state.dart                // auth + products + favorites + connectivity
  navigation/
    app_shell.dart                // bottom nav shell
  screens/
    home_screen.dart
    search_screen.dart            // query + category modes, sort
    product_details_screen.dart   // the comparison hero
    favorites_screen.dart
    account_screen.dart
    auth/welcome_screen.dart
    auth/login_screen.dart
    auth/register_screen.dart
    auth/forgot_password_screen.dart
  widgets/
    buttons.dart  search_bar.dart  category_chips.dart  section_header.dart
    product_card.dart  offer_row.dart  savings_badge.dart  price_text.dart
    favorite_button.dart  status_chip.dart  app_text_field.dart
    empty_state.dart  skeleton.dart  dialogs.dart  snackbars.dart
    missing_image.dart  price_range_bar.dart  sticky_compare_bar.dart
assets/
  fonts/Inter/ (400/500/600/700)
  products/ (50 images)   brand/ (monograms/wordmark)
```

### 4.2 Build order (suggested milestones)

| Order | Work | Deliverable |
|---|---|---|
| 1 | Tokens + theme + typography + spacing (Part 2 §1) | `flutter run` shows the design system on a demo scaffold |
| 2 | Shell + bottom nav + route table | Tab switching + theme everywhere |
| 3 | Product model + seed sample + repository | 10 sample records runnable |
| 4 | ProductCard + Home (all states) | Home fully interactive w/ skeleton/error/offline |
| 5 | Product Details + comparison widgets | The hero screen end-to-end |
| 6 | Search screen (query/category/sort) | Full discovery |
| 7 | Firebase config + Auth screens + auth service | Real register/login/logout |
| 8 | Favorites service + Favorites screen + sync chips | Cloud favorites with honesty states |
| 9 | Account screen + dialogs + privacy | Account complete |
| 10 | Dataset to 50 + URL verification + QA checklist §3 | Demo-ready build + APK |

### 4.3 Open questions for the client (before Milestone 5)

1. Will internet be available during the class presentation? (Drives whether a fully-offline fallback seed is required.)
2. Who owns the Firebase project + admin access after handover?
3. Are product images available as files, or only as marketplace URLs (permission to hotlink)?
4. Professor expectation: store links only, or account linking? (Design assumes links only.)
5. Acceptance criteria confirmation (the plan doc's §7 list).

### 4.4 Handover artifacts

- Source (git repo to be initialized), `README` with Firebase setup, seed script/JSON for the 50 products, APK (`flutter build apk --release`), a 4-minute demo script covering the 3 journeys, and this specification set.

---

*End of design specification. Next step: begin Milestone 2 implementation using the build order in §4.2.*