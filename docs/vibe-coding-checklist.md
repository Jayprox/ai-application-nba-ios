# Vibe Coding — Project Checklist (Chalk That NBA iOS)

> The native iOS client of Chalk That NBA. It's a **second client of the
> existing `backend-api`**, not a new product: same accounts, same numbers,
> no backend changes. Phases 1–4 are short because the product, API and
> screens were decided by the web app; the source docs live in the web repo
> (`ai-application-nba`): `docs/ios-kickoff.md` (the handoff),
> `docs/api.md` (the contract), `PLATFORM.md`. Architecture reference:
> `ai-application-nfl-ios` (built, submitted to the App Store 2026-09-24).

---

## Phase 1 — Concept Clarity

- [x] **One-paragraph pitch**
- [x] **Why this stack?**
- [x] **What does "done" look like?**

```
PITCH:
Chalk That NBA on iPhone: the same stats research app as the web — season
averages, last 5/10, careers and game logs for every player and team since
2003-04, filtered by NBA situational splits (home/away, rest, back-to-backs,
national TV, altitude) with the sample size on every number — plus the
scoreboard, box scores, standings and bracket, leaders, rankings, the
DraftKings props board, and plain-English Ask. No predictions; the app
formats what the API returns.

STACK RATIONALE:
Swift + SwiftUI, MVVM, URLSession + async/await, zero third-party
dependencies, iOS 16+ — the same as Chalk That NFL iOS, so solved problems
(token actor, Keychain, design tokens, date decoding) are reused, not
redesigned. It's a client of the public API like any other (PLATFORM.md §1).

DONE LOOKS LIKE:
Every item in ios-kickoff.md §8 (the parity checklist, copied below) is
checked: the same filters on web and iOS give exactly the same numbers,
every empty state renders a designed message, and a reused refresh token
signs the app out cleanly.
```

---

## Phase 2 — System Design (decided at kickoff, 2026-09-28, with JD)

- [x] **Repo / bundle ID** — repo `ai-application-nba-ios`; Xcode project and
  target "Chalk That NBA"; bundle ID `rookiegame.Chalk-That-NBA`; display
  name "Chalk That NBA"; team `7BK4R85P5E` (same as NFL).
- [x] **Tabs (5)** — **Scores · Players · Leaders · Props · League**.
  League = Standings, Teams, Rankings, Guide, Sign out. Ask is a search
  icon in the nav bar (so the tab bar doesn't depend on Ask).
- [x] **Ask ships in 1.0.**
- [x] **Backend for Debug** — production for both Debug and Release (the app
  only reads, plus login/refresh/Ask). No staging environment exists. The
  URL comes from the `API_BASE_URL` build setting → Info.plist `APIBaseURL`,
  so it can change per configuration later without code changes.
- [x] **Universal links** — later (1.1). Keep the StatQuery ↔ web URL-state
  mapping clean so it's a small add.
- [x] **Folder layout** — mirror NFL exactly, NFL's names kept (JD,
  2026-09-28): `Extensions/ Network/ Models/ ViewModels/ Views/<Feature>/`.
  Auth = `Network/KeychainManager` + `Network/TokenRefresher` (actor), not the
  kickoff's `Services/AuthStore` (same job, NFL's names).
- [x] **Deviations from NFL (approved)**
  - Base URL from the build config instead of hardcoded.
  - Refresh skips itself when the stored access token already differs from
    the one the server rejected (a late 401 after another request already
    refreshed) — what the web's `lib/api.js` does. Guarantees exactly one
    refresh.
  - A refresh that fails with a network error or 429 keeps the session and
    shows an error; only a 401/400 from `/refresh` (expired, invalid,
    reused) signs out — also what the web does.
  - Oswald is bundled (NFL never bundled its fonts). Body text uses the
    system font (kickoff §5 allows Inter or system).
- [ ] **Proposed in step 1 (JD to confirm)**
  - iPhone only (`TARGETED_DEVICE_FAMILY = 1`); kickoff §7.8 targets iPhone
    SE through Pro Max. NFL is iPhone + iPad.
  - A unit-test target, "Chalk That NBATests" (NFL has none), for the auth
    rules, with a URLProtocol stub (no real network, no backend).

---

## Phase 3 — MVP Scope

- [x] **v1 features** — every screen in ios-kickoff.md §3 (Login, Scoreboard,
  Box score, Standings + bracket, Teams, Team detail, Players, Player detail,
  Leaders, Rankings, Props, Ask, Guide) and the stat explorer (§4).
- [x] **Out of scope** — signup, data operations (backfills, syncs, users,
  keys), universal links (1.1), injuries (API returns `null` until a feed
  exists; the badge hides).
- [x] **Success metric** — the §8 parity checklist below.

---

## Phase 4 — UI/UX Plan

- [x] **Screen inventory / endpoints** — ios-kickoff.md §3.
- [x] **Design tokens** — ios-kickoff.md §5 → `Extensions/Color+Brand.swift`
  (web token names: paper, card, card2, rule, line, strong, field, ink,
  muted, faint, link, accent, onAccent, altBg, altInk, live, positive,
  positiveBg, caution).
- [x] **Formatting** — ios-kickoff.md §6 → one formatter file, matching
  `frontend/src/lib/format.js`.

---

## Phase 5 — Build Order (ios-kickoff.md §7)

- [ ] **1. Skeleton + auth** — Xcode project, `Color+Brand`, fonts,
  `APIClient`, Keychain + single-flight refresh, Login, 5-tab shell.
  Test: sign in, force an expired token, confirm exactly one refresh.
- [ ] **2. Scoreboard → Box score** (models, calendar dates, live refresh).
- [ ] **3. Players search → Player detail** with the full stat explorer.
- [ ] **4. Teams → Team detail** (explorer in team mode, defense by position).
- [ ] **5. Leaders, Standings** (table + bracket).
- [ ] **6. Rankings, Props board, Prop check, Guide.**
- [ ] **7. Ask.**
- [ ] **8. Empty-state pass, accessibility (Dynamic Type, VoiceOver),
  SE → Pro Max layouts, App Store assets.**

---

## Phase 6 — Parity Checklist (ios-kickoff.md §8 — the done bar)

Same filters on web and iOS, numbers must match exactly:

- [ ] LeBron 2003-04 regular: 79 GP, 20.9 / 5.5 / 5.9, TS .488, usage 28.3%.
- [ ] LeBron 2003-04 by his rest 0/1/2/3+: 20/40/12/7 games.
- [ ] Jokić 2025-26: 65 GP, 27.7 PPG; Last 10 + Away matches the web.
- [ ] Leaders 2025-26 points: Dončić 33.5 in 64; the qualifier card reads 58 of 82.
- [ ] A 2025-26 box score: every player line matches the web and NBA.com.
- [ ] Standings 2025-26 ranks and clinch marks match the web; bracket series scores match.
- [ ] Props board on a game day: same lines, hit rates and matchup notes as the web.
- [ ] Ask "Jokic on the second night of back to backs": same sentence and numbers as the web.
- [ ] Every empty state (preseason, offseason, rookie, retired player, split with zero games, season type not reached) renders a message, never a blank or an error.
- [ ] Sign-out on another device's token reuse: the app returns to Login cleanly.

---

## Build Log

- **2026-09-28** — Kickoff decisions made with JD (Phase 2 above).
- **2026-09-28** — Step 1 written, waiting on JD's first build and test run:
  Xcode project (app + `Chalk That NBATests`, shared scheme), Info.plist
  (`APIBaseURL` from `API_BASE_URL`, Oswald under `UIAppFonts`),
  `Color+Brand` (web token names), `Font+Brand`, `BackendDate`,
  `APIClient` / `Endpoints` / `KeychainManager` / `TokenRefresher`,
  `AuthViewModel`, `LoginView` (web wording), the 5-tab shell with
  placeholders, League tab with Sign out. Tests: 9 cases covering one
  refresh for 8 concurrent 401s, no second refresh on a late 401, sign-out
  on reuse and on still-401-after-refresh, session kept on offline/429,
  no resurrection after sign-out mid-refresh, and the login messages.
  Oswald .ttf files still to be added by JD.
