CREATE OR REPLACE PROCEDURE SEASONAL_PEAK_TICKET_REPORT(IN_YEAR NUMBER)
IS
    TYPE Season_Revenue IS RECORD (
        spring_revenue NUMBER,
        summer_revenue NUMBER,
        autumn_revenue NUMBER,
        winter_revenue NUMBER,
        total_revenue NUMBER,
        prev_spring_revenue NUMBER,
        prev_summer_revenue NUMBER,
        prev_autumn_revenue NUMBER,
        prev_winter_revenue NUMBER,
        prev_total_revenue NUMBER,
        peak_season VARCHAR2(10)
    );

    CURSOR TICKET_BY_SEASON(ARRIVAL_AIRPORT_NAME VARCHAR2, IN_YEAR NUMBER, IN_SEASON VARCHAR2) IS
        SELECT 
            AP.name AS ARRIVAL_AIRPORT_NAME,
            SUM(T.price) AS SEASONAL_REVENUE
        FROM Ticket T
        JOIN FlightSchedule FS ON T.flightScheduleID = FS.flightScheduleID
        JOIN Airport AP ON FS.arrivalAirportID = AP.airportID
        WHERE EXTRACT(YEAR FROM T.date_of_issue) = IN_YEAR
        AND AP.name = ARRIVAL_AIRPORT_NAME
        AND (
            (IN_SEASON = 'Winter' AND EXTRACT(MONTH FROM T.date_of_issue) IN (12, 1, 2)) OR
            (IN_SEASON = 'Spring' AND EXTRACT(MONTH FROM T.date_of_issue) IN (3, 4, 5)) OR
            (IN_SEASON = 'Summer' AND EXTRACT(MONTH FROM T.date_of_issue) IN (6, 7, 8)) OR
            (IN_SEASON = 'Autumn' AND EXTRACT(MONTH FROM T.date_of_issue) IN (9, 10, 11))
        )
        GROUP BY AP.name;

    V_AIRPORT_NAME VARCHAR2(50);
    V_REVENUE Season_Revenue;
    V_YEAR_NAME VARCHAR2(4);
    V_TOTAL_REVENUE NUMBER;
    V_TOTAL_PREV_REVENUE NUMBER;
    V_PEAK_SEASON VARCHAR2(20);
    V_PEAK_REVENUE NUMBER;
    V_PERCENTAGE_CHANGE NUMBER;
    V_COLOR_CODE VARCHAR2(20);
    V_COLOR_CODE_SEASON VARCHAR2(20);

    CURSOR ARRIVAL_AIRPORTS IS
        SELECT DISTINCT AP.name 
        FROM Airport AP
        JOIN FlightSchedule FS ON AP.airportID = FS.arrivalAirportID;

    PROCEDURE PRINT_CONSOLIDATED_REPORT IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('  ');
        DBMS_OUTPUT.PUT_LINE(LPAD('-',176,'-'));
        DBMS_OUTPUT.PUT_LINE(' | ' || RPAD(' ', 172) || ' | '); 
        DBMS_OUTPUT.PUT_LINE(' | ' || RPAD('                                                         Consolidated Seasonal Peak Ticket Revenue Report for Year ' || V_YEAR_NAME, 172) || ' | ');
        DBMS_OUTPUT.PUT_LINE(' | ' || RPAD('                                                                          Report Generated On: ' || SYSDATE, 172) || ' | '); 
        DBMS_OUTPUT.PUT_LINE(' | ' || RPAD(' ', 172) || ' | '); 
        DBMS_OUTPUT.PUT_LINE(LPAD('-',176,'-'));
        DBMS_OUTPUT.PUT_LINE(' | ' ||
                RPAD('Arrival Airport', 20) || ' | ' ||
                LPAD('Spring Revenue', 15) || ' | ' ||
                LPAD('Summer Revenue', 15) || ' | ' ||
                LPAD('Autumn Revenue', 15) || ' | ' ||
                LPAD('Winter Revenue', 15) || ' | ' ||
                LPAD('Total Revenue', 15) || ' | ' ||
                LPAD('Prev Total Revenue', 20) || ' | ' ||
                LPAD('Percentage Change', 18) || ' | ' ||
                RPAD('Peak Season', 15) || ' | '
            );
        DBMS_OUTPUT.PUT_LINE(LPAD('-',176,'-'));

        FOR AIRPORT IN ARRIVAL_AIRPORTS LOOP
            V_AIRPORT_NAME := AIRPORT.name;

            -- Initialize Revenue
            V_REVENUE.spring_revenue := 0;
            V_REVENUE.summer_revenue := 0;
            V_REVENUE.autumn_revenue := 0;
            V_REVENUE.winter_revenue := 0;
            V_REVENUE.total_revenue := 0;
            V_REVENUE.prev_spring_revenue := 0;
            V_REVENUE.prev_summer_revenue := 0;
            V_REVENUE.prev_autumn_revenue := 0;
            V_REVENUE.prev_winter_revenue := 0;
            V_REVENUE.prev_total_revenue := 0;

            -- Get Revenue for Each Season (Current Year)
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR, 'Spring') LOOP
                V_REVENUE.spring_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR, 'Summer') LOOP
                V_REVENUE.summer_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR, 'Autumn') LOOP
                V_REVENUE.autumn_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR, 'Winter') LOOP
                V_REVENUE.winter_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;

            -- Calculate Total Revenue for Current Year
            V_REVENUE.total_revenue := V_REVENUE.spring_revenue + V_REVENUE.summer_revenue + V_REVENUE.autumn_revenue + V_REVENUE.winter_revenue;

            -- Get Revenue for Each Season (Previous Year)
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR - 1, 'Spring') LOOP
                V_REVENUE.prev_spring_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR - 1, 'Summer') LOOP
                V_REVENUE.prev_summer_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR - 1, 'Autumn') LOOP
                V_REVENUE.prev_autumn_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;
            FOR TICKET IN TICKET_BY_SEASON(V_AIRPORT_NAME, IN_YEAR - 1, 'Winter') LOOP
                V_REVENUE.prev_winter_revenue := TICKET.SEASONAL_REVENUE;
            END LOOP;

            -- Calculate Total Revenue for Previous Year
            V_REVENUE.prev_total_revenue := V_REVENUE.prev_spring_revenue + V_REVENUE.prev_summer_revenue + V_REVENUE.prev_autumn_revenue + V_REVENUE.prev_winter_revenue;

            -- Determine Peak Season for Current Year
            V_PEAK_REVENUE := GREATEST(V_REVENUE.spring_revenue, V_REVENUE.summer_revenue, V_REVENUE.autumn_revenue, V_REVENUE.winter_revenue);
            IF V_PEAK_REVENUE = V_REVENUE.spring_revenue THEN
                V_PEAK_SEASON := 'Spring';
                V_COLOR_CODE_SEASON := CHR(27) || '[95m'; 
            ELSIF V_PEAK_REVENUE = V_REVENUE.summer_revenue THEN
                V_PEAK_SEASON := 'Summer';
                V_COLOR_CODE_SEASON := CHR(27) || '[33m'; -- Yellow
            ELSIF V_PEAK_REVENUE = V_REVENUE.autumn_revenue THEN
                V_PEAK_SEASON := 'Autumn';
                V_COLOR_CODE_SEASON := CHR(27) || '[37m'; 
            ELSE
                V_PEAK_SEASON := 'Winter';
                V_COLOR_CODE_SEASON := CHR(27) || '[34m'; -- Blue
            END IF;

            -- Calculate Percentage Change
            IF V_REVENUE.prev_total_revenue = 0 THEN
                V_PERCENTAGE_CHANGE := NULL;
            ELSE
                V_PERCENTAGE_CHANGE := ((V_REVENUE.total_revenue - V_REVENUE.prev_total_revenue) / V_REVENUE.prev_total_revenue) * 100;
            END IF;

            -- Determine Color Code for Percentage Change
            IF V_PERCENTAGE_CHANGE IS NULL THEN
                V_COLOR_CODE := CHR(27) || '[0m'; -- Default
            ELSIF V_PERCENTAGE_CHANGE > 0 THEN
                V_COLOR_CODE := CHR(27) || '[32m'; -- Green
            ELSE
                V_COLOR_CODE := CHR(27) || '[31m'; -- Red
            END IF;

            -- Print Row for Each Airport
            DBMS_OUTPUT.PUT_LINE(' | ' ||
                RPAD(V_AIRPORT_NAME, 20) || ' | ' ||
                LPAD(TO_CHAR(V_REVENUE.spring_revenue, '999,999,999'), 15) || ' | ' ||
                LPAD(TO_CHAR(V_REVENUE.summer_revenue, '999,999,999'), 15) || ' | ' ||
                LPAD(TO_CHAR(V_REVENUE.autumn_revenue, '999,999,999'), 15) || ' | ' ||
                LPAD(TO_CHAR(V_REVENUE.winter_revenue, '999,999,999'), 15) || ' | ' ||
                LPAD(TO_CHAR(V_REVENUE.total_revenue, '999,999,999'), 15) || ' | ' ||
                LPAD(TO_CHAR(V_REVENUE.prev_total_revenue, '999,999,999'), 20) || ' | ' ||
                LPAD(V_COLOR_CODE || TO_CHAR(V_PERCENTAGE_CHANGE, '99999.99') || '%' || CHR(27) || '[0m', 27) || ' | ' ||
                RPAD(V_COLOR_CODE_SEASON || V_PEAK_SEASON || CHR(27) || '[0m', 30) || ' | '
            );
			DBMS_OUTPUT.PUT_LINE(LPAD('-',176,'-'));

        END LOOP;
    END PRINT_CONSOLIDATED_REPORT;

BEGIN
    V_YEAR_NAME := TO_CHAR(IN_YEAR);
    PRINT_CONSOLIDATED_REPORT;
END SEASONAL_PEAK_TICKET_REPORT;
/

CL SCR
-- Prompt for Year Input
ACCEPT target_year NUMBER PROMPT 'Enter the target year (YYYY): ';
EXEC SEASONAL_PEAK_TICKET_REPORT(&target_year);