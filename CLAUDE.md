# DC Eats (dc-eats) — notes for Claude Code sessions

Started 2026-10-27 from `../state-prompts/DISTRICT_OF_COLUMBIA_PROMPT.md` and `../STATE_EATS_PLAYBOOK.md` (read both). Pipeline ported from
`../nc-eats/` (`northcarolina.py` -> `pipeline/dc.py`); `tracking_params.py`, `injection.py`, `link_blocklist.py` from fl-eats/co-eats;
website blocklist = nc-eats' plus anniessteakhouse.com (883). Never modify another state's folder. Leaderboard artifact link in `LOCAL.md`.

- Brand (Nick, 2026-10-27, `playbook/05-naming.md`): "DC Eats: Restaurants", Home Screen "DC Eats", subtitle "Half-Smokes, Injera &
  Pupusas"; icon = jumbo slice, tip up, on navy #041E42 (`scripts/icon-concepts.swift` `jumboSlice()`, `scripts/make-brand.swift`, passes
  icon-style check `--emblem`); palette flag red #C8102E + navy; header = the flag's three stars over two bars. Bib Gourmand filter applies.
- DC is one city: the District boundary is the state outline, the 8 wards (2022) are the "counties" (`co`), and the neighborhood is the
  "town": one of the names the place's cluster gives, decided by a neighborhood-named historic district the place is in, else the
  nearest label point in the cluster (`pipeline/areas.py`, scored there against places named for their neighborhood; DC Health's
  planning neighborhoods and the nearest label anywhere both scored worse). Shapes: Open Data DC, `data/dc/dc_shapes.json`.
- Sources: `playbook/12-sources.md`. Official spine = DLCP Basic Business Licenses (Open Data DC 85bf98d3…, daily, CC BY 4.0; its
  LATITUDE/LONGITUDE are rounded to whole degrees, so `official.py` reads X/Y in EPSG:26985) + ABCA's monthly roster xlsx
  (`data/raw/official/abca_roster_2026-10.xlsx`, joined to ABCA's Open Data layer by license number, else placed by MAR Address
  Points). Never show holder names; never fall back to ENTITYNAME, OWNERNAME, OWNNAME2, CAREOFNAME or mailing addresses (tax layer
  fields are whitelisted in `fetch_official.TAX_FIELDS`).
- DC Health: pass/fail, no grade or score; dc.healthinspections.us is search-only, linked, never crawled (Nick's yes needed; he chose
  "records request first": draft in `playbook/records-requests.md`, for Nick to file at myfoia.dc.gov; not sent). Never infer "closed"
  from a closure notice. Closures come only from lapsed licenses (`dc.py` LAPSED_*: DLCP stale 180+ days or cancelled, ABCA
  safekeeping/cancellation), guarded by `_live_here` (a late renewal, "Expired - 1st Penalty", is not a closure: Call Your Mother).
- Rebuild: `cd pipeline && ../.venv/bin/python fetch_official.py && ../.venv/bin/python listings.py && ../.venv/bin/python calibrate.py &&
  ../.venv/bin/python build_research.py && ../.venv/bin/python dc.py && DC_APP=1 ../.venv/bin/python dc.py`, copy `data/app/places.json`
  and `data/app/detail-district-of-columbia.json` into `DCEats/Resources`, then `.venv/bin/python scripts/make-site.py`,
  `scripts/qa-site.py`, `python3 scripts/publish_app_data.py`, and `.venv/bin/python scripts/make-leaderboard.py` (republish
  `site/index.html` with dc.json, dc_detail.json, dc_shapes.json). dc.py takes several minutes on a loaded Mac: run it in the background.
- Matching: `official.py` keeps the quadrant in street keys ("1213 U St NW" -> ('1213', 'U NW')); one ABCA license can name several venues
  ("Minibar/Barmini"), handled by dc.py's multi-venue pass; "N/A" trade names count as blank; a digit-only name (1789) matches by digits
  at the address. Calibration vs active DC licenses: Meta+Google-open 78.0%, Meta-only 49.8% (web only; the app ships no Google number,
  and a unit test plus dc.py asserts enforce it).
- Link check: `cd pipeline && CHECK_WORKERS=4 ../.venv/bin/python check_websites.py [--retry-transient]` (detached; back up
  `data/dc/website_check.json` first). Done 2026-10-27: 1,422 links ok; backup `website_check.backup-2026-10-27.json`.
- Research: `pipeline/build_research.py` (evidence standard in its docstring) -> `data/research/app/*.json` + `LEADS.md`. Guides today:
  Ethiopian 13, half-smokes 3, oldest 3 (Ben's Chili Bowl 1958, Martin's Tavern 1933, Tune Inn 1947: Ghosts of DC 2026 ties the last two
  to their buildings), pupusas 2, fish market & Wharf 2, mumbo 1, jumbo slice 1. Elcielo's two Guide entries at La Cosecha: the One Star
  tasting room is its own record, the Recommended bistro is our "El Cielo" listing (same site, elcielo.com.co/washington/). Eater DC,
  the Post, City Paper, PoPville, WTOP and NBC4 robots-block Claude; Axios answers 403; guide.michelin.com is read only with Claude's web
  fetcher (`check_sources.READ_BY_FETCHER`). MICHELIN (108 places) in `data/research/michelin.json`, James Beard in `jbf.json`.

## App (ported 2026-10-27 from nc-eats)
- `DCEats/` (bundle com.dceats.ios, Home Screen "DC Eats"); `xcodegen generate`; build with
  `DEVELOPER_DIR="/Applications/Xcode 1.app/Contents/Developer"` (Xcode 27.1, 27A9275 on 2026-10-27: check it's a public release before
  any archive), `-derivedDataPath DerivedData`. Simulators: create your own on iOS 27.0 (24A434, back on this Mac 2026-10-28) when
  needed, e.g. "DC Eats 6.9" (iPhone 17 Pro Max) and "DC Eats iPad 13" (iPad Pro 13-inch (M5)); one at a time, deleted when done
  (none kept as of 2026-10-28).
- On an "iPhone Duo" (iOS 27.1) the app runs on the 466 x 678 pt cover screen, where iOS draws the tabs as a floating rail of plain
  Buttons (identifier = the tab's SF Symbol), not a TabBar: SmokeUITests' `tab(_:)` finds either, `isPad` reads the layout on screen,
  and `SCREEN=1 bash scripts/capture-screenshots.sh` captures the cover screen.
- Tests 2026-10-28: 52 unit + 7 UI pass on the iPhone 17 Pro Max (launch 4.7 s; a 6.3 s run at load 16 on 11 cores missed the 6 s bar,
  rerun quiet) and on the iPad Pro 13" (52 unit, 6 UI, Bib Gourmand UI skipped there by design; launch 4.5 s); 2026-10-27 the same on
  the Duo. The accessibility audit skips only when it times out on a saturated Mac; its findings are Dynamic Type on the display-font
  headers and Apple's map "Legal" link, as in the other states.
- Screenshots 2026-10-28 (iOS 27.0): site = `SLEEP=14 bash scripts/capture-screenshots.sh <iPhone 17 Pro Max udid>` -> docs/screenshots
  (1320 x 2868), `scripts/site-images.sh` (480 x 1043), make-site. App Store: the same iPhone captures copied to
  `playbook/app-store/raw/iphone/`, `OUT=$PWD/playbook/app-store/raw/ipad SLEEP=14 bash scripts/capture-screenshots.sh <iPad udid> home
  ethiopian half_smokes map oldest patios`, then `.venv/bin/python scripts/appstore-screenshots.py` -> playbook/app-store/iphone (8,
  1320 x 2868) and ipad (6, 2064 x 2752), captions with no "free", "best" or MICHELIN/James Beard marks. The iPad set leaves out
  honors: "MICHELIN & James Beard" truncates in the iPad list column (a large navigation title can't wrap). Guide titles must fit
  about 28 characters at iPhone width: the patios guide is "Sidewalk Cafés & Patios" (was "... & Summer Gardens", which truncated).
- Data: core places.json + one detail file (region "District of Columbia"). Detail `lic` = [source, number, type, status, first issued,
  expires, [endorsements]] for DLCP and ABCA licenses; `liq` = the ABCA type and class. Core `liq` 1 = a live ABCA on-premises license of
  its own (Class C or D); `pt` 1 = that license's sidewalk café or summer garden endorsement (the "Sidewalk Cafés & Patios" guide).
- Guides: half-smokes, mumbo, jumbo slice, Ethiopian, pupuserías, fish market & Wharf, honors, oldest, sidewalk cafés, near me, all.
  Home hides an empty guide. Search knows the DC guide phrases (`Search.tagPhrases`).

## Website (ported 2026-10-27 from nc-eats)
- `scripts/make-site.py` -> `docs/` (BASE /dc-eats until a custom domain); `scripts/explore.js` is the web app (keys `dceats-`, map of
  the District and its wards from `dc_shapes.json`, credited to Open Data DC); `scripts/qa-site.py [--static]` checks both (served under
  /dc-eats/ on a free port). Pages: landing, guide pages for guides with `MIN_GUIDE` (4) places (Ethiopian today), honors, licenses &
  inspections explained, 14 neighborhood pages + index, explore, privacy, terms, 404.
- qa-site.py's DC checks: no inspection field anywhere in the data; every license DLCP's or ABCA's 7-field record; "serves alcohol" only
  with an ABCA license and class; outdoor seating only with the endorsement; no holder/owner/mailing field; state names followed by
  Avenue/Street don't count as another state (DC's avenues).
- `make-site.py`'s `merged()` keeps the core's `liq` (1) and puts the detail's class in `liq_class` (they share a key in the app data).
- 2026-10-28: `qa-site.py` passes in full (22 pages at 375 and 1280, dark mode, the web app); OTA copy docs/data/app 2026-10-28.1, republished fresh with no `previous` copy (DC was never published; the kept 10-27 copy held the Hard Rock tag).
- Outbound links (QA 2026-10-28, P1): `pipeline/tracking_params.py` (identical in every state; don't edit here) also strips tags after
  "#", tags written into the path, scheme-less links' tags and `_kx`; the app's `TrackingParams.tracked(in:)` (DCEatsTests; 52/52 unit tests pass 2026-10-28 on an iPhone 17 Pro Max) mirrors it
  and testTrackingGuardCatchesABrokenCopy covers each kind (Hard Rock DC's `#utm_source=rest_of_network…` was the one DC case). Every
  website is one link with no spaces and no map pin: `DataGuards.malformedWebsites` on the raw field (URL(string:) would encode a
  space) and qa-site's `website_problem` on the site data and the manifest's current app files.
