# Chalk That NBA — App Store submission notes (draft)

Draft for JD to review before submitting. Items marked **JD** are
decisions or facts only JD can supply. Not legal advice.

## App Store Connect: app record

| Field | Value |
|---|---|
| Name | Chalk That NBA |
| Bundle ID | `rookiegame.Chalk-That-NBA` |
| SKU | chalk-that-nba-ios (**JD** to confirm) |
| Primary category | Sports |
| Secondary category | Reference (optional) |
| Price | Free |
| Availability | **JD** (NFL app's settings are the reference) |

## Listing text

**Subtitle (30 max):** NBA stats with the sample size

**Promotional text (170 max):**
Every player and team since 2003-04, filtered by home/away, rest, back-to-backs, national TV and altitude, with the games count on every number.

**Description:**
Chalk That NBA is a stats research app. Every number is counted from real NBA box scores at the moment you ask; there are no projections or picks.

- Scores and box scores, with the split tags each team carried into the game.
- Player and team pages: season averages, last 5 and last 10, career and full game logs for every season since 2003-04.
- Splits: home or away, night 1 or 2 of a back-to-back, days of rest, national TV, and altitude. Combine as many as you like; the sample size and record are always shown.
- Leaders, standings with the playoff bracket, rankings, and defense by position.
- Props: DraftKings lines next to how often a player went over that exact line before. Counts, never picks.
- Ask: plain-English questions like "Jokić on the second night of back-to-backs", answered with verified numbers.

Accounts are by invitation; there is no public sign-up.

**Keywords (100 max):** nba,basketball,stats,splits,back to back,rest,box score,game log,leaders,standings,props,player

**Support URL / Marketing URL:** **JD** (the web app URL works for marketing)
**Privacy Policy URL:** host `docs/privacy-policy.html` (e.g. from the web service or GitHub Pages), **JD**

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
  > Chalk That NBA is a research tool for NBA statistics. Accounts are created by the developer (no public sign-up); use the demo account above. The Props tab shows publicly available DraftKings lines next to historical counts for reference. The app does not accept wagers or link to sportsbooks. "Ask" uses an AI model only to choose which statistics query to run; all numbers come from our database.
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
