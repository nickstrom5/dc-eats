# DC Eats: name, icon, palette (Nick's calls, 2026-10-27)

Asked with AskUserQuestion after the private leaderboard v1 (link in `LOCAL.md`) and the concept sheet
(`playbook/brand/concepts-sheet.png`).

## Name: "DC Eats"
- App Store name **DC Eats: Restaurants** (20 chars), Home Screen **DC Eats**, subtitle **Half-Smokes, Injera & Pupusas** (29 chars;
  no trademark in it). Site: `dc.eatsranked.com` once Nick adds the Cloudflare CNAME `dc` (until then the github.io address).
- Checks (2026-10-27): no App Store app named "DC Eats", "District Eats" or "Capital Eats" turned up (web search; apps.apple.com and
  itunes.apple.com disallow Claude in robots.txt, so the store itself wasn't read). USPTO trademark search (tmsearch.uspto.gov, typed into
  the search box): no live "DC EATS" or "CAPITAL EATS" mark; "@DISTRICT EATS" (serial 87566613, promotional services, Florida) is dead
  (abandoned). Domains dceats.com, districteats.com and capitaleats.com are registered by others (not needed). Known risk: DC Comics
  guards its "DC" marks; the name is a food app's place name, not a comics or entertainment use.
- Rejected: "District Eats" (an active DC dining Instagram account uses it; Axios profiled it in 2024), "Capital Eats" (Capital/Capitol
  confusion, near The Capital Grille). Avoided: "Mumbo", Eater DC, Washingtonian, Destination DC's marks, team names, anything with
  "Washington" (Washington Eats is the state app).

## Icon: B, the jumbo slice
- One huge slice, tip up, wider than the round paper plate under it so it hangs over both sides; pepperoni; on flag navy `#041E42`.
  Plate `#EEF0F2` is the backing shape (like Connecticut's sheet pan) with a 13 px navy ring; crust `#D98E3F`, cheese `#F6C453`,
  pepperoni `#B3261E`. `scripts/icon-concepts.swift` `jumboSlice()`; passes `state-prompts/icon-style/check.swift --emblem`
  (box 0.730 x 0.644, centroid +34 px, coverage 31.4%) and reads as a pizza slice at 60 px.
- Not chosen: A half-smoke on flag red (reads like Michigan's coney and Chicago's hot dog at 60 px), C injera platter on slate.

## Palette: District flag red & navy
- Flag red `#C8102E` (no official hex is published; the common reproduction) as a fill and for accents (5.9:1 on white, white on it
  5.9:1); navy `#041E42` for text and fills (16.7:1 on white); white and cool-grey surfaces. Not the Commanders' burgundy and gold.
- Header element: a thin band of the flag's three stars over two bars (no seal, no team marks).
- Display face: Barlow Condensed; text: Public Sans (the leaderboard; the app uses the system faces with a condensed display weight).

## Inspections: records request first
- DC Health's portal (dc.healthinspections.us) is search only. Nick chose a public-records request for a bulk extract (drafted in
  `playbook/records-requests.md`; Nick sends it). Until then each place links the portal, and no inspection data is shown. The portal is
  not crawled.
