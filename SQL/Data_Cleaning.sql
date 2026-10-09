-- Create the Cleaned Table
select distinct
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country
into dbo.OnlineRetail_Cleaned
from dbo.OnlineRetail_Raw
where CustomerID is not null and InvoiceNo is not null and Quantity > 0 and UnitPrice > 0 

-- Check Count of Rows of OnlineRetail_Cleaned Table 
select 
count(*) as Cleaned_Row_Count
from dbo.OnlineRetail_Cleaned

-- Validate Cleaning Rules (Check again null, negative, zero etc)
select
count(*) as Total_Cleaned_rows,
sum(case when CustomerID is null then 1 else 0 end) as Null_CustomerID,
sum(case when InvoiceNo is null then 1 else 0 end) as Null_InvoiceNo,
sum(case when Quantity <= 0 then 1 else 0 end) as Invalid_Quantity,
sum(case when UnitPrice <= 0 then 1 else 0 end) as Invalid_UnitPrice
from dbo.OnlineRetail_Cleaned

-- Final Duplicate Validation
With DuplicateCheck as ( 
select 
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country,
Count(*) as Row_count
From dbo.OnlineRetail_Cleaned
Group By 
InvoiceNo,
StockCode,
Description,
Quantity,
InvoiceDate,
UnitPrice,
CustomerID,
Country
Having count(*) > 1
)
Select
count(*) as Remaining_Duplicate_Groups
from DuplicateCheck

-- Revenue Calculation (Create Revenue Column)
Select top 10
InvoiceNo,
StockCode,
Description,
Quantity,
UnitPrice,
Quantity * UnitPrice as Revenue, 
CustomerID,
InvoiceDate
from dbo.OnlineRetail_Cleaned
