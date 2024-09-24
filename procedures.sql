-- B) User-defined function for custom transformation
-- Transforming numeric month to string month

DROP FUNCTION IF EXISTS get_month_string;

CREATE OR REPLACE FUNCTION get_month_string(rental_date TIMESTAMP WITHOUT TIME ZONE)
RETURNS VARCHAR(20)
LANGUAGE plpgsql
AS
$$
DECLARE 
	get_month VARCHAR(20);
BEGIN
	get_month := TO_CHAR(rental_date::TIMESTAMP WITHOUT TIME ZONE, 'Month');
	RETURN get_month;
END;
$$;


-- Test the transformation function

SELECT get_month_string(CURRENT_TIMESTAMP::TIMESTAMP WITHOUT TIME ZONE);


-- Drop tables

DROP TABLE IF EXISTS dvd_rental_detailed;
DROP TABLE IF EXISTS monthly_rental_summary;

-- C) Create detailed and summary tables

CREATE TABLE IF NOT EXISTS dvd_rental_detailed(
	rental_id SERIAL PRIMARY KEY,
	rental_date TIMESTAMP,
	month VARCHAR(20),
	film_title VARCHAR(50),
	customer_id INT,
	staff_id INT
);


CREATE TABLE IF NOT EXISTS monthly_rental_summary(
	month VARCHAR(20),
	total_movies_rented INT
);


-- Check detailed and summary tables created
-- Check detailed and summary tables after executing trigger
-- and inserting data in detailed table

SELECT * FROM dvd_rental_detailed;
SELECT * FROM monthly_rental_summary;


-- D) Extract raw data & insert into detailed table

INSERT INTO dvd_rental_detailed
SELECT
	r.rental_id,
	r.rental_date,
	get_month_string(r.rental_date),
	f.title AS film_title,
	r.customer_id,
	r.staff_id
FROM rental r
JOIN inventory i
ON r.inventory_id = i.inventory_id
JOIN film f
ON i.film_id = f.film_id;

-- Clear tables to test trigger
TRUNCATE TABLE dvd_rental_detailed;
TRUNCATE TABLE monthly_rental_summary;

-- E) Create a trigger & function to the update the summary table

CREATE OR REPLACE FUNCTION update_summary_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS
$$
BEGIN
	DELETE FROM monthly_rental_summary;
	INSERT INTO monthly_rental_summary
    SELECT TO_CHAR(rental_date, 'Month'), COUNT(*)
    FROM dvd_rental_detailed
    GROUP BY TO_CHAR(rental_date, 'Month')
	ORDER BY 2 DESC;
RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER update_summary
	AFTER INSERT
	ON dvd_rental_detailed
	FOR EACH STATEMENT
	EXECUTE PROCEDURE update_summary_function();
	
	
-- DROP Trigger 
DROP TRIGGER update_summary ON dvd_rental_detailed;


-- F) Procedure to refresh data in both the detailed and the summary table

CREATE OR REPLACE PROCEDURE refresh_rental_tables()
LANGUAGE plpgsql
AS 
$$
BEGIN
    DELETE FROM dvd_rental_detailed;
	DELETE FROM monthly_rental_summary;
	
	INSERT INTO dvd_rental_detailed
	SELECT
		r.rental_id,
		r.rental_date,
		get_month_string(r.rental_date) AS month,
		f.title AS film_title,
		r.customer_id,
		r.staff_id
	FROM rental r
	JOIN inventory i
	ON r.inventory_id = i.inventory_id
	JOIN film f
	ON i.film_id = f.film_id;
	
	INSERT INTO monthly_rental_summary
    SELECT 
		TO_CHAR(rental_date, 'Month'), 
		COUNT(*)
    FROM dvd_rental_detailed
    GROUP BY TO_CHAR(rental_date, 'Month')
	ORDER BY 2 DESC;

END;
$$;


-- Test the procedure
-- Delete all rows with staff_id = 1

DELETE FROM dvd_rental_detailed
WHERE staff_id = 1;

-- Verify the detailed table before/after running the procedure
SELECT * FROM dvd_rental_detailed;
SELECT COUNT(*) FROM dvd_rental_detailed;

-- Call the procedure to restore tables
CALL refresh_rental_tables();
