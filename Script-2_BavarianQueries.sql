--- here only querys for bavarian table
--- export: Prepare data in database cm_UAM2035fromSQLite, table odpair_2035_fromsqlite_44342281_raw
--- export to odpair_lvm2035_23716900_onlybav
---- filter: only bav taz's
---- filter: from != to
--- finally transfer to new database xyz



-- add geometry columns (points and line)
ALTER TABLE odpair_LVM2035_23712030_onlyBAV
	ADD COLUMN IF NOT EXISTS geom_point_fromOD geometry(Point),
	ADD COLUMN IF NOT EXISTS geom_point_toOD geometry(Point),
	ADD COLUMN IF NOT EXISTS ODconnect geometry(Linestring);
	
	
-- ADD COLUMN IF NOT EXISTS allpoints geometry(Point); -- planned as merge/union to have all start/end-points only once. 

--- fill geometry columns
-- Bayern is UTM32 is 32632 im LVM-export (old and 'official' EPSG:25832)
UPDATE odpair_LVM2035_23712030_onlyBAV SET
	geom_point_fromOD = st_setsrid(st_makepoint(fromzone_xcoord, fromzone_ycoord), 32632),
	geom_point_toOD = st_setsrid(st_makepoint(tozone_xcoord, tozone_ycoord), 32632);


UPDATE odpair_LVM2035_23712030_onlyBAV
	set	ODconnect = st_makeline(geom_point_fromOD, geom_point_toOD);

--- Create geometry indexes
	
CREATE INDEX fromOD_geom_idx
  ON odpair_LVM2035_23712030_onlyBAV
  USING GIST (geom_point_fromOD);
 
CREATE INDEX toOD_geom_idx
  ON odpair_LVM2035_23712030_onlyBAV
  USING GIST (geom_point_toOD);
 
CREATE INDEX conn_geom_idx
  ON odpair_LVM2035_23712030_onlyBAV
  USING GIST (ODconnect);
 
 
 
 select * from odpair_LVM2035_23712030_onlyBAV order by od_concat asc;
 
-- Merge back-and-forth
--- 0) Create Column
ALTER TABLE odpair_LVM2035_23712030_onlyBAV ADD COLUMN IF NOT EXISTS od_concat text;
--- 1) Concatenate
UPDATE odpair_LVM2035_23712030_onlyBAV set
	od_concat = CONCAT(LEAST(fromzone_no, tozone_no), '-', GREATEST(fromzone_no, tozone_no));

---1.1) Index
CREATE EXTENSION btree_gist;

CREATE INDEX od_merge_idx
  ON odpair_LVM2035_23712030_onlyBAV
  USING GIST (od_concat);

--- 2) Merge into new table --TODO, NOT YET RUN!!! (if table does not exist yet, obviously)
SELECT od_concat, count(*)
	FROM odpair_LVM2035_23712030_onlyBAV
	group by od_concat;
 
SELECT max(fromzone_name), min(tozone_name), max(directdist), min(imp_ttime), min(imp_distance), min(imp_demand), max(odconnect) INTO TABLE odpair_LVM2035_23712030_onlyBAV_merged
	FROM odpair_LVM2035_23712030_onlyBAV
	group by od_concat;

-----???-----


--- add possible UAM travel time TODO: Not somewhere in "raw" to be able to play with params in only study area
ALTER TABLE LVM_OD_onlyBAV ADD COLUMN IF NOT EXISTS ttime_uam_h float8;
ALTER TABLE LVM_OD_onlyBAV ADD COLUMN IF NOT EXISTS ttime_uam_min float8;

--- params: v_uam = 250km/h
UPDATE LVM_OD_onlyBAV set ttime_uam_min = (directdist / 250) * 60 ;






