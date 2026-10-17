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

### 4.1 Signed-in layout

```
┌ AppBar (56): "Account" ─────────────────────┐
├────────────────────────────────────────────┤
│  ┌ Profile header ──────────────────────┐  │
│  │ (A)  Angela Santos                  │  │  avatar 64 primaryContainer
│  │      angela.santos@gmail.com        │  │  name title / email caption
│  └─────────────────────────────────────┘  │
│  ┌ List card ───────────────────────────┐  │
│  │ ♥  My favorites        (12)      ›   │  │  → Favorites tab (live count)
│  │ ☁  Sync status               ●Synced│  │  StatusChip inline
│  │ ℹ  App info               v1.0.0  ›  │  │  dialog (version/build/stack)
│  │ 🔒  Privacy & data             ›    │  │  dialog (honest scope)
│  └─────────────────────────────────────┘  │
│  [Log out] (error-tinted TextButton)      │  → confirm AppDialog
└────────────────────────────────────────────┘
```

### 4.2 Specs

- Profile header shows Firebase `displayName`/`email`; no edit-profile in the prototype (documented out-of-scope, no dead control).
- "My favorites" shows live count; tap → Favorites tab.
- "Sync status" mirrors the Favorites `StatusChip`.
- "App info" dialog: PricePulse 1.0.0 (build 1) · Flutter + Firebase Auth + Cloud Firestore · "Built as an academic prototype" caption.
- "Log out": dialog "Log out of PricePulse?" — `TextButton` "Cancel" + destructive "Log out". After: session cleared, Favorites shows its signed-out prompt, snackbar "You've been logged out."

### 4.3 Privacy & data dialog (honest scope)

- "PricePulse stores your name, email address, and favorites in Cloud Firestore."
- "Product prices are recorded records — they are not fetched live from store APIs."
- "Opening a listing hands off to the store's website or app. PricePulse doesn't collect store-side data."
- "Your favorites are only visible to your account."

### 4.4 Signed-out state

Same shell, profile header replaced by compact auth entry: lockup + tagline, `PrimaryButton` "Sign in", `TextButton` "Create account", caption "Saving favorites requires an account."

---

## 5. Supporting flows & globals

- **LinkUnavailableDialog:** "Listing link unavailable" / "This marketplace link hasn't been added yet. Try another store or check back later." Actions: `TextButton` "Copy link" (only when a URL exists but failed at launch) + `PrimaryButton` "OK".
- **Sign-out confirm:** as 4.2.
- **AuthPromptSheet:** as Part 2 · 2.8.
- **Snackbar queue:** one at a time; errors replace queued info.