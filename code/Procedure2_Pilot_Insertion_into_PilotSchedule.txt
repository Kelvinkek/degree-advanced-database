CREATE OR REPLACE PROCEDURE MANUAL_ASSIGN_PILOT(
    P_FlightScheduleID  NUMBER,
    P_PilotID           NUMBER,
    P_Position          VARCHAR2,
    P_Status            VARCHAR2
)
IS
    V_DEPARTURE DATE;
    V_ARRIVAL   DATE;
    V_COUNT     NUMBER;
    V_POSITION_EXISTS NUMBER;

    -- Define a custom exception for schedule conflict
    EX_SCHEDULE_CONFLICT EXCEPTION;
    -- Define a custom exception for position already assigned
    EX_POSITION_EXISTS EXCEPTION;

BEGIN
    -- Get the departure and arrival times for the given flight schedule ID
    SELECT DEPARTUREDATETIME, ARRIVALDATETIME
    INTO V_DEPARTURE, V_ARRIVAL
    FROM FlightSchedule
    WHERE FlightScheduleID = P_FlightScheduleID;

    -- Check if the position is already assigned for the given flight schedule ID
    SELECT COUNT(*)
    INTO V_POSITION_EXISTS
    FROM PilotSchedule
    WHERE FlightScheduleID = P_FlightScheduleID
    AND POSITION = P_Position;

    -- Raise an exception if the position is already assigned
    IF V_POSITION_EXISTS > 0 THEN
        RAISE EX_POSITION_EXISTS;
    END IF;

    -- Check for schedule conflicts
    SELECT COUNT(*)
    INTO V_COUNT
    FROM PilotSchedule PS
    INNER JOIN FlightSchedule FS
    ON PS.FlightScheduleID = FS.FlightScheduleID
    WHERE PS.PILOTID = P_PilotID
    AND (
        (V_DEPARTURE BETWEEN FS.DEPARTUREDATETIME AND FS.ARRIVALDATETIME) OR
        (V_ARRIVAL BETWEEN FS.DEPARTUREDATETIME AND FS.ARRIVALDATETIME) OR
        (FS.DEPARTUREDATETIME BETWEEN V_DEPARTURE AND V_ARRIVAL) OR
        (FS.ARRIVALDATETIME BETWEEN V_DEPARTURE AND V_ARRIVAL)
    );

    -- Raise an exception if there is a scheduling conflict
    IF V_COUNT > 0 THEN
        RAISE EX_SCHEDULE_CONFLICT;
    ELSE
        -- Insert the pilot schedule record
        INSERT INTO PilotSchedule (FlightScheduleID, PILOTID, POSITION, STATUS)
        VALUES (P_FlightScheduleID, P_PilotID, P_Position, P_Status);
        COMMIT;

        -- Success message
        DBMS_OUTPUT.PUT_LINE('Pilot assigned successfully!');
    END IF;

EXCEPTION
    -- Handle the position already assigned exception
    WHEN EX_POSITION_EXISTS THEN
        RAISE_APPLICATION_ERROR(-20003, 'Error: Position is already assigned to this flight schedule.');

    -- Handle the schedule conflict exception
    WHEN EX_SCHEDULE_CONFLICT THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error: Pilot has a scheduling conflict with another flight!');

    -- Handle other exceptions
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20002, 'Error: Unable to assign pilot to flight schedule.');
END MANUAL_ASSIGN_PILOT;
/


-- SELECT 
--     FS1.FLIGHTSCHEDULEID AS FlightScheduleID1,
--     FS2.FLIGHTSCHEDULEID AS FlightScheduleID2,
--     FS1.DEPARTUREDATETIME,
--     FS1.ARRIVALDATETIME
-- FROM 
--     FlightSchedule FS1
-- JOIN 
--     FlightSchedule FS2
-- ON 
--     FS1.DEPARTUREDATETIME = FS2.DEPARTUREDATETIME
--     AND FS1.ARRIVALDATETIME = FS2.ARRIVALDATETIME
--     AND FS1.FLIGHTSCHEDULEID <> FS2.FLIGHTSCHEDULEID
-- ORDER BY 
--     FS1.DEPARTUREDATETIME, FS1.ARRIVALDATETIME;

-- SELECT * FROM PilotSchedule WHERE FlightScheduleID IN (265, 128);

-- exec MANUAL_ASSIGN_PILOT(128, 6, 'assistant', 'onduty');
-- exec MANUAL_ASSIGN_PILOT(128, 7, 'leader', 'onduty');
-- exec MANUAL_ASSIGN_PILOT(128, 7, 'assistant', 'onduty');