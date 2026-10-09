-- Monthly Revenue Trend 
select
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1) as Sales_Month,
count(distinct InvoiceNo) as Total_Orders,
count(distinct CustomerID) as Active_Customers,
sum(Quantity) as Unit_Sold,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
Group by 
	DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1)
Order by Sales_Month

-- Monthly Revenue Growth
with Monthly_Revenue as (
select
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1) as Sales_Month,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
group by 
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1)
),
RevenueGrowth as (
select
Sales_Month,
Total_Revenue,
Lag(Total_Revenue) over (order by Sales_Month) as Previous_Month_Revenue
from Monthly_Revenue
)
select
Sales_Month,
Total_Revenue,
Previous_Month_Revenue,
Round(100.0 * (Total_Revenue - Previous_Month_Revenue) / NULLIF(Previous_Month_Revenue, 0), 2) as Revenue_Growth_Percentage 
from RevenueGrowth
order by Sales_Month

-- Top 20 Products by Revenue 
select Top 20 
StockCode,
Description,
sum(Quantity) as Unit_Sold,
count(distinct InvoiceNo) as Total_Orders,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
group by StockCode, Description
order by Total_Revenue Desc

-- Top 20 Products by Unit Sold
select Top 20 
StockCode,
Description,
sum(Quantity) as Unit_Sold,
count(distinct InvoiceNo) as Total_Orders,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
group by StockCode, Description
order by Unit_Sold Desc

-- Top 20 Customers by Revenue
select Top 20
CustomerID, 
count(distinct InvoiceNo) as Total_Orders,
sum(Quantity) as Units_Purchased,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
where CustomerID is not Null 
group by CustomerID
order by Total_Revenue Desc

-- Country-wise Sales Performance
select
Country,
count(distinct CustomerID) as Total_Customers,
count(distinct InvoiceNo) as Total_Orders,
sum(Quantity) as Units_Sold,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned 
where CustomerID is not Null
group by Country
order by Total_Revenue Desc 

-- Average Order Value by Month 
select
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1) as Sales_Month,
count(distinct InvoiceNo) as Total_Orders,
Round(sum(Revenue), 2) as Total_Revenue,
Round(sum(Revenue) / NULLIF(count(distinct InvoiceNo), 0), 2) as Average_Order_Value 
from dbo.OnlineRetail_Cleaned
group by 
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1)
order by Sales_Month

-- Customer Revenue Analysis
select
CustomerID,
count(distinct InvoiceNo) as Total_Orders,
sum(Quantity) as Total_Units_Purchased,
Round(sum(Revenue), 2) Total_Revenue,
Round(sum(Revenue) / NULLIF(count(distinct InvoiceNo), 0) ,2) as Average_Order_Value
from dbo.OnlineRetail_Cleaned
where CustomerID IS NOT NULL
group by CustomerID
order by Total_Revenue DESC 

-- Product Performance
select
StockCode,
Description,
sum(Quantity) as Units_Sold,
count(distinct InvoiceNo) as Orders,
count(distinct CustomerID) as Customers,
Round(sum(Revenue), 2) as Revenue,
Round(sum(Revenue) / NULLIF(sum(Quantity), 0), 2) as Revenue_Per_Unit
from dbo.OnlineRetail_Cleaned
group by StockCode, Description
order by Revenue desc 

-- Day-of-Week Sales Analysis
select
DATENAME(WEEKDAY, InvoiceDate) as Day_Name,
count(distinct InvoiceNo) as Total_Orders,
sum(Quantity) as Units_Sold,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
group by
	DATENAME(WEEKDAY, InvoiceDate),
	DATEPART(WEEKDAY, InvoiceDate)
order by DATEPART(WEEKDAY, InvoiceDate)

-- Hourly Sales Analysis
select
DATEPART(HOUR, InvoiceDate) as Sales_Hour,
count(distinct InvoiceNo) as Total_Orders,
sum(Quantity) as Units_Sold,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
group by DATEPART(HOUR, InvoiceDate)
order by Sales_Hour

-- Revenue Contribution by Country 
with CountryRevenue as (
select
Country,
Round(sum(Revenue), 2) as Total_Revenue
from dbo.OnlineRetail_Cleaned
where CustomerID is not Null
group by Country
)
select
Country,
Total_Revenue,
Round(100.0 * Total_Revenue / sum(Total_Revenue) over (), 2) as Revenue_Contribution_Percentage
from CountryRevenue
order by Total_Revenue desc 

-- Customer Purchase Frequency
with CustomerOrders as (
select
CustomerID,
count(distinct InvoiceNo) as Order_Count
from dbo.OnlineRetail_Cleaned
where CustomerID is not null
group by CustomerID
)
select
case 
	when Order_Count = 1 then '1 Order'
	when Order_Count between 2 and 3 then '2-3 Orders'
	when Order_Count between 4 and 5 then '4-5 Orders'
	when Order_Count between 6 and 10 then '6-10 Orders'
	else '11+ Orders'
	end as Purchase_frequency,
count(*) as Customer_Count,
Round(100.0 * count(*) / sum(count(*)) over(), 2) as Customer_Percentage
from CustomerOrders
group by 
	case 
	when Order_Count = 1 then '1 Order'
	when Order_Count between 2 and 3 then '2-3 Orders'
	when Order_Count between 4 and 5 then '4-5 Orders'
	when Order_Count between 6 and 10 then '6-10 Orders'
	else '11+ Orders' 
	end
order by 
	case 
	when Order_Count = 1 then '1 Order'
	when Order_Count between 2 and 3 then '2-3 Orders'
	when Order_Count between 4 and 5 then '4-5 Orders'
	when Order_Count between 6 and 10 then '6-10 Orders'
	else '11+ Orders'
	end 

-- Repeat Customer Revenue vs One-Time Customer Revenue
with CustomerOrders as (
select
CustomerID,
count(distinct InvoiceNo) as Order_Count,
sum(Revenue) as Customer_revenue
from dbo.OnlineRetail_Cleaned
where CustomerID is not null
group by CustomerID
)
select
case when Order_Count = 1 then 'One-Time-Customer'
else 'Repeat Customer'
end as Customer_Type,
count(*) as Customer_Count,
Round(sum(Customer_revenue), 2) as Total_Revenue,
Round(100.0 * sum(Customer_revenue) / sum(sum(Customer_revenue)) over(), 2) as Revenue_Percentage
from CustomerOrders
group by 
	case when Order_Count = 1 then 'One-Time-Customer'
	else 'Repeat Customer'
	end 

-- Create the final clean dataset
select
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country,
Revenue,
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1) as Purchase_Month
from dbo.OnlineRetail_Cleaned
where CustomerID IS NOT NULL

-- Verify
select Top 20 *
from dbo.OnlineRetail_Cleaned
Where CustomerID IS NOT NULL
order by InvoiceDate
