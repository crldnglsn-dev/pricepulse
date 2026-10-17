# PricePulse

Philippine e-commerce price comparison — Flutter + Firebase Android prototype.
Compare recorded prices across **Shopee, Lazada, and TikTok Shop**, open the
cheapest listing, and keep favorites synced to your account.

Approved design: [`design/`](design/) — see `design/README.md` for the doc index.

## Status — Milestone 2 complete

- **Design system**: tokens (color/typography/spacing/radius) in `lib/theme/`,
  Inter bundled in `assets/fonts/` (no network needed at demo time).
- **Components**: buttons, search bar, category chips, product/featured cards,
  offer rows, savings banner/badge, lowest pill, price range bar, sticky
  compare bar, status chip, skeletons, empty/error states, dialogs/snackbars.
- **Screens**: **Home** and **Product Details / Price Comparison** (the hero
  screen) fully built per `design/03a`. A lean **Search Results** screen is
  also included because Home's search bar and category chips route into it.
  Favorites/Account tabs are honest scaffolding shells for a later milestone.
- **Data**: 10 clearly-marked **seed** products from `design/04` §2
  (`lib/data/seed_products.dart`). Every `productUrl` is a placeholder on
  `example.invalid` — links are **not verified** and must be replaced in
  Milestone 5. The UI intentionally renders the designed "link unavailable"
  state for all of them.
- **State**: Provider (`ProductsProvider`) consumes `ProductRepository`, so
  Milestone 4 can swap the seed for a Firestore stream without touching UI.

## Commands

```sh
flutter pub get
flutter analyze      # currently: No issues found
flutter test         # currently: 14 tests pass
flutter run          # requires an emulator/device
```

## Roadmap (from the approved plan doc)

| Milestone | Status |
|---|---|
| 1 Source/asset audit (Kotlin unavailable → rebuild) | Done |
| 2 Flutter foundation, tokens, components, Home + Details | **Done** |
| 3 Comparison/redirects polish + search/categories | Partially done (search scaffolded) |
| 4 Firebase Auth + Firestore (products + favorites) | Pending |
| 5 50-product dataset, verified links, QA | Pending |
| 6 APK build + handover | Pending |

## Scope guardrails

Recorded (not live) prices with freshness labels · no social login · no fake
marketplace links · savings only across comparable offers · every loading /
empty / error / disabled state designed explicitly.