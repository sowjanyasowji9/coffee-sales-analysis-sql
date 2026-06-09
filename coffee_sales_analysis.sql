CREATE DATABASE monday_coffee;

USE monday_coffee;

CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);

CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	price DECIMAL(10,2)
);


CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total DECIMAL(10,2),
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);

-- load data
LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/city.csv'
INTO TABLE city
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

SELECT * FROM city;
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM sales;

-- Reports & Data Analysis

-- Q.1 Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
	city_name,
	ROUND(
	(population * 0.25)/1000000, -- Calculates 25% of the city population (Meaning 25 people drink coffee out of every 100) and Converts the number into millions
	2) as coffee_consumers_in_millions, -- Rounds to 2 decimal places for neat output.
	city_rank
FROM city
ORDER BY coffee_consumers_in_millions DESC;

-- -- Q.2
-- Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	YEAR(sale_date) = 2023 -- Filters rows where sale happened in 2023
	AND
	QUARTER(sale_date) = 4 -- Filters rows where sale happened in 2023
-- This much money was earned from coffee in Q4 2023 across all cities.
    
SELECT 
	ci.city_name,
	SUM(s.total) as total_revenue
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id -- Links each sale to the customer who bought.
JOIN city as ci
ON ci.city_id = c.city_id -- Links each customer to their city,Now every sale is connected to a city
WHERE 
	 YEAR(s.sale_date) = 2023 -- Take the year from sale_date and check if it equals 2023.
	AND
	QUARTER(s.sale_date) = 4 -- Take the year from sale_date and check if it equals 2023.
GROUP BY 1
ORDER BY 2 DESC;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

SELECT 
	p.product_name,
	COUNT(s.sale_id) as total_orders
FROM products as p
LEFT JOIN
sales as s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

-- city abd total sale
-- no cx in each these city

SELECT 
    ci.city_name,
    SUM(s.total) AS total_revenue,
    COUNT(DISTINCT s.customer_id) AS total_cx,
    ROUND(
        SUM(s.total) / COUNT(DISTINCT s.customer_id),
        2
    ) AS avg_sale_pr_cx
FROM sales AS s
JOIN customers AS c
    ON s.customer_id = c.customer_id
JOIN city AS ci
    ON ci.city_id = c.city_id
GROUP BY ci.city_name
ORDER BY total_revenue DESC;

--  Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

WITH city_table as 
(
	SELECT 
		city_name,
		ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table
AS
(
	SELECT 
		ci.city_name,
		COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
)
SELECT 
	customers_table.city_name,
	city_table.coffee_consumers as coffee_consumer_in_millions,
	customers_table.unique_cx
FROM city_table
JOIN 
customers_table
ON city_table.city_name = customers_table.city_name;

-- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

SELECT * 
FROM (
    SELECT 
        ci.city_name,
        p.product_name,
        COUNT(s.sale_id) AS total_orders,
        DENSE_RANK() OVER (
            PARTITION BY ci.city_name 
            ORDER BY COUNT(s.sale_id) DESC
        ) AS rnk
    FROM sales AS s
    JOIN products AS p
        ON s.product_id = p.product_id
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, p.product_name
) AS t1
WHERE rnk <= 3
ORDER BY city_name, total_orders DESC;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

SELECT 
	ci.city_name,
	COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE 
	s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

-- Conclusions

WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(SUM(s.total) / COUNT(DISTINCT s.customer_id), 2) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent
    FROM city
)
SELECT 
    cr.city_name,
    cr.estimated_rent,
    ct.total_cx,
    ct.avg_sale_pr_cx,
    ROUND(cr.estimated_rent / ct.total_cx, 2) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name
ORDER BY ct.avg_sale_pr_cx DESC;


-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH monthly_sales AS (
    SELECT 
        ci.city_name,
        MONTH(sale_date) AS month,
        YEAR(sale_date) AS year,
        SUM(s.total) AS total_sale
    FROM sales AS s
    JOIN customers AS c
        ON c.customer_id = s.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name, YEAR(sale_date), MONTH(sale_date)
),
growth_ratio AS (
    SELECT
        city_name,
        month,
        year,
        total_sale AS cr_month_sale,
        LAG(total_sale, 1) OVER (PARTITION BY city_name ORDER BY year, month) AS last_month_sale
    FROM monthly_sales
)
SELECT
    city_name,
    month,
    year,
    cr_month_sale,
    last_month_sale,
    ROUND(
        (cr_month_sale - last_month_sale) / last_month_sale * 100,
        2
    ) AS growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL
ORDER BY city_name, year, month;


-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer


WITH city_table AS (
    SELECT 
        ci.city_name,
        SUM(s.total) AS total_revenue,
        COUNT(DISTINCT s.customer_id) AS total_cx,
        ROUND(
            SUM(s.total) / COUNT(DISTINCT s.customer_id),
            2
        ) AS avg_sale_pr_cx
    FROM sales AS s
    JOIN customers AS c
        ON s.customer_id = c.customer_id
    JOIN city AS ci
        ON ci.city_id = c.city_id
    GROUP BY ci.city_name
),
city_rent AS (
    SELECT 
        city_name, 
        estimated_rent,
        ROUND((population * 0.25) / 1000000, 3) AS estimated_coffee_consumer_in_millions
    FROM city
)
SELECT 
    cr.city_name,
    ct.total_revenue,
    cr.estimated_rent AS total_rent,
    ct.total_cx,
    cr.estimated_coffee_consumer_in_millions,
    ct.avg_sale_pr_cx,
    ROUND(
        cr.estimated_rent / ct.total_cx,
        2
    ) AS avg_rent_per_cx
FROM city_rent AS cr
JOIN city_table AS ct
    ON cr.city_name = ct.city_name
ORDER BY ct.total_revenue DESC;
