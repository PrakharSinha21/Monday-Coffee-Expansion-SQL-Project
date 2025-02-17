-- Monday Coffee Project

--CREATE TABLE
DROP TABLE IF EXISTS city;
CREATE TABLE city
(
	city_id	INT PRIMARY KEY,
	city_name VARCHAR(15),	
	population	BIGINT,
	estimated_rent	FLOAT,
	city_rank INT
);


DROP TABLE IF EXISTS customers;
CREATE TABLE customers
(
	customer_id INT PRIMARY KEY,	
	customer_name VARCHAR(25),	
	city_id INT,
	CONSTRAINT fk_city FOREIGN KEY (city_id) REFERENCES city(city_id)
);


DROP TABLE IF EXISTS products;
CREATE TABLE products
(
	product_id	INT PRIMARY KEY,
	product_name VARCHAR(35),	
	Price float
);


DROP TABLE IF EXISTS sales;
CREATE TABLE sales
(
	sale_id	INT PRIMARY KEY,
	sale_date	date,
	product_id	INT,
	customer_id	INT,
	total FLOAT,
	rating INT,
	CONSTRAINT fk_products FOREIGN KEY (product_id) REFERENCES products(product_id),
	CONSTRAINT fk_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id) 
);


select * from city;
select * from customers;
select * from products;
select * from sales;


--Data Analysis
--Q1.How many people in each city are estimated to consume coffee,given that 25% of the population does?
select city_name, 
	  round((population*0.25)/1000000,2) as coffee_consumer_in_millions,
	   city_rank
from city
order by 2 desc; 


--Q2.What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?
select sum(total) as total_revenue 
from sales
where extract(year from sale_date) = 2023
		and
      extract(quarter from sale_date) = 4;

--Q3.Find revenue generated from coffee sales from each city in last quarter of 2023?
select ci.city_name,
       sum(s.total) as total_revenue
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
where extract(year from s.sale_date) = 2023
		and
      extract(quarter from s.sale_date) = 4
group by 1
order by 2 desc;

--Q4.How many units of each coffee product have been sold?
select product_name,count(s.sale_id)as total_orders
from products as p
left join sales as s
on s.product_id = p.product_id
group by 1
order by 2 desc;


--Q5.What is the average sales amount per customer in each city?
select ci.city_name,
	SUM(s.total) as total_revenue,
	COUNT(DISTINCT s.customer_id) as total_cx,
	ROUND(
			SUM(s.total)::numeric/
				COUNT(DISTINCT s.customer_id)::numeric
			,2) as avg_sale_pr_cx
from sales as s
join customers as c
on s.customer_id = c.customer_id
join city as ci
on ci.city_id = c.city_id
group by 1
order by 2 desc;


--Q6.Provide a list of cities along with their populations and estimated coffee consumers.
with city_table as
(
	select city_name,
		   ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table as
(
			select ci.city_name,
				   count(distinct c.customer_id) as unique_cs
			from sales as s
			join customers as c
			on c.customer_id = s.customer_id
			join city as ci
			on ci.city_id = c.city_id
			group by 1
)
						select customers_table.city_name,
							   city_table.coffee_consumers as coffee_consumers_in_millions,
							   customers_table.unique_cs
						from city_table
						join customers_table
						on city_table.city_name = customers_table.city_name;


--Q7.What are the top 3 selling products in each city based on sales volume?
select *
from (
    select ci.city_name,
		   p.product_name,
		   count(s.sale_id) as total_orders,
		   dense_rank() over(partition by ci.city_name order by count(s.sale_id)desc) as rank
	from sales as s
	join products as p
	on s.product_id = p.product_id
	join customers as c
	on c.customer_id = s.customer_id
	join city as ci
	on ci.city_id = c.city_id
	group by 1,2
) AS T1
where rank <= 3;


--Q8.How many unique customers are there in each city who have purchased coffee products?

select ci.city_name,
	   count(distinct c.customer_id) as unique_cs
from city as ci
left join customers as c
on ci.city_id = c.city_id
join sales as s
on s.customer_id = c.customer_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by 1;



--Q9.Find each city and their average sale per customer and avg rent per customer

with city_table
as
(
		select ci.city_name,
			SUM(s.total) as total_revenue,
			COUNT(DISTINCT s.customer_id) as total_cx,
			ROUND(
					SUM(s.total)::numeric/
						COUNT(DISTINCT s.customer_id)::numeric
					,2) as avg_sale_pr_cx
		from sales as s
		join customers as c
		on s.customer_id = c.customer_id
		join city as ci
		on ci.city_id = c.city_id
		group by 1
		order by 2 desc
),
city_rent
as
(
		 select city_name,
		 		estimated_rent
		 from city
)
select 
	cr.city_name,
	cr.estimated_rent,
	ct.total_cx,
	ct.avg_sale_pr_cx,
	round(estimated_rent::numeric/total_cx::numeric, 2) as avg_rent_per_cs
from city_rent as cr
join city_table as ct
on cr.city_name = ct.city_name
order by 4 desc;




--Q10.Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer
WITH city_table
AS
(
	SELECT 
		ci.city_name,
		SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
				SUM(s.total)::numeric/
					COUNT(DISTINCT s.customer_id)::numeric
				,2) as avg_sale_pr_cx
		
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(
	SELECT 
		city_name, 
		estimated_rent,
		ROUND((population * 0.25)/1000000, 2) as estimated_coffee_consumer_in_millions
	FROM city
)
SELECT 
	cr.city_name,
	total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_cx,
	estimated_coffee_consumer_in_millions,
	ct.avg_sale_pr_cx,
	ROUND(
		cr.estimated_rent::numeric/
									ct.total_cx::numeric
		, 2) as avg_rent_per_cx
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;








	   
