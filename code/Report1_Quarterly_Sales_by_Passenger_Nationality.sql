-- CLEAR FORMAT
CLEAR BREAK  
CLEAR COMPUTE 
CLEAR COLUMN 

-- Enable output formatting
SET SERVEROUTPUT ON
SET LINESIZE 230
SET PAGESIZE 100
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';

CREATE OR REPLACE PROCEDURE QUARTERLY_SALES_REPORT_BY_NATIONALITY(IN_YEAR NUMBER)
IS
    -- Define a record type for quarterly revenue
    TYPE revenue_rec IS RECORD (
        q1_revenue NUMBER,
        q2_revenue NUMBER,
        q3_revenue NUMBER,
        q4_revenue NUMBER,
        total_revenue NUMBER,
        prev_q1_revenue NUMBER,
        prev_q2_revenue NUMBER,
        prev_q3_revenue NUMBER,
        prev_q4_revenue NUMBER,
        prev_total_revenue NUMBER,
        percentage_change NUMBER
    );

    -- Define the cursor for quarterly sales data
    CURSOR SALES_BY_NATIONALITY IS
        SELECT
            p.nationality AS nationality,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (1, 2, 3) THEN py.totalAmount ELSE 0 END) AS Q1_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (4, 5, 6) THEN py.totalAmount ELSE 0 END) AS Q2_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (7, 8, 9) THEN py.totalAmount ELSE 0 END) AS Q3_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (10, 11, 12) THEN py.totalAmount ELSE 0 END) AS Q4_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (1, 2, 3) AND EXTRACT(YEAR FROM b.bookingDate) = IN_YEAR - 1 THEN py.totalAmount ELSE 0 END) AS prev_Q1_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (4, 5, 6) AND EXTRACT(YEAR FROM b.bookingDate) = IN_YEAR - 1 THEN py.totalAmount ELSE 0 END) AS prev_Q2_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (7, 8, 9) AND EXTRACT(YEAR FROM b.bookingDate) = IN_YEAR - 1 THEN py.totalAmount ELSE 0 END) AS prev_Q3_revenue,
            SUM(CASE WHEN EXTRACT(MONTH FROM b.bookingDate) IN (10, 11, 12) AND EXTRACT(YEAR FROM b.bookingDate) = IN_YEAR - 1 THEN py.totalAmount ELSE 0 END) AS prev_Q4_revenue
        FROM
            Booking b
        JOIN Payment py ON b.bookingID = py.bookingID
        JOIN Passenger p ON b.passengerID = p.passengerID
        WHERE EXTRACT(YEAR FROM b.bookingDate) IN (IN_YEAR, IN_YEAR - 1)
        GROUP BY
            p.nationality;

    -- Variables to store the results of the cursor
    V_NATIONALITY VARCHAR2(25);
    V_REVENUE revenue_rec;  -- Declare a record of type revenue_rec
	V_COLOR_CODE VARCHAR2(20);

BEGIN
    -- Title Setup
    DBMS_OUTPUT.PUT_LINE(LPAD('-',204,'-'));
	DBMS_OUTPUT.PUT_LINE(' | ' || RPAD(' ', 200) || ' | '); 
    DBMS_OUTPUT.PUT_LINE(' | ' || RPAD('                                                                               Quarterly Sales by Passenger Nationality for Year ' || IN_YEAR, 200) || ' | ');
    DBMS_OUTPUT.PUT_LINE(' | ' || RPAD('                                                                                          Report Generated On: ' || SYSDATE, 200) || ' | '); 
    DBMS_OUTPUT.PUT_LINE(' | ' || RPAD(' ', 200) || ' | '); 
    DBMS_OUTPUT.PUT_LINE(LPAD('-',204,'-'));

    -- Header for the table
    DBMS_OUTPUT.PUT_LINE(' | ' ||
        RPAD('Nationality', 13) || ' | ' ||
        LPAD('Q1 Revenue', 14) || ' | ' ||
        LPAD('Prev Q1 Rev', 14) || ' | ' ||
        LPAD('Q2 Revenue', 14) || ' | ' ||
        LPAD('Prev Q2 Rev', 14) || ' | ' ||
        LPAD('Q3 Revenue', 14) || ' | ' ||
        LPAD('Prev Q3 Rev', 14) || ' | ' ||
        LPAD('Q4 Revenue', 14) || ' | ' ||
        LPAD('Prev Q4 Rev', 14) || ' | ' ||
        LPAD('Total Rev', 14) || ' | ' ||
        LPAD('Prev Total Rev', 16) || ' | ' ||
        LPAD('Percentage', 12) || ' | ' 
    );

    DBMS_OUTPUT.PUT_LINE(LPAD('-',204,'-'));

    -- Process each row from the cursor
    FOR SALES_REC IN SALES_BY_NATIONALITY LOOP
        -- Assign values from the cursor to the variables
        V_NATIONALITY := SALES_REC.nationality;
        V_REVENUE.q1_revenue := NVL(SALES_REC.Q1_revenue, 0);
        V_REVENUE.q2_revenue := NVL(SALES_REC.Q2_revenue, 0);
        V_REVENUE.q3_revenue := NVL(SALES_REC.Q3_revenue, 0);
        V_REVENUE.q4_revenue := NVL(SALES_REC.Q4_revenue, 0);
        V_REVENUE.prev_q1_revenue := NVL(SALES_REC.prev_Q1_revenue, 0);
        V_REVENUE.prev_q2_revenue := NVL(SALES_REC.prev_Q2_revenue, 0);
        V_REVENUE.prev_q3_revenue := NVL(SALES_REC.prev_Q3_revenue, 0);
        V_REVENUE.prev_q4_revenue := NVL(SALES_REC.prev_Q4_revenue, 0);

        -- Calculate total revenue for current year and previous year
        V_REVENUE.total_revenue := V_REVENUE.q1_revenue + V_REVENUE.q2_revenue + V_REVENUE.q3_revenue + V_REVENUE.q4_revenue;
        V_REVENUE.prev_total_revenue := V_REVENUE.prev_q1_revenue + V_REVENUE.prev_q2_revenue + V_REVENUE.prev_q3_revenue + V_REVENUE.prev_q4_revenue;

        -- Calculate the percentage change between current year and previous year total revenue
        IF V_REVENUE.prev_total_revenue = 0 THEN
            V_REVENUE.percentage_change := NULL;
        ELSE
            V_REVENUE.percentage_change := ((V_REVENUE.total_revenue - V_REVENUE.prev_total_revenue) / V_REVENUE.prev_total_revenue) * 100;
        END IF;
		
		-- Determine color code for percentage change
        IF V_REVENUE.percentage_change IS NULL THEN
            V_COLOR_CODE := CHR(27) || '[0m'; -- Default color
        ELSIF V_REVENUE.percentage_change > 0 THEN
            V_COLOR_CODE := CHR(27) || '[32m'; -- Green for positive change
        ELSIF V_REVENUE.percentage_change < 0 THEN
            V_COLOR_CODE := CHR(27) || '[31m'; -- Red for negative change
        ELSE
            V_COLOR_CODE := CHR(27) || '[0m'; -- Default color
        END IF;
		
        -- Print the result for each nationality in the formatted table
        DBMS_OUTPUT.PUT_LINE(' | ' ||
            RPAD(V_NATIONALITY, 13) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.q1_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.prev_q1_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.q2_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.prev_q2_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.q3_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.prev_q3_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.q4_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.prev_q4_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.total_revenue, '9,999,999.99'), 14) || ' | ' ||
            LPAD(TO_CHAR(V_REVENUE.prev_total_revenue, '9,999,999.99'), 16) || ' | ' ||
			V_COLOR_CODE || LPAD(TO_CHAR(V_REVENUE.percentage_change, '9999.99') || '%', 15) || CHR(27) || '[0m' || ' | ' 
        );
    END LOOP;

    -- End of the report
    DBMS_OUTPUT.PUT_LINE(LPAD('-',204,'-'));
END QUARTERLY_SALES_REPORT_BY_NATIONALITY;
/

CL SCR
-- Prompt for Year Input
ACCEPT target_year NUMBER PROMPT 'Enter the target year (YYYY): ';
EXEC QUARTERLY_SALES_REPORT_BY_NATIONALITY(&target_year);
