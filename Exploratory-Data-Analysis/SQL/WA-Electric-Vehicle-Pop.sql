-- View first 1,000 rows.
SELECT TOP 1000 *
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data;


-- View each unique state and their number of occurrences.
SELECT State, COUNT(State) as Num_Observations
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
GROUP BY State
ORDER BY Num_Observations desc;

-- * The dataset primarily consists of Washington observations (153,491) followed by California (91), so we'll be focusing on Washington.

-- Filter by WA and aggregate EV make to view frequency counts of each.
SELECT Make, COUNT(Make) as Make_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE State = 'WA'
GROUP BY State, Make
ORDER BY Make_Count DESC

-- * Tesla is by far the most common manufacturer with 69,444 counts followed by Nissan with 13,633, then Chevrolet, Ford, and BMW. These are the top 5.

-- Filter by WA counties and aggregate EV make to view frequency counts of each manufacturer by county.
SELECT Make, County, COUNT(Make) as Make_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE State = 'WA'
GROUP BY County, Make
ORDER BY Make_Count DESC

/* Interestingly, more than half of Tesla occurrences seen previously are within the King county (39,710) followed by Snohomish (9279).
*  Likely due to King county and Seattle both being the most populous country and city respectively.
*  But, it's worth investigating this further.
*/

-- Find the frequency of each Washington county.
SELECT County, COUNT(County) as County_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE State = 'WA'
GROUP BY County
ORDER BY County_Count DESC

/* King county has 80,637 occurrences followed by Snohomish with 17,727.
*  Based on what we saw earlier, it makes sense that a majority of Tesla occurrences are within the King county as it is more likely with having the highest number of observations.
*  With that being said, the proportions of Tesla observations by total observations are quite similar: 49% vs 52% with King as the former and Snohomish as the latter.
*/

-- Group by make, WA cities, and counties and view manufacturer counts
SELECT Make, City, County, COUNT(Make) as Make_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE State = 'WA'
GROUP BY City, County, Make
ORDER BY Make_Count DESC

--

-- Using CTE to look at electric vehicle types and their associated frequency; also calculating proportion of each EV type
WITH EV_Type_Counts (EV_Type, EV_Counts)
AS
(
SELECT [Electric Vehicle Type], COUNT([Electric Vehicle Type])
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
GROUP BY [Electric Vehicle Type]
),
EV_Total (Total)
AS
(
SELECT COUNT([Electric Vehicle Type])
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
)
SELECT EV_Type, EV_Counts, Total, ROUND(CAST(EV_Counts as float)/CAST(Total as float), 3) * 100 as Percentage
FROM EV_Type_Counts, EV_Total

-- * Plug-in Hybrid Electric Vehicles (PHEVs) compose 22.4% and Battery Electric Vehicles (BEVs) compose the remaining 77.6%

-- View counts of each EV type by model year
SELECT [Model Year], [Electric Vehicle Type], COUNT([Electric Vehicle Type]) AS EV_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
GROUP BY [Model Year], [Electric Vehicle Type]
ORDER BY [Model Year] DESC

SELECT COUNT([Electric Range])
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE [Electric Range] > 0

-- * There are 80,969 observations where electric range was recorded which is a little over half of the total data, but still a decent amount that we can use.

SELECT COUNT([Base MSRP])
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE [Base MSRP] > 0

-- * Only 3,431 observations where MSRP was recorded.

-- Average electric range by make and frequency
GO
CREATE VIEW Avg_Electric_Range_By_Make_Frequency AS
SELECT Make, AVG([Electric Range]) AS Electric_Range_Avg, COUNT(Make) AS Make_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Data
WHERE [Electric Range] > 0
	AND State = 'WA'
GROUP BY Make
GO


-- Viewing second table
SELECT *
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County

-- Converting Date column to `date` data type.
UPDATE MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
SET Date = CONVERT(date, Date)

-- Extract month and year from Date column to create two new columns containing each.
ALTER TABLE MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
ADD
Month tinyint,
Year int

UPDATE MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
SET Month = Month(Date), Year = Year(Date)

-- View counts of all states
SELECT State, COUNT(State) as State_Count
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
GROUP BY State
ORDER BY State_Count DESC

/* Washington has the highest observation count like the previous table at 6,318 followed by California at 1,428.
*  Both tables focus on Washington, so we can create some interesting combinations of data here using joins which we will do later.
*/

-- Order by converted Date column to view observations in chronological order.
SELECT *
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
WHERE State = 'WA'
ORDER BY Date


-- View average percent electric vehicles by year
SELECT Year, AVG([Percent Electric Vehicles]) * 100 AS Avg_Percent_EV
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
WHERE State = 'WA'
GROUP BY Year
ORDER BY Year DESC

/* We can see significant increases in the percentage of electric vehicles ranging from 2017 to 2023.
*  Each year, the average percentage of electric vehicles in Washington increments more than the previous year.
*/

-- View BEV and PHEV sum counts by year and calculate percentages
DROP TABLE IF EXISTS #EV_Counts
CREATE TABLE #EV_Counts (
Year int,
BEVs_Total int,
PHEVs_Total int,
EV_Total int
)

INSERT INTO #EV_Counts
SELECT
	Year,
	SUM([Battery Electric Vehicles (BEVs)]),
	SUM([Plug-In Hybrid Electric Vehicles (PHEVs)]),
	SUM([Battery Electric Vehicles (BEVs)]) + SUM([Plug-In Hybrid Electric Vehicles (PHEVs)])
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
WHERE State = 'WA'
GROUP BY Year

SELECT
	*,
	CAST(BEVs_Total as float) / CAST(EV_Total as float) * 100 AS BEVs_Percentage,
	CAST(PHEVs_Total as float) / CAST(EV_Total as float) * 100 as PHEVs_Percentage
FROM #EV_Counts
ORDER BY Year DESC

-- * BEVs increase in proportion steadily while PHEVs decrease steadily between 2017 to 2023

-- View EV totals compared to non-EV totals
GO
CREATE VIEW EV_Vs_NonEV_Totals_Yearly AS
SELECT Year, SUM([Electric Vehicle (EV) Total]) AS EV_Total, SUM([Non-Electric Vehicle Total]) AS Non_EV_Total
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
WHERE State = 'WA'
GROUP BY Year
GO

/* As expected, the number of electric vehicles rises over the years in Washington.
*  Interestingly, our dataset only contains 2023 data up to September, but the amount of electric vehicles already nearly surpasses 2022.
*  We can expect 2023 to be the highest total of electric vehicles in Washington as more data comes in.
*/

-- Rolling electric vehicle and non-electric vehicle totals and average percentage of electric vehicles by year and month
GO
CREATE VIEW Rolling_Vehicle_Totals_By_Year_Month AS
SELECT
	Year,
	Month,
	SUM([Electric Vehicle (EV) Total]) OVER (PARTITION BY Year, Month) AS EV_Rolling_Total,
	SUM([Non-Electric Vehicle Total]) OVER (PARTITION BY Year, Month) AS Non_EV_Rolling_Total,
	AVG(([Percent Electric Vehicles]) * 100) OVER (PARTITION BY Year, Month) AS AVG_EV_Rolling_Total
FROM MyDatabase.dbo.Electric_Vehicle_Population_Size_History_By_County
WHERE State = 'WA'
GO

/* Steady incline of non-electric vehicle counts until July 2021 when the number of non-electric vehicle counts steady declines instead!
*  From July 2021 to September 2023, the total of non-electric vehicles drops by 31 million.
*/

-- Previously created views for use in data visualizations later.

SELECT * FROM EV_Vs_NonEV_Totals_Yearly
ORDER BY Year DESC

SELECT * FROM Avg_Electric_Range_By_Make_Frequency
ORDER BY Make_Count DESC

SELECT * FROM Rolling_Vehicle_Totals_By_Year_Month
ORDER BY 1