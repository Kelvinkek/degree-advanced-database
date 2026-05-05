CREATE OR REPLACE PROCEDURE INSERT_REFUND(
    p_cancellationID IN NUMBER
) IS
    v_bookingID      NUMBER;
    v_ticketID       NUMBER;
    v_boardingTime   DATE;
    v_totalAmount    NUMBER;
    v_refundAmount   NUMBER;
    v_cancelDate     DATE;
    v_lastRefundID   NUMBER;
    v_newRefundID    NUMBER;
    v_error_code     NUMBER;
    v_error_msg      VARCHAR2(200);

    -- Custom exception for cancellation after boarding time
    EX_NO_REFUND EXCEPTION;

BEGIN
    -- Step 1: Get the bookingID from the cancellation table (ensure single row with ROWNUM)
    SELECT bookingID, cancelDate
    INTO v_bookingID, v_cancelDate
    FROM (SELECT bookingID, cancelDate
          FROM Cancellation
          WHERE cancellationID = p_cancellationID
          AND ROWNUM = 1);

    -- Step 2: Get the ticketID, boardingTime from the Ticket table based on bookingID (ensure single row with ROWNUM)
    SELECT TicketID, boardingTime
    INTO v_ticketID, v_boardingTime
    FROM (SELECT TicketID, boardingTime
          FROM Ticket
          WHERE bookingID = v_bookingID
          AND ROWNUM = 1);

    -- Step 3: Get the totalAmount from the Payment table based on bookingID (ensure single row with ROWNUM)
    SELECT totalAmount
    INTO v_totalAmount
    FROM (SELECT totalAmount
          FROM Payment
          WHERE bookingID = v_bookingID
          AND ROWNUM = 1);

    -- Step 4: Calculate the number of days between cancellation date and boarding time
    IF v_cancelDate < v_boardingTime - 3 THEN
        -- If more than 3 days before boarding time, refund 80%
        v_refundAmount := v_totalAmount * 0.80;
    ELSIF v_cancelDate < v_boardingTime - 2 THEN
        -- If more than 2 days but less than 3 days before boarding time, refund 50%
        v_refundAmount := v_totalAmount * 0.50;
    ELSE
        -- If 2 days or less before boarding time, no refund
        RAISE EX_NO_REFUND;
    END IF;

    -- Step 5: Get the last refundID from the Refund table and increment it by 1
    SELECT NVL(MAX(refundID), 0)
    INTO v_lastRefundID
    FROM Refund;

    v_newRefundID := v_lastRefundID + 1;

    -- Step 6: Insert the refund record using SYSDATE for refundDate
    INSERT INTO Refund(refundID, cancellationID, refundDate, refundAmount)
    VALUES (v_newRefundID, p_cancellationID, SYSDATE, v_refundAmount);

    -- Step 7: Update booking status to 'Refunded'
    UPDATE Booking
    SET status = 'Refunded'
    WHERE bookingID = v_bookingID;

    -- Commit the transaction
    COMMIT;

    -- Success message
    DBMS_OUTPUT.PUT_LINE('Refund record inserted successfully with refund amount: ' || v_refundAmount);

EXCEPTION
    -- Custom exception for no refund
    WHEN EX_NO_REFUND THEN
        DBMS_OUTPUT.PUT_LINE('No refund applicable as the cancellation occurred within 2 days of the boarding time.');

    -- Capture other errors
    WHEN OTHERS THEN
        v_error_code := SQLCODE;
        v_error_msg := SQLERRM;
        RAISE_APPLICATION_ERROR(-20002, 'Error: Unable to insert refund record. Error Code: ' || v_error_code || ' - ' || v_error_msg);
END INSERT_REFUND;
/

SELECT DISTINCT
    C.cancellationID, 
    C.bookingID, 
    C.cancelDate, 
    P.totalAmount,
    T.boardingTime
FROM Cancellation C
LEFT JOIN Refund R ON C.cancellationID = R.cancellationID
LEFT JOIN Payment P ON C.bookingID = P.bookingID
LEFT JOIN Ticket T ON C.bookingID = T.bookingID
WHERE R.cancellationID IS NULL;

-- select * from booking where bookingID = 491;
-- exec INSERT_REFUND(39);
-- select * from booking where bookingID = 491;
-- select * from booking where bookingID = 476;
-- exec INSERT_REFUND(62);
-- select * from booking where bookingID = 476;


