-- Verify Data
select top 10 *
from [dbo].[OnlineRetail_Raw]

-- Total Rows
select count(*) as Total_Rows
from dbo.[OnlineRetail_Raw]

-- Check Column Names and Data Types
EXEC sp_help '[dbo].[OnlineRetail_Raw]'

-- Missing Value or Null Value
select 
count(*) as Total_Rows,
sum(case when InvoiceNo is null then 1 else 0 end) as Missing_InvoiceNo,
sum(case when StockCode is null then 1 else 0 end) as Missing_StockCode,
sum(case when Description is null then 1 else 0 end) as Missing_Description,
sum(case when Quantity is null then 1 else 0 end) as Missing_Quantity,
sum(case when InvoiceDate is null then 1 else 0 end) as Missing_InvoiceDate,
sum(case when UnitPrice is null then 1 else 0 end) as Missing_UnitPrice,
sum(case when CustomerID is null then 1 else 0 end) as Missing_CustomerID,
sum(case when Country is null then 1 else 0 end) as Missing_Country
from [dbo].[OnlineRetail_Raw]

-- Calculate Missing Percentage
select
count(*) as Total_Rows,
ROUND(100.0 * sum(case when InvoiceNo is null then 1 else 0 end) / count(*), 2) as Missing_InvoiceNo_Percentage,
ROUND(100.0 * sum(case when Description is null then 1 else 0 end) / count(*), 2) as Missing_Description_Percentage,
ROUND(100.0 * sum(case when CustomerID is null then 1 else 0 end) / count(*), 2) as Missing_CustomerID
from [dbo].[OnlineRetail_Raw]

-- Check Duplicate Records
select
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country,
count(*) as Duplicate_Count
from [dbo].[OnlineRetail_Raw]
group by 
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country 
having count(*) > 1 
order by Duplicate_Count desc

-- Calculate Total Exact Duplicate Rows
with DuplicateRecords as (
select
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country,
count(*) as Duplicate_Count
from [dbo].[OnlineRetail_Raw]
group by 
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country 
having count(*) > 1 
)
select 
count(*) as Duplicate_Groups,
sum(Duplicate_Count) as Total_Rows_In_Duplicate_Groups,
sum(Duplicate_Count - 1) as Actual_Extra_duplicate_Rows
from DuplicateRecords

-- Investigate a Duplicate Example
select *
from [dbo].[OnlineRetail_Raw]
where InvoiceNo = '555524'
order by StockCode, Description

-- Confirm Exact Duplicates within Invoice 555524
select
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country,
count(*) as Duplicate_Count
from [dbo].[OnlineRetail_Raw]
where InvoiceNo = '555524'
group by 
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country 
having count(*) > 1 
order by Duplicate_Count desc

-- Basic Dataset Summary 
select 
count(distinct CustomerID) as Unique_Customer,
count(distinct InvoiceNo) as Unique_Invoices,
count(distinct Country) as Unique_Countries,
min(InvoiceDate) as First_Transaction_date,
max(InvoiceDate) as Last_Transaction_Date
from dbo.OnlineRetail_Raw

-- Cancellation & Negative Transaction Analysis
select 
count(distinct case when InvoiceNo like 'C%' then InvoiceNo end) as Cancelled_Invoices ,
sum(case when InvoiceNo like 'C%' then 1 else 0 end) as Cancelled_Rows,
sum(case when Quantity < 0 then 1 else 0 end) as Negative_Quantity_Rows,
sum(case when UnitPrice < 0 then 1 else 0 end) as Negative_Price_Rows
from dbo.OnlineRetail_Raw

-- Investigate Negative Quantity Transaction
select top 20 
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country
from dbo.OnlineRetail_Raw
where Quantity < 0
order by InvoiceDate

-- Check Null Invoice Numbers
select
count(*) as Null_Invoice_Rows,
sum(case when InvoiceNo is null and quantity < 0 then 1 else 0 end) as Null_InvoiceNo_with_Negative_Quantity,
sum(case when InvoiceNo is null and Quantity >=0 then 1 else 0 end) as Null_InvoiceNo_with_Positive_Quantity
from dbo.OnlineRetail_Raw

-- Negative Quantity Breakdown
SELECT
    COUNT(*) AS Total_Negative_Quantity_Rows,

    SUM(CASE 
        WHEN InvoiceNo IS NULL THEN 1 
        ELSE 0 
    END) AS Negative_Quantity_With_Null_InvoiceNo,

    SUM(CASE 
        WHEN InvoiceNo IS NOT NULL THEN 1 
        ELSE 0 
    END) AS Negative_Quantity_With_InvoiceNo

FROM dbo.OnlineRetail_Raw
WHERE Quantity < 0;

-- 
SELECT TOP 30
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
FROM dbo.OnlineRetail_Raw
WHERE Quantity < 0
    AND InvoiceNo IS NOT NULL
ORDER BY InvoiceDate;

-- Zero UnitPrice Analysis
SELECT
    COUNT(*) AS Zero_UnitPrice_Rows,

    SUM(CASE 
        WHEN Quantity > 0 THEN 1 
        ELSE 0 
    END) AS Positive_Quantity_Zero_Price,

    SUM(CASE 
        WHEN Quantity < 0 THEN 1 
        ELSE 0 
    END) AS Negative_Quantity_Zero_Price,

    SUM(CASE 
        WHEN CustomerID IS NULL THEN 1 
        ELSE 0 
    END) AS Zero_Price_Null_CustomerID,

    SUM(CASE 
        WHEN CustomerID IS NOT NULL THEN 1 
        ELSE 0 
    END) AS Zero_Price_With_CustomerID

FROM dbo.OnlineRetail_Raw
WHERE UnitPrice = 0;

-- Investigate Zero Price Transactions with CustomerID
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
FROM dbo.OnlineRetail_Raw
WHERE UnitPrice = 0
    AND CustomerID IS NOT NULL
ORDER BY InvoiceDate;

-- The 3 Positive Quantity Rows with NULL InvoiceNo
SELECT *
FROM dbo.OnlineRetail_Raw
WHERE InvoiceNo IS NULL
    AND Quantity > 0;

-- Valid Purchase Transaction Check
SELECT
    COUNT(*) AS Total_Raw_Rows,

    SUM(
        CASE 
            WHEN CustomerID IS NOT NULL
             AND InvoiceNo IS NOT NULL
             AND Quantity > 0
             AND UnitPrice > 0
            THEN 1 
            ELSE 0 
        END
    ) AS Valid_Purchase_Rows

FROM dbo.OnlineRetail_Raw;

-- Profile the Valid Purchase Dataset
SELECT
    COUNT(*) AS Valid_Purchase_Rows,
    COUNT(DISTINCT CustomerID) AS Valid_Customers,
    COUNT(DISTINCT InvoiceNo) AS Valid_Invoices,
    COUNT(DISTINCT Country) AS Valid_Countries,
    MIN(InvoiceDate) AS First_Valid_Purchase,
    MAX(InvoiceDate) AS Last_Valid_Purchase
FROM dbo.OnlineRetail_Raw
WHERE CustomerID IS NOT NULL
    AND InvoiceNo IS NOT NULL
    AND Quantity > 0
    AND UnitPrice > 0;

-- Check Duplicates Within Valid Purchase Data
WITH DuplicateRecords AS (
    SELECT
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country,
        COUNT(*) AS Duplicate_Count
    FROM dbo.OnlineRetail_Raw
    WHERE CustomerID IS NOT NULL
        AND InvoiceNo IS NOT NULL
        AND Quantity > 0
        AND UnitPrice > 0
    GROUP BY
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS Duplicate_Groups,
    SUM(Duplicate_Count) AS Total_Rows_In_Duplicate_Groups,
    SUM(Duplicate_Count - 1) AS Actual_Extra_Duplicate_Rows
FROM DuplicateRecords;

-- Do duplicate rows change the number of customers or invoices?
WITH ValidPurchases AS (
    SELECT *
    FROM dbo.OnlineRetail_Raw
    WHERE CustomerID IS NOT NULL
        AND InvoiceNo IS NOT NULL
        AND Quantity > 0
        AND UnitPrice > 0
),
DeduplicatedPurchases AS (
    SELECT DISTINCT
        InvoiceNo,
        StockCode,
        Description,
        Quantity,
        InvoiceDate,
        UnitPrice,
        CustomerID,
        Country
    FROM ValidPurchases
)
SELECT
    (SELECT COUNT(DISTINCT CustomerID) FROM ValidPurchases) AS Customers_Before_Deduplication,
    (SELECT COUNT(DISTINCT CustomerID) FROM DeduplicatedPurchases) AS Customers_After_Deduplication,

    (SELECT COUNT(DISTINCT InvoiceNo) FROM ValidPurchases) AS Invoices_Before_Deduplication,
    (SELECT COUNT(DISTINCT InvoiceNo) FROM DeduplicatedPurchases) AS Invoices_After_Deduplication;
