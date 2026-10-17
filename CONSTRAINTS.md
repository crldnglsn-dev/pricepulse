# Constraints

Last reviewed: 2026-10-17 by @carlj

The bar for PricePulse. Every number below has a command that produces the
verdict, and a reason. A dimension with a number and no command is an
aspiration, not a constraint.

`CONSTRAINTS.md` is the canonical source. Anything in `pubspec.yaml` scripts or
tooling that mirrors it is a convenience wrapper — if they disagree, this file
wins.

---

## Floor

Always enforced. No setup, no threshold to negotiate.

- No new suppression comments: `// ignore:`, `// ignore_for_file:`, `/* ignore */`, `coverage:ignore`
- No unfinished work where the implementation belongs: `TODO`, `throw UnimplementedError`, `throw UnsupportedError`, an empty `catch {}` turning a failure into silence
- No skipped or deleted tests without a stated reason in the commit message
- No secrets in source; this stops mattering the moment Firebase config lands, so review it then
- No fabricated market data: a price or link is never presented as verified unless it was read off a live listing, and savings are never computed across records marked `comparable: false`
- This file does not get weakened to make a change pass

Enforced by `dart run tool/floor_guard.dart` (exit 1 = blocked).

---

## Enforced with numbers

| Dimension | Rule | Checked by | Runs at |
|-----------|------|-----------|---------|
| Types and lint | Zero analyzer issues, errors or warnings | `flutter analyze` | every edit |
| Floor | No violations of the floor above | `dart run tool/floor_guard.dart` | every edit |
| Coverage: total | Line coverage of `lib/` at least 80% | `flutter test --coverage` then `dart run tool/coverage_check.dart --min 80` | task end |
| Coverage: changed | Every changed `lib/` file at least 80% line covered | `dart run tool/coverage_check.dart --changed 80` | task end |
| Tests | All tests pass, none skipped | `flutter test` | every edit |
| Accessibility | No render overflow at 320/768/1440dp or at 200% text scale | `flutter test test/ui_resilience_test.dart` | every edit |
| Accessibility | Interactive targets at least 44dp | `flutter test` + review | every edit |
| Market data | Every seed offer points at a real marketplace host, never `example.invalid` | `flutter test test/seed_data_test.dart` | every edit |
| Market data | Every referenced image file exists and is a real JPEG or PNG | `flutter test test/seed_data_test.dart` | every edit |
| Market data | No seed URL is dead | `dart run tool/verify_links.dart` | before every demo |

**Why these numbers**

- **80% coverage.** High enough to force a test for new logic, low enough to
  admit a config constant. The codebase sits at 86.8%, so this floor has
  headroom rather than being a wall — see the ratchet below.
- **44dp targets.** WCAG 2.1 AA floor. `design/04` §3.4 sets the same bar, so
  the constraint and the spec agree.
- **320dp and 200% text scale.** `design/04` §3.4 requires Android font scale
  200% with no clipped prices or buttons. These are the two widths and scales
  where that actually breaks.
- **`example.invalid` may not appear.** `link_utils.dart` treats that host as
  unavailable on purpose. A record using it while claiming to be live is the
  exact dishonesty the app exists to avoid.

### Not enforced here, and why

- **Lighthouse / axe-core** need a running URL. This is a Flutter app with no
  web target, so there is nothing to point them at. Dropping the dimension
  rather than inventing a check that cannot run.
- **Semgrep and gitleaks.** Nothing to scan today — three dependencies, no
  secrets. Both become worth installing the day Firebase config lands, and
  that day the floor entry above stops being theoretical.
- **Architecture boundaries.** `dependency-cruiser` is JS-only. The Flutter
  equivalent is import lint rules in `analysis_options.yaml`, written by hand.

---

## Measured, not yet enforced

Recorded so a regression is visible. Not a gate.

| Metric | Today | Direction |
|--------|-------|-----------|
| Total line coverage (`lib/`) | 86.8% (1047/1206) | must not fall |
| Asset payload | 1805 KB | must not grow |
| Seed products with 3 verified stores | 3 of 5 | must not fall |
| Placeholder product records | 0 | must stay 0 |

**Why recorded rather than gated.** A ratchet asks for no negotiation: record
where you are, then refuse to get worse. Each of these already has a hard
invariant in the table above; these numbers catch the slow version of the same
decay.

The assets figure is a real risk. Five bundled images are 175 KB. Fifty
products at current resolution would be ~1.75 MB before any resizing, which is
why `MissingImage` remains a legitimate answer rather than a failure.

---

## Exceptions

None. If a constraint needs an exception, add a row here with an owner and an
expiry date — do not delete the rule. Deleting it unblocks everyone forever;
an exception unblocks one case until a date.

| ID | Rule | Path | Reason | Owner | Expires |
|----|------|------|--------|-------|---------|
| — | — | — | — | — | — |

---

## How to run everything

```
# fast — every edit (under 5s)
flutter analyze
dart run tool/floor_guard.dart

# task end
flutter test
flutter test --coverage
dart run tool/coverage_check.dart --min 80 --changed 80

# before a demo (network — only Lazada returns real 404s)
dart run tool/verify_links.dart
```

`tool/verify_links.dart` reports `UNVERIFIED` for Shopee and TikTok Shop
because both answer HTTP 200 for pages that do not exist. Those links are only
really confirmed by opening them on a device. That limitation is recorded
rather than hidden, and it is why the command is a pre-demo gate and not an
every-edit one.

---

## Adding a dimension

1. Install the tool and confirm it runs today on this codebase.
2. Add a row above with the command in the `Checked by` column and the reason
   beneath the table.
3. If the codebase fails it today, record today's value under *Measured* first
   and let it ratchet up. Do not set a number the project fails — that is how
   a build goes permanently red and gets ignored.
