# Chalk That Hardwood (repo: Chalk That NBA) — App Store submission notes (draft)

Draft for JD to review before submitting. Items marked **JD** are
decisions or facts only JD can supply. Not legal advice.

## Name: Chalk That Hardwood (renamed 2026-09-29)

"NBA" can't appear in the app's name, subtitle, keywords or branding:
Apple rejected the sister app's "Chalk That NFL" under Guideline 4.1(a)
(it's now Chalk That Gridiron). The same applies here. Factual mentions
inside the app (NBA.com, NBA Finals) are fine; the listing uses "pro
basketball" and carries an independence disclaimer.

## App Store Connect: app record

| Field | Value |
|---|---|
| Name (App Information) | Chalk That Hardwood |
| Bundle ID | `rookiegame.Chalk-That-NBA` (internal, never shown to users; keep it) |
| Primary category | Sports |
| Secondary category | Reference (optional) |
| Price | Free |

## Listing text (paste-ready; lengths checked)

**Subtitle (29/30):** Pro basketball stats & splits

**Promotional text (149/170):**
Every player and team since 2003-04, filtered by home/away, rest, back-to-backs, national TV and altitude, with the games count next to every number.

**Keywords (97/100), no trademarks, no spaces after commas:**
basketball,stats,splits,box score,game log,leaders,standings,props,player,rest,back to back,hoops

**Description (1423/4000):**

```
Chalk That Hardwood is a pro basketball stats research app. Every number is counted from real box scores at the moment you ask. No projections, no picks.

SCORES AND BOX SCORES
Every game on any date, with the split tags each team carried into it: home or away, days of rest, back-to-back night, altitude and national TV.

PLAYERS AND TEAMS
Season averages, last 5 and last 10, careers and full game logs for every season since 2003-04, including the regular season, play-in, playoffs and in-season tournament.

SPLITS
Narrow any view to home or away games, the first or second night of a back-to-back, days of rest, national TV, or altitude. Combine as many as you like. The games count and team record are always shown, so you can judge the sample.

LEADERS, STANDINGS AND RANKINGS
League leaders with a clear qualifier, standings with the playoff bracket, player and team rankings, and defense by position.

PROPS
Sportsbook player lines next to how often a player went over that exact line before. Counts, never picks. The app does not take wagers or link to sportsbooks.

ASK
Ask questions in plain English, like "who leads the league in steals" or "points on the second night of back-to-backs", and get answers built from verified numbers.

Accounts are by invitation; there is no public sign-up.

Chalk That Hardwood is an independent app and is not affiliated with, endorsed by, or sponsored by the NBA or any team.
```

**Support URL:** https://jayprox.github.io/chalkthat-privacy/hardwood-support.html
**Marketing URL:** leave blank (optional)
**Privacy Policy URL:** https://jayprox.github.io/chalkthat-privacy/hardwood.html

Hosting: both pages live in the `chalkthat-privacy` repo (GitHub Pages),
alongside the NFL pages. `docs/support.html` and `docs/privacy-policy.html`
here are the source drafts; edit the hosted copies when the policy changes.

## Age rating (questionnaire)

- Gambling (real money): **No**. The app shows sportsbook lines as information and takes no wagers.
- Simulated gambling: **No**.
- **JD**: Apple's questionnaire asks about gambling themes; betting lines may push the rating up. Answer the same way as for Chalk That NFL.

## App Privacy ("nutrition label"), draft

- **Data used to track you:** none.
- **Data linked to you:** User ID (App Functionality).
- **Data not linked to you:** Search History, i.e. the text of Ask questions (App Functionality). Question text is sent to Anthropic to interpret the question.
- No analytics, no advertising, no third-party SDKs.
- **JD**: confirm against how backend-api stores Ask questions (cache keys hold the question text; rate limiting is per account, in memory).

## Export compliance

`ITSAppUsesNonExemptEncryption = NO` is set in Info.plist: the app uses only HTTPS and the system Keychain, which are exempt. App Store Connect won't ask on each build.

## App Review

- **Sign-in required.** Create a review account (`npm run create-user` in the web repo). Enter its username and password in App Review Information. **JD** (never put credentials in this repo)
- Review notes (suggested):
  > Chalk That Hardwood is a research tool for pro basketball statistics. It is independent and not affiliated with the NBA; league and team names appear only as factual data. Accounts are created by the developer (no public sign-up); use the demo account above. The Props tab shows publicly available DraftKings lines next to historical counts for reference. The app does not accept wagers or link to sportsbooks. "Ask" uses an AI model only to choose which statistics query to run; all numbers come from our database.
- The review happens in the offseason / preseason, so Props may show "No prop lines yet". Mention it in the notes if still true then.

## Screenshots

Required: 6.9" (iPhone 17 Pro Max class, 1320 × 2868) and 6.5" if you support it; Xcode 26's simulator "Save Screen" gives the right sizes. Suggested set, dark UI:

1. Player detail: LeBron 2003-04 tiles (sample size + record visible)
2. Splits open: Last 10 + Away with the header "… · 1 split applied"
3. Box score with split tags
4. Standings with cut lines, or the bracket
5. Leaders with "Who qualifies"
6. Ask: "Jokic on the second night of back to backs"

## Assets still missing

- [x] App icon, 1024 × 1024, no transparency
- [x] Oswald font files in `Chalk That NBA/Resources/Fonts/` (Medium, SemiBold, Bold) + OFL.txt
