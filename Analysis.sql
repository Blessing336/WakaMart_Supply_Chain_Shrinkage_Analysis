
-- Confirm all tables

SELECT * FROM DimDate;

SELECT * FROM DimLocation;

SELECT * FROM DimProduct;

SELECT * FROM FactRetail;

=========================================================================================
-- Which Products Are Most Responsible for Shrinkage and How Much Money Are We Losing?
=========================================================================================

-- What are the top 5 products with the highest total units lost across all shipments?

WITH Product_Loss AS(
SELECT 
ProductName AS Product_Name, 
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY ProductName)

SELECT 
TOP 5 
Product_Name, 
Units_Lost
FROM Product_Loss
ORDER BY Units_Lost DESC;



-- What is the cumulative financial loss per product over the last 8 months?

WITH Loss AS (
SELECT
ProductName AS Product_Name,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost,
CAST(SUM(UnitCost * (PlannedUnits - ActualUnitsReceived)) AS DECIMAL(11,2)) AS Loss
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY ProductName)

SELECT 
Product_Name,
SUM(Loss) AS Financial_Loss 
FROM Loss
GROUP BY Product_Name
ORDER BY Financial_Loss DESC;



-- Which product have the highest average shrinkage rate across each shipment?

WITH Shrinkage_Rate AS(
SELECT
ShipmentID AS Shipment,
ProductName AS Product_Name,
PlannedUnits AS Expected_Units,
PlannedUnits - ActualUnitsReceived AS Units_Lost,
CAST((1.0 *(PlannedUnits - ActualUnitsReceived)/PlannedUnits) AS DECIMAL(3,2)) * 100 AS Shrinkage_Rate
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived),

Avg_Shrink AS(
SELECT 
Shipment,
Product_Name,
CAST(AVG(Shrinkage_Rate) AS DECIMAL(4,2)) AS Avg_Shrink_Rate,
ROW_NUMBER() OVER(PARTITION BY Shipment ORDER BY AVG(Shrinkage_Rate) DESC) AS Row_Num
FROM Shrinkage_Rate
GROUP BY Shipment, Product_Name)

SELECT 
Shipment,
Product_Name,
Avg_Shrink_Rate
FROM Avg_Shrink
WHERE Row_Num = 1;



-- What is the shrinkage-to-profit ratio for each product, and which ones are losing more than they earn?


WITH shrinkage_to_profit AS(
SELECT
ProductName AS Product_Name,
SUM(PlannedUnits) AS Expected_Units,
SUM(PlannedUnits * UnitPrice) AS Planned_Price,
SUM((PlannedUnits * UnitPrice) - (PlannedUnits * UnitCost)) AS Expected_Profit,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost,
SUM((PlannedUnits - ActualUnitsReceived) * UnitPrice) AS Loss,
CAST(SUM((PlannedUnits - ActualUnitsReceived) * UnitPrice)/SUM((PlannedUnits * UnitPrice) - (PlannedUnits * UnitCost)) AS DECIMAL(4,2)) AS Ratio
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY ProductName)

SELECT 
Product_Name,
Ratio AS Shrinkage_To_Profit_Ratio
FROM shrinkage_to_profit
WHERE Ratio >= 1
ORDER BY shrinkage_to_profit_Ratio DESC;




=========================================================================================
-- Which Locations Are Losing the Most Inventory and Is It a Regional Pattern?
=========================================================================================

-- What is the total number of units lost per receiving location?

SELECT
LocationName AS Location_Name,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
FROM FactRetail f
LEFT JOIN DimLocation l
ON l.locationID = f.ToLocationID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY LocationName
ORDER BY Units_Lost DESC;



-- Which region experienced the highest average shrinkage rate across all deliveries?

WITH Shrinkage_Rate AS(
SELECT
Region,
ShipmentID AS Shipment,
PlannedUnits - ActualUnitsReceived AS Units_Lost,
CAST((1.0 *(PlannedUnits - ActualUnitsReceived)/PlannedUnits) AS DECIMAL(3,2)) * 100 AS Shrinkage_Rate,
ROW_NUMBER() OVER(PARTITION BY Region ORDER BY CAST(1.0 *(PlannedUnits - ActualUnitsReceived)/PlannedUnits AS DECIMAL(3,2)) DESC) AS Row_Num
FROM FactRetail f
LEFT JOIN DimLocation l
ON l.LocationID = f.ToLocationID
WHERE PlannedUnits > ActualUnitsReceived),

Avg_Shrinkage_Rate_ AS(
SELECT 
Region,
AVG(Shrinkage_Rate) AS Avg_Shrinkage_Rate
FROM Shrinkage_Rate
GROUP BY Region)

SELECT TOP 1 Region 
FROM Avg_Shrinkage_Rate_
ORDER BY Avg_Shrinkage_Rate DESC;


-- Is a certain warehouse associated with severe shrinkage at destinations?


WITH Shrinkage AS(
SELECT 
LocationName AS Warehouse,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
FROM FactRetail f
LEFT JOIN DimLocation l
ON l.LocationID = f.FromLocationID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY LocationName)

SELECT TOP 1 
Warehouse
FROM Shrinkage
ORDER BY Units_Lost DESC;


-- What is the regional trend in shrinkage loss over the last 6 months?

WITH Regional_Shrinkage AS(
SELECT
Region,
DATENAME(MONTH, DispatchDate) AS Month,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost,
ROW_NUMBER() OVER(PARTITION BY Region ORDER BY MIN(DATEPART(MONTH, DispatchDate))) AS Row_Num
FROM FactRetail f
LEFT JOIN DimLocation l
ON l.LocationID = f.FromLocationID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY Region, DATENAME(MONTH, DispatchDate))

SELECT 
Region,
Month,
Units_Lost,
LAG(Units_Lost) OVER(PARTITION BY Region ORDER BY Row_Num) AS Prev_Units_Lost,
CAST(1.0*(Units_Lost - LAG(Units_Lost) OVER(PARTITION BY Region ORDER BY Row_Num))/LAG(Units_Lost) OVER(PARTITION BY Region ORDER BY Row_Num) AS DECIMAL(4,2)) * 100 AS Percent_Change
FROM Regional_Shrinkage



-- Which locations have shrinkage rates significantly above the company average?

WITH Loss AS(
SELECT
LocationName AS Location_Name,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
FROM FactRetail f
LEFT JOIN DimLocation l
ON l.LocationID = f.ToLocationID
--WHERE Units_Lost > (SELECT AVG(PlannedUnits - ActualUnitsReceived) FROM FactRetail)
GROUP BY LocationName)

SELECT
Location_Name
FROM Loss
WHERE Units_Lost > (SELECT AVG(PlannedUnits - ActualUnitsReceived) FROM FactRetail)





===========================================================================================
-- How Much Shrinkage Comes from Perishable Goods and Is It Worth Investing in Cold Chain?
===========================================================================================

-- What percentage of total shrinkage units are from perishable products?

WITH Units_Lost AS(
SELECT 
PerishableFlag AS Perishable_Flag,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived
GROUP BY PerishableFlag),

Aggregated AS(
SELECT 
MAX(CASE WHEN Perishable_Flag = 'Yes' THEN Units_Lost END) AS Perishable_Loss,
SUM(Units_Lost) AS Units_Lost
FROM Units_Lost)

SELECT 
CAST((1.0*Perishable_Loss)/Units_Lost AS DECIMAL(4,2)) * 100 AS Perishable_Percent
FROM Aggregated



-- What is the monthly financial loss from perishables compared to non-perishables?
 
WITH Perishables AS(
SELECT 
PerishableFlag AS Perishable_Flag,
ProductName AS Product_Name,
(PlannedUnits - ActualUnitsReceived) * UnitPrice AS Financial_Loss
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived)

SELECT
Perishable_Flag,
SUM(Financial_Loss) AS Financial_Loss
FROM Perishables
GROUP BY Perishable_Flag




-- Which perishable category account for the highest shrinkage cost?

WITH Perishable AS(
SELECT 
PerishableFlag AS Perishable_Flag,
ProductName AS Product_Name,
Category,
PlannedUnits - ActualUnitsReceived AS Units_Lost,
(PlannedUnits - ActualUnitsReceived) * UnitPrice AS Financial_Loss
FROM FactRetail f
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived),

Category_Financial_Loss AS(
SELECT
Category,
Perishable_Flag,
CAST(SUM(Financial_Loss) AS DECIMAL(13,2)) AS Total_Financial_Loss
FROM Perishable
WHERE Perishable_Flag = 'Yes'
GROUP BY Category, Perishable_Flag)

SELECT 
TOP 1 
Category
FROM Category_Financial_Loss
WHERE Perishable_Flag = 'Yes'


-- Are there specific routes or locations where perishable shrinkage consistently spikes?

WITH Shrinkage AS(
SELECT 
PerishableFlag,
fl.LocationName AS From_Location,
tl.LocationName AS To_Location,
SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
FROM FactRetail f
LEFT JOIN DimLocation fl
ON fl.LocationID = f.FromLocationID
LEFT JOIN DimLocation tl
ON tl.LocationID = f.ToLocationID
LEFT JOIN DimProduct p
ON p.ProductID = f.ProductID
WHERE PlannedUnits > ActualUnitsReceived AND PerishableFlag = 'Yes'
GROUP BY PerishableFlag, FromLocationID, ToLocationID, fl.LocationName,tl.LocationName)

SELECT 
TOP 1 
From_Location,
To_Location
FROM Shrinkage
ORDER BY Units_Lost DESC;



