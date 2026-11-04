"""The District's own geography (Open Data DC, CC BY 4.0; fetch_official.py): its boundary, its 8 wards (2022), its 46 neighborhood
clusters with their 132 neighborhood label points, and the Historic Preservation Office's historic districts.

Every mailing address in the District says "Washington", so a place's neighborhood comes from here, never from a map listing's town:
- ward: the 2022 ward polygon the point falls in ("Ward 2");
- cluster: the neighborhood cluster polygon ("Cluster 6", named "Dupont Circle, Connecticut Avenue/K Street");
- hood: one of the names the place's own cluster gives (a cluster holds 1 to 6). The District draws no line between, say, Adams
  Morgan and Kalorama Heights, and its label points (2003) only mark where a name sits, so the name is chosen in this order:
  1. a historic district named for one of those neighborhoods, when the place is inside it: "Shaw Historic District" makes 9th Street
     Shaw, though Cluster 7's only label point, Logan Circle's, is 200 m away;
  2. else the nearest label point inside the cluster, passing over a neighborhood whose historic district covers all of it (WHOLE)
     when the place is outside that district: 14th Street is never Mount Pleasant, whose label is the nearest there;
  3. a cluster with no label point inside it takes the first name in its list.
  Checked 2026-10-28 against the 93 places whose own names give a neighborhood ("Boqueria Dupont", "El Rey Navy Yard"): this rule
  gets 71 right (it moves 128 of 3,208 places); the nearest label in the cluster alone 67, the nearest label anywhere 59. DC Health's
  "Planning Neighborhoods" (census tract groups; 1610 U St in "Adams Morgan", 3801 14th St in "16th St Heights") get 62 and move 783
  places, mostly wrongly: not used. (common.canon_city reads the 2003 "Near Southeast" label as Navy Yard.)
inside(): the District's boundary polygon (the "outside DC" test for Arlington, Silver Spring, Takoma Park, Chevy Chase MD).
"""
import json, math, os, re
from shapely.geometry import shape, Point
from shapely.prepared import prep
from shapely import STRtree
from common import RAW, canon_city

OFF = os.path.join(RAW, "official")
_B = shape(json.load(open(os.path.join(OFF, "boundary.json")))["features"][0]["geometry"]).buffer(0)
BOUNDARY = _B
# about 15 m: a point geocoded onto the boundary street itself (Western Ave, Eastern Ave, Southern Ave) stays in; a place across the street
# in Maryland is 25-40 m out and is dropped (its zip and Overture's region say so too)
_PB = prep(_B.buffer(0.00015))
_W = json.load(open(os.path.join(OFF, "wards.json")))["features"]
WARDS = [(f["properties"]["NAME"], shape(f["geometry"]).buffer(0)) for f in _W]
_C = json.load(open(os.path.join(OFF, "clusters.json")))["features"]
CLUSTERS = [(f["properties"]["NAME"], f["properties"]["NBH_NAMES"], shape(f["geometry"]).buffer(0)) for f in _C]
CLUSTER_NAMES = {c: n for c, n, _ in CLUSTERS}
# "South Central" (Cluster 24) is the label layer's own word, not a neighborhood name anyone uses: its places take the nearest other label
_LAB = [(canon_city(f["properties"]["NAME"]), f["geometry"]["coordinates"]) for f in json.load(open(os.path.join(OFF, "labels.json")))["features"]
        if f["properties"]["NAME"] != "South Central"]
_wt = STRtree([g for _, g in WARDS]); _ct = STRtree([g for _, _, g in CLUSTERS])
# label points per cluster
LABELS = {}
for name, (x, y) in _LAB:
    p = Point(x, y)
    for i in _ct.query(p):
        if CLUSTERS[i][2].contains(p):
            LABELS.setdefault(CLUSTERS[i][0], []).append((name, x, y)); break


# Historic districts named for a neighborhood: the only official lines drawn around one. Blagden Alley/Naylor Court lies in Shaw.
# Downtown's district is left out (it covers Penn Quarter's blocks too), and so are districts named for a street or an institution.
HD_HOODS = {"Anacostia Historic District": "Historic Anacostia", "Bloomingdale Historic District": "Bloomingdale",
            "Capitol Hill Historic District": "Capitol Hill", "Cleveland Park Historic District": "Cleveland Park",
            "Dupont Circle Historic District": "Dupont Circle", "Foggy Bottom Historic District": "Foggy Bottom",
            "Foxhall Village Historic District": "Foxhall Village", "Georgetown Historic District": "Georgetown",
            "Kingman Park Historic District": "Kingman Park", "LeDroit Park Historic District": "Le Droit Park",
            "Logan Circle Historic District": "Logan Circle", "Mount Pleasant Historic District": "Mount Pleasant",
            "Mount Vernon Square Historic District": "Mount Vernon Square",
            "Mount Vernon Triangle Historic District": "Mount Vernon Triangle", "Shaw Historic District": "Shaw",
            "Blagden Alley/Naylor Court": "Shaw", "Takoma Park Historic District": "Takoma",
            "Woodley Park Historic District": "Woodley Park"}
# districts that cover the whole neighborhood they're named for, so a place well outside one isn't in that neighborhood
WHOLE = {"Georgetown", "Mount Pleasant", "Le Droit Park", "Foxhall Village"}
HISTORIC = {}
for f in json.load(open(os.path.join(OFF, "historic.json")))["features"]:
    n = HD_HOODS.get(f["properties"]["NAME"].strip())
    if n:
        g = shape(f["geometry"]).buffer(0)
        HISTORIC[n] = HISTORIC[n].union(g) if n in HISTORIC else g
_HP = {n: prep(g) for n, g in HISTORIC.items()}
# the names a cluster may give: its label points' and its own list's ("Cardozo/Shaw" counts as Shaw)
LISTED = {c: {n for n, _, _ in LABELS.get(c, [])} | {canon_city(x.strip()) for x in re.split(r"[,/]", names or "")}
          for c, names, _ in CLUSTERS}


def first_name(cluster):
    return canon_city(re.split(r",\s*", CLUSTER_NAMES.get(cluster) or "")[0]) or None


def inside(la, lo):
    return la == la and lo == lo and _PB.contains(Point(lo, la))


def _hit(tree, geoms, p, near=0.0004):
    for i in tree.query(p):
        if geoms[i].contains(p):
            return i
    # a point a few meters outside every polygon (on the river edge): the nearest within ~40 m
    best, bd = None, near
    for i in tree.query(p.buffer(near)):
        d = geoms[i].distance(p)
        if d < bd:
            best, bd = i, d
    return best


def locate(la, lo):
    """(ward, cluster, neighborhood) for a point, or (None, None, None) outside the District."""
    if la != la or lo != lo:
        return None, None, None
    p = Point(lo, la)
    wi = _hit(_wt, [g for _, g in WARDS], p)
    ci = _hit(_ct, [g for _, _, g in CLUSTERS], p)
    ward = WARDS[wi][0] if wi is not None else None
    cl = CLUSTERS[ci][0] if ci is not None else None
    hood = None
    if cl:
        inn = [n for n, g in _HP.items() if n in LISTED[cl] and g.contains(p)]
        if len(inn) == 1:
            hood = inn[0]
        else:
            labs = sorted(LABELS.get(cl) or [], key=lambda t: math.hypot((t[2] - la) * 111, (t[1] - lo) * 86.6))
            # about 100 m: a place across the street from its district's edge still counts
            hood = next((n for n, _, _ in labs if n not in WHOLE or HISTORIC[n].distance(p) < 0.001), None) or first_name(cl)
    return ward, cl, hood


def write_shapes(path):
    """The map outlines both builds ship: the District's boundary and its 8 wards, simplified (Open Data DC, CC BY 4.0), in the
    {"state": [[ring]], "counties": [{"name", "c": [ring]}]} shape the other states use (a ward stands where a county would)."""
    def rings(geom, tol, min_area):
        geom = geom.simplify(tol, preserve_topology=True)
        polys = [p for p in getattr(geom, "geoms", [geom]) if p.geom_type == "Polygon" and p.area >= min_area]
        return [[[round(x, 5), round(y, 5)] for x, y in p.exterior.coords] for p in polys]
    out = {"state": [[r] for r in rings(BOUNDARY, 0.0002, 0.00001)],
           "counties": [{"name": n, "c": rings(g, 0.0003, 0.00001)} for n, g in sorted(WARDS, key=lambda t: int(t[0].split()[-1]))]}
    json.dump(out, open(path, "w"), separators=(",", ":"))
    return out
