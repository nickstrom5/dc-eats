"""Download the Overture Maps extracts that the DC build reads -> data/dc/

- overture_dc_bbox.parquet     every place in the District's bounding box plus a margin (name, category, address, point)
- overture_dc_sources.parquet  which datasets each eating/drinking listing came from (Meta, Foursquare, ...)
- dc_overture_region.geojson   Overture's land division area for the District (a cross-check of the official boundary)

Reads the public Overture bucket over S3 with DuckDB (no account needed). Adapted from nc-eats/pipeline/fetch_overture.py.
The District's own boundary, wards and neighborhood clusters come from Open Data DC (fetch_official.py), not from here.
"""
import os, json, time
import duckdb
from shapely import wkb
from shapely.geometry import mapping

RELEASE = "2026-10-21.0"
OUT = os.path.join(os.path.dirname(__file__), "..", "data", "dc")
# The District (38.79°N–38.996°N, 77.12°W–76.91°W) plus a margin, so Arlington, Silver Spring and Takoma Park rows exist to be clipped
BBOX = "bbox.xmin BETWEEN -77.16 AND -76.88 AND bbox.ymin BETWEEN 38.77 AND 39.02"
EAT = "('restaurant','casual_eatery','bar','fast_food_restaurant','coffee_shop','cafe','smoothie_juice_bar','brewery','food_court')"
os.makedirs(OUT, exist_ok=True)

con = duckdb.connect()
con.execute("INSTALL httpfs; LOAD httpfs; INSTALL spatial; LOAD spatial; SET s3_region='us-west-2';")
places = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=places/type=place/*.parquet"

t = time.time()
if not os.path.exists(f"{OUT}/overture_dc_bbox.parquet"):
    con.execute(f"""
COPY (
  SELECT id, names.primary AS name, basic_category AS cat, taxonomy.primary AS tax, taxonomy.hierarchy AS hier, confidence,
         operating_status AS status, brand.names.primary AS brand, addresses[1].freeform AS street, addresses[1].locality AS city,
         addresses[1].postcode AS zip, addresses[1].region AS region, ST_Y(geometry) AS lat, ST_X(geometry) AS lon, websites[1] AS web,
         phones[1] AS phone
  FROM read_parquet('{places}', hive_partitioning=1) WHERE {BBOX}
) TO '{OUT}/overture_dc_bbox.parquet' (FORMAT PARQUET)""")
    print("places in bbox", round(time.time() - t), "s", flush=True)
if not os.path.exists(f"{OUT}/overture_dc_sources.parquet"):
    con.execute(f"""
COPY (
  SELECT id, list_transform(sources, lambda x: x.dataset) AS ds, list_transform(sources, lambda x: x.update_time) AS ut,
         list_transform(sources, lambda x: x.record_id) AS rid,
         len(socials) AS n_soc, len(websites) AS n_web, len(phones) AS n_ph
  FROM read_parquet('{places}', hive_partitioning=1)
  WHERE {BBOX} AND basic_category IN {EAT}
) TO '{OUT}/overture_dc_sources.parquet' (FORMAT PARQUET)""")
    print("sources", round(time.time() - t), "s", flush=True)

areas = f"s3://overturemaps-us-west-2/release/{RELEASE}/theme=divisions/type=division_area/*.parquet"
rows = con.execute(f"""
  SELECT subtype, class, names.primary AS name, ST_AsWKB(geometry) AS g
  FROM read_parquet('{areas}', hive_partitioning=1)
  WHERE country = 'US' AND region = 'US-DC' AND subtype IN ('region', 'county', 'locality')
    AND bbox.xmin > -77.3 AND bbox.xmax < -76.8 AND bbox.ymin > 38.7 AND bbox.ymax < 39.1""").fetchall()
out = {}
for sub, cls, name, g in rows:
    out[f"{sub}:{cls}:{name}"] = mapping(wkb.loads(bytes(g)).buffer(0).simplify(0.0001, preserve_topology=True))
json.dump(out, open(f"{OUT}/dc_overture_region.geojson", "w"))
print("division areas:", sorted(out), round(time.time() - t), "s total")
