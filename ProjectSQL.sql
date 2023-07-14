USE hocsql
/* Data Understanding*/
Select top 1 * from Orders;
select top 1 * from Managers;
select top 1 * from Profiles;
select top 1 * from Returns;

select distinct province,region from Orders
select distinct status from Returns
select distinct customer_segment from Orders
select distinct product_category from Orders
select distinct shipping_mode from Orders
select distinct product_container from Orders
select min(unit_price), avg(unit_price), max(unit_price) from Orders
select distinct format(order_date,'yyyy-MM-dd') from Orders

/* Q1: Total orders, returns and sold by month */
with data as(
Select format(od2.order_date,'yyyy-MM') as Y_M
, sum(od2.order_quantity) as order_qty
, round(sum(od2.value),2) as order_value
, round(sum(shipping_cost),2) as shipping_cost
, round(case when sum(re2.order_quantity) is null then 0 else sum(re2.order_quantity) end,2) as return_qty
, round(case when sum(re2.value) is null then 0 else sum(re2.value) end,2) as return_value
, sum(od2.order_quantity) - sum(re2.order_quantity) as sold_qty
, round(sum(od2.value) - sum(re2.value),2) as sold_value
, round(sum(od2.profit) - sum(re2.value),2) as sold_profit
from Orders od2
left join (select od1.order_id, od1.order_quantity, od1.value, od1.profit from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2
on od2.order_id = re2.order_id
group by format(od2.order_date,'yyyy-MM')
)
select *, round(return_qty/order_qty*100,2) as "%_return" from data
UNION ALL
select 'Total', sum(dt.order_qty),sum(dt.order_value), sum(dt.shipping_cost), sum(dt.return_qty),sum(dt.return_value), sum(dt.sold_qty), sum(dt.sold_value),sum(dt.sold_profit),round(sum(dt.return_qty)/sum(dt.order_qty)*100,2)
from data dt

/* Q2: Total sold quantity by customer_segment and product_category in 2012 */
select year,customer_segment, "Office Supplies", "Furniture", "Technology"
FROM (
select format(od2.order_date,'yyyy') as year,customer_segment, product_category
, od2.order_quantity - (case when re2.order_quantity is null then 0 else re2.order_quantity end) as sold_qty
from Orders od2
left join (select od1.order_id, od1.order_quantity from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2
on od2.order_id = re2.order_id
where format(od2.order_date,'yyyy') = '2012'
	) as PivotData
PIVOT
(SUM(sold_qty)
	FOR product_category IN ("Office Supplies", "Furniture", "Technology")
	) as PivotTable

	/* For PostgreSQL */
select to_char(od2.order_date,'yyyy') as year,customer_segment
, sum(case when product_category in ('Office Supplies') then od2.order_quantity end) - sum(case when product_category in ('Office Supplies') then re2.order_quantity end) as "Office Supplies"
, sum(case when product_category in ('Furniture') then od2.order_quantity end) - sum(case when product_category in ('Furniture') then re2.order_quantity end) as "Furniture"
, sum(case when product_category in ('Technology') then od2.order_quantity end) - sum(case when product_category in ('Technology') then re2.order_quantity end) as "Technology"
from Orders od2
left join (select od1.order_id, od1.order_quantity from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2
on od2.order_id = re2.order_id
where to_char(od2.order_date,'yyyy') = '2012'
group by to_char(od2.order_date,'yyyy'),customer_segment


/* Q3: Total orders, and sold quantity by manager */
with data2 as(
select manager_name, manager_level
, count(od2.order_id) total_order
, sum(od2.order_quantity) order_qty
, round(sum(od2.value),2) order_value
, sum(od2.order_quantity) - sum(re2.order_quantity) as sold_qty
, round(sum(od2.value) - sum(re2.value),2) as sold_value
from Orders od2
left join (select od1.order_id, od1.order_quantity, od1.value, od1.profit from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2 
			on od2.order_id = re2.order_id
left join Profiles pr on od2.province = pr.province
left join Managers ma on pr.manager_id = ma.manager_id
group by manager_name, manager_level)
select * from data2
union all
select 'Total','', sum(total_order), sum(order_qty), sum(order_value), sum(sold_qty), sum(sold_value)
from data2

/* Q4: Top 3 orders had highest profit in Corporate customer_segment in each province*/
select *
from (
	select province, order_id,customer_segment, profit
	, RANK() OVER(Partition by province order by profit desc) as [profit_rank]
	from Orders od
	where customer_segment LIKE '%Corporate%') as rank
where profit_rank <= 3

/* Q5: Total orders, quantity and value in Atlantic region but not in Newfoundland province*/
select region, province, count(*) total_order, sum(order_quantity) order_qty, sum(value) order_value
from orders
where region = 'Atlantic'
and order_id not in (select order_id from Orders where province = 'Newfoundland')
group by region, province

/* Q6: Average shipping code by shipping_mode and product_container */
select product_container
, case when "Delivery Truck" is NULL then 0 else ROUND("Delivery Truck",2) end "Delivery Truck"
, case when "Regular Air" is NULL then 0 else ROUND("Regular Air",2) end "Regular Air"
, case when "Express Air" is NULL then 0 else ROUND("Express Air",2) end "Express Air"
from (
	select product_container, shipping_mode, shipping_cost
	from Orders) as pivotdata
PIVOT
 (AVG(shipping_cost)
FOR shipping_mode IN ("Delivery Truck", "Regular Air", "Express Air")) as pivottable
order by "Regular Air"

	/* For PostgreSQL */
select product_container
, round(avg(case when shipping_mode = 'Delivery Truck' then shipping_cost end),2) as "Delivery Truck"
, round(avg(case when shipping_mode = 'Regular Air' then shipping_cost end),2) as "Regular Air"
, round(avg(case when shipping_mode = 'Express Air' then shipping_cost end),2) as "Express Air"
from Orders
group by product_container
order by "Regular Air"


/* Q7: Total order and return quantity by range_price */
with data3 as
(select unit_price, od2.order_quantity as order_qty, re2.order_quantity as return_qty
from Orders od2
left join (select od1.order_id, od1.order_quantity from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2 
on od2.order_id = re2.order_id)
select '<10' as range_price, sum(order_qty) order_qty,  sum(return_qty) return_qty, round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price < '10'
union all
select '11-50', sum(order_qty) order_qty,  sum(return_qty) return_qty, round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price between '11' and '50'
union all
select '51-100', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price between '51' and '100'
union all
select '101-200', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price between '101' and '200'
union all
select '201-500', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price between '201' and '500'
union all
select '501-1000', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price between '501' and '1000'
union all
select '1001-2000', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price between '1001' and '2000'
union all
select '>2000', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3
where unit_price > '2000'
union all
select 'Total', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
, round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
from data3

/* Q8: Select days had no sale */
select format('2019-01-01','yyyy-MM-dd') + d.date from generate_series(0,1460) as d(date)
