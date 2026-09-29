# Parity test plan (ios-kickoff.md §8, the definition of done)

Manual cases for signing off 1.0. Each one runs on both the web app and the iOS
app with the same filters; **the numbers must match exactly**. Record
pass/fail and the build number in the Result column. Unit tests (`xcodebuild test`)
cover formatting, query bodies, decoding and auth; these cases cover the live
data end to end.

Web: https://web-production-081bcf.up.railway.app · iOS: Debug or TestFlight build, same account.

| ID | Case | Steps (iOS; do the same on the web) | Expected | Result |
|---|---|---|---|---|
| P-01 | LeBron 2003-04 regular | Players → Active only off → "lebron" → LeBron James → Season 2003-04, Regular, Season Avg | Header "Season average · 79 games"; Points 20.9, Rebounds 5.5, Assists 5.9; TS% .488; Usage (est.) 28.3% | |
| P-02 | LeBron rest splits | P-01, then Splits → Rest days 0 / 1 / 2 / 3+ in turn ("Rest measured by: His games") | 20 / 40 / 12 / 7 games | |
| P-03 | Jokić 2025-26 | "jokic" → Nikola Jokić → 2025-26, Regular, Season Avg; then Last 10 + Venue Away | 65 games, 27.7 PPG; Last 10 + Away tiles and record identical to the web | |
| P-04 | Points leaders 2025-26 | Leaders tab → 2025-26, Regular, Points | #1 Dončić 33.5 in 64 GP; "Who qualifies" reads 58 of 82 | |
| P-05 | 2025-26 box score | Scores → any 2025-26 date → a final game | Every player line (Min, Pts … +/-), starters, DNP reasons and team totals match the web and NBA.com | |
| P-06 | Standings + bracket | League → Standings → 2025-26; then Playoffs | Ranks and clinch marks match; cut lines after seeds 6 and 10; every series score matches | |
| P-07 | Props board | Props tab on a game day (from Oct 21, 2026) → Points, then 2 other markets | Same lines, prices, open→close movement, L10/Season hit counts and matchup notes as the web | |
| P-08 | Ask | Magnifier → "Jokic on the second night of back to backs" | Same sentence and numbers as the web; removing a chip re-runs; "Open the full view" opens Jokić with Night 2 applied | |
| P-09 | Empty states | See E-01 … E-08 | Every case shows a message, never a blank screen or an error | |
| P-10 | Token reuse sign-out | Sign in on iOS and on the web with the same account. Force a reuse (sign in on a 2nd simulator with a copied refresh token, or ask the backend to revoke all sessions) | iOS returns to Login cleanly on its next request; no crash, no stuck spinner | |

## Empty states (ios-kickoff.md §1.5)

| ID | State | How to reach it | Expected |
|---|---|---|---|
| E-01 | Offseason day | Scores → any date in August | "No NBA games on …" with Previous / Next game day links |
| E-02 | Preseason | Scores → early October 2026 | Cards say "Preseason"; eyebrow "2026-27 · Preseason" |
| E-03 | Rookie (no games yet) | Players → a 2026 draftee | "No games for … since 2003-04 (where our stats begin)." |
| E-04 | Retired player | Active only off → e.g. Dirk Nowitzki | Bio line ends "Retired"; explorer works on his seasons |
| E-05 | Split with zero games | Any player → Splits → B2B Night 2 + Altitude + Venue Home | "None of X's … games match these splits." + Clear splits |
| E-06 | Season type not reached | Stephen Curry → 2025-26 → Playoffs | "Stephen Curry didn't play in the 2025-26 playoffs. Games that season: …" + Show buttons |
| E-07 | NBA Cup before 2023-24 | Any player → 2019-20 → NBA Cup | "The NBA Cup started in 2023-24, so there are no Cup games in 2019-20." |
| E-08 | No prop lines | Props tab in the offseason | "No prop lines yet…" or the nearest date's lines with arrows |

## Accessibility and layout

| ID | Check | Expected |
|---|---|---|
| A-01 | Settings → Accessibility → Larger Text at the largest non-accessibility size (the app caps at xxxLarge, like NFL) | Nothing clipped or overlapping on Player detail, Box score, Standings, Props |
| A-02 | VoiceOver on a box score, the game log, the standings table | Each row is read once as a sentence; tiles read "Points, 20.9" |
| A-03 | iPhone SE (3rd gen) simulator | Scoreboard header, Players filters and box-score header fit; tables scroll sideways with the first column pinned |
| A-04 | iPhone 17 Pro Max simulator + landscape | Same, no stretched cards |
