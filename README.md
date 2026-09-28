# Chalk That NBA — iOS

Native SwiftUI client of the Chalk That NBA `backend-api`, the same API the
web app (`ai-application-nba`) uses. Same accounts, same numbers; the app
formats what the API returns and never computes a stat of its own.

- **Handoff / spec:** `ai-application-nba/docs/ios-kickoff.md`
- **API contract:** `ai-application-nba/docs/api.md`
- **Progress and decisions:** `docs/vibe-coding-checklist.md`
- **Architecture reference:** `ai-application-nfl-ios` (same layout and patterns)

## Stack

Swift + SwiftUI, MVVM, `URLSession` + async/await, iOS 16+, no third-party
dependencies. The file list is a synchronized folder: new files under
`Chalk That NBA/` are picked up by Xcode without editing the project.

```
Chalk That NBA/
  Chalk_That_NBAApp.swift   entry: Login or the tab shell
  Extensions/               Color+Brand (design tokens), Font+Brand, BackendDate
  Network/                  APIClient, Endpoints, KeychainManager, TokenRefresher
  Models/                   wire models, one file per API resource
  ViewModels/               one per screen
  Views/<Feature>/          screens
  Resources/Fonts/          Oswald (Medium, SemiBold, Bold)
Chalk That NBATests/        unit tests (auth / refresh rules, stubbed network)
```

## Configuration

The API base URL is the `API_BASE_URL` build setting (target → Build
Settings), written into Info.plist as `APIBaseURL`. Debug and Release both
use production today.

## Auth

Tokens live in the Keychain. `TokenRefresher` (an actor) guarantees one
refresh in flight and skips a refresh when another request already
rotated the token, because reusing a refresh token signs the user out
everywhere (api.md §2). `Chalk That NBATests/TokenRefreshTests.swift` pins
this down.
