SELECT * FROM sales;

-- Create large_sales table from sales table
CREATE TABLE large_sales(
	channel VARCHAR(30),
	customer_id BIGINT,
	sales_amount float
);

INSERT INTO large_sales
	SELECT channel, customer_id, sales_amount
	FROM sales
	WHERE sales_amount > 100000
	ORDER BY sales_amount DESC;
	
SELECT * FROM large_sales;
---------------------------------------------------
-- Create large_sales_by_channel table from large_sales

CREATE TABLE large_sales_by_channel (
	channel VARCHAR(30),
	number_of_sales BIGINT
);

INSERT INTO large_sales_by_channel
	SELECT channel, COUNT(customer_id)
	FROM large_sales
	GROUP BY channel;
	
SELECT * FROM large_sales_by_channel;
------------------------------------------------
-- Create function to insert data into large_sales_by_channel

CREATE OR REPLACE FUNCTION insert_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM large_sales_by_channel;
	INSERT INTO large_sales_by_channel
		SELECT channel, COUNT(customer_id)
		FROM large_sales
		GROUP BY channel;
RETURN NEW;
END;
$$

-- Create trigger for the above function

CREATE TRIGGER new_large_sale
	AFTER INSERT
	ON large_sales
	FOR EACH STATEMENT
	EXECUTE PROCEDURE insert_trigger_function();
--------------------------------------------------------

SELECT COUNT(*) FROM large_sales;
SELECT SUM(number_of_sales) FROM large_sales_by_channel;

INSERT INTO large_sales VALUES 
('call center', 57, 125000);

SELECT * FROM large_sales_by_channel;
---------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_trigger_function()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM large_sales_by_channel;
	INSERT INTO large_sales_by_channel
		SELECT channel, COUNT(customer_id)
		FROM large_sales
		GROUP BY channel;
RETURN NEW;
END;
$$;

CREATE TRIGGER large_sales_update
AFTER UPDATE
ON large_sales
FOR EACH statement
EXECUTE PROCEDURE update_trigger_function();

SELECT * FROM large_sales WHERE customer_id > 20000;
SELECT COUNT(*) FROM large_sales WHERE customer_id > 20000;
SELECT * FROM large_sales_by_channel;

UPDATE large_sales
SET channel = 'VIP'
WHERE customer_id > 20000;

DROP TRIGGER IF EXISTS large_sales_update ON large_sales;
DROP TRIGGER IF EXISTS new_large_sale ON large_sales;