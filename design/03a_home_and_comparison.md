# PricePulse — UI/UX Design Specification

**Part 3a · Hero screens: Home & Product Details / Price Comparison**

These two screens define the product. Every other screen reuses their components.

---

## 1. Home / Discover

**Purpose:** instant discovery and a zero-friction path to comparison. Answer "what can I compare, and where do I start" in 3 seconds.

### 1.1 Layout (top → bottom, scroll body)

```
┌ HomeAppBar ────────────────────────────────┐
│ ◆ PricePulse                    [avatar]   │  wordmark + account shortcut
├────────────────────────────────────────────┤
│ (scroll content, 16 side padding)          │
│                                            │
│  [  🔍  Search products…         · 50  ]   │  SearchBarHome pill, height 52
│                                            │
│  (category chips — horizontal scroll)      │
│  [All] [Smartphones] [Laptops] [Audio] …   │
│                                            │
│  TOP PICKS                              ›  │  SectionHeader
│  ┌──────┐ ┌──────┐ ┌──────┐ (horizontal) │
│  │card  │ │card  │ │card  │               │
│  └──────┘ └──────┘ └──────┘               │
│                                            │
│  All products · 50                      ›  │  SectionHeader + count
│  ┌────────────┐ ┌────────────┐            │  2-col grid, gap 12
│  │ ProductCard│ │ ProductCard│            │
│  └────────────┘ └────────────┘            │
│  …                                         │
└────────────────────────────────────────────┘
┌ BottomNav: Home(filled) | Favorites | Account ┐
```

### 1.2 Detailed specs

**HomeAppBar** (56): left wordmark — 20px pulse/graph glyph (`trending_down`-style stroke path in `primary`) + "PricePulse" `headline1` on one baseline. Trailing avatar (32 circle, `primaryContainer`, white initial letter from `auth.currentUser?.displayName` or neutral "P") — tap switches bottom nav to Account tab; tooltip "Account".

**SearchBarHome**: read-only pill (52h, `surface`, border 1, radius pill). Leading `search` 20 `textSecondary`, hint "Search products…" `body`, trailing 50-product count chip (`caption` on `surfaceElevated`). Whole pill is a tap target → push `SearchResultsScreen` with `mode=query`. The count chip reads "50 products" from the loaded dataset length (hidden during loading) — this microcopy makes the catalog feel substantial. Semantics label "Search products".

**Category chips**: single-select. Items (10): All · Smartphones · Laptops & Tablets · Audio · Wearables · Gaming · PC Parts · Home & Living · Kitchen · Beauty · Accessories. Tap behavior: `All` re-renders Home grid inline; any concrete category pushes `SearchResultsScreen` with `mode=category` + preset. (Decision: concrete categories leave Home so the grid doesn't jump mid-scroll and the results screen owns sort/filter.)

**"Top picks" carousel**: 4–6 curated products flagged in the dataset (`featured: true`). Horizontal `ListView`, height ~250, card 180w. Card = image 1:1, "Top pick" pill (top-left, `secondaryContainer`), title 2 lines, price row + `SavingsBadge`. No favorite button (declutter; taps open Details).

**"All products · 50"**: `SectionHeader` (headline2) + trailing `TextButton` "See all" → Search Results (All). Grid = `SliverGrid` 2 columns, `mainAxisExtent` ~296, gap 12, `ProductCard`.

**Pull-to-refresh**: refetches the Firestore products stream; success → silent; failure while content exists → inline `OfflineChip` banner above grid (not a full-screen error).

### 1.3 Behavioral & states

| State | Presentation |
|---|---|
| Loading (first open) | Skeleton layout: avatar shimmer, search pill shimmer, chip row (5 pill skeletons), carousel of 2 card skeletons, grid of 6 `SkeletonBox` cards |
| Loaded | Full layout |
| Error (no cached data) | `ErrorState` centered "We couldn't load products" + "Try again" |
| Error (cached data exists) | Keep content; show `OfflineChip` banner "Offline — showing saved products" at top of scroll |
| Empty dataset | Centered `EmptyState`: "No products yet" + caption "The catalog is being set up." (only reachable in dev) |
| Search tap | Push Search Results (keyboard autofocus) |

**Success path visual:** after data arrives, cards fade in gently (200ms stagger by index, capped 8 items).

### 1.4 Flutter implementation notes

- `CustomScrollView` + `SliverAppBar`(pinned, collapsing search) is acceptable but the simple version (fixed app bar + `ListView` with headers) is preferred for reliability.
- Grid uses `SliverGridDelegateWithFixedCrossAxisCount` w/ `mainAxisExtent` to keep card heights uniform.
- Carousel: `ListView.separated` horizontal, `RepaintBoundary` per card.
- Read-only search: `Material` + `InkWell` inside pill (not a real `TextField`) to avoid keyboard focus steal.

---

## 2. Product Details / Price Comparison

**Purpose (primary differentiator):** answer "which store is cheapest and how much do I save" — instantly, honestly, actionably.

### 2.1 Layout (scroll body + sticky footer)

```
┌ AppBar (56) ────────────────────────────────┐
│ ‹ Back                                  ♥ │   favorite (empty/filled)
├────────────────────────────────────────────┤
│  [image hero: 1:1, surfaceElevated well]   │   max 380dp, centered
│  "3 prices recorded" chip (top-left overlay)│
│                                            │
│  CATEGORY (overline · textMuted)           │  e.g. "ELECTRONICS · AUDIO"
│  RGB Wireless Mechanical Keyboard          │  headline1, wraps fully
│                                            │
│  ┌ SavingsBanner ───────────────────────┐  │  if ≥2 offers & min<max
│  │ ✓ ₱149 cheaper than the highest offer│  │
│  │    Buy on TikTok Shop for ₱1,150     │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ┌ Price summary card ──────────────────┐  │
│  │  from ₱1,150           Range: ₱1,150│  │
│  │  ▓▓▓▓▓▓▓▓▓▓▓▓●──●────────●          │  │  PriceRangeBar
│  │  ₱1,150   [✓ Lowest stored price   ] │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  AVAILABLE OFFERS (headline2)              │
│  ┌ OfferRow.lowest (green rail) ────────┐  │
│  │ ● TT  TikTok Shop    [✓ Lowest]      │  │
│  │       Recorded Oct 16       ₱1,150   │  │
│  ├──────────────────────────────────────┤  │
│  │ ● SP  Shopee                    ₱1,299│  │
│  │       Recorded Oct 16                 │  │
│  ├──────────────────────────────────────┤  │
│  │ ● LZ  Lazada                   ₱1,250│  │
│  │       Recorded Oct 16                 │  │
│  └──────────────────────────────────────┘  │
│                                            │
│  ABOUT THIS PRODUCT                        │
│  description… (2 lines then More/Less)     │
│                                            │
│  💬 clock: "Prices are recorded manually · │
│   last checked Oct 16, 2026. They may      │
│   differ from live store prices."          │
└────────────────────────────────────────────┘
┌ StickyCompareBar (safe-area) ──────────────┐
│  [ Open lowest · TikTok Shop · ₱1,150   ]  │  PrimaryButton full width
└────────────────────────────────────────────┘
```

### 2.2 Detailed specs

**AppBar:** back `IconButton`; favorite `FavoriteButton` (outline heart; filled `secondary` when saved). Both 48 targets. On scroll, hairline border appears.

**Image hero:** aspect 1:1, `surfaceElevated` well, centered image with `fit: contain`, generous breathing room. `MissingImage` if asset missing. Overlay top-left "3 prices recorded" chip (12px, `surface` 80% opacity pill, `caption`).

**Title block:** overline category (textMuted), then product full name `headline1` (never ellipsis). No invented metadata.

**SavingsBanner** (only when ≥2 offers and min < max): `successContainer`, check icon in success circle, title `body` 600 `onSuccess`: "₱149 cheaper than the highest offer", subline `caption`: "Buy on TikTok Shop for ₱1,150". If only 1 offer exists → no banner; the price card simply states it's the only recorded price.

**Price summary card** (`surface` + border, r-md, padding 16):
- Top row: "from ₱1,150" `body` textSecondary + right-aligned "Range ₱1,150 – ₱1,299" `caption` muted.
- `PriceRangeBar`: track 6px; three 8px marker dots (store accents) positioned by `(price−min)/(max−min)`; rail to the min marker green, remainder `border`. Renders horizontally; if any price is missing/zero → bar hidden, replaced by caption "1 recorded offer".
- Bottom row: big `₱1,150` `priceLarge` in `success` + `LowestPill` on the right. Single offer → price `textPrimary`, pill removed.

**Available offers:** section header + stack of `OfferRow`s (gap 8). Sorted **cheapest first** (fixed rule — predictable, no sort control on this prototype). Each row:
- Leading: store dot (10) in store accent + monogram circle 36 (`surfaceElevated`, store accent letter: "S" / "L" / "TT").
- Middle: store display name `body` 600; below `caption` muted "Recorded Oct 16, 2026".
- Trailing: price `price` (tabular). Lowest row: price `success`, green 3px left rail, `LowestPill`; other rows price `textPrimary` + chevron hint.
- **Stores without a recorded offer** render `OfferRow.disabled`: store name + caption "No recorded offer yet", dashed border, muted, no CTA. Absence is information — never hidden.
- **Row tap** (offer has URL): opens that store's listing. The row is the CTA (large target), Semantics label "Open Shopee listing".

**Freshness footer:** clock icon 14 + `caption` muted, wrapped, two lines max: "Prices are recorded manually for this prototype. Last checked Oct 16, 2026 — live store prices may differ." This is the honesty contract.

**About this product:** collapse/expand, opens at 2 lines. Content: `description`. Empty description → section omitted.

**StickyCompareBar:** pinned via `bottomNavigationBar` slot, `surfaceElevated`, top border, safe-area padding 12. `PrimaryButton` full width:
- Label: "Open lowest · Shopee · ₱1,150" (store display name + formatted cheapest).
- Tap → validate URL (`http/https`) → `url_launcher`; failure → `AppDialog` "Listing link unavailable" + copy-link button.
- Unavailable cheapest URL → button disabled + `caption` under bar "Listing link unavailable — check back soon".
- Success → info snackbar "Opening Shopee…" (1.5s) → OS handoff.

### 2.3 Exhaustive states

| State | Presentation |
|---|---|
| Loading | Skeleton: hero square, title lines, banner box, 3 offer-row skeletons, footer ghost |
| Not found (bad id) | `EmptyState` "Product not found" + "Back to Home" |
| Deleted while open | Stream-aware → same not-found state (no crash) |
| 1 offer only | No banner; price `textPrimary`; footer "Open · Shopee · ₱1,150"; pill → "Only recorded offer" (`caption` muted) |
| Missing/Invalid URL (one store) | That row's tap → `LinkUnavailableDialog`; other rows unaffected |
| Missing/Invalid URL (cheapest store) | Footer disabled + caption; each row still individually actionable |
| Non-http(s) scheme | Treated as unavailable — same dialog |
| Favorite tapped signed-out | `AuthPromptSheet`; "Sign in" pushes auth; return restores clean state |
| Offline while page open | Cached prices usable; footer tap → snackbar "+ can't open while offline" |

### 2.4 Comparison honesty (success-path microcopy)

- Lowest store is labeled "Lowest recorded price" — never "best deal".
- Savings only when ≥2 offers exist **and** all offers belong to the same product record (no variant mixing). The dataset is curated so each record = one comparable product (model/variant checked).
- If a record's offers differ in variant, dataset marks `comparable: false` → banner hidden, rows show caption "Different variant — shown for reference only".

### 2.5 Flutter implementation notes

- `Scaffold` body `CustomScrollView` + pinned `SliverAppBar`; footer in `bottomNavigationBar` slot (always visible; text-scale safe; no keyboard interference — no text input on this screen).
- Offers render inside the main scroll view (no nested `ListView`) to avoid scroll-physics bugs.
- `PriceRangeBar` = small `CustomPainter` (markers positioned by normalized price).
- Row heights: `minHeight` 64 so text scaling can grow them.
- URL check: `Uri.tryParse` and require `http`/`https` scheme; else treat as unavailable.