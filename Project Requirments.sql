---Req 1
-- Drop the category_counts table if it exists
IF OBJECT_ID('dbo.category_counts', 'U') IS NOT NULL 
DROP TABLE dbo.category_counts;

-- Create the category_counts table
SELECT
  customer_id,
  category_name,
  COUNT(*) AS rental_count,
  MAX(rental_date) AS latest_rental_date
INTO category_counts
FROM complete_joint_dataset_with_rental_date
GROUP BY
  customer_id,
  category_name;

SELECT *
FROM category_counts
WHERE customer_id = 1
ORDER BY rental_count DESC;


IF OBJECT_ID('dbo.total_counts', 'U') IS NOT NULL 
DROP TABLE dbo.total_counts;

-- Create the total_counts table
SELECT
  customer_id,
  SUM(rental_count) AS total_rental_count
INTO total_counts
FROM category_counts
GROUP BY customer_id;

-- Profile just the first 5 customers sorted by ID as an illustration
SELECT *
FROM total_counts
WHERE customer_id <= 5
ORDER BY customer_id;

-- Drop the top_categories table if it exists
IF OBJECT_ID('tempdb..#top_categories', 'U') IS NOT NULL 
DROP TABLE #top_categories;

-- Create the top_categories table
WITH ranked_cte AS (
  SELECT
    customer_id,
    category_name,
    rental_count,
    DENSE_RANK() OVER (
      PARTITION BY customer_id
      ORDER BY 
        rental_count DESC,
        latest_rental_date DESC,
        category_name
    ) AS category_rank
  FROM category_counts
)
SELECT *
INTO #top_categories
FROM ranked_cte
WHERE category_rank <= 2;

-- Inspect the first 3 customer_id (showing the top 6 rows)
SELECT TOP 6 *
FROM #top_categories
ORDER BY customer_id, category_rank;
 


 ---Req 2

 IF OBJECT_ID('tempdb..#film_counts', 'U') IS NOT NULL 
DROP TABLE #film_counts;

-- Create the film_counts table
SELECT DISTINCT
  film_id,
  title,
  category_name,
  COUNT(*) OVER (
    PARTITION BY film_id
  ) AS rental_count
INTO #film_counts
FROM complete_joint_dataset_with_rental_date;

-- Inspect the first 5 rows from the film_counts table
SELECT TOP 5 *
FROM #film_counts;


-- Drop the category_film_exclusions table if it exists
IF OBJECT_ID('tempdb..#category_film_exclusions', 'U') IS NOT NULL 
DROP TABLE #category_film_exclusions;

-- Create the category_film_exclusions table
SELECT DISTINCT
  customer_id,
  film_id
INTO #category_film_exclusions
FROM complete_joint_dataset_with_rental_date;

-- Inspect the first 10 rows from the category_film_exclusions table
SELECT TOP 10 *
FROM #category_film_exclusions;


--create 3 top category film recommendations for the top 2 categories

IF OBJECT_ID('tempdb..#top_categories', 'U') IS NOT NULL 
DROP TABLE #top_categories;

WITH ranked_cte_top_categories AS (
  SELECT
    customer_id,
    category_name,
    rental_count,
    DENSE_RANK() OVER (
      PARTITION BY customer_id
      ORDER BY rental_count DESC, latest_rental_date DESC, category_name
    ) AS category_rank
  FROM category_counts
)
SELECT *
INTO #top_categories
FROM ranked_cte_top_categories
WHERE category_rank <= 2;

-- Create the film_counts temporary table
IF OBJECT_ID('tempdb..#film_counts', 'U') IS NOT NULL 
DROP TABLE #film_counts;

SELECT DISTINCT
  film_id,
  title,
  category_name,
  COUNT(*) OVER (
    PARTITION BY film_id
  ) AS rental_count
INTO #film_counts
FROM complete_joint_dataset_with_rental_date;

-- Create the category_film_exclusions temporary table
IF OBJECT_ID('tempdb..#category_film_exclusions', 'U') IS NOT NULL 
DROP TABLE #category_film_exclusions;

SELECT DISTINCT
  customer_id,
  film_id
INTO #category_film_exclusions
FROM complete_joint_dataset_with_rental_date;

-- Drop the top_category_recommendations table if it exists
IF OBJECT_ID('tempdb..#top_category_recommendations', 'U') IS NOT NULL 
DROP TABLE #top_category_recommendations;

-- Create the top_category_recommendations table
WITH ranked_cte AS (
  SELECT
    tc.customer_id,
    tc.category_name,
    tc.category_rank,
    fc.film_id,
    fc.title,
    fc.rental_count,
    DENSE_RANK() OVER (
      PARTITION BY 
        tc.customer_id,
        tc.category_rank
      ORDER BY
        fc.rental_count DESC,
        fc.title
    ) AS reco_rank
  FROM #top_categories AS tc
  INNER JOIN #film_counts AS fc
    ON tc.category_name = fc.category_name
  WHERE NOT EXISTS (
    SELECT 1
    FROM #category_film_exclusions AS cfe
    WHERE
      cfe.customer_id = tc.customer_id
      AND
      cfe.film_id = fc.film_id
  )
)
SELECT *
INTO #top_category_recommendations
FROM ranked_cte
WHERE reco_rank <= 3;

-- Inspect the top category recommendations
SELECT *
FROM #top_category_recommendations;


SELECT *
FROM #top_category_recommendations
WHERE customer_id = 1
ORDER BY category_rank, reco_rank;


---req 3

IF OBJECT_ID('tempdb..#average_category_count', 'U') IS NOT NULL 
DROP TABLE #average_category_count;

-- Create the average_category_count table
SELECT
  category_name,
  FLOOR(AVG(rental_count)) AS avg_rental_count
INTO #average_category_count
FROM category_counts
GROUP BY category_name;

SELECT *
FROM #average_category_count
ORDER BY category_name;


--calculate the percentile values

IF OBJECT_ID('tempdb..#top_categories', 'U') IS NOT NULL 
DROP TABLE #top_categories;

WITH ranked_cte_top_categories AS (
  SELECT
    customer_id,
    category_name,
    rental_count,
    DENSE_RANK() OVER (
      PARTITION BY customer_id
      ORDER BY rental_count DESC, latest_rental_date DESC, category_name
    ) AS category_rank
  FROM category_counts
)
SELECT *
INTO #top_categories
FROM ranked_cte_top_categories
WHERE category_rank <= 2;

-- Create the film_counts temporary table
IF OBJECT_ID('tempdb..#film_counts', 'U') IS NOT NULL 
DROP TABLE #film_counts;

SELECT DISTINCT
  film_id,
  title,
  category_name,
  COUNT(*) OVER (
    PARTITION BY film_id
  ) AS rental_count
INTO #film_counts
FROM complete_joint_dataset_with_rental_date;

-- Create the category_film_exclusions temporary table
IF OBJECT_ID('tempdb..#category_film_exclusions', 'U') IS NOT NULL 
DROP TABLE #category_film_exclusions;

SELECT DISTINCT
  customer_id,
  film_id
INTO #category_film_exclusions
FROM complete_joint_dataset_with_rental_date;

-- Drop the top_category_percentile table if it exists
IF OBJECT_ID('tempdb..#top_category_percentile', 'U') IS NOT NULL 
DROP TABLE #top_category_percentile;

-- Create the top_category_percentile table
WITH calculated_cte AS (
  SELECT
    tc.customer_id,
    tc.category_name AS top_category_name,
    tc.rental_count,
    cc.category_name,
    tc.category_rank,
    PERCENT_RANK() OVER (
      PARTITION BY cc.category_name
      ORDER BY cc.rental_count DESC
    ) AS raw_percentile_value
  FROM category_counts AS cc
  LEFT JOIN #top_categories AS tc
    ON cc.customer_id = tc.customer_id
)
SELECT 
  customer_id,
  category_name,
  rental_count,
  category_rank,
  CASE
    WHEN ROUND(100 * raw_percentile_value, 0) = 0 THEN 1
    ELSE ROUND(100 * raw_percentile_value, 0)
  END AS percentile
INTO #top_category_percentile
FROM calculated_cte
WHERE top_category_name = category_name;

-- Inspect the top category percentiles (showing the top 10 rows)
SELECT TOP 10 *
FROM #top_category_percentile
ORDER BY 
  customer_id,
  category_rank;


  --Joining our temporary tables
-- Drop the customer_category_joint_table if it exists
IF OBJECT_ID('tempdb..#customer_category_joint_table', 'U') IS NOT NULL 
DROP TABLE #customer_category_joint_table;

-- Create the customer_category_joint_table
SELECT
  t1.customer_id,
  t1.category_name,
  t1.rental_count,
  t1.latest_rental_date,
  t2.total_rental_count,
  t3.avg_rental_count,
  t4.percentile,
  t1.rental_count - t3.avg_rental_count AS average_comparison,
  ROUND(100.0 * t1.rental_count / t2.total_rental_count, 0) AS category_percentage
INTO #customer_category_joint_table
FROM category_counts AS t1
INNER JOIN total_counts AS t2
  ON t1.customer_id = t2.customer_id
INNER JOIN #average_category_count AS t3
  ON t1.category_name = t3.category_name
INNER JOIN #top_category_percentile AS t4
  ON t1.customer_id = t4.customer_id
  AND t1.category_name = t4.category_name;

-- Inspect customer = 1 rows sorted by percentile
SELECT TOP 5 *
FROM #customer_category_joint_table
WHERE customer_id = 1
ORDER BY percentile;

--create top 2 category insights table
-- Drop the top_category_insights table if it exists
IF OBJECT_ID('tempdb..#top_category_insights', 'U') IS NOT NULL 
DROP TABLE #top_category_insights;

-- Create the top_category_insights table
WITH ranked_cte AS (
  SELECT
    customer_id,
    ROW_NUMBER() OVER (
      PARTITION BY customer_id
      ORDER BY 
        rental_count DESC,
        latest_rental_date DESC
    ) AS category_rank,
    category_name,
    rental_count,
    average_comparison,
    percentile,
    category_percentage
  FROM #customer_category_joint_table
)
SELECT *
INTO #top_category_insights
FROM ranked_cte
WHERE category_rank <= 2;

-- Inspect the result for the first 3 customers (showing the top 10 rows)
SELECT TOP 10 *
FROM #top_category_insights
ORDER BY 
  customer_id,
  category_rank,
  percentile;

--1st Category Insights
-- Drop the first_category_insights table if it exists
IF OBJECT_ID('tempdb..#first_category_insights', 'U') IS NOT NULL 
DROP TABLE #first_category_insights;

-- Create the first_category_insights table
SELECT
  customer_id,
  category_name,
  rental_count,
  average_comparison,
  percentile
INTO #first_category_insights
FROM #top_category_insights
WHERE category_rank = 1;

-- Inspect the first 10 results
SELECT TOP 10 *
FROM #first_category_insights
ORDER BY customer_id;

---req 5
--transform