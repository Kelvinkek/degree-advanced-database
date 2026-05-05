CREATE OR REPLACE TRIGGER update_booking_status_paid
AFTER INSERT OR UPDATE ON Payment
FOR EACH ROW
DECLARE
    v_booking_status VARCHAR2(50);
BEGIN
    IF :NEW.paymentDate IS NOT NULL THEN
        -- Retrieve the current status of the booking
        SELECT status INTO v_booking_status 
        FROM Booking 
        WHERE bookingID = :NEW.bookingID;
        
        -- Update the status if it's not already 'paid'
        IF v_booking_status != 'paid' THEN
            UPDATE Booking
            SET status = 'paid'
            WHERE bookingID = :NEW.bookingID;	
        END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'Error updating booking status.');
END;
/

-- select * from booking where bookingID = 499;
-- insert into Payment (paymentID, bookingID, totalAmount, method, paymentDate, paymentTime) values (451, 499, 5909.40, 'Maybank2u', to_date('20/9/2024','DD/MM/RRRR'), TO_TIMESTAMP('18:48:00.000000','HH24:MI:SS.FF'));
-- insert into Payment (paymentID, bookingID, totalAmount, method, paymentDate, paymentTime) values (453, 493, 5909.40, 'Maybank2u', to_date('20/9/2024','DD/MM/RRRR'), TO_TIMESTAMP('18:48:00.000000','HH24:MI:SS.FF'));
