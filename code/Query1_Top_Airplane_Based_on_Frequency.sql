-- CLEAR FORMAT
CLEAR BREAK  
CLEAR COMPUTE 
CLEAR COLUMN 

SET SERVEROUTPUT ON
SET LINESIZE 208
SET PAGESIZE 150
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
SET UNDERLINE ON

-- Column Formatting
COLUMN model FORMAT A15 Heading "Model"
COLUMN business_freq FORMAT 99999999 Heading "Freq (Business)"
COLUMN business_prev_freq FORMAT 99999999 Heading "Prev Freq (Business)"
COLUMN economy_freq FORMAT 99999999 Heading "Freq (Economy)"
COLUMN economy_prev_freq FORMAT 99999999 Heading "Prev Freq (Economy)"
COLUMN first_class_freq FORMAT 99999999 Heading "Freq (First-Class)"
COLUMN first_class_prev_freq FORMAT 99999999 Heading "Prev Freq (First-Class)"
COLUMN total_freq FORMAT 99999999 Heading "Total Freq"
COLUMN total_prev_freq FORMAT 99999999 Heading "Prev Total Freq"
COLUMN percentage_change FORMAT 999999.99 Heading "Percentage Change (%)" JUSTIFY RIGHT

CL SCR
-- Prompt user to input the year
ACCEPT input_year DATE FORMAT 'YYYY' PROMPT 'Enter the year (YYYY):'

-- Drop the view if it exists
BEGIN
    EXECUTE IMMEDIATE 'DROP VIEW AirplaneUsageView';
EXCEPTION
    WHEN OTHERS THEN
        NULL; -- Ignore errors if the view does not exist
END;
/

-- Create or replace view for usage frequency and percentage change
CREATE OR REPLACE VIEW AirplaneUsageView AS
SELECT 
    a.model,
    -- Business class frequencies
    COALESCE(SUM(CASE WHEN a.class = 'business' AND TO_CHAR(fs.departureDateTime, 'YYYY') = '&input_year' THEN 1 ELSE 0 END), 0) AS business_freq,
    COALESCE(SUM(CASE WHEN a.class = 'business' AND TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END), 0) AS business_prev_freq,
    -- Economy class frequencies
    COALESCE(SUM(CASE WHEN a.class = 'economy' AND TO_CHAR(fs.departureDateTime, 'YYYY') = '&input_year' THEN 1 ELSE 0 END), 0) AS economy_freq,
    COALESCE(SUM(CASE WHEN a.class = 'economy' AND TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END), 0) AS economy_prev_freq,
    -- First-class frequencies
    COALESCE(SUM(CASE WHEN a.class = 'first' AND TO_CHAR(fs.departureDateTime, 'YYYY') = '&input_year' THEN 1 ELSE 0 END), 0) AS first_class_freq,
    COALESCE(SUM(CASE WHEN a.class = 'first' AND TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END), 0) AS first_class_prev_freq,
    -- Total frequencies for the input year
    COALESCE(SUM(CASE WHEN TO_CHAR(fs.departureDateTime, 'YYYY') = '&input_year' THEN 1 ELSE 0 END), 0) AS total_freq,
    -- Total frequencies for the previous year
    COALESCE(SUM(CASE WHEN TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END), 0) AS total_prev_freq,
    CASE 
        WHEN COALESCE(SUM(CASE WHEN TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END), 0) = 0
            THEN NULL
        ELSE ROUND((SUM(CASE WHEN TO_CHAR(fs.departureDateTime, 'YYYY') = '&input_year' THEN 1 ELSE 0 END) - 
                   SUM(CASE WHEN TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END)) * 100.0 / 
                  GREATEST(1, SUM(CASE WHEN TO_CHAR(fs.departureDateTime, 'YYYY') = TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY') THEN 1 ELSE 0 END)), 2)
    END AS percentage_change
FROM 
    Airplane a
LEFT JOIN 
    FlightSchedule fs ON a.airplaneID = fs.airplaneID
LEFT JOIN 
    Ticket t ON fs.flightScheduleID = t.flightScheduleID
WHERE
    TO_CHAR(fs.departureDateTime, 'YYYY') IN ('&input_year', TO_CHAR(TO_DATE('&input_year', 'YYYY') - INTERVAL '1' YEAR, 'YYYY'))
    OR fs.departureDateTime IS NULL -- Include airplanes without flights
GROUP BY 
    a.model;
/

-- Report Header
TTITLE CENTER ================================================================================================== SKIP 1 -
CENTER 'Top Airplanes Based on Frequency of Customer Booked for the Year of ' &input_year'' SKIP 1 -
CENTER 'Report Generated On: ' _DATE RIGHT 'Page No. : ' FORMAT 999 SQL.PNO SKIP 1 -
CENTER ================================================================================================== SKIP 2

-- Main Query to select from the view
SELECT 
    model,
    business_freq,
    business_prev_freq,
    economy_freq,
    economy_prev_freq,
    first_class_freq,
    first_class_prev_freq,
    total_freq,
    total_prev_freq,
    CASE 
        WHEN percentage_change > 0 THEN CHR(27) || '[32m' || percentage_change || '%' || CHR(27) || '[0m' 
        WHEN percentage_change < 0 THEN CHR(27) || '[31m' || percentage_change || '%' || CHR(27) || '[0m'
        ELSE TO_CHAR(percentage_change) || '%' 
    END AS "Percentage Change (%)"
FROM 
    AirplaneUsageView
ORDER BY 
    total_freq DESC;

CLEAR BREAKS

-- Clear formatting
CLEAR COLUMNS
CLEAR COMPUTES
TTITLE OFF
