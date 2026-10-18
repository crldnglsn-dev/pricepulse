# PricePulse — UI/UX Design Specification

**Part 3b · Remaining screens: Search Results · Favorites · Authentication · Account**

---

## 1. Search Results

**Purpose:** a single results surface for both query and category entry modes — one code path, two entry points.

### 1.1 Layout

```
┌ AppBar: [‹] [ 🔍 Search products…   (×) ]  │  SearchField (autofocus in query mode)
├────────────────────────────────────────────┤
│  in category mode: category chips row     │  (re-filter quickly)
│  RESULTS · 12 · "wireless"  [Sort ▾]      │  caption + sort
│  ┌────────────┐ ┌────────────┐            │  2-col grid, gap 12
│  │ ProductCard│ │ ProductCard│            │
│  └────────────┘ └────────────┘            │
└────────────────────────────────────────────┘
```

### 1.2 Specs & states

- **Query mode:** app bar holds a real `SearchField` (autofocus, clear ×). Debounced (300ms) client-side filter over name, category, brand-if-present. Empty query → show "Browse categories" chips + "All products" grid (browse fallback — no empty state).
- **Category mode:** title = category name; chip row acts as breadcrumb control; grid shows that category.
- **Result caption:** "12 of 50 products" (honest count).
- **Sort:** `TextButton` "Sort" → menu: Featured (default) / Price: low→high / Price: high→low / Name A–Z. Uses each card's recorded min price.
- **Empty query results:** `EmptyState` (search icon) — "No results for “{query}”", body "Check the spelling or try a broader category.", up to 3 suggestion category chips, `TextButton` "Clear search".
- **No products at all (dev):** "The catalog is being set up."
- **Loading:** grid skeleton (6 boxes). **Error:** `ErrorState` + "Try again".
- Back returns to Home preserving scroll; re-typing keeps query (`ValueNotifier`).

---

## 2. Favorites

**Purpose:** a persistent, cloud-synced shortlist — identical on this device and after re-login on another.

### 2.1 Signed-in layout

```
┌ AppBar (56) ────────────────────────────────┐
│  Favorites                       [● Synced] │  StatusChip
├────────────────────────────────────────────┤
│  (optional) OfflineChip banner when offline │
│  ┌────────────┐ ┌────────────┐              │  2-col grid (same ProductCard)
│  │ ProductCard│ │ ProductCard│              │  + live FavoriteButton to un-save
│  └────────────┘ └────────────┘              │
└────────────────────────────────────────────┘
```

### 2.2 Specs

- Grid reuses `ProductCard` untouched (same card everywhere = consistency); favorite state shown filled.
- **Remove:** heart tap → card collapse (150ms) + `AppSnackbar` "Removed from favorites · Undo" (4s). Undo restores via Firestore write.
- **Sync feedback:** `StatusChip` — "Synced" (success) when the write stream is healthy; "Waiting for connection" (warning) with pending writes. Auto-updates from the provider. This transparently communicates the cloud-sync behavior documented in the plan.
- Tap card → Details; toggling there updates this grid via the shared stream.
- Order: newest favorited first (by saved timestamp).

### 2.3 States

| State | Presentation |
|---|---|
| Signed out | `EmptyState`: heart icon, "Log in to see your favorites", body "Create a free account and your saved products follow you on any device.", `PrimaryButton` "Sign in / Create account", `TextButton` "Browse products" → Home tab |
| Signed in, empty | `EmptyState`: heart-outline icon, "No favorites yet", body "Tap the ♥ on any product to keep it here.", `PrimaryButton` "Discover products" → Home tab |
| Loading | Skeleton grid (6) |
| Offline with cache | Show cached list + `OfflineChip` banner "Showing saved favorites — sync paused" |
| Sync conflict | Last-write-wins (backend rule); single source per session, no conflict UI in prototype |

---

## 3. Authentication

**Purpose:** honest, conventional email/password auth (Firebase). No social buttons unless a provider is genuinely configured.

### 3.1 Welcome (account entry, signed out)

- Brand lockup centered (glyph 48 + "PricePulse" `display` 28).
- Tagline: "Compare prices across Shopee, Lazada & TikTok Shop."
- Benefit list (icon + text, `body`):
  1. ✅ "See the lowest recorded price for any product"
  2. ✅ "Open the cheapest listing in one tap"
  3. ✅ "Keep favorites synced to your account"
- `PrimaryButton` full width "Create account" → Register.
- `TextButton` "I already have an account" → Login.
- `TextButton` "Explore as guest" → back to Home (browse/compare still available; favorites prompt on save).
- Back returns to Account — signed-out state.

### 3.2 Register

- Title "Create your account" `headline1`; subline "Takes less than a minute." `body` muted.
- Fields (`AppTextField`): Display name (required, ≥2 chars), Email (required, format), Password (required, ≥8 chars, visibility toggle).
- Password helper `caption`: "At least 8 characters" — turns green when satisfied.
- `PrimaryButton` "Create account" (loading: spinner + disabled, width preserved).
- Validation on blur + submit; server errors → inline `errorContainer` banner above the button, Firebase codes mapped to human copy ("already registered" → "This email is already in use. Try signing in."; "network" → "Check your connection and try again.").
- Terms line `caption` muted: "By continuing you accept the demo Terms. This prototype stores your email, name, and favorites."
- Success → pop to Account tab + snackbar "Welcome, {name}!".

### 3.3 Login

- Title "Welcome back"; subline "Sign in to your PricePulse account."
- Fields: Email, Password (visibility toggle) + right-aligned `TextButton` "Forgot password?".
- `PrimaryButton` "Sign in" (loading state); inline error mapping (wrong creds → "Incorrect email or password. Check and try again.").
- `TextButton` "New here? Create an account" → Register.
- Success → pop to Account tab + snackbar "Signed in as {email}".

### 3.4 Forgot password

- Title "Reset your password".
- Body: "Enter your email and we'll send a reset link."
- Field Email + `PrimaryButton` "Send reset link" (loading).
- **Result (mirrors Firebase, no account disclosure):** screen swaps to an info state — "If an account exists for this email, a reset link has been sent." + `TextButton` "Back to sign in". Info snackbar too.
- Errors: invalid email → field error; network → banner.

### 3.5 Auth chrome (shared)

- Dark `bg`; single column, max-width 480 centered; 24 top padding; keyboard-aware (`resizeToAvoidBottomInset`, safe area).
- Keyboard "done" submits the last field.
- No social buttons; no fake "Continue with Google" chrome.
- Pending-favorite intent: if the user authenticated from an `AuthPromptSheet`, the tapped favorite is re-applied silently after success.

---

## 4. Account

**Prototype status.** This build has no accounts and no server. The signed-out shell below is what actually ships. The signed-in layout is written against the `AuthService` contract rather than against Firebase, so it activates when a Firebase-backed service replaces the guest one — swapping the service is a one-line change in `app.dart`, and no screen imports a backend.

**The rule for this screen.** It is the screen most able to lie: it is where a prototype would be tempted to show a profile, a sync status and a log-out button it does not have. Nothing here may imply a session, a sync or a server that does not exist. Where the original spec assumed a backend, the copy is corrected rather than aspirational.

### 4.1 Signed-in layout

```
┌ AppBar (56): "Account" ─────────────────────┐
├────────────────────────────────────────────┤
│  ┌ Profile header ──────────────────────┐  │
│  │ (A)  Angela Santos                  │  │  avatar 56 primaryContainer
│  │      angela.santos@gmail.com        │  │  name headline2 / email caption
│  └─────────────────────────────────────┘  │
│  ┌ List card ───────────────────────────┐  │
│  │ ♥  My favorites        (12)      ›   │  │  → Favorites tab (live count)
│  │ ☁  Where favorites live            │  │  On this device. Not synced.
│  │ ℹ  App info               v1.0.0  ›  │  │  dialog (version/build/stack)
│  │ 🔒  Privacy & data             ›    │  │  dialog (honest scope)
│  └─────────────────────────────────────┘  │
│  [Log out] (error-tinted TextButton)      │  → confirm AppDialog
└────────────────────────────────────────────┘
```

### 4.2 Specs

- Profile header shows `displayName`/`email` from the `AuthUser`; no edit-profile in the prototype (documented out-of-scope, no dead control). Without a display name the email is the heading and is not repeated below it.
- "My favorites" shows the live count as "N saved"; tap → Favorites tab. While the store is still loading the count is a dash, never `0` — showing zero would claim the answer is known.
- "Where favorites live" states where favorites are in words: "On this device. Not synced to an account." The Favorites tab carries the same fact as a `StatusChip`. The Account row uses words rather than the chip because the chip is wide enough to squeeze the title into an awkward wrap on a phone; the wording is the chip's exact wording, so the two screens cannot disagree. The spec's original row was called "Sync status"; that name is not used, because there is no sync to report.
- The trailing chip and the row label are both flexible, so the row survives a 200% text scale on a 320dp phone.
- "App info" dialog: PricePulse 1.0.0 (build 1) · Flutter · local device storage · "Built as an academic prototype".
- "Log out": shown only when signed in. Dialog "Log out of PricePulse?" — `TextButton` "Cancel" + destructive "Log out". After: session cleared, snackbar "You've been logged out."
- A "Log out" button is never shown without a session. A control that does nothing is worse than no control.

### 4.3 Privacy & data dialog (honest scope)

- "Your favorites are stored on this device only. Nothing is uploaded, and this build has no account to attach to."
- "Product prices are recorded records — they are not fetched live from store APIs."
- "Opening a listing hands off to the store's app or website. PricePulse does not collect store-side data."
- "Removing the app removes your favorites with it."

The dialog must match what is actually stored. The original spec's text named Cloud Firestore, which is not in this build, so it is corrected here. Design QA §3.5 requires this dialog to match stored data exactly.

### 4.4 Signed-out state

Same shell, profile header replaced by the brand lockup, the tagline "Compare recorded prices across Shopee, Lazada & TikTok Shop.", `PrimaryButton` "Sign in", `TextButton` "Create account", and a caption saying that accounts are not part of this prototype build while favorites are saved on this device and work without signing in.

- The original §4.4 caption, "Saving favorites requires an account", is **wrong for this build** and is not used. Favorites work without an account here, so the opposite is true.
- "Sign in" and "Create account" open an honest notice explaining that accounts are not part of this build and where favorites actually live. They are not dead controls and they are not a fake form. A real sign-in form arrives with the backend.

---

## 5. Supporting flows & globals

- **LinkUnavailableDialog:** "Listing link unavailable" / "This marketplace link hasn't been added yet. Try another store or check back later." Actions: `TextButton` "Copy link" (only when a URL exists but failed at launch) + `PrimaryButton` "OK".
- **Sign-out confirm:** as 4.2.
- **AuthPromptSheet:** as Part 2 · 2.8.
- **Snackbar queue:** one at a time; errors replace queued info.