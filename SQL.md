# SQL

## Data Understanding
Select top 1 * from Orders;
select top 1 * from Managers;
select top 1 * from Profiles;
select top 1 * from Returns;
![image](https://github.com/hhienly/SQL/assets/138852319/2d256dff-d8a4-4d15-85aa-8c4e4e310d03)

select distinct province, region from Orders
select distinct status from Returns
select distinct customer_segment from Orders
select distinct product_category from Orders
select distinct shipping_mode from Orders
select distinct product_container from Orders
select min(unit_price), avg(unit_price), max(unit_price) from Orders
select distinct format(order_date,'yyyy-MM-dd') from Orders

### Query data
#### /* Q1: Total orders, returns and sold by month */
$ git clone https://github.com/ltnquang/ute.git
#!/bin/sh
With data as(
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
select *, round(return_qty/order_qty *100,2) as "%_return" from data
UNION ALL
select 'Total', sum(dt.order_qty),sum(dt.order_value), sum(dt.shipping_cost), sum(dt.return_qty),sum(dt.return_value), sum(dt.sold_qty), sum(dt.sold_value),sum(dt.sold_profit),round(sum(dt.return_qty)/sum(dt.order_qty)*100,2)
from data dt
![image](https://github.com/hhienly/SQL/assets/138852319/cff81970-9a25-4144-9dad-3ca3f83ad137)

SELECT sales.customer_id, SUM(menu.price) AS total_spent
FROM sales
INNER JOIN menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

