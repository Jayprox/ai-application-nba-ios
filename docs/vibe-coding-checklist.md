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
- [x] **Added in step 1 (JD didn't object; pushed 2026-09-28)**
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

- [x] **1. Skeleton + auth** — Xcode project, `Color+Brand`, fonts,
  `APIClient`, Keychain + single-flight refresh, Login, 5-tab shell.
  Test: sign in, force an expired token, confirm exactly one refresh.
- [x] **2. Scoreboard → Box score** (models, calendar dates, live refresh).
- [x] **3. Players search → Player detail** with the full stat explorer.
- [x] **4. Teams → Team detail** (explorer in team mode, defense by position).
- [x] **5. Leaders, Standings** (table + bracket).
- [x] **6. Rankings, Props board, Prop check, Guide.**
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
- **2026-09-28** — Step 1 pushed by JD. Oswald .ttf files still not in
  `Resources/Fonts` (display text falls back to the system font).
- **2026-09-28** — Step 2 written (Scoreboard → Box score), waiting on JD's
  build: `Format` (port of lib/format.js: calendar dates in a fixed UTC
  calendar, tip-off in the viewer's timezone, JS-exact `toFixed(1)` /
  `Math.round`, checked against Node over 60,000 values), game + box-score
  models, `States` (Loading / Error / Empty cards with the web's wording),
  `FlowLayout`, `AppRoute` (one push enum for every tab),
  `ScoreboardView` + `GameCardView` (date arrows skip empty days, date
  picker, designed empty day with prev/next links, stale-date guard),
  `BoxScoreView` + `BoxScoreTable` (header, split tags, per-team tables
  with a pinned player column, starters, DNP reasons, totals, VoiceOver
  reads each row as one line). Live games re-fetch every ~60 s on both
  screens (the web doesn't poll; kickoff §3 allows it). Tests added:
  `FormatTests`, `DecodingTests`. The test host now shows a blank screen
  under XCTest so no real screen fires requests during tests.
- **2026-09-28** — Step 2 pushed by JD.
- **2026-09-28** — Step 3 written (Players → Player detail + stat explorer),
  waiting on JD's build: models for /teams, /players, /players/:id,
  /players/:id/props and POST /query (StatQuery with a custom encoder:
  only set splits are sent, rest "3+" as a string, team ids as numbers;
  QueryResponse generic over data: Averages / CareerData / [GameLogRow]);
  `ExplorerFilters` (port of buildQuery); Players tab (debounced search,
  team menu, Active only, truncation + retired-hidden lines); Player
  detail (bio line, injury badge hidden while null, no-seasons empty
  state, waits for props so the first query carries tonight's lines);
  StatExplorerView (season menu, type pills, scope tabs, collapsible
  splits with "Rest measured by", result header + record, every
  meta.notes line, NoGames with the web's four messages and one-tap
  fixes, Prop check, tiles with "est." in caution color, career table
  newest first + Career row, game log with box-score links, Pts line
  and tags, freshness footer); shared `Pills`, `UnderlineTabs`,
  `DataTable` (pinned first column). Stale guard: a result shows only
  while it matches the current controls. Tests: `ExplorerTests` ports
  StatExplorer.test.js, NoGames.test.jsx and PropCheck.test.jsx, plus
  query/player decoding.
- **2026-09-28** — Step 3 pushed by JD.
- **Decision (JD, 2026-09-28): team "Net rtg (est.)" = off_rtg − def_rtg
  on the device, as the web does (option A: web parity, no backend
  change).** It's the one derived number in the app, isolated in
  `Format.netRating` and documented there; checked against Node's
  output over 50,000 pairs.
- **2026-09-28** — Step 4 written (Teams → Team detail), waiting on JD's
  build: Teams list (conference → division, Altitude arena tag and
  footnote); Team detail (header with altitude/elevation, explorer in team
  mode with team tiles / team career "All seasons" / team game log
  "W 118-110"; default season = /seasons latest_with_games); Defense by
  position (follows the explorer's season, regular or playoffs; one card
  per position with allowed, rank, vs league avg and strong/weak); the
  season roster (follows season + type; names open the player on that
  season and type via `AppRoute.player(id:season:seasonType:)`).
  Explorer gained `startSeason` / `startType` and `onFiltersChange`.
  Tests: `TeamTests`.
- **2026-09-28** — Step 4 pushed by JD.
- **2026-09-28** — Step 5 written (Leaders, Standings + bracket), waiting
  on JD's build: Leaders tab (7 stat tabs incl. Usage as "28.3%", season
  menu, Regular / Playoffs / All, top 25, rows open the player on that
  season and type, "Who qualifies" card from meta.qualifier with "so far"
  for the current season and the 15+ min rule on usage, usage note);
  Standings under League (season menu, Standings | Playoffs tabs; table
  per conference in rank order with clinch marks, playoff / play-in cut
  lines and shading from meta.format, legend, every meta.notes line;
  bracket: Finals, then West / East stacked Play-In → First round (1v8,
  4v5, 3v6, 2v7) → semis → conf finals, series scores from
  higher_wins / lower_wins, in-progress series outlined, team links
  open the playoffs / play-in filters). `AppRoute.team` now takes a
  season and type. `DataTable` rows gained prefix / suffix / muted /
  shaded / cut line. `Array.stableSorted` keeps JS's stable sort order.
  Tests: `LeagueTests` (bracket order ported from Standings.test.js).
  Note: Leaders shows the qualifier and usage notes through the card
  and footnote, as the web does, rather than repeating meta.notes.
- **2026-09-28** — Step 5 pushed by JD.
- **2026-09-28** — Step 6 written (Rankings, Props board, Guide; Prop
  check shipped in step 3), waiting on JD's build:
  Rankings under League (Players / Teams / Matchups; season, Regular /
  Playoffs, Season / Last 10, position; players table with score, GP and
  each stat with its z-score underneath; teams with W-L, Off / Def / Net /
  Pace and each rank underneath, "Rank by" re-sorts; matchups by position
  with allowed + rank · vs league avg, strong / weak, League avg row;
  every meta.notes line). Props tab (date arrows between dates with
  lines, date picker, 12 market tabs, game filter, 4 sorts ported from
  lib/props.js sortRows; one card per player like the web's phone
  layout: line, prices, movement from open, matchup note with weak /
  strong D, Last 10, Season or Last szn, Avg, Result or Opening /
  Closing; the web's three no-lines messages; notes). Guide under
  League (all 12 sections of Guide.jsx, same wording except three phone
  edits listed in GuideContent.swift; jump links). `DataTable` rows
  gained a second line (`subcells`) and a muted `detail`.
  Gotcha handled: the decoder camelCases dictionary keys too
  (z["ts_pct"] -> "tsPct"), so lookups go through `Format.decodedKey`.
  Tests: `PropsAndRankingsTests` (ports props.test.js and
  rankings.test.js, plus payloads and the guide's structure).
- **2026-09-28** — Step 6 pushed by JD.
- **2026-09-28** — Step 7 written (Ask), waiting on JD's build: AskView
  from the magnifier on every tab (eyebrow "Plain English · verified
  numbers", search box capped at 300 chars, the web's six examples);
  answer = sentence + clarify buttons + removable chips + a view per
  view.type (stats tiles / game log, leaders, player and team rankings,
  matchups, props tiles, standings, game, series; unsupported shows the
  examples) + the web's footer + "Open the full view →". The plan is
  read with a plain decoder (`JSONValue`) and re-sent unchanged, so
  snake_case keys (`season_type`, `rest_by`) and chip keys stay intact;
  `APIClient.requestData` gives Ask the raw body through the same
  auth/refresh flow. `WebLink` maps the answer's web path to the native
  screen with its URL state (player/team explorer filters, leaders,
  rankings, standings/bracket, games, props); Leaders, Rankings,
  Standings, Player and Team detail accept those start values. This is
  most of the 1.1 universal-links mapping already. Tests: `AskTests`.
