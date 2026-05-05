-- Setting environment
SET SERVEROUTPUT ON
SET LINESIZE 190
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

CL SCR
-- Prompt user to input the year
ACCEPT input_year CHAR FORMAT '9999' PROMPT 'Enter the year (YYYY): '

-- Column Formatting
COLUMN cltv_segment FORMAT A15 HEADING "CLTV Segment"
COLUMN customer_id FORMAT 999999 HEADING "Customer ID"
COLUMN passenger_name FORMAT A30 HEADING "Passenger Name"
COLUMN avg_purchase_value FORMAT 999999999.99 HEADING "Average Purchase Value per Year (USD)"
COLUMN num_of_purchases FORMAT 999999 HEADING "Number of Purchases per Year"
COLUMN avg_customer_lifespan FORMAT 999.99 HEADING "Average Customer Lifespan (Years)"
COLUMN customer_lifetime_value FORMAT 999999999.99 HEADING "Customer Lifetime Value (USD)"

-- Title Setup
TTITLE CENTER ====================================================================================================================== SKIP 1 -
       CENTER 'Top 10 Passengers by CLTV Segment for the Year of ' &input_year SKIP 1 -
       CENTER 'Report Generated On: ' _DATE -
       RIGHT 'Page No. : ' FORMAT 999 SQL.PNO SKIP 1 -
       CENTER ====================================================================================================================== SKIP 2

-- Create or Replace View for CLTV Calculation
WITH cltv_report AS(
SELECT
    p.passengerID AS customer_id,
    p.name AS passenger_name,
    ROUND(AVG(pm.totalAmount), 2) AS avg_purchase_value,
    COUNT(DISTINCT b.bookingID) / COUNT(DISTINCT EXTRACT(YEAR FROM b.bookingDate)) AS num_of_purchases,
    ROUND((MAX(b.bookingDate) - MIN(b.bookingDate)) / 365, 2) AS avg_customer_lifespan,
    ROUND(
        AVG(pm.totalAmount) *
        (COUNT(DISTINCT b.bookingID) / COUNT(DISTINCT EXTRACT(YEAR FROM b.bookingDate))) *
        ((MAX(b.bookingDate) - MIN(b.bookingDate)) / 365), 2
    ) AS customer_lifetime_value
FROM
    Passenger p
JOIN
    Booking b ON p.passengerID = b.passengerID
JOIN
    Payment pm ON b.bookingID = pm.bookingID
WHERE
    EXTRACT(YEAR FROM b.bookingDate) = &input_year
GROUP BY
    p.passengerID, p.name
HAVING
    COUNT(DISTINCT b.bookingID) > 1 -- Only include passengers with more than one purchase
ORDER BY
    customer_lifetime_value DESC)

-- Generate Report with CLTV Segmentation for Top 10 Passengers in Each Segment
BREAK ON cltv_segment SKIP 2
COMPUTE SUM LABEL 'Total' OF avg_purchase_value, num_of_purchases, avg_customer_lifespan, customer_lifetime_value ON cltv_segment;

SELECT cltv_segment, customer_id, passenger_name, avg_purchase_value, num_of_purchases, avg_customer_lifespan, customer_lifetime_value
FROM (
    SELECT 
        cltv_segment,
        customer_id,
        passenger_name,
        avg_purchase_value,
        num_of_purchases,
        avg_customer_lifespan,
        customer_lifetime_value,
        ROW_NUMBER() OVER (PARTITION BY cltv_segment ORDER BY customer_lifetime_value DESC) AS seq_num
    FROM (
        SELECT 
            CASE 
                WHEN customer_lifetime_value > 10000 THEN 'High'
                WHEN customer_lifetime_value > 7000 THEN 'Medium'
                ELSE 'Low'
            END AS cltv_segment,
            customer_id,
            passenger_name,
            avg_purchase_value,
            num_of_purchases,
            avg_customer_lifespan,
            customer_lifetime_value
        FROM cltv_report
    )
)
WHERE seq_num <= 10
-- ORDER BY Modification to specify the sequence High, Medium, Low explicitly
ORDER BY 
    CASE cltv_segment
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
    END ASC,
    customer_lifetime_value DESC;

-- Clear Formatting
CLEAR COLUMNS
CLEAR BREAKS
CLEAR COMPUTES
TTITLE OFF;
