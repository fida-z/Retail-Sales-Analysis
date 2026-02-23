use sales;
-- EXPLORATORY DATA ANALYSIS :

-- SALES ANALYSIS :

-- What is the total Revenue generated?
select sum(line_total) as 'Total Revenue' from order_items_staging 
	join orders_staging on order_items_staging.order_id = orders_staging.order_id 
    where orders_staging.order_status = 'Completed'; 
    
-- Average Order Value :

select sum(line_total)/count(quantity) as 'AOV' from order_items_staging 
	join orders_staging on order_items_staging.order_id = orders_staging.order_id 
    where orders_staging.order_status = 'Completed'; 
    
-- Month-wise breakdown of Revenue :

select month(order_date) as 'Month', sum(line_total) as 'Total Revenue' from order_items_staging
	join orders_staging on order_items_staging.order_id = orders_staging.order_id 
    where orders_staging.order_status = 'Completed' group by month(order_date)order by 'Total Revenue';
    -- June July have highest revenue
    
-- Cancelled v/s Completed Orders:
select order_status, count(order_status) from orders_staging group by order_status;
	-- Around double the orders are cancelled or returned. This is a serious issue.

-- CUSTOMER ANALYSIS :

-- No. of Repeat Customers:
with repeat_customers as (
	select (customer_id) as 'Repeat Customers' from orders_staging group by customer_id having count(order_id) > 1
     )
     
select count(*) from repeat_customers;
	-- 5988 customers are returning customers

-- Loyalty v/s Non-Loyalty Member Spending :
with loyalty as (
select customers_staging.customer_id, loyalty_member, orders_staging.order_id, line_total from customers_staging join
	orders_staging on customers_staging.customer_id = orders_staging.order_id
    join order_items_staging on order_items_staging.order_id = orders_staging.order_id
)

select sum(line_total), loyalty_member from loyalty group by loyalty_member;
	-- Loyalty Members spend more than non-loyalty members
    
-- Year-over-Year Growth in Customer counts :
with year_cust as (
	select year(signup_date) as 'Year' , count(customer_id) as 'Counts' from customers_staging group by year(signup_date)
)
select `Year`, `Counts` - lag(`Counts`) over (order by `Year`) as 'Growth' from year_cust;


-- PRODUCT ANALYSIS :

-- Top Selling Products by Quantity:
select products_staging.product_name, sum(order_items_staging.quantity) from order_items_staging
	join products_staging on
    order_items_staging.product_id = products_staging.product_id 
    group by order_items_staging.product_id order by sum(quantity) desc limit 10;

-- Category Contribution to Total Revenue :
select category, sum(line_total) as 'Total Revenue' from order_items_staging 
	join orders_staging on order_items_staging.order_id = orders_staging.order_id 
    join products_staging on order_items_staging.product_id = products_staging.product_id
    where orders_staging.order_status = 'Completed'
    group by category; 
    
-- High Return Products :
select product_name, count(returns_staging.order_item_id) as 'returns' from returns_staging 
	join order_items_staging on returns_staging.order_item_id = order_items_staging.order_item_id
    join products_staging on order_items_staging.product_id = products_staging.product_id
    group by products_staging.product_name
    order by `returns` desc limit 10;

-- Returns by Category :
select category, count(returns_staging.order_item_id) as 'returns' from returns_staging 
	join order_items_staging on returns_staging.order_item_id = order_items_staging.order_item_id
    join products_staging on order_items_staging.product_id = products_staging.product_id
    group by products_staging.category
    order by `returns` desc limit 10;
    
-- Basic Market Basket (Products often bought together) :
select p1.product_name, p2.product_name, count(*) from order_items_staging as orders1 
	join order_items_staging as orders2 on orders1.order_id = orders2.order_id
    join products_staging as p1 on orders1.product_id = p1.product_id
    join products_staging as p2 on orders2.product_id = p2.product_id
    where orders1.product_id < orders2.product_id
    group by p1.product_name, p2.product_name 
    order by count(*) desc;

-- Stores with the Most Orders :
select store_name, count(order_id) as 'counts' from stores_staging join orders_staging 
	on stores_staging.store_id = orders_staging.store_id
    group by store_name
    order by `counts` desc;
