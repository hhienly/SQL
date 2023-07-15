# SQL

## Data Understanding
- Check all columns in tables
````sql
Select top 1 * from Orders;
Select top 1 * from Managers;
Select top 1 * from Profiles;
Select top 1 * from Returns;
````
![image](https://github.com/hhienly/SQL/assets/138852319/2d256dff-d8a4-4d15-85aa-8c4e4e310d03)

- Check distinct values in columns
````sql
Select distinct province, region from Orders
Select distinct status from Returns
Select distinct customer_segment from Orders
Select distinct product_category from Orders
Select distinct shipping_mode from Orders
Select distinct product_container from Orders
Select min(unit_price), avg(unit_price), max(unit_price) from Orders
Select distinct format(order_date,'yyyy-MM-dd') from Orders
````
- Entity Relationship Diagram
![image](https://github.com/hhienly/SQL/assets/138852319/c10bf3db-6558-4e45-92d7-b7066df7f978)

### Query data
#### Q1: Total orders, returns and sold by month
````sql
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
      From Orders od2
      Left join (select od1.order_id, od1.order_quantity, od1.value, od1.profit from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2
      on od2.order_id = re2.order_id
      Group by format(od2.order_date,'yyyy-MM')
      )
Select *, round(return_qty/order_qty *100,2) as "%_return" from data
UNION ALL
select 'Total', sum(dt.order_qty),sum(dt.order_value), sum(dt.shipping_cost), sum(dt.return_qty),sum(dt.return_value), sum(dt.sold_qty), sum(dt.sold_value),sum(dt.sold_profit),round(sum(dt.return_qty)/sum(dt.order_qty)*100,2)
From data dt
````
![image](https://github.com/hhienly/SQL/assets/138852319/cff81970-9a25-4144-9dad-3ca3f83ad137)

#### Q2: Total sold quantity by customer_segment and product_category in 2012
````sql
	/* For MSSM */
Select year,customer_segment, "Office Supplies", "Furniture", "Technology"
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
Select to_char(od2.order_date,'yyyy') as year,customer_segment
    , sum(case when product_category in ('Office Supplies') then od2.order_quantity end) - sum(case when product_category in ('Office Supplies') then re2.order_quantity end) as "Office Supplies"
    , sum(case when product_category in ('Furniture') then od2.order_quantity end) - sum(case when product_category in ('Furniture') then re2.order_quantity end) as "Furniture"
    , sum(case when product_category in ('Technology') then od2.order_quantity end) - sum(case when product_category in ('Technology') then re2.order_quantity end) as "Technology"
From Orders od2
````
![image](https://github.com/hhienly/SQL/assets/138852319/fa4f243b-e458-408c-b598-d3dc894e014d)

#### Q3: Total orders, and sold quantity by manager
````sql
With data2 as(
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
Select * from data2
Union all
Select 'Total','', sum(total_order), sum(order_qty), sum(order_value), sum(sold_qty), sum(sold_value)
From data2
````
![image](https://github.com/hhienly/SQL/assets/138852319/64a32402-f684-4c76-9aea-ab4b6849cd78)

#### Q4: Top 3 orders had highest profit in 'Corporate' customer_segment by each province
````sql
Select *
From (
    	select province, order_id,customer_segment, profit
    	, RANK() OVER(Partition by province order by profit desc) as [profit_rank]
    	from Orders od
    	where customer_segment LIKE '%Corporate%') as rank
Where profit_rank <= 3
````
![image](https://github.com/hhienly/SQL/assets/138852319/8331d763-f4ab-48d0-bd42-15c8480d5afe)

#### Q5: Total orders, quantity and value in Atlantic region but not in Newfoundland province
````sql
Select region, province, count(*) total_order, sum(order_quantity) order_qty, sum(value) order_value
From orders
Where region = 'Atlantic'
    And order_id not in (select order_id from Orders where province = 'Newfoundland')
Group by region, province
````
![image](https://github.com/hhienly/SQL/assets/138852319/3ad6a8d2-6b4c-410b-a7db-01ed1e9e52ef)

#### Q6: Average shipping code by shipping_mode and product_container
````sql
	/* For MSSM */
Select product_container
      , case when "Delivery Truck" is NULL then 0 else ROUND("Delivery Truck",2) end "Delivery Truck"
      , case when "Regular Air" is NULL then 0 else ROUND("Regular Air",2) end "Regular Air"
      , case when "Express Air" is NULL then 0 else ROUND("Express Air",2) end "Express Air"
From (
	Select product_container, shipping_mode, shipping_cost
	From Orders) as pivotdata
PIVOT
 (AVG(shipping_cost)
FOR shipping_mode IN ("Delivery Truck", "Regular Air", "Express Air")) as pivottable
order by "Regular Air"

	/* For PostgreSQL */
select product_container
      , round(avg(case when shipping_mode = 'Delivery Truck' then shipping_cost end),2) as "Delivery Truck"
      , round(avg(case when shipping_mode = 'Regular Air' then shipping_cost end),2) as "Regular Air"
      , round(avg(case when shipping_mode = 'Express Air' then shipping_cost end),2) as "Express Air"
From Orders
Group by product_container
Order by "Regular Air"
````
![image](https://github.com/hhienly/SQL/assets/138852319/25313392-564a-41c4-a018-0a20a77ef1c7)

#### Q7: Total order and return quantity by range_price
````sql
With data3 as
    (select unit_price, od2.order_quantity as order_qty, re2.order_quantity as return_qty
    from Orders od2
    left join (select od1.order_id, od1.order_quantity from Orders od1 inner join Returns re1 on od1.order_id = re1.order_id) re2 
    on od2.order_id = re2.order_id)
Select '<10' as range_price, sum(order_qty) order_qty,  sum(return_qty) return_qty, round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
        , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price < '10'
UNION ALL
Select '11-50', sum(order_qty) order_qty,  sum(return_qty) return_qty, round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
        , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price between '11' and '50'
UNION ALL
Select '51-100', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
      , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price between '51' and '100'
UNION ALL
Select '101-200', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
        , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price between '101' and '200'
UNION ALL
Select '201-500', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
        , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price between '201' and '500'
UNION ALL
Select '501-1000', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
        , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price between '501' and '1000'
UNION ALL
Select '1001-2000', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
        , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price between '1001' and '2000'
UNION ALL
Select '>2000', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
      , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
Where unit_price > '2000'
UNION ALL
Select 'Total', sum(order_qty), sum(return_qty), round(sum(return_qty)/sum(order_qty)*100,2) as "%_return"
      , round(sum(order_qty)/(select sum(order_qty) from data3)*100,2) as "%_order/total"
From data3
````
![image](https://github.com/hhienly/SQL/assets/138852319/82ad9177-b0ca-45aa-b5b4-653c8aa4eca2)

