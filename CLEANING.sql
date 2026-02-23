USE sales;

-- DATA CLEANING :

-- 1. Checking for Duplicates :
-- 1.1 in customers table :

WITH DUPLICATE_CTE AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY CUSTOMER_ID, FIRST_NAME, LAST_NAME, GENDER, AGE, EMAIL, PHONE_NUMBER, CITY, COUNTRY, SIGNUP_DATE, LOYALTY_MEMBER
        ) AS COUNTS
    FROM CUSTOMERS
)
SELECT * FROM DUPLICATE_CTE WHERE COUNTS > 1;
-- ABOVE QUERY DISPLAYS ROWS WITH DUPLICATE COLUMNS.

CREATE TABLE `customers_staging` (
  `customer_id` int DEFAULT NULL,
  `first_name` text,
  `last_name` text,
  `gender` text,
  `age` int DEFAULT NULL,
  `email` text,
  `phone_number` text,
  `city` text,
  `country` text,
  `signup_date` text,
  `loyalty_member` text,
  `counts` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO CUSTOMERS_STAGING SELECT *, ROW_NUMBER() OVER(
		PARTITION BY CUSTOMER_ID, FIRST_NAME, LAST_NAME, GENDER, AGE, EMAIL, PHONE_NUMBER, CITY, COUNTRY, SIGNUP_DATE, LOYALTY_MEMBER
        ) AS COUNTS
        FROM CUSTOMERS;

DELETE FROM CUSTOMERS_STAGING WHERE COUNTS > 1;
SELECT * FROM CUSTOMERS_STAGING WHERE COUNTS > 1;


-- 1.2 in order_items table :

WITH DUPLICATE_CTE AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY ORDER_ITEM_ID, ORDER_ID, PRODUCT_ID, QUANTITY, UNIT_PRICE, LINE_TOTAL
	) AS COUNTS
	FROM ORDER_ITEMS
)
SELECT * FROM DUPLICATE_CTE WHERE COUNTS > 1;

		-- No duplicates in this table.
        
CREATE TABLE `order_items_staging` (
  `order_item_id` int DEFAULT NULL,
  `order_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `quantity` int DEFAULT NULL,
  `unit_price` int DEFAULT NULL,
  `line_total` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO ORDER_ITEMS_STAGING SELECT * FROM ORDER_ITEMS;

-- 1.3 from orders table :
SELECT * FROM ORDERS;
WITH DUPLICATE_CTE AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY ORDER_ID, CUSTOMER_ID, STORE_ID, ORDER_DATE, PAYMENT_METHOD, ORDER_sTATUS, TOTAL_AMOUNT, DISCOUNT_AMOUNT, TAX_AMOUNT
	) AS COUNTS
 FROM ORDERS
 )
 SELECT * FROM DUPLICATE_CTE WHERE COUNTS > 1;
 
  -- No duplicates in orders table.
  
CREATE TABLE `orders_staging` (
  `order_id` int DEFAULT NULL,
  `customer_id` int DEFAULT NULL,
  `store_id` int DEFAULT NULL,
  `order_date` text,
  `payment_method` text,
  `order_status` text,
  `total_amount` text,
  `discount_amount` int DEFAULT NULL,
  `tax_amount` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO ORDERS_STAGING SELECT * FROM ORDERS;

-- 1.4 From products table :

WITH DUPLICATE_CTE AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY PRODUCT_ID, PRODUCT_NAME, CATEGORY, SUBCATEGORY, BRAND, COST_PRICE, SELLING_PRICE, SUPPLIER_ID, LAUNCH_DATE, IS_ACTIVE
	) AS COUNTS FROM PRODUCTS
)

SELECT * FROM DUPLICATE_CTE WHERE COUNTS > 1;

	-- No duplicates in product table

CREATE TABLE `products_staging` (
  `product_id` int DEFAULT NULL,
  `product_name` text,
  `category` text,
  `subcategory` text,
  `brand` text,
  `cost_price` text,
  `selling_price` text,
  `supplier_id` int DEFAULT NULL,
  `launch_date` text,
  `is_active` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO PRODUCTS_STAGING SELECT * FROM PRODUCTS;

WITH DUPLICATE_CTE AS (
	SELECT *, ROW_NUMBER() OVER (
		PARTITION BY RETURN_ID, ORDER_ITEM_ID, RETURN_DATE, RETURN_REASON, REFUND_AMOUNT
	) AS COUNTS FROM RETURNS
)
SELECT * FROM DUPLICATE_CTE WHERE COUNTS > 1;
    -- No duplicates in returns table
    
CREATE TABLE `returns_staging` (
  `return_id` int DEFAULT NULL,
  `order_item_id` int DEFAULT NULL,
  `return_date` text,
  `return_reason` text,
  `refund_amount` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO RETURNS_STAGING SELECT * FROM RETURNS;


WITH DUPLICATE_CTE AS (
	SELECT *, ROW_NUMBER() OVER(
		PARTITION BY STORE_ID, STORE_NAME, STORE_TYPE, CITY, COUNTRY, OPENING_DATE, STORE_SIZE_SQFT
	) AS COUNTS FROM STORES
 )
SELECT * FROM DUPLICATE_CTE WHERE COUNTS > 1;

-- No duplicates in stores table.

CREATE TABLE `stores_staging` (
  `store_id` int DEFAULT NULL,
  `store_name` text,
  `store_type` text,
  `city` text,
  `country` text,
  `opening_date` text,
  `store_size_sqft` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO STORES_STAGING SELECT * FROM STORES;


-- adding primary and foreign keys to our tables :

alter table customers_staging add constraint primary key(customer_id);
alter table products_staging add constraint primary key(product_id);
alter table stores_staging add constraint primary key(store_id);
alter table orders_staging add constraint primary key(order_id);
alter table returns_staging add constraint primary key(return_id);

alter table orders_staging add constraint fk_orders_cust foreign key(customer_id) references customers_staging(customer_id);
alter table order_items_staging add constraint fk_product foreign key(product_id) references products_staging(product_id);
alter table orders_staging add constraint fk_store foreign key(store_id) references stores_staging(store_id);
alter table order_items_staging add constraint fk_orders foreign key(order_id) references orders_staging(order_id);
alter table returns_staging add constraint fk_orderitem foreign key(order_item_id) references order_items_staging(order_item_id);



-- 2. Standardising Values :

-- 2.1 on customers table :
SELECT AGE FROM customers_staging WHERE AGE <= 0;
	-- No negative ages found
SELECT DISTINCT(CITY) FROM customers_staging ORDER BY 1;
	-- Inconsistencies found - city names are mispelled or do not follow uniform case.
UPDATE customers_staging SET CITY = 'Bengaluru' where CITY = 'Banglore';
UPDATE customers_staging SET CITY = 'Chennai' where CITY = 'chenai';
UPDATE customers_staging SET CITY = 'Hyderabad' where CITY = 'Hydrabad';
UPDATE customers_staging SET CITY = 'Mumbai' WHERE CITY = 'Mumabi';
UPDATE customers_staging SET CITY = UPPER(CITY);

SELECT PHONE_NUMBER FROM CUSTOMERS_STAGING WHERE PHONE_NUMBER LIKE '+%'; -- MANY PHONE NUMBERS HAVE A REDUNDANT + IN FRONT. REMOVING AND CONVERTING :
UPDATE customers_staging SET PHONE_NUMBER = TRIM(LEADING '+' FROM PHONE_NUMBER) WHERE PHONE_NUMBER LIKE '+%';


-- 2.2 on order_items table :

SELECT * FROM order_items_staging where quantity < 0 or unit_price < 0 or line_total < 0;

	-- many records have negative quantity and line_total values. This might imply that they are returned products. Checking :
SELECT COUNT(*) FROM order_items_staging WHERE quantity < 0; -- gives 170
select count(*) from returns_staging; -- gives 1000

	-- the number of negative orders and number of returned orders is inconsistent. Hence, the negative quantities do not seem to have any logical explanation. deleting:

DELETE FROM order_items_staging where quantity < 0 or unit_price < 0 or line_total < 0;

-- 2.3 on orders table :
 
SELECT * FROM orders_staging WHERE total_amount LIKE 'â%';
	-- several rows in total_amount have special characters in their beginning. this must be rectified.
update orders_staging set total_amount =  trim(leading 'â‚¹' from total_amount) where total_amount like 'â‚¹%';
alter table orders_staging modify column total_amount int;

-- 2.4 on products table :
select * from products_staging;

select count(*) from products_staging;
	-- the second word of each product is unncessary and already given by subcategory, it can be removed.
update products_staging set product_name = regexp_replace(product_name, ' [A-Z]+',''); 
update products_staging set cost_price =  trim(leading 'â‚¹' from cost_price);
update products_staging set selling_price = trim(leading 'â‚¹' from selling_price);

alter table products_staging modify column cost_price int;
alter table products_staging modify column selling_price int;

-- 2.5 on returns table :
select * from returns_staging;

select distinct(return_reason) from returns_staging order by 1;
select * from returns_staging where refund_amount < 0;

	-- no standardising errors in returns.
    
-- 2.6 on stores table :
select distinct(store_type) from stores_staging;
select distinct(city) from stores_staging;
select * from stores_staging where store_size_sqft < 0;

	-- no standardising errors in stores.


-- handle nulls
-- handle datetime

-- 3. Handling datetime :

-- 3.1 on customers :

update customers_staging set signup_date = str_to_date(signup_date, '%m-%d-%Y') where signup_date like '__-__-%'; 
update customers_staging set signup_date = str_to_date(signup_date, '%d/%m/%Y') where signup_date like '__/__/%'; 

alter table customers_staging modify column signup_date date;

-- 3.2 on orders :

update orders_staging set order_date = str_to_date(order_date, '%m-%d-%Y') where order_date like '__-__-%'; 
update orders_staging set order_date = str_to_date(order_date, '%d/%m/%Y') where order_date like '__/__/%'; 

alter table orders_staging modify column order_date date;

-- 3.3 on products :

update products_staging set launch_date = str_to_date(launch_date, '%m-%d-%Y') where launch_date like '__-__-%'; 
update products_staging set launch_date = str_to_date(launch_date, '%d/%m/%Y') where launch_date like '__/__/%'; 

alter table products_staging modify column launch_date date;

-- 3.4 on returns :

update returns_staging set return_date = str_to_date(return_date, '%m-%d-%Y') where return_date like '__-__-%'; 
update returns_staging set return_date = str_to_date(return_date, '%d/%m/%Y') where return_date like '__/__/%'; 

alter table returns_staging modify column return_date date;

-- 3.5 on stores:

select * from stores_staging;

update stores_staging set opening_date = str_to_date(opening_date, '%m-%d-%Y') where opening_date like '__-__-%';
update stores_staging set opening_date = str_to_date(opening_date, '%d/%m/%Y') where opening_date like '__/__/%';



-- 4. Handling Null values:

-- 4.1 on customers :
update customers_staging set email = null where email = '';
update customers_staging set phone_number = null where phone_number = '';

select * from customers_staging where first_name is null or 
	last_name is null or 
    gender is null or 
    age is null or 
    email is null or
    phone_number is null or 
    city is null or 
    loyalty_member is null;
-- email and phone number are null for many customers. However, there is no method to obtain them from the data.

update customers_staging set phone_number = coalesce(phone_number,'Not Available');
update customers_staging set email = coalesce(email,'Not Available');

-- 4.2 on order_items :

select * from order_items_staging;


-- 5. Checking for general inconsistencies :

-- any customers who have ordered before they even signed up?
select * from customers_staging 
	join orders_staging on 
	customers_staging.customer_id = orders_staging.customer_id 
    where customers_staging.signup_date > orders_staging.order_date;

-- orders in the future :

delete from orders_staging where order_date > '2026-02-01';


