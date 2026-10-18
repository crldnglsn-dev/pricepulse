# PricePulse — UI/UX Design Specification

**Part 2 · Design System & Reusable Components**

---

## 1. Design tokens

### 1.1 Color

**Milk & Blush** — a warm, light palette. The app is about soft things
(prices, favourites, small purchases), so the base is warm paper rather than a
dark slab, and the accents are rose, lilac and mint.

**The fill / text split.** On a dark theme one colour can serve as both a
fill and a label. On paper it cannot: a soft rose reads at 2.5:1 as text,
which is not enough. So each hue has a *fill* and a *text* variant, and the
text variant is the one that carries a label. `test/theme_contrast_test.dart`
holds this honest: body text 7:1, captions and small text 4.5:1, UI chrome
3:1.

**Neutrals (surfaces & borders)**

| Token | Hex | Usage |
|---|---|---|
| `bg` | `#FFF9F6` | Warm paper — app background, app bar |
| `surface` | `#FFFFFF` | Cards, nav bar, fields, sheets |
| `surfaceElevated` | `#FFFCFB` | Chips, dialogs, snackbars |
| `surfaceHover` | `#F7EFF4` | Pressed wash on a tappable surface |
| `border` | `#EFE3EA` | Standard 1px borders |
| `borderSubtle` | `#F7EFF3` | Low-emphasis card borders |
| `scrim` | `#333E2B36` | Modal backdrop |

**Brand**

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#FF6FA5` | Primary button fill, ripple, selected chip border — **fills only** |
| `primaryHover` | `#FF87B4` | Hover state of primary |
| `primaryPressed` | `#E85A8E` | Ripple/down state |
| `primaryContainer` | `#FFE4EE` | Blush fill — selected chip, avatar, highlights |
| `onPrimary` | `#4A1F36` | Text/icon **on** `primary` — deep plum, 5.4:1 |
| `accent` | `#C33D6E` | Brand as **text**, a glyph or a border on a light surface, 4.8:1 |
| `onPrimaryContainer` | `#8A2450` | Text on `primaryContainer` |
| `secondary` | `#A78BFA` | Lilac — secondary emphasis |
| `secondaryContainer` | `#EEE8FF` | Soft lilac fill ("Top pick" badge) |
| `secondaryTint` | `#4A2E93` | Text on `secondaryContainer` |
| `tertiary` | `#5ECFB6` | Mint — tertiary emphasis |

**Semantic**

| Token | Hex | Usage |
|---|---|---|
| `success` | `#2FA37B` | Lowest-price accents, savings icon — **fills and icons** |
| `successContainer` | `#DFF5EB` | Savings banner / savings chip fill |
| `onSuccess` | `#14503A` | Text and icons on `successContainer`, 8.2:1 |
| `warning` | `#B8780E` | Outdated-price hint, partial-data notices |
| `error` | `#C2303F` | Validation text, destructive actions, error banners |
| `errorContainer` | `#FFE3E7` | Error toast/banner fill |
| `favourite` | `#E8437E` | The filled heart on a photo, 3.8:1 on a near-white scrim |

**Text**

| Token | Hex | Usage |
|---|---|---|
| `textPrimary` | `#2E2733` | Warm charcoal — primary text, prices, 14:1 |
| `textSecondary` | `#5C5468` | Secondary text, captions, 7.2:1 |
| `textMuted` | `#6F6679` | Muted text, timestamps, hints, 5.4:1 |
| `textDisabled` | `#B5ACBD` | Disabled controls |

**Depth**

| Token | Hex | Usage |
|---|---|---|
| `shadow` | `#1FE86FA8` | The soft shadow under a card — rose-tinted, so it belongs to the palette |
| `shadowStrong` | `#2EE86FA8` | The one surface that floats above everything |

**Background wash**

| Token | Hex | Usage |
|---|---|---|
| `meshBlush` | `#FFD9E6` | Soft gradient blob, top-left |
| `meshLilac` | `#E4DCFF` | Soft gradient blob, top-right |
| `meshButter` | `#FFEFCB` | Soft gradient blob, lower-right |
| `meshMint` | `#D2F3E9` | Soft gradient blob, mid-left |

These are **painted**, not blurred. A live `BackdropFilter` behind a
scrolling list re-blurs the whole area every frame, which is the most
expensive thing you can put on a budget phone, and it would only frost the
app's own content anyway. The wash sits behind the list and never moves.

**Marketplace identification** (store accent dots/badges only — never full-control backgrounds)

| Store | Hex | Rationale |
|---|---|---|
| Shopee | `#E2553A` | Muted orange-red of the Shopee brand, darkened for paper |
| Lazada | `#4A6FD4` | Softened brand blue, readable on `surface` |
| TikTok Shop | `#149C93` | Brand teal, readable on `surface` |

Marketplace accents appear as a **colored dot + store name** (and the store monogram glyph); the store name text is always adjacent so color is never the only signal. Full store-colored buttons or brand logos are not used.

### 1.2 Typography

**Family:** Nunito (bundled `assets/fonts/Nunito-Variable.ttf` — one variable file covering the 200–1000 weight range), system fallback. Nunito's rounded terminals and open apertures are most of what makes the app read as friendly rather than technical, and its numerals stay legible at price sizes. It ships as a single 270 KB file against Inter's 1.6 MB for the same four weights, so the whole asset payload went **down** by 1.35 MB in the re-skin.

Every style states its weight twice — once as `fontWeight`, for the engine's
font matching, and once as an explicit `wght` axis variation, so a bold
heading is bold rather than a slightly-heavier 400.

**Numbers:** every price uses `FontFeature.tabularFigures()` so `₱1,150`, `₱1,299` and `₱1,299.00` stack vertically aligned in the offer list. Prices use `,` thousands separators and `₱` prefix; `:00` decimals only when cents are non-zero.

| Style | Size / Weight | Letter-spacing | Usage |
|---|---|---|---|
| `display` | 28 / 700 | −0.4 | Welcome hero, rare page titles |
| `headline1` | 22 / 700 | −0.2 | Screen titles, product name on Details |
| `headline2` | 18 / 600 | −0.1 | Section headers ("Available offers") |
| `title` | 15 / 600 | 0 | Card & list titles, nav labels |
| `bodyLarge` | 16 / 400 | 0.1 | Product descriptions, primary reading |
| `body` | 14 / 400 | 0.1 | Offer rows, secondary text |
| `caption` | 12 / 500 | 0.2 | Timestamps, meta, tabs |
| `overline` | 11 / 600 | 1.0 | Eyebrows — "RECORDED PRICE", categories on Details |
| `priceLarge` | 24 / 700 (tabular) | −0.2 | Hero price on Comparison |
| `price` | 16 / 700 (tabular) | 0 | Offer-row prices |
| `labelLarge` | 14 / 600 | 0.3 | Buttons |
| `labelSmall` | 12 / 600 | 0.15 | Badges, chips, pills |

Line heights 1.3–1.45; long product names wrap naturally (never ellipsis on the Details screen; 2 lines + ellipsis on cards).

### 1.3 Spacing (4pt grid)

| Token | px |
|---|---|
| `space-1` | 4 |
| `space-2` | 8 |
| `space-3` | 12 |
| `space-4` | 16 (screen padding) |
| `space-5` | 20 |
| `space-6` | 24 (section gap) |
| `space-8` | 32 |
| `space-10` | 40 |

Grid gap 12 (cards), card padding 14–16, list rows 64dp tall. Vertical rhythm between sections on a scroll screen = 24.

### 1.4 Corner radius

| Token | px | Usage |
|---|---|---|
| `r-xs` | 12 | Pills, badges, chips |
| `r-sm` | 18 | Inputs, small cards, buttons |
| `r-md` | 24 | Product cards, sheets, dialogs, offer rows |
| `r-lg` | 30 | Hero carousel cards |
| `r-pill` | 999 | Search field, ghost buttons, category pills |

Soft and generous. The rounded shape is most of what makes a surface read as
friendly rather than technical. Images inside cards crop to the card radius
(no double-rounded look).

### 1.5 Elevation, borders, iconography, motion

**Shadows before borders.** On paper, a hard outline reads as a diagram and a
soft shadow reads as a card. Cards sit on `surface` with a rose-tinted
shadow (`shadow`, blur 20, offset 0/8, spread −6) and a hairline
`borderSubtle` stroke. Floating layers (bottom sheets, dialogs, the sticky
comparison footer) use `shadowStrong` and no border.

**Icons:** Material Symbols outline style (weight ~1.5), drawn at:

| Size | Usage |
|---|---|
| 24 | Bottom nav, app bar |
| 22 | Card actions (favorite) |
| 20 | Buttons with text, section headers |
| 18 | Dense list affordances |
| 14 | Inline badges, store checks |

**Motion:**

| Moment | Behavior |
|---|---|
| Route push (Details, Search) | Slide-up-right 250ms, easeOutCubic; back uses the same inverse (system gesture supported) |
| Tab switch | Crossfade 200ms, and the selected nav icon pops 1→1.22→1 on a half-sine over 420ms |
| Press | Scale to 0.96, easing in; on release it springs back past the resting size and settles (easeOutBack) |
| Card entrance (Home, Search grids) | Fade + 14dp lift, each card 45ms behind the one before it |
| Favorite tap | Heart scale pop 1→1.25→1 at 200ms + fill color change |
| Savings figure | Counts up from 0 to the recorded saving over 650ms when the details screen opens — it lands on the same number it would show without the animation |
| Skeleton shimmer | 1s loop, only during loading |
| Bottom sheet / dialog | Fade + slide 220ms with scrim fade |
| Snackbar | Auto-in, 4s info / 6s errors, slide-up |

Honor `MediaQuery.disableAnimations` — all motion degrades to instant swap.

**Sound/haptics:** light haptic tick on favorite toggle and on "Open listing" success; none elsewhere.

---

## 2. Reusable component inventory

Every component below is defined once and reused across screens. Naming shown matches the planned Flutter widget set.

### 2.1 Buttons & icon buttons

| Component | Anatomy / spec | States |
|---|---|---|
| `PrimaryButton` | Fill `primary`, radius `r-sm` (12), height 48, `labelLarge`, optional leading icon, content vertical-center | default / pressed (`primaryPressed` + scale .97) / disabled (`textDisabled` fill) / loading (spinner replaces label, width preserved) |
| `SecondaryButton` | 1px `border` stroke, `surfaceElevated` fill, text `textPrimary` | same set; loading allowed |
| `TextButton` | `primary` text, no fill | disabled → `textDisabled` |
| `GhostButton` (pill) | radius `r-pill`, `surfaceElevated` fill, used for filter/sort chips toggles | selected variant uses `primaryContainer` + `onPrimaryContainer` |
| `IconButton` | 48×48 target (min 44), default 24 icon | pressed → `surfaceHover` circular ripple; disabled → `textDisabled` |
| `FavoriteButton` | Heart `r_md` ghost circle (32 visual on 44 target), empty = white outline, active = `secondary` fill | transition animation per motion table |

### 2.2 Search

| Component | Spec |
|---|---|
| `SearchBarHome` | Read-only pill (height 52), `surface` fill, 1px `border`, leading search icon `textSecondary`, hint "Search products…", trailing microchip "50 products". Tap → push Search Results with autofocus |
| `SearchField` (results screen) | Real `TextField`, same visual, autofocus, clear (×) affordance, leading back? — no, app bar back stays; field sits in app bar bottom |

### 2.3 Category chips

Pill row, horizontal scroll, height 38, gap 8. Unselected: `surface` + border, `textSecondary`. Selected: `primaryContainer` fill + `onPrimaryContainer` text + primary border. Leading icon for first chip ("All" uses grid icon). Chips carry an optional count read as muted small text only when the dataset is loaded.

### 2.4 Product card (grid) & carousel card

| Part | Spec |
|---|---|
| Container | `surface` + 1px `borderSubtle`, radius `r-md`, padding 12 body |
| Image | 4:3 crop in `surfaceElevated` well, radius `r-sm`; favorite heart absolute top-right on a scrim circle; error → `MissingImage` (see 2.9) |
| Store dots | Row of up to 3 dots (8px) using store accents — present stores colored, absent stores `border` gray. Caption "3 stores" beside; tooltip-free |
| Title | `title`, max 2 lines + ellipsis |
| Meta | Category `caption`, `textMuted` |
| Price row | `price` 16/700 tabular lowest price; prefix "from " as `caption` when >1 offer; trailing `SavingsBadge` ("Save ₱199") when ≥2 comparable offers |

Card tap target = whole card; visual pressed = `surfaceHover` + scale .98.

**Carousel card** (Home "Top picks"): width 180, image 1:1, same body, adds a top-left `secondaryContainer` "Top pick" label pill. No favorite on carousel (keep it clean; tap opens Details).

### 2.5 Comparison components (details screen)

| Component | Spec |
|---|---|
| `OfferRow` | Height 64, `surface` + 1px `borderSubtle`, radius `r-md`. Leading: store dot + monogram (36). Middle: store name `body` 600 + freshness `caption` muted ("Recorded Oct 16"). Trailing: price `price` tabular + `LowestPill` or `chevron`. Slotted: `OfferRow.lowest` (green 3px left rail + green price + `LowestPill`), `OfferRow.disabled` (muted, dashed border, "No recorded offer yet" caption, no CTA). `void:disabled` never shown — a store with data is always present per record |
| `LowestPill` | `success` text on `successContainer`, `labelSmall`, leading check icon, radius `r-xs`. Text: "Lowest" |
| `SavingsBadge` | Green savings text — icon `savings` 14 + "Save ₱149", same green treatment, `labelSmall` on `successContainer` |
| `FreshnessLabel` | Clock icon 14 + `caption` muted: "Prices recorded periodically · last checked Oct 16, 2026" |
| `PriceRangeBar` | Optional summary bar: horizontal track 6px `surfaceElevated`, rounded; 3 marker dots positioned proportionally across min–max range; green left edge to the lowest marker. Pure visual (no live data) |
| `SavingsBanner` | Full-width `successContainer` card radius `r-md`: icon + "₱149 cheaper than the highest offer" (`body` 600, `onSuccess`) + subline "Buy on TikTok Shop for ₱1,150" (`caption`) |
| `StickyCompareBar` | Bottom safe-area bar, `surfaceElevated` + top border `border`: `PrimaryButton` full width "Open cheapest · Shopee · ₱1,150"; disabled when cheapest URL missing → caption underneath "Listing link unavailable" |

### 2.6 Favorites & status affordances

| Component | Spec |
|---|---|
| `StatusChip` | Small pill, 18pt dot + `caption`. Variants: `SyncedChip` (`success` dot, "Synced"), `OfflineChip` (`warning` dot, "Offline — changes will sync later") |
| `RemoveFavorite` | Heart toggle reused; un-favoriting animates card collapse + shows undo `Snackbar` ("Removed from favorites · Undo") 4s |

### 2.7 Form fields

`AppTextField`: `surface` fill, 1px `border`, radius `r-sm`, height 52, `body` text. Floating label style: label moves to top on focus/fill (`caption`). States: default / focused (primary border + 1.5px) / error (error border + `caption` error message under field) / disabled / with `show/hide` password affordance (24 icon). Error message never replaces the hint; validation shows after first blur or submit.

### 2.8 Feedback components

| Component | Spec |
|---|---|
| `AppDialog` | `surface` radius `r-md`, title `headline2`, body `body`, actions = `TextButton` + `PrimaryButton` right-aligned. Used for: sign-out confirm, link-unavailable, privacy info |
| `AppSnackbar` | `surfaceElevated` + border, radius `r-sm`, `body` text. Success (green left rail + check), Error (error left rail), Info (neutral) |
| `AuthPromptSheet` | Bottom sheet: heart illustration in `secondaryContainer`, title "Save & sync favorites", copy "Create a free account so your favorites follow you across devices.", `PrimaryButton` "Sign in or create account", `TextButton` "Not now" |

### 2.9 Placeholder & empty-state primitives

| Component | Spec |
|---|---|
| `MissingImage` | `surfaceElevated` well + centered outlined image icon 48 `textMuted` + optional `caption` "No image" — used in cards and hero |
| `EmptyState` | Centered composition: 72 icon in `primaryContainer` circle, `headline2` title, `body` muted body (max 2 lines), optional `PrimaryButton`/`TextButton` CTA. Used for: empty search, empty favorites, no products, signed-out favorites |
| `Skeleton` | `SkeletonBox` = rounded 12 rect `surfaceElevated` with shimmer sweep (moving highlighted band). Variants sized per layout slot (image 4:3, text lines 3, pill rows) |
| `ErrorState` | Reuses `EmptyState` structure with error icon, message, and `PrimaryButton` "Try again" |

### 2.10 Navigation & shells

| Component | Spec |
|---|---|
| `AppBar` | Height 56, `bg` fill (transparent over scroll with hairline border appearing on scroll), leading/trailing `IconButton`s. Title uses `headline1` for screen titles, or overline+title combo for Details |
| `BottomNav` | 3 items, icons + `labelSmall` labels, height 64 + safe-area, `surface` fill, top hairline border `border`. Active: primary icon + `onSecondaryContainer`-style primary label; inactive `textMuted`. Selected icon switches to filled variant |
| `HomeAppBar` | Wordmark: pulse/graph glyph in `primary` + "PricePulse" `headline1`; trailing: avatar circle 32 (`primaryContainer`, initial letter) → switches to Account tab (deep-links tab, keeps stack) |

### 2.11 Micro-interaction conventions

- Buttons shrink scale .97 on press; ripples follow Material enabled state.
- All tappable rows show a pressed `surfaceHover` wash.
- Loading never blanks a screen that already has content: firestore-stream list refresh happens in-place; initial loads show skeletons in the exact layout footprint.
- Focus order follows reading order (document order in Flutter by default); every icon-only control exposes a `Semantics` label / tooltip.

---

## 3. Accessibility baseline (applied everywhere)

- **Contrast:** body text ≥ 7:1 on surfaces; `body`/`caption` ≥ 4.5:1; large text and UI chrome ≥ 3:1. Every text token is checked against the surface it sits on by `test/theme_contrast_test.dart`, so a palette change that breaks a label fails the build rather than shipping.
- **Touch targets:** ≥ 48×48 for icons and list rows, ≥ 44 minimum; buttons ≥ 48 tall.
- **Text scaling:** supports Android font scale up to 200% without clipping — prices use `FittedBox`-free layouts with breakpoints; `PriceRangeBar` becomes a simple stat row when constrained.
- **Color independence:** "Lowest" = green price **+ pill + check icon**; store identity = colored dot **+ name**. Never color alone.
- **Focus & keyboard:** visible focus rings (accent border on fields/buttons); form flow navigates ✓ next → submit.
- **Reduced motion:** honor `disableAnimations`.
- **Large screens:** content column capped at 480dp and centered on wide/landscape; grid adapts 2→3 columns ≥ 600dp width.