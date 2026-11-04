# District of Columbia sources (checked 2026-10-27)

Every host below was robots-checked with `pipeline/check_sources.py` (ClaudeBot, Claude-User, anthropic-ai; RFC 9309 matcher; an empty
202 counts as a bot check) in its own step, before any other request. User agent on every scripted request:
`DCEatsBuild/1.0 (+nick@eatsranked.com)`. Raw files are in `data/raw/official/` (git-ignored, never public).

DC is one jurisdiction with no county layer. Its restaurants are licensed by DLCP (a Basic Business License for every restaurant,
carryout and bakery) and, when they pour, by ABCA. DC Health inspects them **pass/fail, with no grade, score or placard**
("performs pass-fail inspections rather than assigning grades", dchealth.dc.gov/service/division-food), and publishes reports only
through a search portal.

## Official records

| Source | What | Terms | Cadence | Status |
|---|---|---|---|---|
| **DLCP "Basic Business Licenses"**, Open Data DC item `85bf98d3915f412c8a4de706f2d13513` (maps2.dcgis.dc.gov/dcgis/rest/services/FEEDS/DCRA/FeatureServer/0; robots.txt 404, nothing disallowed) | 280,934 rows with history; we read the 29,927 food, street-vending and entertainment rows. Fields used: CUSTOMERNUMBER (shown as the license number), status, business activity, trade name, premises address, MAR_ID, SSL, ward, cluster, first issue date, expiry. Active (2026-10-27): Restaurant 2,232, Delicatessen 1,067 (DC's carryout class), Caterers 315, Bakery 67, Street Vending Business 954 | **CC BY 4.0** | `DATAREFRESHEDON` 2026-10-27 (daily) | **used**. `ENTITYTRADENAME` is blank or a placeholder ("N/A" on 212 rows) on 557 of 2,232 active Restaurant licenses: such a license never names a place (we never fall back to ENTITYNAME). ENTITYNAME is read only to recognise a listing named for its holder and to let a nameless license confirm a listing at its own address; owner, agent and billing fields are never requested. **The feed's LATITUDE/LONGITUDE are rounded to whole degrees** (39, -77), so points come from X/Y (Maryland State Plane, EPSG:26985). `INITIALISSUEDATE` is shown as "first licensed", never as "opened" |
| **ABCA roster** "Alcohol License Holders October 2026" (abca.dc.gov/page/current-alcohol-license-holders, Excel, Last-Modified 2026-10-01; robots allow) | 2,408 licenses (2,357 in DC): license number, status, trade name, entity, address, class (A/B off-premises, C/D on-premises), establishment type, endorsements (sidewalk café, summer garden, entertainment, dancing, brewpub, sports wagering, streatery, carry-out), capacity, expiry. Live on-premises (Active, Issued, About to Expire): 1,543 (C 1,469, D 74) | public roster, no stated terms | monthly, posted on the 1st | **used**: "serves alcohol" = a live Class C/D license of the place's own; none matched is "—", never "no". Entity names are never shown |
| ABCA "Alcohol License Business Locations", Open Data DC `cabe9dcef0b344518c7fae1a3def7de1` (FeatureServer/5) | 2,329 rows: the roster's points and MAR_IDs | CC BY 4.0 | last edited 2026-06-08 (lags the roster) | **used to place roster rows** by license number (2,278 placed; the other 79 by their address in the MAR) |
| ABCA "Alcohol License Cancellations", `8ff680ae6b58474083f9f860531c9ad0` (FeatureServer/42) | 485 rows: license, trade name, address, MAR_ID, cancellation date, reason | CC BY 4.0 | last edited 2026-06-01 | **used as a closure signal**, only together with a lapsed DLCP food license (below) |
| "Address Points" (the Master Address Repository), `aa514416aaf74fdc94748f1e56e7cc8a` | 144,444 addresses with MAR_ID and point | CC BY 4.0 | — | **used as the geocoder** for ABCA roster rows and researched addresses. The MAR web service at citizenatlas.dc.gov is retired (404) and the MAR 2 API (datagate.dc.gov) needs a key |
| "Washington DC Administrative Boundary" `7241f6d500b44288ad983f0942b39663`, "Wards from 2022" `c5cd8b40fb784548a6680aead5f919ed`, "Neighborhood Clusters" `f6c703ebe2534fc3800609a07bad8f5b`, "Neighborhood Labels" `c4b0cd43d50949e98e57de9f22b455fc` | The District's outline, 8 wards, 46 clusters (NBH_NAMES), 132 label points | CC BY 4.0 | — | **used**: the "outside DC" test, the ward filter and map, and each place's neighborhood: one of the names its own cluster gives, picked by a historic district named for it when the place is inside one, else the nearest label point inside the cluster (skipping Georgetown, Mount Pleasant, LeDroit Park and Foxhall Village outside their districts, which cover those whole neighborhoods); DC draws no official neighborhood lines (`areas.py`). The label layer dates from 2003 (DATELASTMODIFIED): its short forms are spelled out ("Central NE" → Central Northeast, "Monumental Core" → National Mall), "Near Southeast" is read as Navy Yard (its cluster's own list names both), and "South Central" is not used |
| Historic Preservation Office "Historic Districts", Open Data DC item `a443bfb6d078439e9e1941773879c7f6` (maps2.dcgis.dc.gov/dcgis/rest/services/DCGIS_DATA/Historic_WebMercator/MapServer/6) | 74 designated districts; 18 named for a neighborhood (Shaw, Blagden Alley/Naylor Court, Dupont Circle, Georgetown, Mount Pleasant, LeDroit Park, Bloomingdale, Capitol Hill, …) | CC BY 4.0 | fetched 2026-10-28 | **used** for neighborhoods only (above): the only official lines around a named neighborhood. Checked against the 93 places whose own names give a neighborhood: 71 right, against 67 for the nearest label alone and 59 for the nearest label anywhere. DC Health's "Planning Neighborhoods" (`de63a68eb7674548ae0ac01867123f7e`, census-tract groups) scored 62 and moved 783 places, mostly wrongly (1610 U St in "Adams Morgan"): **not used** |
| OCFO "Integrated Tax System Public Extract" `7d5e6cabd2304e779c719a4d5515af77` (republished under dated names such as ITSPE_08172026, so resolved by item id; services.arcgis.com answers 403 "Invalid URL" to robots.txt, the API normally) | 221,683 lots: SSL, use code, land, building and total assessed value | CC BY 4.0 | updated 2026-10-27 | **fetched, not used yet**. A building-value board is possible: it would have to say the value is the whole lot's (often an office tower's). OWNERNAME, OWNNAME2, CAREOFNAME and mailing addresses are never requested |
| **DC Health inspections**: dc.healthinspections.us (`?a=Inspections`, renders, 200; robots.txt 404) | Search by name, establishment or inspection type, ward, quadrant, date; one HTML report per inspection (`_paper_food_inspection_report.cfm?inspectionID=`) with Priority, Priority Foundation and Core counts, corrected-on-site and repeat marks, and the risk category. A rolling "past 3 years", "scanned on a weekly basis", posted after a 24-hour to 7-day review | no API, no bulk file, no Open Data DC dataset | weekly | **linked, not copied** (the prompt: no crawl without Nick's yes, one request at a time, cached, stop at any block; a records request is outward). Each place links the portal. Never inferring "closed" from a closure report (reopenings aren't always posted) |

### Closures from the license record
A listing with no live record of its own comes off the list when its business's DLCP food license at this address has lapsed (closed,
cancelled, revoked or transferred, or expired more than 180 days ago) **and** its ABCA license was cancelled or sits in safekeeping, and no
live or recently expired license at the address carries an agreeing name. A late renewal ("Expired - 1st Penalty") doesn't count: Call
Your Mother's Park View license expired 2026-09-30 and the place stays. 16 places came off this way on 2026-10-27 (MXDC, Across the
Pond, The Eleanor, Coco Lezzone, Melange …; `data/dc/qa_debug.json` `lapsed_closed`). Hand-checked and honored places are exempt.

### Multi-venue licenses
One ABCA license can name several places ("Minibar/Barmini", "Jont/Colada Shop/Bresca"): each listing named in the license's list is
confirmed by it (20 on 2026-10-27), while a license that names one place still confirms one listing only.

## Base and benchmarks

| Source | What | Terms | Cadence | Rows |
|---|---|---|---|---|
| Overture Maps places `2026-10-21.0` (newest release) | Map listings, address points | CDLA-Permissive-2.0 / Apache-2.0 + Foursquare NOTICE | Monthly | 5,961 DC eating/drinking listings (569 marked closed); clipped three ways: the official boundary (+15 m), a DC zip (200xx, 202xx–205xx) and Overture's own region (31 rows outside) |
| UCSD Google Local 2021 (`meta-District_of_Columbia.json.gz`, mcauleylab.ucsd.edu, 2.4 MB; robots.txt 404) | 2021 ratings, reviews, price, 2021 closures: **web leaderboard only, never the app** | research dataset | frozen Sep 2021 | 3,522 food listings (683 closed by 2021); 2,663 matched to Overture listings |
| BLS QCEW, NAICS 722, 2025 annual average (from the prompt; data.bls.gov's robots.txt disallows Claude, so not re-read) | Private eating and drinking places: 2,694 (2,240 restaurants, 182 bars) | public | quarterly | benchmark only. The app keeps 2,969 restaurants and the leaderboard 3,273: both count coffee shops, bakeries, carryouts and hotel restaurants, and every DC place with a live license |

## Calibration (2026-10-27, `data/dc/calibration*.json`)

Every map listing inside the District was checked against 5,351 active DLCP food, caterer and vending licenses and live ABCA licenses
(same business name nearby, or the same street address with a distinctive name word in common). DC licenses every place that sells food,
so this is a real rate, not a floor.

| Kind of listing | On an active DC license |
|---|---|
| Meta + open in Google 2021 | 78.0% of 1,307 |
| Meta only | 49.8% of 1,282 |
| Chain store list (brand feed) + Google 2021 / only | 62.5% of 24 / 42.9% of 63 |
| Microsoft only | 22.3% of 206 |
| Foursquare/BrightQuery/Microsoft + Google 2021 | 20.4% of 793 |
| BrightQuery only | 15.5% of 833 |
| Foursquare only | 15.3% of 561 |
| Overture says closed / Google 2021 says closed | 5.6% / 1.8% |
| App grouping: Meta ≥ 0.95 | 77.1% of 1,909 |
| App grouping: Meta 0.90–0.95 | 34.0% of 235 |

The other way, the open map listings hold 68.9% of the 2,023 businesses with an active DLCP Restaurant license, 44.9% of 914 with a
Delicatessen license and 71.4% of 1,518 with a live on-premises ABCA license; licensed restaurants and bars among the rest are added from
the lists (web 660, app likewise).

Keep rule (from these numbers): web = Meta or brand feed or an active license or hand-checked, minus what Google showed closed in 2021
(unless licensed or checked); app = an active license, hand-checked, Meta ≥ 0.95, Meta 0.90–0.95 with a website, or a chain store list.

## Honors

- **MICHELIN Guide Washington, D.C.** (`data/research/michelin.json`), read 2026-10-27 with Claude's web fetcher (guide.michelin.com
  answers scripts with an empty 202 AWS WAF challenge; never retried): 108 places, 2 Two Stars (Jônt, minibar by José Andrés), 18 One Star,
  28 Bib Gourmand (both counts confirmed on the Guide's own filter pages), 60 Selected. Every restaurant's own Guide page read for its
  address. Oyster Oyster's Green Star: first awarded in the December 2024 guide (RAMW press release); its Guide page carries the chef's
  sustainability statement the Guide shows for Green Star holders. Gravitas, Kinship, Métier and Tail Up Goat (One Stars in the
  Nov 18, 2025 announcement) are not among the 108. The Inn at Little Washington is in Virginia, out of scope.
- **James Beard** (`data/research/jbf.json`, jamesbeard.org stories): 2026 winner Susan Bae (Moon Rabbit), Outstanding Pastry Chef or Baker;
  2026 nominees Maison Bar à Vins (Best New Restaurant), Brent Kroll (Maxwell Park; Outstanding Professional in Beverage Service), Suresh
  Sundas (Tapori; Best Chef: Mid-Atlantic); 11 semifinalists (Centrolina, 2 Amys, Marcus DC, Bresca, Service Bar, Cucina Morini, 2Fifty
  Texas BBQ, MITA, Ama, My Little Chamomile; the Fried Rice Collective's Outstanding Restaurateur nod belongs to the group and isn't shown
  on one place). America's Classics (Wikipedia's list; the Foundation's past-awards search loads by script and returned nothing to the
  fetcher): Ben's Chili Bowl 2004, Annie's Paramount Steakhouse 2019 (C. F. Folks, 2013, closed in 2018). Earlier DC winners (Rob Rubba,
  Aaron Silverman, Jeremiah Langhorne …) are leads, not yet checked.
- `anniessteakhouse.com` (Annie's old domain) now serves an online slot gambling promotion: added to `pipeline/website_blocklist.json`.

## Hand-checked guides (`pipeline/build_research.py`, its docstring has the evidence standard)

- Naming pages: Washingtonian (Ethiopian guide Aug 31, 2026; cheap eats Aug 27, 2026; DCity Apr 2025; Petworth Aug 2024), Washington.org's
  current neighborhood and half-smoke pages (© 2026, undated: the weakest kind), the Wharf's own fish-market page, MICHELIN, and the
  places' own sites. Every cited host passes `check_sources.py` (132 URLs on 12 hosts, 0 unusable, 2026-10-27).
- Oldest places need a founding year tied to the current address: Ben's Chili Bowl 1958 (its own site), Martin's Tavern 1933 and the
  Tune Inn 1947 (Ghosts of DC, May 16 and Jun 9, 2026: "same building" at Wisconsin and N; "at 331½ Pennsylvania Avenue SE since 1947").
- Blocked or unusable: Eater DC, the Post, City Paper, PoPville, WTOP and NBC4 disallow Claude in robots.txt; axios.com answers 403;
  floridaavenuegrill.com answers a bot check; martins-tavern.com answered 521; gloriasrestaurants.com is a parked domain.
