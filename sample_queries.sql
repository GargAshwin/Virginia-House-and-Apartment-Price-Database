CREATE SCHEMA IF NOT EXISTS Virginia_Residence_Price_DB;
USE Virginia_Residence_Price_DB;

#1. Show each county name with its associated median home price
SELECT 
	county_name, 
    median_house_price 
FROM (
	county
	NATURAL JOIN(
		SELECT * FROM house_by_county_data
	) AS ANYNAME
);

#2. Show each city name with its associated median home price
SELECT 
	city_name, 
    median_house_price 
FROM (
	city
	NATURAL JOIN(
		SELECT * FROM house_by_city_data
	) AS ANYNAME
);

#3. Show all the cities and their different median apartment type prices
SELECT 
	city_id, 
	city_name, 
    One_Bedroom_Price, 
    Two_Bedroom_Price, 
    Three_Bedroom_Price, 
    Four_Bedroom_Price 
FROM (
	city
	NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_city_data
    ) AS ANYNAME
);

#4. Show all the counties and their different median apartment type prices
SELECT 
	county_id, 
	county_name, 
    One_Bedroom_Price, 
    Two_Bedroom_Price, 
    Three_Bedroom_Price, 
    Four_Bedroom_Price 
FROM (
	county
	NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_county_data
    ) AS ANYNAME
);

#5. Find the median house price of Fairfax County
SELECT 
	county_name, 
    median_house_price 
FROM (
	county
	NATURAL JOIN(
		SELECT * FROM house_by_county_data
	) AS ANYNAME
) WHERE county_name = "Fairfax County";

#6. Find the median apartment prices of Richmond city
SELECT 
	city_id, 
	city_name, 
    One_Bedroom_Price, 
    Two_Bedroom_Price, 
    Three_Bedroom_Price, 
    Four_Bedroom_Price 
FROM (
	city
	NATURAL JOIN(
		SELECT * FROM apartment_by_city_data
	) AS ANYNAME
) WHERE city_name = "Richmond city";

#7. Find the county and city with the highest house median price
(SELECT 
	county_name, 
	median_house_price AS highest_price
FROM (
	county
	NATURAL JOIN(
		SELECT * FROM house_by_county_data
	) AS ANYNAME
) ORDER BY median_house_price DESC
LIMIT 1) UNION (SELECT 
	city_name, 
    median_house_price AS highest_price
FROM (
	city
	NATURAL JOIN(
		SELECT * FROM house_by_city_data
	) AS ANYNAME
) ORDER BY median_house_price DESC
LIMIT 1);


#8. Find the county and city with the lowest house median price
(SELECT 
	county_name, 
    median_house_price 
FROM (
	county
	NATURAL JOIN(
		SELECT * FROM house_by_county_data
	) AS ANYNAME
) ORDER BY median_house_price ASC
LIMIT 1)
UNION (SELECT 
	city_name, 
    median_house_price
FROM (
	city
	NATURAL JOIN(
		SELECT * FROM house_by_city_data
	) AS ANYNAME
) ORDER BY median_house_price ASC
LIMIT 1);

#9. Select the counties and cities with the highest one bedroom apartment median price
(SELECT 
	county_name, 
	One_Bedroom_Price AS highest_one_bedroom_price
FROM (
	county
    NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_county_data
    ) AS ANYNAME
)
WHERE One_Bedroom_Price >= ALL(
	SELECT MAX(One_Bedroom_Price) FROM apartment_by_county_data
)) UNION (SELECT 
	city_name, 
	One_Bedroom_Price AS highest_one_bedroom_price
FROM (
	city
    NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_city_data
    ) AS ANYNAME
)
WHERE One_Bedroom_Price >= ALL(
	SELECT MAX(One_Bedroom_Price) FROM apartment_by_city_data
));

#10. Select all the counties and cities with the lowest median four bedroom apartment price 
(SELECT 
	county_name, 
    Four_Bedroom_Price AS lowest_median_four_bedroom_price 
FROM (
	county
    NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_county_data
    ) AS ANYNAME
)
WHERE Four_Bedroom_Price <= ALL(
	SELECT MIN(Four_Bedroom_Price) FROM apartment_by_county_data
)) UNION (SELECT 
	city_name, 
    Four_Bedroom_Price AS lowest_median_four_bedroom_price 
FROM (
	city
    NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_city_data
    ) AS ANYNAME
)
WHERE Four_Bedroom_Price <= ALL(
	SELECT MIN(Four_Bedroom_Price) FROM apartment_by_city_data
));

#11. Find the total average housing price in Virginia by county
SELECT 
	AVG(median_house_price) AS total_average_median_house_price_by_county
FROM house_by_county_data;

#12. Find the total average housing price in Virginia by city
SELECT 
	AVG(median_house_price) AS total_average_median_house_price_by_city
FROM house_by_city_data;

#13. Select all the cities where the median home price is less than $200,000
SELECT 
	city_name, 
    median_house_price 
FROM (
	city
	NATURAL JOIN(
		SELECT * FROM house_by_city_data
	) AS ANYNAME
)
WHERE median_house_price <= 200000;

#14. Show all the median single bedroom prices that are above the total average one bedroom apartment price across counties
SELECT 
	county_name, 
    One_Bedroom_Price 
FROM (
	county
    NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_county_data
    ) AS ANYNAME
)
WHERE One_Bedroom_Price >= ALL(
	SELECT AVG(One_Bedroom_Price) AS total_average_one_apartment_price
	FROM apartment_by_county_data
);

#15. Show all the median two bedroom prices that are below the total average two bedroom apartment price across cities
SELECT 
	city_name, 
    Two_Bedroom_Price 
FROM (
	city
    NATURAL LEFT JOIN(
		SELECT * FROM apartment_by_city_data
    ) AS ANYNAME
)
WHERE Two_Bedroom_Price >= ALL(
	SELECT AVG(Two_Bedroom_Price) AS total_average_two_apartment_price
	FROM apartment_by_city_data
);