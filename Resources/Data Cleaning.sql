-- Use WakaMart Retail Database

USE "WakaMart Retail";

-- Inspect tables

SELECT * FROM FactRetail;

SELECT * FROM DimDate;

SELECT * FROM DimLocation;

SELECT * FROM DimProduct;




-- Find the completeness in Columns of FactRetail

SELECT * FROM FactRetail;

SELECT 'Shipment' AS [Columns], CAST(SUM(100.0 * CASE WHEN ShipmentID IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Percent_Complete FROM FactRetail
UNION
SELECT 'Product', CAST(SUM(100.0 * CASE WHEN ProductID IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ProductID FROM FactRetail
UNION
SELECT 'FLocation',CAST(SUM(100.0 * CASE WHEN FromLocationID IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ShipmentID FROM FactRetail
UNION
SELECT 'TLocation', CAST(SUM(100.0 * CASE WHEN ToLocationID IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ProductID FROM FactRetail
UNION
SELECT 'Dispatch',CAST(SUM(100.0 * CASE WHEN DispatchDate IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ShipmentID FROM FactRetail
UNION
SELECT 'Received', CAST(SUM(100.0 * CASE WHEN ReceivedDate IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ProductID FROM FactRetail
UNION
SELECT 'Planned',CAST(SUM(100.0 * CASE WHEN PlannedUnits IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ShipmentID FROM FactRetail
UNION
SELECT 'Actual', CAST(SUM(100.0 * CASE WHEN ActualUnitsReceived IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ProductID FROM FactRetail
UNION
SELECT 'Note',CAST(SUM(100.0 * CASE WHEN NoteText IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ShipmentID FROM FactRetail
UNION
SELECT 'Target', CAST(SUM(100.0 * CASE WHEN TargetTransitDays IS NOT NULL THEN 1 END) /COUNT(*) AS DECIMAL (10,2)) AS Nulls_ProductID FROM FactRetail


SELECT DISTINCT TargetTransitDays FROM FactRetail;


-- Fix Nulls in ReceivedDate Column by setting ReceivedDate column as TargetTransitDays + DispatchDate


UPDATE FactRetail
SET ReceivedDate =
CASE WHEN ReceivedDate IS NULL THEN DATEADD(DAY, TargetTransitDays, DispatchDate) ELSE ReceivedDate END
FROM FactRetail


-- Deduplicate (We have no duplicate in FactRetail)

SELECT *,
ROW_NUMBER() OVER(PARTITION BY ShipmentID, ProductID, FromLocationID, ToLocationID, DispatchDate, ReceivedDate, PlannedUnits,
ActualUnitsReceived, NoteText, TargetTransitDays ORDER BY ShipmentID) AS Row_Num 
FROM FactRetail;


-- Standardize columns in FactRetail

SELECT DISTINCT ProductID FROM FactRetail;


UPDATE FactRetail
SET ProductID =
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(ProductID, '.', ''),',',''),'@',''),'!',''),'$',''),'#',''),'/',''),'*',''),':',''),';','')
FROM FactRetail;


-- set ActualUnitsReceived = PlannedUnits where ActualUnitsReceived IS NULL

UPDATE FactRetail
SET ActualUnitsReceived = PlannedUnits
WHERE ActualUnitsReceived IS NULL;

-- Removed rows where FromLocationID IS NULL

DELETE FROM FactRetail
WHERE FromLocationID IS NULL


-- create function to set texts in notetext column to propercase
CREATE FUNCTION dbo.Propercase (@input nvarchar(max))
RETURNS nvarchar(max)
AS
BEGIN
	DECLARE @index int = 1;
	DECLARE @output nvarchar(max) = '';
	DECLARE @char char(1) = '';
	DECLARE @prevchar char(1) = ' ';

	WHILE @index <= Len(@input)
	BEGIN
		SET @char =SUBSTRING(@input, @index, 1);
		IF @prevchar = ' '
			SET @output += UPPER(@char);
		ELSE
			SET @output += LOWER(@char);
		SET @prevchar = @char;
		SET @index += 1;
	END
	RETURN @output;
END

UPDATE FactRetail
SET NoteText =
dbo.Propercase(NoteText);


UPDATE FactRetail
SET ToLocationID =
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(ToLocationID, '.', ''),',',''),'@',''),'!',''),'$',''),'#',''),'/',''),'*',''),':',''),';','')
FROM FactRetail;



UPDATE FactRetail
SET NoteText =
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(NoteText, '.', ''),',',''),'@',''),'!',''),'$',''),'#',''),'/',''),'*',''),':',''),';','')
FROM FactRetail;




======================================
-- Clean DimProduct Table
======================================

SELECT * FROM DimProduct

SELECT DISTINCT ProductName FROM DimProduct

UPDATE DimProduct
SET ProductName =
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(ProductName, '.', ''),',',''),'@',''),'!',''),'$',''),'#',''),'/',''),'*',''),':',''),';','')
FROM DimProduct;

UPDATE DimProduct
SET Category =
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(
REPLACE(Category, '.', ''),',',''),'@',''),'!',''),'$',''),'#',''),'/',''),'*',''),':',''),';','')
FROM DimProduct;

-- standardize texts in category column

UPDATE DimProduct
SET Category =
dbo.Propercase(Category);


-- convert UnitCost and UnitPrice to decimal

UPDATE DimProduct
SET UnitCost = CAST(UnitCost AS DECIMAL(8,2))
FROM DimProduct;

UPDATE DimProduct
SET UnitPrice = CAST(UnitPrice AS DECIMAL(8,2))
FROM DimProduct;

-- remove trailing spaces in PerishableFlag column

UPDATE DimProduct
SET PerishableFlag =
TRIM(PerishableFlag)
FROM DimProduct;



----------------------------------------------------------- DATA CLEANING DONE ------------------------------------------------------------

