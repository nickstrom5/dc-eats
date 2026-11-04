"""Official District of Columbia records -> one table of licensed food and alcohol businesses (data/raw/official, fetch_official.py).

DC is one jurisdiction with no county layer. Its open records (Open Data DC, CC BY 4.0; playbook/12-sources.md):
- "dlcp": the Department of Licensing and Consumer Protection's Basic Business Licenses. Every food, street-vending and entertainment
          license row, history included. A license row names its business activity (Restaurant, Delicatessen, Caterers, Bakery, ...),
          trade name (ENTITYTRADENAME), premises address with its Master Address Repository id (MAR_ID) and lots (SSL), status, first
          issue date and expiry. The legal entity (ENTITYNAME) is kept only to recognise a map listing named for its holder: it is never
          shown, and a license with no trade name has no name of its own (we never fall back to the entity).
- "abc":  the Alcoholic Beverage and Cannabis Administration's monthly roster ("Alcohol License Holders", Excel, posted on the 1st),
          joined by license number to ABCA's Open Data layer (which lags the roster) for the MAR_ID and point; the MAR's address points
          place the rest. Class C (spirits) and D (wine and beer) are on-premises; A and B are stores.
- "cancellations": ABCA's alcohol license cancellations (date and reason), a closure signal only together with other evidence.

DC Health inspects food establishments pass/fail with no grade, score or placard, and publishes reports only through a search portal
(dc.healthinspections.us); nothing here reads it.

load() returns: jur, lic (our id), shown (the agency's own number), name, dba, holder, keys, addr, city (None), zip, num, street, lat, lon,
kind, active, ltype, status, first, exp, mar, ssl, ward, cluster, endorse, biz.
kind: food (restaurants, delis, bakeries) | onprem (an on-premises alcohol license) | caterer | truck (street vending) | retail (groceries,
      food products, package stores) | other (school cafeterias, vending machines, delivery companies, wholesalers).
"""
import os, re, json, datetime
import numpy as np, pandas as pd
from common import norm_name, RAW, name_sim, _stems, GENERIC, nice

OFF = os.path.join(RAW, "official")
DIRS = {"N": "N", "S": "S", "E": "E", "W": "W", "NORTH": "N", "SOUTH": "S", "EAST": "E", "WEST": "W"}
QUAD = {"NW", "NE", "SW", "SE"}
TYPES = set("ST STREET AVE AV AVENUE BLVD BOULEVARD RD ROAD DR DRIVE LN LANE CT COURT PL PLACE PKWY PARKWAY TER TRL TRAIL WAY HWY CIR "
            "CIRCLE PLZ SQ MALL BND PASS XING RUN ROW WALK RDG LOOP FWY FREEWAY EXPY EXPRESSWAY PIKE PK PKE BV".split())


def road(a):
    """One spelling for numbered roads and DC's lettered streets: 'US HIGHWAY 1' = 'US 1'."""
    a = re.sub(r"(\d)\s*&\s*(\d)", r"\1-\2", a.upper())
    a = re.sub(r"\b(US|I)-(\w)", r"\1 \2", a)
    a = re.sub(r"\b(?:INTERSTATE(?: HIGHWAY| HWY)?|IH|I H)\s*(?=\d)", "I ", a)
    a = re.sub(r"\b(?:US|U S)\s+(?:HIGHWAY|HWY)\b", "US", a)
    a = re.sub(r"\bHIGHWAY\b", "HWY", a)
    return a


ORD = {"FIRST": "1ST", "SECOND": "2ND", "THIRD": "3RD", "FOURTH": "4TH", "FIFTH": "5TH", "SIXTH": "6TH", "SEVENTH": "7TH",
       "EIGHTH": "8TH", "NINTH": "9TH", "TENTH": "10TH", "ELEVENTH": "11TH", "TWELFTH": "12TH"}


def street_key(a):
    """'1213 U St NW' -> ('1213', 'U NW'); '675 15TH STREET NW' -> ('675', '15TH NW'). DC's quadrant is part of the street: 1st St NE and
    1st St SE are different streets, and lettered streets ("U", "H") are one letter long, so the quadrant keeps them apart."""
    if not isinstance(a, str):
        return None, None
    a = re.sub(r"[.,#]", " ", road(a))
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*\d+[A-Z]?)?\s+(.*)$", a)
    if not m:
        return None, None
    words = [w for w in m.group(2).split() if w]
    quad = next((w for w in words if w in QUAD), None)
    if len(words) > 1 and words[0] in DIRS:
        words = words[1:]
    core = []
    for w in words:
        if (w in TYPES or w in QUAD) and core:
            break
        core.append(w)
    core = [ORD.get(w, w) for w in core][:3]
    if quad and core:
        core.append(quad)
    return m.group(1), " ".join(core) or None


def street_compat(a, b):
    """Same street, or one is a whole-word prefix of the other; a quadrant on both must agree."""
    if not isinstance(a, str) or not isinstance(b, str) or not a or not b:
        return False
    qa, qb = a.split()[-1] if a.split()[-1] in QUAD else None, b.split()[-1] if b.split()[-1] in QUAD else None
    if qa and qb and qa != qb:
        return False
    a2, b2 = (a.rsplit(" ", 1)[0] if qa else a), (b.rsplit(" ", 1)[0] if qb else b)
    return a2 == b2 or a2.startswith(b2 + " ") or b2.startswith(a2 + " ")


def street_nums(a):
    """'1501-1505 14th St NW' -> {'1501', '1503', '1505'}; '1213 U St NW' -> {'1213'}."""
    if not isinstance(a, str):
        return set()
    a = road(a)
    m = re.match(r"^\s*(\d+)[A-Z]?(?:\s*-\s*(\d+)[A-Z]?)?\s", a.upper() + " ")
    if not m:
        return set()
    lo = int(m.group(1)); hi = int(m.group(2)) if m.group(2) else lo
    if hi < lo:   # "1500-02"
        hi = int(str(lo)[: len(str(lo)) - len(m.group(2))] + m.group(2)) if m.group(2) else lo
    return {str(x) for x in range(lo, hi + 1, 2 if (hi - lo) % 2 == 0 else 1)} if 0 <= hi - lo <= 12 else {str(lo)}


def _names(*vals):
    out = []
    for v in vals:
        if not isinstance(v, str):
            continue
        v = re.sub(r"\s*\((?:MOBILE|MOBILE UNIT|COMMISSARY|CATERING|SPECIAL EVENT|SPEC EVENT|TEMP(?:ORARY)? EVENT|INSIDE [^)]*)\)\s*$", "", v, flags=re.I)
        for part in re.split(r"\s*/\s*|\s+\bdba\b\s+|\s+&\s+(?=[A-Z][a-z])|\s*\bt/a\b\s*", v, flags=re.I):
            k = norm_name(re.sub(r"\b(?:LLC|INC|CORP|CORPORATION|LTD|CO)\b\.?", "", part, flags=re.I))
            if k and k not in out:
                out.append(k)
    return out


_META = os.path.join(OFF, "meta.json")
META = json.load(open(_META)) if os.path.exists(_META) else {}
# the day the license table was read (fetch_official.py writes it); the feed's own DATAREFRESHEDON is in LIC_REFRESHED after load()
LIST_DATE = (META.get("licenses") or {}).get("fetched")
LIC_REFRESHED = None
ABC_ROSTER = "2026-10"   # the roster file read (abca_roster_<month>.xlsx); its page says "Alcohol License Holders October 2026"
DLCP_ITEM = "https://opendata.dc.gov/datasets/85bf98d3915f412c8a4de706f2d13513"
ABC_PAGE = "https://abca.dc.gov/page/current-alcohol-license-holders"
ABC_ITEM = "https://opendata.dc.gov/datasets/cabe9dcef0b344518c7fae1a3def7de1"
CANCEL_ITEM = "https://opendata.dc.gov/datasets/8ff680ae6b58474083f9f860531c9ad0"
INSPECTIONS_PORTAL = "https://dc.healthinspections.us/?a=Inspections"


def _zip(z):
    z = re.sub(r"\D", "", str(int(z)) if isinstance(z, float) and z == z else str(z or ""))
    return z[:5] if len(z) >= 5 else ""


def _addr(a):
    """'1213 U ST NW, 102, WASHINGTON, DC, 20009, USA' -> ('1213 U St NW', '20009'); the unit and town are dropped."""
    parts = [p.strip() for p in (a or "").split(",")]
    street = re.sub(r"\s+", " ", parts[0] if parts else "").strip()
    z = next((p for p in parts if re.fullmatch(r"\d{5}(?:-\d{4})?", p)), "")
    return (nice(street, addr=True) if street else None), _zip(z)


DLCP_KIND = {"Restaurant": "food", "Delicatessen": "food", "Bakery": "food", "Caterers": "caterer", "Mobile Delicatessen": "truck",
             "Street Vending Business": "truck", "Grocery Store": "retail", "Food Products": "retail", "Marine Food Product (Retail)": "retail",
             "Marine Food Product (Wholesale)": "retail", "Ice Cream Manufacturer": "retail", "Candy Manufacturer": "retail",
             "Cigarette Sales (Retail)": "retail", "Patent Medicine": "retail"}
# ABCA establishment types that sell for drinking on the premises (Class C or D; abca.dc.gov/page/alcohol-license-types-and-classes)
ONPREM = {"Restaurant", "Tavern", "Nightclub", "Hotel", "Multipurpose", "Club", "Marine Vessel", "Arena", "Bed and Breakfast", "Railroad"}
ABC_LIVE = {"Active", "Issued", "About to Expire", "License Issued"}
ENDORSE = [("Sidewalk Cafe", "Sidewalk café"), ("Summer Garden", "Summer garden"), ("Entertainment", "Entertainment"), ("Dancing", "Dancing"),
           ("Cover Charge", "Cover charge"), ("Brewpub", "Brewpub"), ("Wine Pub", "Wine pub"), ("Distillery Pub", "Distillery pub"),
           ("Sports Wagering", "Sports wagering"), ("Streatery", "Streatery"), ("Carry-Out and Delivery", "Carry-out and delivery")]
_SP = None


def _stateplane(x, y):
    global _SP
    if _SP is None:
        from pyproj import Transformer
        _SP = Transformer.from_crs(26985, 4326, always_xy=True)
    if x is None or y is None or x != x or y != y:
        return np.nan, np.nan
    lo, la = _SP.transform(float(x), float(y))
    return la, lo


def _date(ms):
    return datetime.datetime.fromtimestamp(ms / 1000, datetime.UTC).date().isoformat() if isinstance(ms, (int, float)) and ms == ms else None


# placeholder trade names ("N/A" on 212 license rows, "NONE", "SAME", a bare number): no name of its own
PLACEHOLDER = re.compile(r"(?i)\s*(?:n/?a|none|tbd|same|same as above|null|unknown|-+|\.+|\d+)\s*")


def _row(jur, lic, shown, name, holder, addr, z, la, lo, kind, active, ltype, **kw):
    num, st = street_key(addr)
    name = None if isinstance(name, str) and PLACEHOLDER.fullmatch(name) else name
    # a license with no trade name can still confirm a listing at its address by its holder's name; it never names a place (dba stays None)
    return {"jur": jur, "lic": lic, "shown": shown, "name": name, "dba": name, "holder": holder, "keys": _names(name) or _names(holder), "addr": addr,
            "city": None, "zip": z, "num": num, "street": st, "lat": la, "lon": lo, "kind": kind, "active": active, "ltype": ltype, **kw}


def load_dlcp():
    global LIC_REFRESHED
    rows = []
    for r in json.load(open(os.path.join(OFF, "licenses.json"))):
        act = r.get("BUSINESSACTIVITY") or ""
        kind = DLCP_KIND.get(act, "other")
        trade = (r.get("ENTITYTRADENAME") or "").strip() or None
        addr, z = _addr(r.get("PREMISEADDRESS"))
        la, lo = _stateplane(r.get("X_COORDINATE"), r.get("Y_COORDINATE"))
        mar = int(r["MAR_ID"]) if isinstance(r.get("MAR_ID"), (int, float)) and r["MAR_ID"] == r["MAR_ID"] else None
        rows.append(_row("dlcp", f"dlcp-{r['OBJECTID']}", r.get("CUSTOMERNUMBER"), trade, (r.get("ENTITYNAME") or "").strip() or None,
                         addr, z, la, lo, kind, r.get("LICENSESTATUS") == "Active", act,
                         status=r.get("LICENSESTATUS"), first=_date(r.get("INITIALISSUEDATE")), exp=_date(r.get("LICENSEENDDATE")),
                         status_date=_date(r.get("LICENSESTATUSDATE")), mar=mar, ssl=r.get("SSL"), ward=r.get("WARD"),
                         cluster=r.get("NEIGHBORHOODCLUSTER"), endorse=None, primary=r.get("PRIMARYACTIVITYFLAG") == "Yes",
                         in_dc=r.get("PREMISEINDC") != "No"))
        if r.get("DATAREFRESHEDON"):
            LIC_REFRESHED = max(LIC_REFRESHED or "", _date(r["DATAREFRESHEDON"]))
    return pd.DataFrame(rows)


def mar_points():
    """MAR address points: (number, street key) -> [(MAR_ID, lat, lon, zip)]."""
    out = {}
    p = os.path.join(OFF, "mar.json")
    if not os.path.exists(p):
        return out
    for r in json.load(open(p)):
        n, st = street_key(r.get("ADDRESS"))
        if n and st and r.get("LATITUDE"):
            out.setdefault((n, st), []).append((r.get("MAR_ID"), float(r["LATITUDE"]), float(r["LONGITUDE"]), _zip(r.get("ZIPCODE"))))
    return out


def load_abc(mar=None):
    """The ABCA roster (the current list), placed from ABCA's layer by license number, else from the MAR by address."""
    import openpyxl
    layer = {a["LICENSE"]: a for a in json.load(open(os.path.join(OFF, "abc.json")))}
    wb = openpyxl.load_workbook(os.path.join(OFF, f"abca_roster_{ABC_ROSTER}.xlsx"), read_only=True)
    rows_ = list(wb.worksheets[0].iter_rows(values_only=True))
    head = rows_[0]
    mar = mar if mar is not None else mar_points()
    rows, placed = [], {"layer": 0, "mar": 0, "none": 0}
    for v in rows_[1:]:
        r = dict(zip(head, v))
        if not r.get("License Number") or (r.get("State") or "DC").strip().upper() not in ("DC", "D.C.", "WASHINGTON DC"):
            continue
        et, cls = (r.get("Establishment Type") or "").strip(), (r.get("Class Type") or "").strip()
        kind = "onprem" if et in ONPREM else "caterer" if et == "Caterer" else "retail" if cls in ("A", "B") else "other"
        addr, _ = _addr(r.get("Address"))
        z = _zip(r.get("Zip Code"))
        lay = layer.get(r["License Number"])
        la = lo = np.nan; mid = None
        if lay and lay.get("LATITUDE"):
            la, lo = float(lay["LATITUDE"]), float(lay["LONGITUDE"]); mid = int(float(lay["MAR_ID"])) if lay.get("MAR_ID") else None
            placed["layer"] += 1
        else:
            hit = mar.get(street_key(addr)) if addr else None
            if hit:
                same = [h for h in hit if h[3] == z] or hit
                mid, la, lo, _z = same[0]; mid = int(mid) if mid else None
                placed["mar"] += 1
            else:
                placed["none"] += 1
        endorse = [label for col, label in ENDORSE if str(r.get(col) or "").strip().upper() in ("CHECKED", "Y", "YES", "TRUE", "X", "1")]
        exp = r.get("License Expiration Date")
        if isinstance(exp, datetime.datetime):
            exp = exp.date().isoformat()
        elif isinstance(exp, str) and re.match(r"\d{1,2}/\d{1,2}/\d{4}", exp.strip()):
            mm, dd, yy = exp.strip().split("/"); exp = f"{yy}-{int(mm):02d}-{int(dd):02d}"
        status = (r.get("Status") or "").strip()
        rows.append(_row("abc", f"abc-{r['License Number']}", r["License Number"], (r.get("Trade Name") or "").strip() or None,
                         (r.get("Entity Name") or "").strip() or None, addr, z, la, lo, kind, status in ABC_LIVE,
                         f"{et} (Class {cls})" if et and cls and cls != et else et or None,
                         status=status, first=None, exp=exp, status_date=None, mar=mid, ssl=None,
                         ward=(lay or {}).get("WARD"), cluster=None, endorse=endorse or None, primary=True, in_dc=True,
                         abc_type=et, abc_class=cls, capacity=r.get("Total Capacity")))
    print("ABCA roster rows placed:", placed)
    return pd.DataFrame(rows)


def load_cancellations():
    rows = []
    for r in json.load(open(os.path.join(OFF, "cancellations.json"))):
        addr, z = _addr(r.get("ADDRESS"))
        num, st = street_key(addr)
        rows.append({"lic": r.get("LICENSE"), "name": (r.get("TRADE_NAME") or "").strip() or None, "keys": _names(r.get("TRADE_NAME")),
                     "addr": addr, "num": num, "street": st, "mar": int(float(r["MAR_ID"])) if r.get("MAR_ID") else None,
                     "date": _date(r.get("CANCELLATION_DATE")), "reason": r.get("REASON"), "type": r.get("TYPE"), "class": r.get("CLASS"),
                     "lat": float(r["LATITUDE"]) if r.get("LATITUDE") else np.nan, "lon": float(r["LONGITUDE"]) if r.get("LONGITUDE") else np.nan})
    return pd.DataFrame(rows)


def load():
    mar = mar_points()
    df = pd.concat([load_dlcp(), load_abc(mar)], ignore_index=True)
    # a license row without a point of its own: the MAR's point for its address
    miss = df.lat.isna() & df.addr.notna()
    fill = 0
    for i in df.index[miss]:
        hit = mar.get((df.at[i, "num"], df.at[i, "street"]))
        if hit:
            same = [h for h in hit if h[3] == df.at[i, "zip"]] or hit
            df.at[i, "lat"], df.at[i, "lon"] = same[0][1], same[0][2]
            if df.at[i, "mar"] is None or df.at[i, "mar"] != df.at[i, "mar"]:
                df.at[i, "mar"] = same[0][0]
            fill += 1
    print("license rows placed from the MAR by address:", fill, "of", int(miss.sum()))
    # one business can hold several records (a DLCP restaurant license and an ABCA license, two activities on one license): the same
    # MAR address (or street address) and a name in common
    df["biz"] = np.arange(len(df))
    df["addrkey"] = [f"m{int(m)}" if m is not None and m == m else (f"{n}|{s}" if n and s else None) for m, n, s in zip(df.mar, df.num, df.street)]
    for key, g in df[df.addrkey.notna()].groupby("addrkey"):
        idx = list(g.index)
        if len(idx) < 2 or len(idx) > 400:
            continue
        for x in range(len(idx)):
            for y in range(x + 1, len(idx)):
                a, b = idx[x], idx[y]
                ka = df.at[a, "keys"] + _names(df.at[a, "holder"]); kb = df.at[b, "keys"] + _names(df.at[b, "holder"])
                if not ka or not kb:
                    continue
                if any(name_sim(p, q) >= 85 or ((_stems(p) - GENERIC) & (_stems(q) - GENERIC)) for p in ka for q in kb):
                    old, new = df.at[b, "biz"], df.at[a, "biz"]
                    df.loc[df.biz == old, "biz"] = new
    df["county"] = "District of Columbia"
    return df


if __name__ == "__main__":
    d = load()
    print(d.groupby(["jur", "kind", "active"]).size())
    print("refreshed", LIC_REFRESHED)
