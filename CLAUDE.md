# CLAUDE.md — Chalk That Hardwood iOS

Native SwiftUI client of the Chalk That backend-api. Public name **Chalk That Hardwood**; Xcode project/target "Chalk That NBA", bundle ID `rookiegame.Chalk-That-NBA` (internal names stay "NBA" on purpose). Product owner: JD.
Sibling repo: `../ai-application-nba` (web app + the SHARED PRODUCTION BACKEND). Treat both as ONE product. The web repo's `CLAUDE.md` rules apply here too; this file adds iOS specifics.

## Read first (only what the task needs)
`README.md` -> `../ai-application-nba/docs/api.md` (contract) -> `../ai-application-nba/docs/ios-kickoff.md` (spec) -> `docs/vibe-coding-checklist.md` (progress + decisions; also the backlog reference) -> `docs/parity-test-plan.md` -> `../ai-application-nba/docs/PARITY.md` (documented vs tested parity) -> `../ai-application-nba/docs/AGENT-WORKFLOW.md`.
Verify docs against code before relying on them.

## Architecture (confirmed)
Swift + SwiftUI, MVVM, `URLSession` + async/await, iOS 16+, zero third-party dependencies, 72 Swift files in the app folder plus 9 in the test target (81 in the repo).
`Chalk That NBA/`: `Extensions/` (Color/Font+Brand, BackendDate, `Format.swift` = port of web `format.js`), `Network/` (APIClient, Endpoints, KeychainManager, `TokenRefresher` actor), `Models/` (one file per resource), `ViewModels/`, `Views/<Feature>/`. Tabs: Scores, Players, Leaders, Props, League; Ask is a toolbar button.
Files are a synchronized Xcode folder (new files under `Chalk That NBA/` are picked up automatically; do not hand-edit `project.pbxproj` unless approved).
Tests: `Chalk That NBATests/` (77 unit tests, stub server). Scheme: `Chalk That NBA`.
`API_BASE_URL` build setting -> Info.plist `APIBaseURL`. **Debug AND Release point at PRODUCTION.** No staging exists.

## HARD RULES
1. Never invent, fabricate or silently estimate NBA statistics. The app only formats what the API returns; no client-side stats, averages, projections or probabilities. "est." labels stay (team ratings/pace, usage).
2. Data parity: same endpoint + same filters as web must show the same numbers. Formatting changes must be mirrored from/to web `format.js`.
3. Do not change backend behavior, API contract or shared services. Needing a new/changed field = stop and propose it to JD; it is a web-repo task.
4. Never modify production data. The app is read-only plus login/refresh/Ask; do not add write calls. Do not run the app against production with real credentials during agent sessions; no login, no network calls to the API.
5. Never expose or commit secrets, tokens, review-account credentials or `.env`-style files. Tokens belong in the Keychain only. Never log tokens.
6. No paid API calls (Ask hits Anthropic through the backend: do not exercise it live).
7. Do not install packages or add dependencies (the app has none by design) without approval.
8. No commits, merges, pushes, TestFlight/App Store submissions, signing or provisioning changes without explicit JD approval. Work on a `claude/<task>` branch/worktree, never `main`.
9. Preserve existing functionality; no refactors of auth (`TokenRefresher` single-flight rule) without approval: reusing a refresh token signs the user out everywhere.
10. Report only what was actually run. Never claim a build or test passed unless executed. Say "not run" and why.
11. `git status` first; if the tree is unexpectedly dirty, stop and report.

## Building / testing (environment limits)
- Cloud/Linux sessions have no Xcode. There the only check is `python3 scripts/check_balance.py "Chalk That NBA"` (brace/paren balance; it cannot catch type errors). Report anything else as NOT verified.
- With Xcode on JD's Mac: `xcodebuild test -project "Chalk That NBA.xcodeproj" -scheme "Chalk That NBA" -destination 'platform=iOS Simulator,name=<installed simulator>'`. Unit tests use a stub server and make no network calls. Running them needs JD's go-ahead for the session.
- UI/manual parity cases (`docs/parity-test-plan.md`) are run by JD or by a QA agent only with JD present; results go in `../ai-application-nba/docs/PARITY.md`.

## Roles
Lead/Coordinator = main session. `ios-developer`, `qa-test-automation`, `code-reviewer` are subagents in `.claude/agents/`. Web changes belong to the web repo's `web-developer`. Delegate only when it helps; QA and review get a fresh agent.

## Parity with web
The shared parity record is `../ai-application-nba/docs/PARITY.md` (documented vs tested, feature matrix, manual cases P-01..P-10 from `docs/parity-test-plan.md`). Read it before a feature task; update its rows when iOS behavior or test results change. When running Claude Code here and you need it, start with `--add-dir ../ai-application-nba` (read-only intent; do not add it permanently, because that folder holds the production `.env`).

## Permissions and their limits
`.claude/settings.json` is an allowlist + ask + deny list for sessions started in this repo. It is best-effort pattern matching, NOT a sandbox, and it does not stop Debug builds from calling the production API. Details and remaining gaps: `../ai-application-nba/docs/AGENT-VALIDATION.md` §6.

## Cross-repo protocol
Contract changes flow web -> iOS, never the reverse: propose in the web repo, get JD approval, update `docs/api.md`, then match here. Record the change in `../ai-application-nba/docs/PARITY.md`. Decoder note: the JSON decoder camel-cases keys but NOT keys inside dictionaries (known past bugs: `playerB2BNight`, rankings z-score keys).

## Backlog / continuity
Backlog = web repo `docs/vibe-coding-checklist.md` (Backlog v2). iOS progress and decisions = this repo's `docs/vibe-coding-checklist.md`. No other backlog/session files.

## Report format after any task
Files changed; checks actually run + result; not verified (esp. anything needing Xcode/simulator); risks; contract/parity impact; decisions needed.
