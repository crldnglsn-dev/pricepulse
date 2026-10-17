# AGENTS.md

**Read `CONSTRAINTS.md` before writing code. Do not weaken it to make a change
pass.**

---

## What this project is

PricePulse — a Flutter app that compares recorded prices for the same product
across Shopee, Lazada, and TikTok Shop, and hands off to the store's listing.

## The rule that matters most here

Market data is **recorded**, not live. Never present a price or a link as
verified unless it was read off a live listing, and never compute savings
across records marked `comparable: false`. The app's credibility is that it
tells you when it does not know something — "No recorded offer yet",
"Recorded Oct 17, 2026 — live store prices may differ". Adding a claim the data
cannot support is worse than adding no feature at all.

## Gates

```powershell
./tool/check.ps1         # analyze, floor guard, tests, coverage
./tool/check.ps1 -Full   # adds the network link check (pre-demo only)
```

Individual commands are listed in `CONSTRAINTS.md`. Run the fast gates after
every edit; run the full set before handing work back.

## Conventions

- Design tokens are single-source: `lib/theme/app_colors.dart`,
  `app_spacing.dart`, `app_typography.dart`, `app_layout.dart`. No raw hex, no
  arbitrary pixel values.
- Screens depend on providers; providers depend on repository interfaces. A
  screen must never import Firebase or `seed_products.dart` directly. This is
  what makes the later Firebase swap a one-line change in `app.dart`.
- **The data layer is `lib/data/`.** Three boundaries exist and each is
  swapped, not rewritten:
  `ProductRepository` (stream — Firestore hands you a stream, so the contract
  is one), `FavoritesRepository`, `AuthService`.
- **Nothing but `DataFailure` crosses the data boundary.** No raw exceptions,
  no `e.toString()` in a screen. A failure a user sees must say what they can
  do about it.
- **Data arriving from outside is untrusted.** Validate it in
  `catalog_parser.dart` at the edge; downstream code may then trust the types.
- `FavoritesRepository.toggle` takes the desired end state, not "flip", so a
  retry after a lost response cannot double-save.
- Put new components in `lib/widgets/`, colocated and focused. A component over
  200 lines wants splitting.
- Specs live in `design/`. Change the spec and the code together, or the
  contradiction becomes a lie told in a demo.

## Testing

86 tests across seven files. When you add behaviour, add a test that fails
without it. `test/seed_data_test.dart` guards the hand-typed catalog;
`test/ui_resilience_test.dart` guards layout at 320dp and 200% text scale;
`test/link_confirmation_test.dart` guards that no store link ever opens
without an explicit confirmation; `test/data_contract_test.dart` guards the
repository contracts and the boundary parser.
