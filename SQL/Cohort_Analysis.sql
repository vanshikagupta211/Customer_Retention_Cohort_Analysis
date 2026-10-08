-- Overall Customer & Sales KPIs
SELECT
    COUNT(DISTINCT CustomerID) AS Total_Customers,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    SUM(Quantity) AS Total_Units_Sold,
    ROUND(SUM(Quantity * UnitPrice), 2) AS Total_Revenue,
    ROUND(
        SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo),
        2
    ) AS Average_Order_Value,
    ROUND(
        SUM(Quantity * UnitPrice) / COUNT(DISTINCT CustomerID),
        2
    ) AS Average_Revenue_Per_Customer,
    ROUND(
        CAST(COUNT(DISTINCT InvoiceNo) AS DECIMAL(18,2))
        / COUNT(DISTINCT CustomerID),
        2
    ) AS Average_Orders_Per_Customer
FROM dbo.OnlineRetail_Cleaned

-- One-time vs Repeat Customers (New vs Returning Customers)
with CustomerOrders as (
select 
CustomerID,
COUNT(distinct InvoiceNo) as Order_Count
from dbo.OnlineRetail_Cleaned
group by CustomerID
)
select
Case When Order_Count = 1 then 'One-Time-Customer' else 'Repeat Customers' end as Customer_Type,
Count(*) as Customer_Count,
Round( 100.0 * Count(*) / sum(count(*)) over(), 2) as Customer_Percentage
from CustomerOrders
group by 
	Case When Order_Count = 1 then 'One-Time-Customer' else 'Repeat Customers' end
order by Customer_Count desc 

-- Order Frequency Distribution (Repeat Purchase Analysis) 
with CustomerOrders as (
select
CustomerID,
count(distinct InvoiceNo) as Order_Count
from dbo.OnlineRetail_Cleaned
group by CustomerID
) 
select
Case	
	When Order_Count = 1 then '1 Order'
	When Order_Count between 2 and 3 then '2-3 Orders'
	When Order_Count between 4 and 5 then '4-5 Orders'
	When Order_Count between 6 and 10 then '6-10 Orders'
	else '11+ Orders'
	end as Purchase_Frequency,
count(*) as Customer_Count,
round(100.0 * count(*) / sum(count(*)) over(), 2) as Customer_Percentage
from CustomerOrders
group by 
Case	
	When Order_Count = 1 then '1 Order'
	When Order_Count between 2 and 3 then '2-3 Orders'
	When Order_Count between 4 and 5 then '4-5 Orders'
	When Order_Count between 6 and 10 then '6-10 Orders'
	else '11+ Orders'
	end 
order by 
	Case 
		When min(Order_Count) = 1 then 1
		When min(Order_Count) = 2 then 2
		When min(Order_Count) = 4 then 3 
		When min(Order_Count) = 6 then 4 
		else 5
		end 

-- Monthly Customer Activity
select 
DATEFROMPARTS(
	YEAR(InvoiceDate),
	MONTH(InvoiceDate),
	1 ) as Purchase_Month,
Count(distinct CustomerID) as Action_Customers,
Count(distinct InvoiceNo) as Total_Orders,
sum(Quantity) as Units_Sold,
Round(sum(Quantity * UnitPrice), 2) as Revenue 
from dbo.OnlineRetail_Cleaned
group by 
	DATEFROMPARTS(
	YEAR(InvoiceDate),
	MONTH(InvoiceDate),
	1 )
Order by Purchase_Month

-- Customer First Purchase
select
CustomerID,
min(InvoiceDate) as First_Purchase_Date,
DATEFROMPARTS(
	Year(min(InvoiceDate)),
	Month(min(InvoiceDate)),
	1) as Cohort_Month
from dbo.OnlineRetail_Cleaned
group by CustomerID
order by CustomerID

-- Cohort Assignment
-- Customer Activity Month + Months Since First Purchase
with CustomerCohort as (
select
CustomerID,
DATEFROMPARTS(
	Year(min(InvoiceDate)),
	Month(min(InvoiceDate)),
	1) as Cohort_month
from dbo.OnlineRetail_Cleaned
group by CustomerID
),
CustomerActivity as (
select distinct 
CustomerID,
DATEFROMPARTS(
	Year(InvoiceDate),
	Month(InvoiceDate),
	1) as Purchase_Month
from dbo.OnlineRetail_Cleaned
)
select
A.CustomerID,
C.Cohort_Month,
A.Purchase_Month,
Datediff(
Month,
C.Cohort_Month,
A.Purchase_Month
) as Month_Number
from CustomerActivity A
inner join CustomerCohort C on a.CustomerID = c.CustomerID
order by a.CustomerID, a.Purchase_Month

-- Cohort Size (Cohort Retention)
with CustomerCohort as (
select
CustomerID,
DATEFROMPARTS(
	Year(min(InvoiceDate)),
	month(min(InvoiceDate)),
	1) as Cohort_Month
from dbo.OnlineRetail_Cleaned
group by CustomerID
)
select
Cohort_Month,
count(*) as Cohort_Size
from CustomerCohort
group by Cohort_Month
order by Cohort_Month

-- Retained Customers by Cohort & Purchase Month (Cohort Retention Matrix)
WITH CustomerCohort AS (
SELECT
CustomerID,
DATEFROMPARTS(
      YEAR(MIN(InvoiceDate)),
      MONTH(MIN(InvoiceDate)),
      1) AS Cohort_Month
FROM dbo.OnlineRetail_Cleaned
GROUP BY CustomerID
),
CustomerActivity AS (
SELECT DISTINCT
CustomerID,
DATEFROMPARTS(
     YEAR(InvoiceDate),
     MONTH(InvoiceDate),
	 1) AS Purchase_Month
    FROM dbo.OnlineRetail_Cleaned
)
SELECT
C.Cohort_Month,
A.Purchase_Month,
DATEDIFF(
   MONTH,
   C.Cohort_Month,
   A.Purchase_Month
   ) AS Month_Number,
COUNT(DISTINCT A.CustomerID) AS Retained_Customers
FROM CustomerCohort C
INNER JOIN CustomerActivity A ON C.CustomerID = A.CustomerID
GROUP BY
    C.Cohort_Month,
    A.Purchase_Month
ORDER BY
    C.Cohort_Month,
    A.Purchase_Month;

-- Cohort Retention Percentage 
WITH CustomerCohort AS (
SELECT
CustomerID,
DATEFROMPARTS(
YEAR(MIN(InvoiceDate)),
MONTH(MIN(InvoiceDate)),
1
) AS Cohort_Month
FROM dbo.OnlineRetail_Cleaned
GROUP BY CustomerID
),
CustomerActivity AS (
SELECT DISTINCT
CustomerID,
DATEFROMPARTS(
       YEAR(InvoiceDate),
       MONTH(InvoiceDate),
       1) AS Purchase_Month
FROM dbo.OnlineRetail_Cleaned
),
RetentionData AS (
SELECT
C.Cohort_Month,
A.Purchase_Month,
DATEDIFF(
    MONTH,
    C.Cohort_Month,
    A.Purchase_Month
    ) AS Month_Number,
COUNT(DISTINCT A.CustomerID) AS Retained_Customers
FROM CustomerCohort C
INNER JOIN CustomerActivity A ON C.CustomerID = A.CustomerID
GROUP BY
      C.Cohort_Month,
      A.Purchase_Month
),
CohortSize AS (
SELECT
Cohort_Month,
COUNT(*) AS Cohort_Size
FROM CustomerCohort
GROUP BY Cohort_Month
)
SELECT
R.Cohort_Month,
R.Purchase_Month,
R.Month_Number,
C.Cohort_Size,
R.Retained_Customers,
ROUND(100.0 * R.Retained_Customers / C.Cohort_Size, 2) AS Retention_Percentage
FROM RetentionData R
INNER JOIN CohortSize C ON R.Cohort_Month = C.Cohort_Month
ORDER BY
    R.Cohort_Month,
    R.Month_Number;

-- Create Final Cohort Retention Table (Create Table)
IF OBJECT_ID('dbo.Cohort_Retention', 'U') IS NOT NULL
	DROP TABLE dbo.Cohort_Retention;

With CustomerCohort as (
select
CustomerID,
DATEFROMPARTS(
		Year(min(InvoiceDate)),
		Month(min(InvoiceDate)),
		1) as Cohort_Month
from dbo.OnlineRetail_Cleaned
Group by CustomerID
),
CustomerActivity as (
select distinct 
CustomerID,
DATEFROMPARTS(
		Year(InvoiceDate),
		Month(InvoiceDate),
		1) as Purchase_Month
from dbo.OnlineRetail_Cleaned
),
RetentionData as (
select
C.Cohort_Month,
A.Purchase_Month,
DATEDIFF(
	Month,
	C.Cohort_Month,
	A.Purchase_Month) as Month_Number,
count(distinct A.CustomerID) as Retained_Customers
from CustomerCohort C 
inner join CustomerActivity A on C.CustomerID = A.CustomerID
Group by C.Cohort_Month, A.Purchase_Month
),
CohortSize as (
select 
Cohort_Month,
count(*) as Cohort_Size
from CustomerCohort
Group by Cohort_Month
)
select
R.Cohort_Month,
R.Purchase_Month,
R.Month_Number,
C.Cohort_Size,
R.Retained_Customers,
Cast(
	Round(
		100.0 * R.Retained_Customers / C.Cohort_Size,
		2 
		) as Decimal (10,2)
		) as Retention_Percentage
Into dbo.Cohort_Retention
from RetentionData R
Inner join CohortSize C on R.Cohort_Month = C.Cohort_Month

-- Verify the new table Cohort_Retention
select Top 20 *
from dbo.Cohort_Retention
Order by Cohort_Month, Month_Number


-- Verify Columns of OnlineRetail_Cleaned Table
SELECT
COLUMN_NAME,
DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'OnlineRetail_Cleaned'
ORDER BY ORDINAL_POSITION

-- Add Revenue Column
Alter Table dbo.OnlineRetail_Cleaned
Add Revenue as (Quantity * UnitPrice)

-- Verify Table
select Top 10
Quantity, UnitPrice, Revenue 
from dbo.OnlineRetail_Cleaned
