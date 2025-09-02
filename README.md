# Problem Statement

**WakaMart,** a leading retail and distribution company in Nigeria, launched a **shrinkage analysis** project to **investigate losses caused by under-delivered and missing inventory across its nationwide operations**. The project was initiated in response to rising product-level losses, route-based inefficiencies, and warehouse inconsistencies that have significantly impacted the company’s profitability and logistics efficiency between May 2024 and December 2024.

The project focuses on the following Key Performance Indicators (KPIs); **Total Financial Shrinkage (₦)** across all products and locations, **Shrinkage Rate (%)** by region and location (planned vs actual units), **Units Lost** per Product and Top-Shrinking SKUs, **Warehouse and Route-Based** Shrinkage Patterns, and **Perishable vs Non-Perishable** Shrinkage Contribution. 

These insights will help the **Operations team** prioritize corrective actions on high-loss SKUs and supply routes,and reassess inventory control practices and distribution planning.

<br/>

# Business Objectives

The overall objective of this project is to **identify, quantify, and reduce product shrinkage** across WakaMart’s supply chain, using insights to support the Operations Team in implementing high-impact, evidence-based improvements in distribution and inventory control.

To achieve this, three Key Business Questions were explored and their sub-components:

**1. Which Products Are Most Responsible for Shrinkage, and How Much Money Are We Losing?**

* 1.1: Which products experienced the highest total units lost across all shipments?

* 1.2: What is the cumulative financial loss per product over the last 8 months?

* 1.3: Which products are generating negative margins due to shrinkage, losing more than they earn?

**2. Which Locations Are Losing the Most Inventory, and Is It a Regional Pattern?**

* 2.1: Which destination locations recorded the most under-delivered units?

* 2.2: Which region experienced the highest average shrinkage rate across all deliveries?

* 2.3: Which warehouse is associated with the highest outbound shrinkage volume?

* 2.4: How has shrinkage changed over time across regions, and where is it worsening or improving?

**3. How Much Shrinkage Comes from Perishable Goods, and Is It Worth Investing in Cold Chain?**

* 3.1: What percentage of total shrinkage units are from perishable products?

* 3.2: What is the monthly financial loss from perishables compared to non-perishables?

* 3.3: Which perishable categories account for the highest shrinkage cost?

* 3.4: Are there specific routes or locations where perishable shrinkage consistently spikes?

<br/>

# Data Structure

This analysis is powered by a logistics dataset from WakaMart’s retail and operations, spanning the period from May 2024 to December 2024. The dataset consists of four key relational tables:

1. **FactRetail**: This is the central fact table that contains the logistics records of product movements, from warehouse dispatch to store receipt. Each row represents a single shipment of a specific product between two locations, along with the planned and actual quantities delivered.

Metrics Calculated from This Table: Units_Lost (PlannedUnits - ActualUnitsReceived), Shrinkage Rate ((Units_Lost / PlannedUnits) * 100), Time-based trends (monthly breakdowns by DispatchDate), and Route-level losses (FromLocationID to ToLocationID).

2. **DimProduct**: This is the product table used to enrich the fact table with category-level product data. Each row represents a unique product stocked by WakaMart.

Metrics Calculated from This Table: Aggregated shrinkage by ProductName, Category-level shrinkage cost breakdowns, and Margin loss analysis per product (Profit - Shrinkage Loss)

3. **DimLocation**: This is the location dimension table used to provide names for warehouse and store IDs.

Metrics Calculated from This Table: Units lost by receiving and shipping locations, Regional trend analysis of shrinkage volume and rates, and Loss patterns by route

4. **DimDate**: This table contains columns like date, month, quarter, and Day of the week.


<br/>

# Executive Summary

Between May 2024 and December 2025, **WakaMart recorded a total shrinkage loss of over ₦3.95 billion**, driven primarily by under-delivery, and operational inefficiencies. The worst-hit product was **Fonio (Acha), with losses nearing ₦146 million**, while **Dairy led all perishables with ₦1.11 billion**, accounting for **38%** of all perishable shrinkage costs.

**Rivers Region**, especially via **Buguma Warehouse and Enugu Retail Park, showed consistently high and worsening trends**. The Buguma–Enugu route alone recorded 48,571 units of perishable shrinkage, **81% more than any other route**, pointing to severe issues in cold chain reliability and transit handling. **Lagos also suffered the highest average shrinkage rate (16.13%)**, and **Sorghum and Abakaliki Rice turned out to be unprofitable**, losing **₦1.16** for every **₦1** of projected profit.

WakaMart must urgently **install and audit CCTV footage on loading bays to monitor discrepancies**. Invest in targeted cold-chain stabilization and route-level oversight, especially for perishable shipments from Buguma to Enugu. This should include **temperature-controlled transport, enforced loading protocols, and audit mechanisms at handoff points**.

<br/>

# Key Findings

Identifying what products are at the centre of the shrinkage crisis. Understanding product-level impact helps us trace the first layer of inefficiency: the demand-supply mismatch that turns profit into loss.

## 1. Where Is the Shrinkage Bleeding Us the Most? (Product-Level Analysis)

### 1.1 Core products like Fonio (Acha), Agege Bread, Mallam Dairy, and Pepsi are losing thousands of units

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

In 8 months, **Fonio (Acha)** recorded the **highest inventory shrinkage** at Wakamart with **5,733 units lost**. This was followed by **Agege Bread with 5,278 units**, and **Mallam Dairy with 5,254 units**. **Pepsi Bottle ranked fourth, losing 5,063 units**, while **Basmati Rice (5kg) completed the top five with 5,012 units lost**. These five products alone account for **26,340 units** of confirmed shrinkage, making them critical loss drivers.

These product lines need urgent review in terms of loading processes, storage protocols, and cross-check verification.

<br/>

### 1.2 Consequently, what we lose in stock, we lose tenfold in revenue. Fonio alone cost Wakamart nearly ₦146 million in shrinkage. These losses are no longer operational but financial

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


3 of top 5 products with the highest total units lost made it to the top 5 products with the highest cumulative financial loss. **Fonio (Acha)** caused the highest financial loss at Wakamart, with shrinkage losses reaching **almost ₦146 million**. **Mallam Dairy followed closely, with losses of over ₦136 million**, and **Fayo Dairy trailed slightly behind at just over ₦120 million**. Additional high-loss items include **Abakaliki Rice, with losses nearing ₦120 million**, and **Coaster Biscuit, which generated losses of almost ₦118 million**.

Meanwhile, some products accrued minimal financial impact compared to the top-tier loss items. **Ram Meat and Gala Sausage Roll** contributed losses of under **₦10 million and ₦9 million** respectively.

<br/>

### 1.3 ...Because shrinkage now reverses profits. Some products, like Sorghum and Abakaliki Rice, have flipped into negative margin territory. For every ₦1 in expected profit, we lose ₦1.16

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
        Loss,
        Expected_Profit,
        Ratio AS Shrinkage_To_Profit_Ratio
        FROM shrinkage_to_profit
        WHERE Ratio >= 1
        ORDER BY shrinkage_to_profit_Ratio DESC;

There are products where the financial loss from shrinkage exceeded the expected profit and **Sorghum** led this list with a **shrinkage-to-profit ratio of 1.16**, indicating that for every ₦1 of expected profit, ₦1.16 was lost to shrinkage **(a net negative margin of 16%)**. Similarly, **Abakaliki Rice also had a 1.16 ratio, with shrinkage losses reaching ₦140.2 million against a potential profit of only ₦120.8 million**.

Even widely distributed items like **Agege Bread and Smoked Turkey** showed negative returns, with losses just **2% to 4% higher** than expected earnings.

This calls for **immediate reviews of handling, packaging, vendor quality, or internal theft** linked to these products.

<br/>

<br/>

## 2. Which Locations Are Losing the Most Inventory and Is It a Regional Pattern?

After identifying the top culprits by product, we turn to where shrinkage is most concentrated. Our lens widens to detect if certain stores, warehouses, or even whole regions are systematically leaking stock.

### 2.1 With nearly 150,000 units lost, Enugu Retail Park is at the heart of our product loss

        SELECT
        LocationName AS Location_Name,
        SUM(PlannedUnits - ActualUnitsReceived) AS Units_Lost
        FROM FactRetail f
        LEFT JOIN DimLocation l
        ON l.locationID = f.ToLocationID
        WHERE PlannedUnits > ActualUnitsReceived
        GROUP BY LocationName
        ORDER BY Units_Lost DESC;

**Enugu Retail Park recorded the highest number of under-delivered or lost units at 149,579 units**, making it Wakamart’s most affected receiving location by a significant margin. When compared to the next highest location, **Kano Market Square, which recorded 81,687 units lost, Enugu’s loss volume was 83% higher**. The difference was similarly large when compared to **Ikeja Supermart, which recorded 80,588 units, reflecting an 86% increase**.

Other major receiving points like **Port Harcourt Mall and Abuja Urban Shop** experienced shrinkage of **75,945 units and 75,565 units** respectively, both just over half of what was lost at Enugu.

<br/>

### 2.2 However, Enugu may lose the most in bulk, Lagos is losing faster in proportion with the highest shrinkage rate of 16.13%

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

While **Lagos** did not record the highest number of units lost in absolute terms, its consistently higher shrinkage rate indicates a more **systemic issue** with delivery accuracy or product handling per shipment, rather than one-off losses in volume.

**Lagos recorded the highest average shrinkage rate at 16.13%**. Compared to **Kano**, which had a **shrinkage rate of 15.29%**, Lagos experienced a **5.5%** higher rate of shrinkage. When compared to **Enugu (15.19%)**, the difference was **6.2%**, and when compared to **Rivers**, which had the **lowest rate at 15.11%**, Lagos's shrinkage rate was **6.7%** higher.

<br/>

### 2.3 ...But upstream issues are just as critical. Buguma Warehouse accounts for over 225,000 units lost on outbound shipments (nearly 3x higher than Apapa Warehouse)

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
        Location_Name
        FROM Shrinkage
        ORDER BY Units_Lost DESC;


Products dispatched from **Buguma Warehouse** are disproportionately prone to shrinkage by the time they reach retail destinations. Buguma's shrinkage is **43.3%** higher than that of **Kano Depot**, which lost **157,252 units**, and a staggering **179.9% more than Apapa Warehouse**, which recorded only **80,588 units lost**.

<br/>

### 2.4 While Lagos and Kano show ups and downs in Regional Trends, Rivers Region’s shrinkage is steadily rising

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


Over the last 8 months (May to December 2024), each region in Wakamart's distribution network has displayed distinct and important trends in **shrinkage loss**.

**Kano Region** began with **21,596 units lost** in **May** and ended with **18,712 units** in **December**, indicating an **overall decline**. The **most dramatic drop** occurred between **May and June, with a 20% decrease**. However, inconsistency followed, with fluctuations including a **17%** rise in July and a **7%** rebound in November.

**Lagos Region** showed a similar volatile pattern. Starting at **11,696 units** lost in **May** but closed **December** with **11,028 units lost**, nearly back to its May figures. This region experienced its sharpest improvement in **June, dropping 26% to 8,670**.

**Rivers Region**, however, showed the **highest and most consistent unit losses overall**. Starting from **27,233 units in May**, it **peaked** in **November at 30,463 units**. The largest single-month improvement was in **December, with a 15% decrease, dropping losses to 26,020 units**. Still, this was the highest cumulative shrinkage of all three regions, and the **only region where the overall losses increased over time**.

<br/>
We've now mapped out what products are lost and where the damage is concentrated. But a key business question remains: Are our perishables worth saving, or should we rethink the cold chain investment?
<br/>

## 3. How Much Shrinkage Comes from Perishable Goods and Is It Worth Investing in Cold Chain?
Having exposed the worst-hit products and locations, we now turn to the most sensitive category in retail: perishables. The final act questions whether we should pour more into preservation—or cut our losses.
### 3.1 Perishables represent a third of total unit loss at 32%

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

Nearly one in every three lost units is a perishable item as perishable products accounted for **32% of the total shrinkage units across all Wakamart locations**, while **non-perishable goods represent the remaining 68%**.

<br/>

### 3.2 ...But despite their volume, perishables caused only 28% of financial shrinkage. The majority loss comes from non-perishables

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


**Perishable products** accounted for approximately **₦2.95 billion** in financial losses, while non-perishables incurred a much steeper loss of nearly **₦7.51 billion**. This means that **perishables made up only 28%** of the total financial shrinkage, whereas **non-perishables contributed a dominant 72% of the total loss**. The financial gap between the two categories stands at **44%**, with non-perishables causing over ₦4.5 billion more in losses than their perishable products.

<br/>

### 3.3 ...And Among perishables, dairy stands out at ₦1.11 billion lost, accounting for 38% of perishable loss

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

**Dairy products** lead in shrinkage financial loss with a loss of over **₦1.11 billion**. Following closely after Dairy is the **Bakery category**, which recorded approximately **₦736.86 million in shrinkage costs**, and **Meat**, with losses nearing **₦625.96 million**. In contrast, **Frozen Foods and Beverages** trail behind with **₦384.65 million and ₦92.05** million in losses respectively, placing **Dairy’s** loss at over **1,108%** higher than **Beverages** and **189%** higher than **Frozen Foods**.

<br/>

### 3.4 Buguma Warehouse to Enugu Retail Park alone experiences 81% more perishable shrinkage than any other

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

The **Buguma Warehouse to Enugu Retail Park** route stands out as the most problematic pathway for perishable product losses, with **48,571 units lost**, a volume that surpasses all other major routes by a significant margin. 

In comparison, the **Kano Depot to Kano Market Square** and **Kano Depot to Abuja Urban Shop** routes recorded **26,810** and **25,664** units lost respectively, while the **Apapa Warehouse to Ikeja Supermart** and **Buguma Warehouse to Port Harcourt Mall** routes followed closely with **24,442** and **24,313** units lost.


<br/>

<br/>

# Recommendations

## 1. Which Products Are Most Responsible for Shrinkage and How Much Money Are We Losing?
#### 1.1 Fonio (Acha), Agege Bread, Mallam Dairy, Pepsi Bottle, and Basmati Rice Are High-Shrinkage Products

* Conduct end-to-end product flow audits on these five items from dispatch to shelf.

* Tag each SKU with a high-risk flag in Wakamart’s ERP system to activate stricter loss monitoring.

#### 1.2 Fonio (₦146M loss) and Mallam Dairy Are Costing the Business Significantly

* Introduce unit-level barcode tracking for dairy products and Fonio to improve traceability.

#### 1.3 Sorghum and Abakaliki Rice Have Net-Negative Margins

* Evaluate whether to delist or repackage the products for better inventory control.

## Which Locations Are Losing the Most Inventory and Is It a Regional Pattern?

#### 2.1 Enugu Retail Park Has the Highest Unit Loss (149,579 Units)

* Enforce double-verification protocols.

* Create a weekly loss report specific to Enugu and escalate any irregularities above 5% deviation.

#### 2.2 Lagos Has the Highest Average Shrinkage Rate (16.13%)

* Perform forecast vs. actual delivery reconciliation weekly to detect planning gaps.

* Review last-mile partner contracts for Lagos and consider replacements for underperformers.

#### 2.3 Buguma Warehouse Accounts for 225,524 Units Lost

* Conduct a full-scale forensic audit of Buguma Warehouse (routes, personnel, SOPs).

* Install and audit CCTV footage on loading bays to monitor discrepancies.

#### 2.4 Rivers Region Is the Only One with Increasing Shrinkage Over Time

* Mandate weekly shrinkage performance reviews at all Rivers State locations.

## How Much Shrinkage Comes from Perishable Goods and Is It Worth Investing in Cold Chain?
#### 3.1 Perishables Account for 32% of Units Lost

* Train floor staff on FIFO and stock rotation best practices for perishables.

#### 3.2 Perishables Represent 28% of Financial Loss, Non-Perishables at 72%

* Install and audit CCTV footage on loading bays to monitor discrepancies.

#### 3.3 Dairy Accounts for ₦1.11 Billion in Losses (38% of Perishable Losses)

* Prioritise closed-loop chilled transport for dairy logistics above all other perishables.

#### 3.4 Buguma–Enugu Route Has 81% More Perishable Shrinkage Than Other Routes

* Immediately review driver logs, vehicle conditions, and time delays on this route.












































