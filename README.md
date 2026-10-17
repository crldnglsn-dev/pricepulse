# PricePulse

Philippine e-commerce price comparison — a Flutter prototype that compares the
**same product, same model** across **Shopee, Lazada, and TikTok Shop**, shows
what the spread costs you, and hands off to the cheapest listing.

## Read this first

**Prices in this app are recorded, not live.** They were read off marketplace
listings on a single date and stored. Nothing scrapes, polls, or fetches prices
from a store API. Every price surface shows the date it was recorded and says
the live price may differ. This is deliberate: an academic prototype that
presented stale numbers as current would be worse than one that admitted it.

Tapping a store row always asks for confirmation before leaving the app, and
the confirmation restates the recorded price and its date.

## Status

| Area | State |
|---|---|
| Design system | Complete — tokens in `lib/theme/`, Inter bundled in `assets/fonts/` |
| Screens | Home, Product Details (comparison hero), Search Results complete |
| Catalog | 5 hand-curated products, real marketplace links, bundled images |
| Favorites / Account | Contracts defined; UI not built. Not built. |
| Firebase | Not wired. The repository interfaces exist so it can be. |
| Tests | 86 across 7 files |
| Quality gates | `CONSTRAINTS.md`, enforced by `tool/check.ps1` |

## Data honesty

These are the rules the code enforces, not aspirations:

- A price or link is never presented as verified unless it was read off a live
  listing.
- Savings are **never** computed across records marked `comparable: false`. The
  Bench pomade is marked non-comparable because its Lazada listing sells both a
  20g and an 80g size — comparing those would produce a saving that isn't real.
- A store with no recorded offer renders an explicit "No recorded offer yet"
  row rather than being hidden. Absence is information.
- Only **Lazada** returns a real HTTP 404 for a missing listing. Shopee and
  TikTok Shop answer `200` for pages that do not exist, so
  `tool/verify_links.dart` reports those links as `UNVERIFIED` rather than
  `LIVE`. They must be opened on a device to be truly confirmed.

## Run it

```sh
flutter pub get
flutter run
```

## Quality gates

```sh
./tool/check.ps1          # analyze, floor guard, tests, coverage
./tool/check.ps1 -Full    # adds the network link check (pre-demo)
```

`CONSTRAINTS.md` is the source of truth for the bar: what is enforced, with
which command, and why that number. `tool/floor_guard.dart` watches the diff for
the five moves that quietly lower a standard — a skipped test, a deleted
assertion, a suppression comment, unfinished work, or a threshold edit.

Current coverage: **88.4%** of `lib/`, floor 80%.

## Architecture

Screens depend on providers; providers depend on repository interfaces; no
screen imports data directly. The data layer is `lib/data/`, and it holds three
swapped boundaries:

| Boundary | Shape | Today | Later |
|---|---|---|---|
| `ProductRepository` | `Stream<List<Product>>` | seed dataset | Firestore |
| `FavoritesRepository` | stream + idempotent `toggle` + sync state | contract only | Firestore |
| `AuthService` | user-or-guest + non-enumerating reset | contract only | Firebase Auth |

`ProductRepository` is a stream rather than a future on purpose: Firestore hands
you a stream, and declaring a future would force the Firestore implementation to
flatten it, losing live updates and the offline cache the spec calls for.

Two rules hold across all three: **nothing but `DataFailure` crosses the
boundary**, so a stack trace can never reach a price screen; and **data arriving
from outside is validated at the parse boundary**, so downstream code can trust
the types. Both are enforced by tests, not by convention.

## Design docs

The UI specification lives in [`design/`](design/) — rationale and IA, design
system, the hero screens, the remaining screens, and the states/QA handoff
checklist. Change the spec and the code together, or the contradiction becomes
something you tell in a demo.