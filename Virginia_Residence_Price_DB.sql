CREATE SCHEMA IF NOT EXISTS Virginia_Residence_Price_DB;
USE Virginia_Residence_Price_DB;

#This SQL Script contains verious sections:
#1. Preprocessing (Lines: 9 - 22)
#2. Database implementation & Data Insertion from imported files (Lines: 24 - 221)

####Section 1: Preprocessing

#data sources (this data is imported through import wizard):
#1. https://www.nar.realtor/research-and-statistics/housing-statistics/county-median-home-prices-and-monthly-mortgage-payment
#2. https://www.huduser.gov/portal/datasets/fmr/fmrs/FY2026_code/2026state_summary.odn

#1.1 Enter unsafe mode for data cleaning later in the script
SET SQL_SAFE_UPDATES = 0;

#1.1 Fill in missing data. Specifically, the virginia_house_data table is missing data on 1 county and 1 city
INSERT INTO virginia_house_data(locality_name, Median_Home_Price_Q1_2025, Monthly_Payment_Q1_2025, Monthly_Payment_Q1_2024)
VALUES("Danville city", 154768,0,0); #source for information: https://www.zillow.com/home-values/31172/danville-va/
INSERT INTO virginia_house_data(locality_name, Median_Home_Price_Q1_2025, Monthly_Payment_Q1_2025, Monthly_Payment_Q1_2024)
VALUES("Pittsylvania County", 222500,0,0); #source for information: https://www.redfin.com/county/3005/VA/Pittsylvania-County/housing-market

####Section 2: Database implementation and Data Insertion

#2.1 Construct the Virginia(locality_id (INT), locality_name (VARCHAR)) table. The attribute locality_id will be the primary key.

#Locality names should be ordered by county first and then city to create consistent locality ids
CREATE TABLE IF NOT EXISTS Virginia AS 
SELECT locality_name FROM virginia_apartment_data  #input all the locality names (from any import file)
WHERE locality_name LIKE "%county%" #get county names first
UNION #combine county rows and city rows together
SELECT locality_name FROM virginia_apartment_data 
WHERE locality_name LIKE "%city%" AND locality_name NOT LIKE "%county"; #get city names second

#add the column locality_id and make it a primary key (each locality_name will be uniquely identified by a locality_id)
ALTER TABLE Virginia 
ADD COLUMN locality_id INT AUTO_INCREMENT PRIMARY KEY;

# move this column to the front of the table (for easier joining in the queries section)
ALTER TABLE Virginia
MODIFY COLUMN locality_id INT FIRST;

#2.2 Construct the county(county_id (INT), county_name (VARCHAR)) table. The attribute county_id will be the primary key.
CREATE TABLE IF NOT EXISTS county AS
SELECT locality_id, locality_name AS county_name FROM Virginia
WHERE locality_name LIKE "%county%"; #get county names from the Virignia table

#make the locality_id column a foreign key in county (due to one to many relationship)
ALTER TABLE county
ADD CONSTRAINT county_id_foreign_key FOREIGN KEY (locality_id) REFERENCES Virginia (locality_id);

#make the county_id column a primary key in county
ALTER TABLE county 
ADD COLUMN county_id INT AUTO_INCREMENT PRIMARY KEY;

#move the county_id column to the front
ALTER TABLE county
MODIFY COLUMN county_id INT FIRST;

#2.3 Construct the city(city_id (INT), city_name (VARCHAR) table

#Pull out only the city data from the Virginia table
CREATE TABLE IF NOT EXISTS city AS
SELECT locality_id, locality_name AS city_name FROM Virginia
WHERE locality_name LIKE "%city%" AND locality_name NOT LIKE "%county%"; #get city names from the Virignia table

#make the locality_id column a foreign key in county (due to one to many relationship)
ALTER TABLE city
ADD CONSTRAINT city_id_foreign_key FOREIGN KEY (locality_id) REFERENCES Virginia (locality_id);

#make the county_id column a primary key in county
ALTER TABLE city 
ADD COLUMN city_id INT AUTO_INCREMENT PRIMARY KEY;

#move the city_id column to the front
ALTER TABLE city
MODIFY COLUMN city_id INT FIRST;

#2.4 Construct the house_data_by_county(county_id, median_house_price) table. The attribute county_id will be the primary key.
CREATE TABLE IF NOT EXISTS house_by_county_data
SELECT county_id, median_house_price FROM county #only select county_id and median_house_price from (county_id, county_name, median_house_price)
NATURAL LEFT JOIN( #this will join on locality_name (or county_name), but wont be selected in the resulting table
	SELECT locality_name AS county_name, 
		   Median_Home_Price_Q1_2025 AS median_house_price
    FROM virginia_house_data
) AS ANYNAME;

#make the county_id be a primary key that also references the county_id in the county table (this is a 1..1 relationship)
ALTER TABLE house_by_county_data
ADD CONSTRAINT PRIMARY KEY (county_id);
ALTER TABLE house_by_county_data
ADD CONSTRAINT county__by_house_data_foreign_key FOREIGN KEY (county_id) REFERENCES county(county_id);

#Clean the median_house_price row so that it can be converted to doubles (convert prices to numbers)
UPDATE house_by_county_data
SET median_house_price = REPLACE(median_house_price, "$", "");
UPDATE house_by_county_data
SET median_house_price = REPLACE(median_house_price, ",", "");

#convert house_median_price to double
ALTER TABLE house_by_county_data
MODIFY COLUMN median_house_price DOUBLE;

#2.5 Construct the house_data_by_city(city_id, median_house_price) table. The attribute city_id will be the primary key.
CREATE TABLE IF NOT EXISTS house_by_city_data AS
SELECT city_id, median_house_price FROM city
NATURAL LEFT JOIN(
	SELECT locality_name AS city_name, 
		   Median_Home_Price_Q1_2025 AS median_house_price
    FROM virginia_house_data
) AS ANYNAME;

#make the city_id be a primary key that also references the city_id in the city table (this is a 1..1 relationship)
ALTER TABLE house_by_city_data
ADD CONSTRAINT PRIMARY KEY (city_id);
ALTER TABLE house_by_city_data
ADD CONSTRAINT city__by_house_data_foreign_key FOREIGN KEY (city_id) REFERENCES city(city_id);

#Clean the median_house_price row so that it can be converted to doubles (convert prices to numbers)
UPDATE house_by_city_data
SET median_house_price = REPLACE(median_house_price, "$", "");
UPDATE house_by_city_data
SET median_house_price = REPLACE(median_house_price, ",", "");

#convert house_median_price to double
ALTER TABLE house_by_city_data
MODIFY COLUMN median_house_price DOUBLE;

#2.6 Construct the apartment_data_by_county(county_id,One_Bedroom_Price, Two_Bedroom_Price, Three_Bedroom_Price, Four_Bedroom_Price) table. The attribute county_id will be the primary key.
CREATE TABLE IF NOT EXISTS apartment_by_county_data AS
SELECT county_id, One_Bedroom_Price, Two_Bedroom_Price, Three_Bedroom_Price, Four_Bedroom_Price FROM county
NATURAL LEFT JOIN(
	SELECT locality_name AS county_name,
		   One_Bedroom AS One_Bedroom_Price,
		   Two_Bedroom AS Two_Bedroom_Price,
           Three_Bedroom AS Three_Bedroom_Price,
           Four_Bedroom AS Four_Bedroom_Price
	FROM virginia_apartment_data
    WHERE locality_name LIKE "%county%"
) AS ANYNAME;

#make the county_id be a primary key that also references the county_id in the county table (this is a 1..1 relationship)
ALTER TABLE apartment_by_county_data
ADD CONSTRAINT PRIMARY KEY (county_id);
ALTER TABLE apartment_by_county_data
ADD CONSTRAINT county__by_apartment_data_foreign_key FOREIGN KEY (county_id) REFERENCES county(county_id);

#Clean the apartment_data_by_county columns so that it can be converted to doubles (convert prices to numbers), by first removing any "$" or ","
UPDATE apartment_by_county_data
SET One_Bedroom_Price = REPLACE(One_Bedroom_Price, '$', '');
UPDATE apartment_by_county_data
SET Two_Bedroom_Price = REPLACE(Two_Bedroom_Price, '$', '');
UPDATE apartment_by_county_data
SET Three_Bedroom_Price = REPLACE(Three_Bedroom_Price, '$', '');
UPDATE apartment_by_county_data
SET Four_Bedroom_Price = REPLACE(Four_Bedroom_Price, '$', '');
UPDATE apartment_by_county_data
SET One_Bedroom_Price = REPLACE(One_Bedroom_Price, ',', '');
UPDATE apartment_by_county_data
SET Two_Bedroom_Price = REPLACE(Two_Bedroom_Price, ',', '');
UPDATE apartment_by_county_data
SET Three_Bedroom_Price = REPLACE(Three_Bedroom_Price, ',', '');
UPDATE apartment_by_county_data
SET Four_Bedroom_Price = REPLACE(Four_Bedroom_Price, ',', '');

#convert One_Bedroom_Price, Two_Bedroom_Price, Three_Bedroom_Price, Four_Bedroom_Price to double
ALTER TABLE apartment_by_county_data
MODIFY COLUMN One_Bedroom_Price DOUBLE;
ALTER TABLE apartment_by_county_data
MODIFY COLUMN Two_Bedroom_Price DOUBLE;
ALTER TABLE apartment_by_county_data
MODIFY COLUMN Three_Bedroom_Price DOUBLE;
ALTER TABLE apartment_by_county_data
MODIFY COLUMN Four_Bedroom_Price DOUBLE;

#2.7 Construct the apartment_data_by_city(city_id, One_Bedroom_Price, Two_Bedroom_Price, Three_Bedroom_Price, Four_Bedroom_Price) table. The attribute cit_id will be the primary key.
CREATE TABLE IF NOT EXISTS apartment_by_city_data AS
SELECT city_id, One_Bedroom_Price, Two_Bedroom_Price, Three_Bedroom_Price, Four_Bedroom_Price FROM city
NATURAL LEFT JOIN(
	SELECT locality_name AS city_name,
		   One_Bedroom AS One_Bedroom_Price,
		   Two_Bedroom AS Two_Bedroom_Price,
           Three_Bedroom AS Three_Bedroom_Price,
           Four_Bedroom AS Four_Bedroom_Price
	FROM virginia_apartment_data
    WHERE locality_name LIKE "%city%" AND locality_name NOT LIKE "%county%"
) AS ANYNAME;

#make the city_id be a primary key that also references the city_id in the city table (this is a 1..1 relationship)
ALTER TABLE apartment_by_city_data
ADD CONSTRAINT PRIMARY KEY (city_id);
ALTER TABLE apartment_by_city_data
ADD CONSTRAINT city_by_apartment_data_foreign_key FOREIGN KEY (city_id) REFERENCES city(city_id);

#Clean the apartment_data_by_city columns so that it can be converted to doubles (convert prices to numbers), by first removing any "$" or ","
UPDATE apartment_by_city_data
SET One_Bedroom_Price = REPLACE(One_Bedroom_Price, '$', '');
UPDATE apartment_by_city_data
SET Two_Bedroom_Price = REPLACE(Two_Bedroom_Price, '$', '');
UPDATE apartment_by_city_data
SET Three_Bedroom_Price = REPLACE(Three_Bedroom_Price, '$', '');
UPDATE apartment_by_city_data
SET Four_Bedroom_Price = REPLACE(Four_Bedroom_Price, '$', '');
UPDATE apartment_by_city_data
SET One_Bedroom_Price = REPLACE(One_Bedroom_Price, ',', '');
UPDATE apartment_by_city_data
SET Two_Bedroom_Price = REPLACE(Two_Bedroom_Price, ',', '');
UPDATE apartment_by_city_data
SET Three_Bedroom_Price = REPLACE(Three_Bedroom_Price, ',', '');
UPDATE apartment_by_city_data
SET Four_Bedroom_Price = REPLACE(Four_Bedroom_Price, ',', '');

#convert One_Bedroom_Price, Two_Bedroom_Price, Three_Bedroom_Price, Four_Bedroom_Price to double
ALTER TABLE apartment_by_city_data
MODIFY COLUMN One_Bedroom_Price DOUBLE;
ALTER TABLE apartment_by_city_data
MODIFY COLUMN Two_Bedroom_Price DOUBLE;
ALTER TABLE apartment_by_city_data
MODIFY COLUMN Three_Bedroom_Price DOUBLE;
ALTER TABLE apartment_by_city_data
MODIFY COLUMN Four_Bedroom_Price DOUBLE;