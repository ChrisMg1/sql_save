SELECT postgis_full_version();

CREATE TABLE spatial_test (
  uid  INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  geom GEOMETRY(POINT, 4326)
);


update gps_asset_one set geom = st_setsrid(st_makepoint(lon, lat), 4326)

update gps_asset_two set geom = st_setsrid(st_makepoint(lon, lat), 4326)
