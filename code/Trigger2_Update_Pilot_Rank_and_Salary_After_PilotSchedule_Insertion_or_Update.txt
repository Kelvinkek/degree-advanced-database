CREATE OR REPLACE TRIGGER update_pilot_rank_salary
FOR INSERT OR UPDATE ON PilotSchedule
COMPOUND TRIGGER

    TYPE t_pilot IS TABLE OF PilotSchedule.pilotID%TYPE;
    v_pilot_ids t_pilot := t_pilot();  -- Table to hold unique pilot IDs

    BEFORE STATEMENT IS
    BEGIN
        -- Initialize the table to store pilot IDs
        v_pilot_ids := t_pilot();
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        -- Collect the pilot IDs affected by the insert/update
        IF :NEW.pilotID IS NOT NULL THEN
            v_pilot_ids.EXTEND;
            v_pilot_ids(v_pilot_ids.LAST) := :NEW.pilotID;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        -- Process after all rows have been inserted/updated
        FOR i IN 1 .. v_pilot_ids.COUNT LOOP
            DECLARE
                v_leader_count NUMBER;
            BEGIN
                -- Get the number of times the pilot has been assigned as 'leader'
                SELECT COUNT(*)
                INTO v_leader_count
                FROM PilotSchedule
                WHERE pilotID = v_pilot_ids(i) AND position = 'leader';

                -- Update the pilot's rank and salary based on the number of times they have been a 'leader'
                IF v_leader_count > 30 THEN
                    -- If more than 30 times as 'leader', promote to 'captain' with corresponding salary
                    UPDATE Pilot
                    SET rank = 'captain', salary = 50000
                    WHERE pilotID = v_pilot_ids(i);
                ELSIF v_leader_count > 20 THEN
                    -- If more than 20 times as 'leader', promote to 'officer' with corresponding salary
                    UPDATE Pilot
                    SET rank = 'officer', salary = 25000
                    WHERE pilotID = v_pilot_ids(i);
                ELSIF v_leader_count > 10 THEN
                    -- If more than 10 times as 'leader', promote to 'pilot' with corresponding salary
                    UPDATE Pilot
                    SET rank = 'pilot', salary = 7000
                    WHERE pilotID = v_pilot_ids(i);
                END IF;
            END;
        END LOOP;
    END AFTER STATEMENT;
    
END update_pilot_rank_salary;
/


-- SELECT p.pilotID, p.salary, COUNT(ps.position) AS leader_count 
-- FROM Pilot p
-- LEFT JOIN PilotSchedule ps ON p.pilotID = ps.pilotID AND ps.position = 'leader'
-- GROUP BY p.pilotID, p.salary
-- ORDER BY leader_count DESC;

-- insert into flightSchedule (flightScheduleID, airplaneID, departureAirportID, arrivalAirportID, departureDateTime, arrivalDateTime, status) values (FLIGHTSCHEDULE_SEQ.NEXTVAL, 16, 2, 1, to_timestamp('06/09/2024 05:53:57.000000000','DD/MM/RRRR HH24:MI:SSXFF'), to_timestamp('06/09/2024 18:53:57.000000','DD/MM/RRRR HH24:MI:SSXFF'), 'Delayed');
-- insert into PilotSchedule (flightScheduleID, pilotID, position, status) values (301, 1, 'leader', 'onduty');


