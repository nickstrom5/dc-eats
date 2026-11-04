"""Writes data/research/app/*.json (hand-checked District of Columbia guides) from the compact lists below. Ported from nc-eats.

Each entry cites a page that names the place for the food (robots-checked host: check_sources.py) and 2025-26 evidence that it is
operating, one of: the MICHELIN Guide's current selection; a page dated 2025-26; the place's own site showing a 2026 date; a current
Washington.org (Destination DC) page (© 2026, undated: the weakest of these, named as such in the note); or the place's own active DLCP
business license in the District's daily feed (official, read 2026-10-27). The address comes from the map listing or license we already
hold for that name at that street number (site/dc.json), never from memory; a name that isn't found exactly once (at the street number
given) is left out and listed in data/research/app/LEADS.md. Axios answers Claude's fetcher 403, and Eater DC, the Post, City Paper,
PoPville, WTOP and NBC4 disallow Claude in robots.txt: none is cited.
Usage: ../.venv/bin/python build_research.py   (then dc.py)"""
import json, os, re
from brands import brand_of
from common import norm_name
ROOT = os.path.join(os.path.dirname(__file__), "..")
R = os.path.join(ROOT, "data", "research")
d = json.load(open(os.path.join(ROOT, "site", "dc.json")))
C, M = d["cols"], d["meta"]
norm = lambda s: re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", (s or "").lower().replace("'", "").replace("’", ""))).strip()

# naming pages (each read 2026-10-27)
WDC_HS = "https://washington.org/visit-dc/dc-signature-half-smoke-all-you-need-to-know"   # Washington.org, current (© 2026, undated)
WDC_ADMO = "https://washington.org/visit-dc/things-see-and-do-adams-morgan"              # Washington.org, current (© 2026, undated)
WDC_CH = "https://washington.org/places-to-eat/columbia-heights-washington-dc"           # Washington.org, current (© 2026, undated)
WDC_MP = "https://washington.org/visit-dc/things-see-do-mount-pleasant"                  # Washington.org, current (© 2026, undated)
WASH_ETH = "https://washingtonian.com/guide/food/where-to-eat-ethiopian-food-around-the-dc-area-right-now/"   # Washingtonian, Aug 31, 2026
WASH_CHEAP = "https://washingtonian.com/2026/08/27/best-cheap-eats-around-the-dc-area/"   # Washingtonian, Aug 27, 2026
WASH_DCITY = "https://washingtonian.com/2025/04/24/a-long-running-barbecue-spot-adds-a-whiskey-bar-serving-mumbo-sauce-cocktails/"   # Apr 24, 2025
WASH_PETWORTH = "https://washingtonian.com/2024/08/26/neighborhood-guide-things-to-do-in-petworth/"   # Washingtonian, Aug 26, 2024
WHARF = "https://www.wharfdc.com/fish-market/"     # The Wharf's own page for the Municipal Fish Market (© 2026): "Opened in 1805"
DLCP = "https://opendata.dc.gov/datasets/85bf98d3915f412c8a4de706f2d13513"   # DLCP Basic Business Licenses (official, daily)
MI = "https://guide.michelin.com/us/en/district-of-columbia/washington-dc/restaurant/"
# the places' own sites (each read 2026-10-27)
BENS = "https://benschilibowl.com/locations/"      # "Original U Street location"; "A Washington, D.C. icon since 1958"; © 2026
JUMBO = "https://jumboslicepizzamart.com/"         # "Jumbo Pizza Slice" menu, 2341 18th St NW; © 2026
# history pages (each read 2026-10-27): a founding year tied to the current address, dated 2026
GHOSTS_MARTINS = "https://ghostsofdc.org/2026/05/16/martins-tavern-georgetown-history/"   # Ghosts of DC, May 16, 2026: 1933, same building
GHOSTS_TUNE = "https://ghostsofdc.org/2026/06/09/tune-inn-capitol-hill/"                  # Ghosts of DC, Jun 9, 2026: at 331½ since 1947

# (name as the source writes it, street number to pick the location (or None), note, founded, founded_note, [sources])
GUIDES = {
 "half-smokes": [
  ("Ben's Chili Bowl", "1213", "The U Street original, serving half-smokes with chili since 1958 (its own site); Washington.org's half-smoke page leads with it.",
   1958, "\"A Washington, D.C. icon since 1958\" (its own site), at the U Street original.", [WDC_HS, BENS]),
  ("Meats & Foods", "247", "Pint-sized Bloomingdale takeout with DC-made smokes under chili, pickled peppers and cheese (Washington.org's current half-smoke page; its DC business license is active).",
   None, None, [WDC_HS, DLCP]),
  ("DCity Smokehouse", "1301", "Barbecue in Anacostia; Washington.org's half-smoke page names its sausage with brisket chili, mustard, onions and cheese, and Washingtonian (Apr 2025) its mumbo-sauce cocktail.",
   None, None, [WDC_HS, WASH_DCITY]),
 ],
 "mumbo": [
  ("Howard China", "2827", "Bare-bones carryout near Howard University, known for wings with mumbo sauce (Washingtonian, Aug 2024; its DC business license is active).",
   None, None, [WASH_PETWORTH, DLCP]),
 ],
 "jumbo slice": [
  ("Jumbo Slice Pizza", "2341", "The 18th Street original of Adams Morgan's late-night jumbo slice (Washington.org's current Adams Morgan page; its own menu, © 2026).",
   None, None, [WDC_ADMO, JUMBO]),
 ],
 "ethiopian": [
  ("Buna Coffeehouse", "4400", "Ethiopian breakfast platter and kitfo (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Chercher", "1334", "Vegetarian deluxe platter and bone-in lamb stew (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Chercher", "3608", "Vegetarian deluxe platter and bone-in lamb stew (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Dukem", "1114", "Crispy tibs or minchet abesh on U Street (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Eatopia", "1301", "Ahi-tuna kitfo and tej cocktails (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Elfegne", "2420", "Mehaberawi platter and doro wat (Washingtonian, Aug 2026); MICHELIN Recommended.", None, None, [WASH_ETH, MI + "zenebech"]),
  ("Ethiopic", "401", "House veggie combo with shimbra asa wot on H Street (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Habesha Market", "1919", "Taste of Habesha platter, open until 11 p.m. (Washingtonian, Aug 2026).", None, None, [WASH_ETH, WASH_CHEAP]),
  ("Heat Da Spot", "3213", "An Ethiopian-style egg scramble on Georgia Avenue (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Ice N Slice", "3937", "Doro wat pizza (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Keren", "1780", "Eritrean all-day breakfast, including ful and silsi (Washingtonian, Aug 2026).", None, None, [WASH_ETH, WASH_CHEAP]),
  ("Letena", "3100", "Lega tibs, yebeg wat and lentil sambusas in Columbia Heights (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
  ("Tsehay", "2429", "The Ye Belay combo, for trying many dishes at once (Washingtonian, Aug 2026).", None, None, [WASH_ETH]),
 ],
 "pupusas": [
  ("Gloria's", "3411", "Late-night pork pupusas on 14th Street in Columbia Heights (Washington.org's current Columbia Heights page; its DC business license is active).",
   None, None, [WDC_CH, DLCP]),
  ("Haydee's Restaurant", "3102", "Mexican and Salvadoran plates in Mount Pleasant, with a pupusa platter (Washington.org's current Mount Pleasant page; its DC business license is active).",
   None, None, [WDC_MP, DLCP]),
 ],
 "oldest": [
  ("Martin's Tavern", "1264", "Georgetown tavern on the corner of Wisconsin Avenue and N Street, still run by the Martin family (Ghosts of DC, May 2026).",
   1933, "Opened in 1933, the year Prohibition ended, in the same building it fills today (Ghosts of DC, May 2026).", [GHOSTS_MARTINS]),
  ("Tune Inn", "331", "Capitol Hill dive bar on Pennsylvania Avenue SE, run by the same family for three generations (Ghosts of DC, June 2026).",
   1947, "At this address since 1947, the year on its sign (Ghosts of DC, June 2026).", [GHOSTS_TUNE]),
 ],
 "fish market": [
  ("Jessie Taylor Seafood", "1100", "The main stall at the Municipal Fish Market on Maine Avenue, which the Wharf's own page says opened in 1805.",
   None, None, [WHARF]),
  ("Fish Shop", "610", "Seafood on the Wharf's Water Street; MICHELIN Recommended.", None, None, [MI + "fish-shop-1219293"]),
 ],
}
KINDS = {"half-smokes": ["half-smokes"], "mumbo": ["mumbo"], "jumbo slice": ["jumbo slice"], "ethiopian": ["ethiopian"],
         "pupusas": ["pupusas"], "fish market": ["fish market"], "oldest": []}   # oldest: the founding year makes the tag


def key(s):
    """The name key without a leading "the"."""
    return re.sub(r"^the ", "", norm(s))


def find(name, num):
    """Rows of our data with this name (or the name with words after it: "Dukem" is "Dukem Ethiopian Restaurant") at this street
    number. The District is one city, so no town narrows it."""
    k = key(name)
    hits = [i for i, n in enumerate(C["name"]) if (key(n) == k or key(n).startswith(k + " ") or k.startswith(key(n) + " ")
                                                   or key(n).replace(" ", "") == k.replace(" ", "")) and not C["venue"][i]]
    if num:
        hits = [i for i in hits if (C["addr"][i] or "").split(" ")[0].split("-")[0] == num]
    return hits


leads, n_out = [], {}
for kind, rows in GUIDES.items():
    out = []
    for name, num, note, founded, fnote, srcs in rows:
        hits = find(name, num)
        if len(hits) != 1:
            leads.append(f"- {kind}: {name} ({num or 'no number'}) — {len(hits)} matches in our data; not added"); continue
        i = hits[0]
        out.append({"name": C["name"][i], "address": C["addr"][i], "city": "Washington", "zip": str(C["zip"][i]) if C["zip"][i] else None,
                    "kinds": KINDS[kind], "dishes": [], "note": note, "founded": founded, "founded_note": fnote, "website": None, "open": True,
                    "evidence_date": "2026-10", "sources": srcs, "match_names": [name.upper()] if norm(name) != norm(C["name"][i]) else []})
        if C["name"][i] != name:
            out[-1]["display"] = name   # the source's (and usually the place's own) spelling
    fn = re.sub(r"[^a-z]+", "_", kind).strip("_")
    json.dump(out, open(f"{R}/app/{fn}.json", "w"), indent=1, ensure_ascii=False)
    n_out[kind] = len(out)

open(f"{R}/app/LEADS.md", "w").write("# District of Columbia research leads (not yet verified)\n\nWritten by pipeline/build_research.py.\n\n" + "\n".join(leads) + """

## Waiting for evidence we may use (named by a source, but not yet tied down)
- Oldest places (a founding year at the current address is required): Florida Avenue Grill (1944; its site answers a bot check),
  1789 (own site gives no year), The Tombs, Annie's Paramount Steakhouse (1948; the Dupont Circle address dates later). Old Ebbitt
  Grill was founded in 1856 but has been at 675 15th St NW only since 1983 (the prompt; ebbitt.com/about), so it isn't an oldest place.
- Half-smokes: HalfSmoke (Shaw; Time Out, undated), The Big Stick (near Nationals Park), Florida Avenue Grill's half-smokes and eggs.
- Mumbo sauce: more carryouts named for wings with mumbo sauce; Washingtonian's Jun 2024 piece names J&J Pizza (lemon pepper, mumbo).
  The Alumni (1124 9th St NW, Shaw; Washingtonian Feb 2024, wings with mumbo sauce) has no listing or license in our data yet.
- Ethiopian: Doro Soul Food moved to 2108 8th St NW (Washingtonian, Aug 2026; also "Mélange Foods" there): our data has only its old
  address. Abebech (Brightwood Park; Washingtonian Jun 2025 review) to match.
- Pupusas: El Rinconcito (1326 Park Rd NW), Don Juan (1660 Lamont St NW) and Ercilia's (3070 Mt Pleasant St NW) need a current source;
  Washingtonian's 2026 cheap-eats pupusa pick (El Viejo) is in Silver Spring, MD.
- Fish market: Jessie's Seafood Dinners (Jessie Taylor's carryout, Washingtonian 2024) once our data has it; Captain White's left the
  market at the end of 2021 (now in Oxon Hill, MD).
- Blocked or unusable: axios.com answers Claude's fetcher 403; dc.eater.com, washingtonpost.com, washingtoncitypaper.com, popville.com,
  wtop.com and nbcwashington.com disallow Claude in robots.txt; floridaavenuegrill.com answers a bot check; gloriasrestaurants.com is a
  parked domain for sale.
""")
print(n_out, "| leads:", len(leads))
