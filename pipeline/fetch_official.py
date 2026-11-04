"""Official District of Columbia records -> data/raw/official/ (git-ignored). Every host was robots-checked first (check_sources.py).

All from Open Data DC (CC BY 4.0), through the District's documented ArcGIS REST services (maps2.dcgis.dc.gov answers robots.txt with
404, so nothing is disallowed; the tax extract lives on ArcGIS Online, services.arcgis.com, as co/ct/sc read theirs):
- DLCP "Basic Business Licenses" (item 85bf98d3915f412c8a4de706f2d13513): every food, street-vending and entertainment license row,
  history included. Owner, agent and billing fields are never requested; ENTITYNAME (the legal entity) is kept only to recognise a map
  listing named for its holder, and is never shown. The feed's LATITUDE/LONGITUDE are rounded to whole degrees (39, -77; checked
  2026-10-27), so official.py places each row from X_COORDINATE/Y_COORDINATE (Maryland State Plane, NAD83 meters, EPSG:26985).
- ABCA "Alcohol License Business Locations" (cabe9dcef0b344518c7fae1a3def7de1) and "Alcohol License Cancellations"
  (8ff680ae6b58474083f9f860531c9ad0). APPLICANT (the legal entity) is kept only for the same matching rule.
- "Neighborhood Clusters" (f6c703ebe2534fc3800609a07bad8f5b), "Neighborhood Labels" (c4b0cd43d50949e98e57de9f22b455fc), "Wards from 2022" (c5cd8b40fb784548a6680aead5f919ed) and "Washington DC
  Administrative Boundary" (7241f6d500b44288ad983f0942b39663), as WGS84 polygons, and the Historic Preservation Office's "Historic
  Districts" (a443bfb6d078439e9e1941773879c7f6): the only official lines drawn around named neighborhoods (areas.py).
- "Address Points" (aa514416aaf74fdc94748f1e56e7cc8a), the Master Address Repository (MAR) as open data: the geocoder for ABCA roster
  rows and researched addresses (the MAR web service at citizenatlas.dc.gov is retired; the MAR 2 API needs a key).
- OCFO "Integrated Tax System Public Extract" (7d5e6cabd2304e779c719a4d5515af77), resolved by item id (it is republished under dated
  names like ITSPE_08172026). Only lot, use and value fields: OWNERNAME, OWNNAME2, CAREOFNAME and mailing addresses are never requested.

    ../.venv/bin/python fetch_official.py [licenses abc cancellations areas tax]
"""
import json, os, sys, time
import requests

OUT = os.path.join(os.path.dirname(__file__), "..", "data", "raw", "official")
UA = {"User-Agent": "DCEatsBuild/1.0 (+nick@eatsranked.com)"}
DCGIS = "https://maps2.dcgis.dc.gov/dcgis/rest/services"
LAYERS = {
    "licenses": (f"{DCGIS}/FEEDS/DCRA/FeatureServer/0", "85bf98d3915f412c8a4de706f2d13513",
                 "CATEGORYSERVICETYPE IN ('Food Services','Street Vendor License','Entertainment Services')",
                 "OBJECTID,CUSTOMERNUMBER,LICENSESTATUS,LICENSETYPE,LICENSESTATUSDATE,LICENSESTARTDATE,LICENSEENDDATE,INITIALISSUEDATE,"
                 "BUSINESSACTIVITY,PREMISEADDRESS,PREMISEINDC,ENTITYNAME,ENTITYTRADENAME,ENTITYTYPE,PRIMARYACTIVITYFLAG,"
                 "CATEGORYSERVICETYPE,DATAREFRESHEDON,WARD,ANC,NEIGHBORHOODCLUSTER,BUSINESSIMPROVEMENTDISTRICT,MAINSTREET,MAR_ID,SSL,"
                 "LATITUDE,LONGITUDE,X_COORDINATE,Y_COORDINATE", False),
    "abc": (f"{DCGIS}/DCGIS_DATA/Business_Licensing_and_Grants_WebMercator/FeatureServer/5", "cabe9dcef0b344518c7fae1a3def7de1",
            "1=1", "OBJECTID,LICENSE,APPLICANT,TRADE_NAME,CLASS,ADDRESS,ZIPCODE,WARD,ANC,STATUS,TYPE,BREW_PUB,ENTERTAINMENT,"
            "SALES_CONSUMPTION,SIDEWALK_CAFE,SUMMER_GARDEN,TASTING,WINE_PUB,COVERCHARGE,DANCING,DISTILLERY_PUB,TOTAL_CAPACITY,"
            "GAMES_OF_SKILL,SPORTS_WAGGERING,CARRYOUT_DELIVERY,STREATERY,EXPIRATION_DATE,LONGITUDE,LATITUDE,MAR_ID,CREATED,EDITED", False),
    "cancellations": (f"{DCGIS}/DCGIS_DATA/Business_Licensing_and_Grants_WebMercator/FeatureServer/42",
                      "8ff680ae6b58474083f9f860531c9ad0", "1=1",
                      "OBJECTID,LICENSE,APPLICANT,TRADE_NAME,ADDRESS,ZIPCODE,MAR_WARD,CLASS,TYPE,CANCELLATION_DATE,REASON,LATITUDE,"
                      "LONGITUDE,MAR_ID,CREATED,EDITED", False),
    "clusters": (f"{DCGIS}/DCGIS_DATA/Administrative_Other_Boundaries_WebMercator/MapServer/17", "f6c703ebe2534fc3800609a07bad8f5b",
                 "1=1", "OBJECTID,NBH_NAMES,NAME,TYPE,GIS_ID", True),
    "wards": (f"{DCGIS}/DCGIS_DATA/Administrative_Other_Boundaries_WebMercator/MapServer/53", "c5cd8b40fb784548a6680aead5f919ed",
              "1=1", "OBJECTID,WARD,NAME,LABEL", True),
    "boundary": (f"{DCGIS}/DCGIS_DATA/Administrative_Other_Boundaries_WebMercator/MapServer/10", "7241f6d500b44288ad983f0942b39663",
                 "1=1", "OBJECTID,CITY_NAME,AREAKM", True),
    # the Master Address Repository's address points: the official geocoder (address -> MAR_ID -> point) for rows without a point
    "mar": (f"{DCGIS}/DCGIS_DATA/Location_WebMercator/FeatureServer/0", "aa514416aaf74fdc94748f1e56e7cc8a", "1=1",
            "OBJECTID,ADDRESS,ADDRESS_NUMBER,ADDRESS_NUMBER_SUFFIX,STREET_NAME,STREET_TYPE,QUADRANT,ZIPCODE,STATUS,SSL,WARD,MAR_ID,"
            "LATITUDE,LONGITUDE", False),
    "labels": (f"{DCGIS}/DCGIS_DATA/Administrative_Other_Boundaries_WebMercator/MapServer/35", "c4b0cd43d50949e98e57de9f22b455fc",
               "1=1", "*", True),
    "historic": (f"{DCGIS}/DCGIS_DATA/Historic_WebMercator/MapServer/6", "a443bfb6d078439e9e1941773879c7f6",
                 "1=1", "OBJECTID,NAME,LABEL,STATUS,DESIGNATION,DESIGNATION_DATE,GIS_ID", True),
}
TAX_ITEM = "7d5e6cabd2304e779c719a4d5515af77"
TAX_FIELDS = "OBJECTID,SSL,PROPTYPE,USECODE,LANDAREA,PREMISEADD,NBHDNAME,NEWLAND,NEWIMPR,NEWTOTAL,MIXEDUSE,EXTRACTDAT,PRMS_WARD"
os.makedirs(OUT, exist_ok=True)


def get(url, params):
    for attempt in range(4):
        try:
            r = requests.get(url, params=params, headers=UA, timeout=120)
            r.raise_for_status()
            d = r.json()
            if "error" in d:
                raise RuntimeError(d["error"])
            return d
        except (requests.RequestException, RuntimeError, ValueError) as e:
            if attempt == 3:
                raise
            print("  retry", type(e).__name__, e, flush=True)
            time.sleep(10 * (attempt + 1))
        finally:
            time.sleep(0.5)


def item_meta(item):
    m = get(f"https://www.arcgis.com/sharing/rest/content/items/{item}", {"f": "json"})
    return {k: m.get(k) for k in ("id", "title", "url", "modified", "licenseInfo", "accessInformation")}


def layer(url, where, fields, geom, page=None):
    info = get(url, {"f": "json"})
    page = page or min(int(info.get("maxRecordCount") or 1000), 2000)
    n = get(f"{url}/query", {"where": where, "returnCountOnly": "true", "f": "json"})["count"]
    rows, off = [], 0
    while off < n:
        d = get(f"{url}/query", {"where": where, "outFields": fields, "returnGeometry": "true" if geom else "false", "outSR": 4326,
                                 "orderByFields": "OBJECTID", "resultOffset": off, "resultRecordCount": page, "f": "geojson" if geom else "json"})
        feats = d["features"]
        if not feats:
            break
        rows.extend(feats if geom else [f["attributes"] for f in feats])
        off += len(feats)
        if off % 10000 < page:
            print(f"  {off}/{n}", flush=True)
    return n, rows, {"maxRecordCount": info.get("maxRecordCount"), "editingInfo": info.get("editingInfo"),
                     "fields": [f["name"] for f in info.get("fields") or []]}


def fetch(name):
    if name == "tax":
        meta = item_meta(TAX_ITEM)
        url = meta["url"].rstrip("/") + "/0"
        n, rows, info = layer(url, "1=1", TAX_FIELDS, False)
    else:
        url, item, where, fields, geom = LAYERS[name]
        meta = item_meta(item)
        n, rows, info = layer(url, where, fields, geom)
    meta.update(info, layer_url=url, count=n, rows=len(rows), fetched=time.strftime("%Y-%m-%d"))
    body = {"type": "FeatureCollection", "features": rows} if rows and "geometry" in rows[0] else rows
    json.dump(body, open(f"{OUT}/{name}.json", "w"))
    allmeta = json.load(open(f"{OUT}/meta.json")) if os.path.exists(f"{OUT}/meta.json") else {}
    allmeta[name] = meta
    json.dump(allmeta, open(f"{OUT}/meta.json", "w"), indent=1)
    print(name, n, "rows ->", len(rows), flush=True)


if __name__ == "__main__":
    for w in sys.argv[1:] or ["areas", "abc", "cancellations", "licenses", "tax"]:
        for name in (["clusters", "labels", "wards", "boundary", "historic"] if w == "areas" else [w]):
            fetch(name)
