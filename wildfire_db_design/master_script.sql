-- Drop any tables that already exist
drop table if exists final_project.date_table CASCADE;
drop table if exists final_project.cfs_table CASCADE;
drop table if exists final_project.eco_table CASCADE;
drop table if exists final_project.fire_table CASCADE;


-- Add Primary Key and alter data types to ignitions
ALTER TABLE final_project.ignitions ADD COLUMN f_id SERIAL PRIMARY KEY;
ALTER COLUMN "REP_DATE" TYPE date using ("REP_DATE"::text::date),
ALTER COLUMN "ATTK_DATE" TYPE date using ("ATTK_DATE"::text::date),
ALTER COLUMN "OUT_DATE" TYPE date using ("OUT_DATE"::text::date),
ALTER COLUMN "ACQ_DATE" TYPE date using ("ACQ_DATE"::text::date);


-- Create New Tables

CREATE TABLE IF NOT EXISTS final_project.fire_table(
	f_id serial PRIMARY KEY, 
	fire_id text,
	src_agency text, 
	firename text,
	latitude NUMERIC,
	longitude NUMERIC,
	size_ha NUMERIC,
	cause text,
	protzone text,
	fire_type text,
	more_info text,
	src_agy2 text,
	geometry geometry
);

CREATE TABLE IF NOT EXISTS final_project.date_table( 
	f_id serial REFERENCES final_project.fire_table(f_id) UNIQUE,
	f_year NUMERIC,
	f_month NUMERIC,
	f_day NUMERIC,
	rep_date date,
	attk_date date,
	out_date date,
	decade text,
	acq_date date,
	PRIMARY KEY (f_id)
);

CREATE TABLE IF NOT EXISTS final_project.cfs_table(
	f_id serial REFERENCES final_project.fire_table(f_id) UNIQUE, 
	cfs_ref_id text,
	cfs_note1 text,
	cfs_note2 text,
	PRIMARY KEY (f_id)
);


CREATE TABLE IF NOT EXISTS final_project.eco_table(
	f_id serial REFERENCES final_project.fire_table(f_id) UNIQUE, 
	ecozone NUMERIC,
	ecoz_ref text,
	ecoz_name text,
	ecoz_nom text,
	PRIMARY KEY (f_id)
);


-- Insert Data from Ignitions into fire_table
insert into final_project.fire_table(f_id, fire_id, src_agency, firename, latitude, longitude, size_ha, cause, protzone, 
		  fire_type, more_info, src_agy2, geometry)
SELECT f_id, "FIRE_ID", "SRC_AGENCY", "FIRENAME", "LATITUDE", "LONGITUDE", "SIZE_HA", "CAUSE", "PROTZONE", 
		"FIRE_TYPE", "MORE_INFO", "SRC_AGY2", geometry
FROM final_project.ignitions;

-- Insert Data from Ignitions into cfs_table
insert into final_project.cfs_table(f_id, cfs_ref_id, cfs_note1, cfs_note2)
SELECT f_id, "CFS_REF_ID", "CFS_NOTE1", "CFS_NOTE2"
FROM final_project.ignitions;

-- Insert Data from Ignitions into eco_table
insert into final_project.eco_table(f_id, ecozone, ecoz_ref, ecoz_name, ecoz_nom)
SELECT f_id, "ECOZONE", "ECOZ_REF", "ECOZ_NAME", "ECOZ_NOM"
FROM final_project.ignitions;

-- Insert Data from Ignitions into date_table
insert into final_project.date_table(f_id, f_year, f_month, f_day, rep_date, attk_date, out_date, acq_date, decade)
SELECT f_id, "YEAR", "MONTH", "DAY", "REP_DATE", "ATTK_DATE", "OUT_DATE", "ACQ_DATE", "DECADE"
FROM final_project.ignitions;


-- Create Queries

-- Get All Wildfires in Alberta

SELECT *
FROM final_project.fire_table
WHERE longitude BETWEEN -120 AND -110
AND latitude BETWEEN 49 AND 60;

-- Get The Largest Fire By Decade

SELECT d.decade, ROUND(MAX(f.size_ha), 0)
FROM final_project.fire_table f, final_project.date_table d
WHERE f.f_id = d.f_id
GROUP BY d.decade;

-- Get the Count of Fires by Zone
SELECT e.ecoz_name, COUNT(*) as fires
FROM final_project.fire_table f, final_project.eco_table e
WHERE f.f_id = e.f_id
GROUP BY e.ecoz_name
ORDER BY fires DESC;




