# GLOBAL SITUATION

# Create a view "forestation" to calculate forestation percentages for each country and year
DROP VIEW IF EXISTS forestation;
CREATE VIEW forestation AS
SELECT land_area.total_area_sq_mi * 2.59 AS total_area_sq_km, forest_area.country_code, forest_area.country_name, forest_area.year, forest_area.forest_area_sqkm, regions.region, regions.income_group, SUM(forest_area.forest_area_sqkm) / SUM(land_area.total_area_sq_mi * 2.59) * 100 AS forest_pct
FROM forest_area
INNER JOIN land_area ON forest_area.country_code = land_area.country_code AND forest_area.year = land_area.year
INNER JOIN regions ON regions.country_code = land_area.country_code
GROUP BY land_area.total_area_sq_mi, forest_area.country_code, forest_area.country_name, forest_area.year, forest_area.forest_area_sqkm, regions.region, regions.income_group;

# Select forest area for the year 1990 and 2016 for 'World'
WITH year_1990 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 1990),
year_2016 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 2016)
SELECT forest_area_sqkm
FROM year_1990
WHERE country_name = 'World'
UNION ALL
SELECT forest_area_sqkm
FROM year_2016
WHERE country_name = 'World';

# Select the country with the most significant change in forest area from 1990 to 2016
SELECT DISTINCT b.total_area_sq_km, b.country_name, ABS(b.total_area_sq_km - 1324449) AS dif
FROM (SELECT * FROM forestation WHERE year = 1990) AS year_1990
INNER JOIN (SELECT * FROM forestation WHERE year = 2016) AS b
ON year_1990.country_name = b.country_name
ORDER BY dif
LIMIT 1;

# REGIONAL OUTLOOK

# Create a view "forest_regions" to calculate forestation percentages for each region in the years 1990 and 2016
DROP VIEW IF EXISTS forest_regions;
CREATE VIEW forest_regions AS
(
SELECT land_area.year, regions.region, SUM(forest_area.forest_area_sqkm) / SUM(land_area.total_area_sq_mi * 2.59) * 100 AS forest_pct
FROM forest_area
INNER JOIN land_area ON forest_area.country_code = land_area.country_code AND forest_area.year = land_area.year
INNER JOIN regions ON regions.country_code = land_area.country_code
WHERE land_area.year = 1990 OR land_area.year = 2016
GROUP BY region, land_area.year
);

# Select forestation percentage for each region in the year 2016
SELECT forest_pct, region
FROM forest_regions
WHERE year = 2016
ORDER BY forest_pct;

# Select forestation percentage for each region in the year 1990
SELECT forest_pct, region
FROM forest_regions
WHERE year = 1990
ORDER BY forest_pct;

# Select regions with an increase in forestation percentage from 1990 to 2016
WITH year_1990 AS (SELECT forest_pct, region FROM forest_regions WHERE year = 1990),
year_2016 AS (SELECT forest_pct, region FROM forest_regions WHERE year = 2016)
SELECT (year_1990.forest_pct - year_2016.forest_pct) AS dif, year_1990.region
FROM year_1990
INNER JOIN year_2016 ON year_1990.region = year_2016.region
WHERE (year_1990.forest_pct - year_2016.forest_pct) > 0
ORDER BY dif DESC;

# COUNTRY-LEVEL DETAIL

# Select forest area for the year 1990 and 2016 for each country
WITH year_1990 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 1990),
year_2016 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 2016)
SELECT year_1990.country_name, year_1990.forest_area_sqkm AS forest_area1990, year_2016.forest_area_sqkm AS forest_area2016, (year_1990.forest_area_sqkm - year_2016.forest_area_sqkm) AS dif
FROM year_1990
INNER JOIN year_2016 ON year_1990.country_name = year_2016.country_name
WHERE (year_1990.forest_area_sqkm - year_2016.forest_area_sqkm) IS NOT NULL AND year_1990.country_name <> 'World'
ORDER BY dif DESC
LIMIT 5;

# Select countries with the highest percentage decrease in forest area from 1990 to 2016
WITH year_1990 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 1990),
year_2016 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 2016)
SELECT year_1990.country_name, (year_2016.forest_area_sqkm - year_1990.forest_area_sqkm) / year_1990.forest_area_sqkm * 100 AS dif
FROM year_1990
INNER JOIN year_2016 ON year_1990.country_name = year_2016.country_name
WHERE year_2016.forest_area_sqkm IS NOT NULL AND year_1990.forest_area_sqkm IS NOT NULL
ORDER BY dif
LIMIT 5;

# Select countries with the highest absolute decrease in forest area from 1990 to 2016
WITH year_1990 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 1990),
year_2016 AS (SELECT forest_area_sqkm, year, country_name FROM forestation WHERE year = 2016)
SELECT year_1990.country_name, year_1990.forest_area_sqkm AS forest_area1990, year_2016.forest_area_sqkm AS forest_area2016, (year_1990.forest_area_sqkm - year_2016.forest_area_sqkm) AS dif
FROM year_1990
INNER JOIN year_2016 ON year_1990.country_name = year_2016.country_name
WHERE (year_1990.forest_area_sqkm - year_2016.forest_area_sqkm) IS NOT NULL AND year_1990.country_name <> 'World'
ORDER BY dif DESC
LIMIT 5;

# Select countries grouped by forestation percentiles
WITH percentiles AS
(
SELECT country_name,
CASE
