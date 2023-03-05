use gdb023;

/*  Provide the list of markets in which customer "Atliq Exclusive" operates its
business in the APAC region.*/

select distinct market
from dim_customer
where region="APAC"
and customer="Atliq Exclusive";

/* . What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

with Unq2020 as
(select count(distinct product_code) as unique_products_2020
from fact_sales_monthly
where fiscal_year=2020),
Unq2021 as 
(select count(distinct product_code) as unique_products_2021
from fact_sales_monthly
where fiscal_year=2021)
select unique_products_2020, unique_products_2021,
concat(round((unique_products_2021-unique_products_2020)/unique_products_2020*100,2), "%") as percentage_chg
from Unq2020,Unq2021;


/*3. Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count*/


select segment, count(distinct product_code) as product_count
from dim_product
group by segment
order by 2 desc;


/*4. Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */


with Product_Count as
(select segment,
count(distinct(case when fiscal_year=2020 then product_code end)) as product_count_2020,
count(distinct(case when fiscal_year=2021 then product_code end)) as product_count_2021
from dim_product inner join fact_sales_monthly using(product_code)
group by segment)
select segment, product_count_2020,product_count_2021, 
(product_count_2021-product_count_2020) as difference
from Product_Count;

/*5. Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cost */


select product_code,product,
manufacturing_cost
from fact_manufacturing_cost inner join dim_product using(product_code)
where manufacturing_cost in
(select max(manufacturing_cost) from fact_manufacturing_cost)
union
select product_code,product,
manufacturing_cost
from fact_manufacturing_cost inner join dim_product using(product_code)
where manufacturing_cost in
(select min(manufacturing_cost) from fact_manufacturing_cost);


/* 6. Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average discount_percentage */

select customer_code, customer,
avg(pre_invoice_discount_pct)  as average_discount_percentage  
from fact_pre_invoice_deductions inner join dim_customer
using(customer_code)
where fiscal_year=2021 and market="India"
group by customer_code
order by average_discount_percentage desc
limit 5;

/* 7. Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */

select monthname(date) as Month ,year(date) as Year,
round(sum(sold_quantity*gross_price),2) as Gross_sales_Amount
from fact_sales_monthly
inner join fact_gross_price using(product_code,fiscal_year)
inner join dim_customer
on fact_sales_monthly.customer_code=dim_customer.customer_code
where customer= "Atliq Exclusive"
group by year(date), Month(date)
order by year(date),month(date);


/*8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */
/*The fiscal year in Atliq starts from september 2019 */
with Qtr_table_2020  as
(select date,fiscal_year, case 
                      when date between "2019-09-01" and "2019-11-30" then "Qtr-1"
                       when date between "2019-12-01" and "2020-02-29" then "Qtr-2"
                        when date between "2020-03-01" and "2020-05-31" then "Qtr-3"
						when date between "2020-06-01" and "2020-08-31" then "Qtr-4"
					    else null
                      end as Quarter,
                      sold_quantity
from fact_sales_monthly)
select Quarter, sum(sold_quantity) as Total_sold_quantity
from Qtr_table_2020 
where fiscal_year=2020
group by Quarter;


 /*9. Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */


select sum(sold_quantity*gross_price) into @Total_sale
from fact_sales_monthly
inner join
fact_gross_price
using(product_code,fiscal_year)
where fiscal_year=2021;


select channel,sum(sold_quantity*gross_price) as gross_sales_mln,
round((sum(sold_quantity*gross_price))/@Total_sale *100,2) as Percentage
from 
dim_customer
inner join fact_sales_monthly
using(customer_code)
inner join
fact_gross_price
using(product_code,fiscal_year)
where fiscal_year=2021
group by channel
order by 2 desc;


/*10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields,
division
product_code
product
total_sold_quantity
rank_order */

with Product_Sales  as
(with Product_Sales_Quntity as
(select division, product_code, product, sum(sold_quantity) as total_sold_quantity
from dim_product inner join fact_sales_monthly using(product_code)
where fiscal_year=2021
group by product_code )
select *, dense_rank() over (partition by division order by total_sold_quantity desc)
as rank_order
from Product_Sales_Quntity)
select * from Product_Sales where rank_order<4;




