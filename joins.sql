
IF OBJECT_ID('tempdb..#complete_joint_dataset', 'U') IS NOT NULL 
DROP TABLE #complete_joint_dataset;

SELECT
  rental.customer_id,
  inventory.film_id,
  film.title,
  film_category.category_id,
  category.name AS category_name
INTO #complete_joint_dataset
FROM Films.dbo.rental
INNER JOIN Films.dbo.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN Films.dbo.film
  ON inventory.film_id = film.film_id
INNER JOIN Films.dbo.film_category
  ON film.film_id = film_category.film_id
INNER JOIN Films.dbo.category
  ON film_category.category_id = category.category_id;


-----ties
IF OBJECT_ID('tempdb..#complete_joint_dataset_with_rental_date', 'U') IS NOT NULL 
DROP TABLE #complete_joint_dataset_with_rental_date;

SELECT
  rental.customer_id,
  inventory.film_id,
  film.title,
  category.name AS category_name,
  rental.rental_date
INTO #complete_joint_dataset_with_rental_date
FROM Films.dbo.rental
INNER JOIN Films.dbo.inventory
  ON rental.inventory_id = inventory.inventory_id
INNER JOIN Films.dbo.film
  ON inventory.film_id = film.film_id
INNER JOIN Films.dbo.film_category
  ON film.film_id = film_category.film_id
INNER JOIN Films.dbo.category
  ON film_category.category_id = category.category_id;


-- group by agg on category_name and customer_id
SELECT
  customer_id,
  category_name,
  COUNT(*) AS rental_count,
  MAX(rental_date) AS latest_rental_date
FROM complete_joint_dataset_with_rental_date
GROUP BY 
  customer_id,
  category_name
ORDER BY
  customer_id,
  rental_count DESC,
  latest_rental_date DESC;