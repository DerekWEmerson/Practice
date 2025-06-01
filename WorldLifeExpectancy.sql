# World Life Expectancy Project
# P0. Prepping

# 1. To Do's
-- Set up Database & Tables x2
-- Remove Duplicates
-- Add ID Column
-- Correct Data Types

# 2. Create Database & Tables
CREATE DATABASE world_life_expectancy;
-- To insert the initial .csv data set I used the 'Table Data Import Wizard.'

SELECT *
FROM wle_data;

CREATE TABLE wle_data_backup LIKE wle_data;
INSERT INTO wle_data_backup SELECT * FROM wle_data;
-- This creates our backup table in case we make any mistakes or lose any data.

SELECT *
FROM wle_data_backup;


-- ----------------------------------------------------------------------------------------------
# P1. Data Cleaning

SELECT *
FROM wle_data;

# Search for Duplicates.
SELECT Country, `Year`, CONCAT(Country, `Year`), COUNT(CONCAT(Country, `Year`)) occurances
FROM wle_data
GROUP BY Country, `Year`
HAVING occurances > 1;

# Set up in useable format for our DELETE statement.
SELECT *
FROM (
	SELECT Row_ID, 
	CONCAT(Country, `Year`),
	ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, `Year`) ORDER BY CONCAT(Country, Year)) Row_Num
	FROM wle_data) duplicate_query
WHERE Row_Num > 1;

# Create DELETE statement.
DELETE FROM wle_data
WHERE Row_ID IN (
	SELECT Row_ID
	FROM (
		SELECT Row_ID, 
		CONCAT(Country, `Year`),
		ROW_NUMBER() OVER(PARTITION BY CONCAT(Country, `Year`) ORDER BY CONCAT(Country, Year)) Row_Num
		FROM wle_data) duplicate_query
	WHERE Row_Num > 1);
-- Now go back up and search for duplicates again.

-- ----------------------------------------------------------------------------------------------
# P2. Blanks & NULLS

SELECT *
FROM wle_data;
-- Looks like we have blanks in several columns. Let's see if we can fill any of them in through inference.

# Find all Blanks and NULLs in Status column
SELECT *
FROM wle_data
WHERE status = '' OR NULL;

# These are our different Statuses.
SELECT DISTINCT status
FROM wle_data
WHERE status != '';

# Before updating any statuses, let's make sure all countries have only 1 status and do not change.
SELECT country
FROM wle_data
WHERE status != ''
GROUP BY country
HAVING count(DISTINCT status) > 1;

# Now to safely update the missing values.
-- Find status value associated with other entries for that country
-- Replace '' status.

UPDATE wle_data wd
JOIN (
	SELECT DISTINCT country, status
	FROM wle_data
	WHERE status != '') sq
ON wd.country = sq.country
SET wd.status = sq.status
WHERE wd.status = '';

# Check to verify everything was updated properly.
SELECT *
FROM wle_data
WHERE status = '' OR NULL;

SELECT *
FROM wle_data;

# Find all Blanks and NULLs in Life Expectancy column
SELECT *
FROM wle_data
WHERE `life expectancy` = '' OR NULL;
-- Looks like the values for life expectancy go up gradually, so we'll take the average of the two adjacent years and populate the blanks with this.

# Populating Blanks
-- Find the blanks
-- Select the next and previous years
-- Take the avg of these two years
-- UPDATE the blank with this value

SELECT country, `year`,
LAG(`life expectancy`) OVER (PARTITION BY country ORDER BY `year`) AS prev_le,
LEAD(`life expectancy`) OVER (PARTITION BY country ORDER BY `year`) AS next_le
FROM wle_data;

UPDATE wle_data wd
JOIN (
    SELECT country, `year`,
	LAG(`life expectancy`) OVER (PARTITION BY country ORDER BY `year`) AS prev_le,
	LEAD(`life expectancy`) OVER (PARTITION BY country ORDER BY `year`) AS next_le
    FROM wle_data) sq
ON wd.country = sq.country AND wd.`year` = sq.`year`
SET wd.`life expectancy` = ROUND(((sq.prev_le + sq.next_le) / 2), 1)
WHERE wd.`life expectancy` = '' OR NULL;

SELECT *
FROM wle_data;

# Forgot to ROUND() the decimals off. Resetting the column to correct for error.
UPDATE wle_data wd
JOIN wle_data_backup wdb
	ON wd.row_id = wdb.row_id
SET wd.`life expectancy` = wdb.`life expectancy`;


-- ----------------------------------------------------------------------------------------------
# P3. Exploratory Data Analysis

SELECT *
FROM wle_data;

# 1. Life Expectancy Trends
SELECT country, MIN(`life expectancy`), MAX(`life expectancy`)
FROM wle_data
GROUP BY country
ORDER BY country;
-- Some countries have 0s for both MINs and MAXs.

# Filter out 0s.
SELECT country, MIN(`life expectancy`), MAX(`life expectancy`)
FROM wle_data
GROUP BY country
HAVING MIN(`life expectancy`) != 0 AND MAX(`life expectancy`) != 0
ORDER BY country;

# Look for greatest growth.
SELECT country, 
MIN(`life expectancy`) 'Lowest Life Expectancy', 
MAX(`life expectancy`) 'Highest Life Expectancy',
ROUND(MAX(`life expectancy`) - MIN(`life expectancy`), 1) '15 Year Growth'
FROM wle_data
GROUP BY country
HAVING MIN(`life expectancy`) != 0 AND MAX(`life expectancy`) != 0
ORDER BY `15 year growth` DESC;

# Global Average Life Expectancy Trends
SELECT `year`, ROUND(AVG(`life expectancy`), 2) 'Average Global Life Expectancy'
FROM wle_data
WHERE `life expectancy` != 0
GROUP BY `year`
ORDER BY `year` DESC;

# Desparity
SELECT `year`, 
ROUND(AVG(`life expectancy`), 1) 'Average Global Life Expectancy', 
MIN(`life expectancy`) 'Lowest Life Expectancy', 
MAX(`life expectancy`) 'Highest Life Expectancy',
ROUND(MAX(`life expectancy`) - MIN(`life expectancy`), 1) 'Desparity'
FROM wle_data
WHERE `life expectancy` != 0
GROUP BY `year`
ORDER BY `year` DESC;

# 2. Correlations
# A. GDP to Life Expectancy
SELECT country, `year`, `life expectancy`, GDP
FROM wle_data;

SELECT country, ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_GDP
FROM wle_data
WHERE `life expectancy` != 0 AND GDP != 0
GROUP BY country;
-- Many countries with Zeros

# Search for Zeros
SELECT country, ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_GDP
FROM wle_data
GROUP BY country
ORDER BY AVG_Life_Expectancy, AVG_GDP;

SELECT country, ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_GDP
FROM wle_data
GROUP BY country
ORDER BY AVG_GDP, AVG_Life_Expectancy;

# Filter out 0s
SELECT country, ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_GDP
FROM wle_data
WHERE `life expectancy` != 0 AND GDP != 0
GROUP BY country
ORDER BY AVG_GDP;

# Assigning Categories
SELECT country, ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_GDP
FROM wle_data
WHERE `life expectancy` != 0 AND GDP != 0
GROUP BY country
ORDER BY AVG_GDP;

-- ----------------------------------------------------------------------------------------------
# Come back and redo this
# Assign categories to each year based on the total average GDP and life expectancy for that year
# Then do it for each country (not based on year)
# Then find average life expectancy for all countries within each category
# Then repeat for life expectancy (with categories)
-- Would be interesting to see the percent of "low" GDP countries with higher life expectancies than "high" GDP countries. Or even just which countries have a higher life expectancy than any country with a higher GDP.
# 15:30

SELECT country,
ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy,
CASE WHEN ROUND(AVG(`life expectancy`), 1) < AVG_Global_Life_Expectancy THEN 1 ELSE 0 END Life_Expectancy_Rating,
ROUND(AVG(GDP), 1) AVG_GDP,
CASE WHEN ROUND(AVG(GDP), 1) < AVG_Global_GDP THEN 1 ELSE 0 END GDP_Rating
FROM wle_data t1
JOIN (
	SELECT ROUND(AVG(`life expectancy`), 1) AVG_Global_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_Global_GDP
    FROM wle_data) t2
ON t1.country = t2.country
;

SELECT t1.country,
ROUND(AVG(t1.`life expectancy`), 1) AVG_Life_Expectancy,
CASE WHEN ROUND(AVG(t1.`life expectancy`), 1) < t2.AVG_Global_Life_Expectancy THEN 1 ELSE 0 END Life_Expectancy_Rating,
ROUND(AVG(t1.GDP), 1) AVG_GDP,
CASE WHEN ROUND(AVG(t1.GDP), 1) < t2.AVG_Global_GDP THEN 1 ELSE 0 END AS GDP_Rating
FROM wle_data t1
CROSS JOIN (
SELECT 
	ROUND(AVG(`life expectancy`), 1) AVG_Global_Life_Expectancy, 
	ROUND(AVG(GDP), 1) AVG_Global_GDP
FROM wle_data) t2
GROUP BY t1.country;

	SELECT ROUND(AVG(`life expectancy`), 1) AVG_Life_Expectancy, ROUND(AVG(GDP), 1) AVG_GDP
    FROM wle_data;

# 20:30
-- ----------------------------------------------------------------------------------------------
# Eyeball Average (Mean) GDP
SELECT *, ROW_NUMBER() OVER()
FROM wle_data
WHERE GDP != 0
ORDER BY GDP;
-- Total Rows = 2490, divide by 2, find value at row 1245. MEAN GDP = 1765

# Mathematical Average, but not our mean.
SELECT AVG(GDP)
FROM wle_data
WHERE GDP != 0;

# Count of countries with High & Low GDP. 
SELECT
SUM(CASE WHEN GDP <= 1765 THEN 1 ELSE 0 END) Low_GDP_Count,
SUM(CASE WHEN GDP >= 1765 THEN 1 ELSE 0 END) High_GDP_Count
FROM wle_data
WHERE GDP != 0
;

# Average life expectancy of countries with High GDP. 
SELECT
SUM(CASE WHEN GDP <= 1765 THEN 1 ELSE 0 END) Low_GDP_Count,
ROUND(AVG(CASE WHEN GDP <= 1765 THEN `Life expectancy` ELSE NULL END), 1) Low_GDP_Life_Expectancy,
SUM(CASE WHEN GDP >= 1765 THEN 1 ELSE 0 END) High_GDP_Count,
ROUND(AVG(CASE WHEN GDP >= 1765 THEN `Life expectancy` ELSE NULL END), 1) High_GDP_Life_Expectancy
FROM wle_data
WHERE GDP != 0
;
-- We can see that countries with lower GDPs tend to have lower life expectancies than countries with higher GDPs.
-- Would be interesting to see the percent of "low" GDP countries with higher life expectancies than "high" GDP countries. Or even just which countries have a higher life expectancy than any country with a higher GDP.

# B. Developing vs Developed Countries' Life Expectancy
Select *
FROM wle_data;

# Country Count & Average Life Expectancy per Status
Select status, COUNT(DISTINCT Country), ROUND(AVG(`life expectancy`), 1) Average_Life_Expectancy
FROM wle_data
WHERE `Life expectancy` != 0
GROUP BY status;

# C. BMI
SELECT *
FROM wle_data;

# Search for 0s
SELECT *
FROM wle_data
WHERE BMI = 0;
-- After doing some research, this data seemed to be showing not the average BMI, but rather, the % of obesity in each country.
-- However, these numbers do not line up either. This data seems completely falsified and irrelevant. None of it is accurate on any standards I have seen.
-- As such, I will not be making any observations based on this data.

# D. Deaths to Life Expectancy
SELECT *
FROM wle_data;

# Are infant deaths included in under-five deaths?
SELECT *
FROM wle_data
WHERE `infant deaths` > `under-five deaths`;
-- Although not conclusive, as it's possible for more 2-5 year olds to die than infants, it would seem that infant deaths may be included in the under-five deaths category.

# Search for 0s
SELECT *
FROM wle_data
WHERE `Adult Mortality` = 0
OR `infant deaths` = 0
OR `under-five deaths` = 0;
-- Upon further research, the data on infant deaths also looks to be incorrect. Uncertain where this data is being collected from.
-- Will not be using this data.

# Rolling Total of Adult Mortality
SELECT 
	country,
	`year`,
	`life expectancy`,
	`adult mortality`,
	SUM(`adult mortality`) OVER(PARTITION BY country ORDER BY `year`) Rolling_Total
FROM wle_data
;
-- Interesting to note, but unsure if accurate and many data inconsistencies are present.
-- As this is the end of the tutorial project AND I no longer trust the validity of this data set, this is where we shall leave it.

-- ----------------------------------------------------------------------------------------------
# P4. Things I would do if I were to continue on with this data set
# a. Validate Data Accuracy
# b. Clean up errors and inconsistencies (such as names with special characters, missing data, etc.)