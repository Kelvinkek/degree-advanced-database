BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE memberships_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE passenger_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE promotion_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE airport_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE airplane_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE pilot_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE booking_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE meal_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE luggage_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE lostluggage_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE cancellation_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE refund_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE payment_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE flightschedule_seq';
    EXECUTE IMMEDIATE 'DROP SEQUENCE ticket_seq';
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error while dropping sequences: ' || SQLERRM);
        RAISE;
END;
/
	
DECLARE
    v_max_id NUMBER;
    v_exists NUMBER;
BEGIN
    -- Memberships Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'MEMBERSHIPS_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE memberships_seq';
    END IF;
    SELECT COALESCE(MAX(memberID), 0) + 1 INTO v_max_id FROM Memberships;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE memberships_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Passenger Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'PASSENGER_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE passenger_seq';
    END IF;
    SELECT COALESCE(MAX(passengerID), 0) + 1 INTO v_max_id FROM Passenger;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE passenger_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Promotion Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'PROMOTION_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE promotion_seq';
    END IF;
    SELECT COALESCE(MAX(promotionID), 0) + 1 INTO v_max_id FROM Promotion;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE promotion_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Airport Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'AIRPORT_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE airport_seq';
    END IF;
    SELECT COALESCE(MAX(airportID), 0) + 1 INTO v_max_id FROM Airport;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE airport_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Airplane Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'AIRPLANE_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE airplane_seq';
    END IF;
    SELECT COALESCE(MAX(airplaneID), 0) + 1 INTO v_max_id FROM Airplane;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE airplane_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Pilot Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'PILOT_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE pilot_seq';
    END IF;
    SELECT COALESCE(MAX(pilotID), 0) + 1 INTO v_max_id FROM Pilot;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE pilot_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Booking Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'BOOKING_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE booking_seq';
    END IF;
    SELECT COALESCE(MAX(bookingID), 0) + 1 INTO v_max_id FROM Booking;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE booking_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Meal Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'MEAL_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE meal_seq';
    END IF;
    SELECT COALESCE(MAX(mealID), 0) + 1 INTO v_max_id FROM Meal;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE meal_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Luggage Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'LUGGAGE_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE luggage_seq';
    END IF;
    SELECT COALESCE(MAX(luggageID), 0) + 1 INTO v_max_id FROM Luggage;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE luggage_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- LostLuggage Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'LOSTLUGGAGE_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE lostluggage_seq';
    END IF;
    SELECT COALESCE(MAX(reportID), 0) + 1 INTO v_max_id FROM LostLuggage;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE lostluggage_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Cancellation Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'CANCELLATION_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE cancellation_seq';
    END IF;
    SELECT COALESCE(MAX(cancellationID), 0) + 1 INTO v_max_id FROM Cancellation;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE cancellation_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Refund Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'REFUND_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE refund_seq';
    END IF;
    SELECT COALESCE(MAX(refundID), 0) + 1 INTO v_max_id FROM Refund;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE refund_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Payment Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'PAYMENT_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE payment_seq';
    END IF;
    SELECT COALESCE(MAX(paymentID), 0) + 1 INTO v_max_id FROM Payment;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE payment_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- FlightSchedule Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'FLIGHTSCHEDULE_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE flightschedule_seq';
    END IF;
    SELECT COALESCE(MAX(flightScheduleID), 0) + 1 INTO v_max_id FROM FlightSchedule;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE flightschedule_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

    -- Ticket Sequence
    SELECT COUNT(*) INTO v_exists FROM user_sequences WHERE sequence_name = 'TICKET_SEQ';
    IF v_exists > 0 THEN
        EXECUTE IMMEDIATE 'DROP SEQUENCE ticket_seq';
    END IF;
    SELECT COALESCE(MAX(ticketID), 0) + 1 INTO v_max_id FROM Ticket;
    EXECUTE IMMEDIATE 'CREATE SEQUENCE ticket_seq START WITH ' || v_max_id || ' INCREMENT BY 1';

END;
/



