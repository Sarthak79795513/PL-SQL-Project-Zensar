-- Creating tables for Bus Reservation System
CREATE TABLE Buses (
    BusID NUMBER PRIMARY KEY,
    BusName VARCHAR2(50),
    Source VARCHAR2(50),
    Destination VARCHAR2(50),
    TotalSeats NUMBER,
    AvailableSeats NUMBER
);

CREATE TABLE Passengers (
    PassengerID NUMBER PRIMARY KEY,
    PassengerName VARCHAR2(50),
    ContactNumber VARCHAR2(15)
);

CREATE TABLE Reservations (
    ReservationID NUMBER PRIMARY KEY,
    BusID NUMBER REFERENCES Buses(BusID),
    PassengerID NUMBER REFERENCES Passengers(PassengerID),
    SeatsBooked NUMBER,
    ReservationDate DATE DEFAULT SYSDATE
);

CREATE TABLE Payments (
    PaymentID NUMBER PRIMARY KEY,
    ReservationID NUMBER REFERENCES Reservations(ReservationID),
    PaymentDate DATE DEFAULT SYSDATE,
    Amount NUMBER(10, 2),
    PaymentMethod VARCHAR2(20)
);

-- Sequences for generating IDs
CREATE SEQUENCE Reservations_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE Payments_seq START WITH 1 INCREMENT BY 1;

-- Insert sample data into Buses
INSERT INTO Buses VALUES (1, 'Express 101', 'City A', 'City B', 40, 40);
INSERT INTO Buses VALUES (2, 'Express 202', 'City B', 'City C', 30, 30);
INSERT INTO Buses VALUES (3, 'Express 303', 'City C', 'City D', 50, 50);

-- Insert sample data into Passengers
INSERT INTO Passengers VALUES (1, 'John Doe', '9876543210');
INSERT INTO Passengers VALUES (2, 'Jane Smith', '8765432109');
INSERT INTO Passengers VALUES (3, 'Alice Brown', '7654321098');

-- Procedure to book seats
CREATE OR REPLACE PROCEDURE BookSeat (
    p_BusID IN NUMBER,
    p_PassengerID IN NUMBER,
    p_SeatsBooked IN NUMBER,
    p_PaymentMethod IN VARCHAR2
) AS
    v_AvailableSeats NUMBER;
    v_ReservationID NUMBER;
BEGIN
    -- Check available seats
    SELECT AvailableSeats INTO v_AvailableSeats
    FROM Buses
    WHERE BusID = p_BusID;

    IF v_AvailableSeats >= p_SeatsBooked THEN
        -- Update the available seats
        UPDATE Buses
        SET AvailableSeats = AvailableSeats - p_SeatsBooked
        WHERE BusID = p_BusID;

        -- Insert into Reservations
        SELECT Reservations_seq.NEXTVAL INTO v_ReservationID FROM DUAL;
        INSERT INTO Reservations (ReservationID, BusID, PassengerID, SeatsBooked)
        VALUES (v_ReservationID, p_BusID, p_PassengerID, p_SeatsBooked);

        -- Insert payment details
        INSERT INTO Payments (PaymentID, ReservationID, Amount, PaymentMethod)
        VALUES (Payments_seq.NEXTVAL, v_ReservationID, p_SeatsBooked * 100, p_PaymentMethod);

        DBMS_OUTPUT.PUT_LINE('Reservation successful! Reservation ID: ' || v_ReservationID);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Not enough seats available.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Bus not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- Procedure to cancel reservation
CREATE OR REPLACE PROCEDURE CancelReservation (
    p_ReservationID IN NUMBER
) IS
    v_SeatsBooked NUMBER;
    v_BusID NUMBER;
BEGIN
    -- Get reservation details
    SELECT SeatsBooked, BusID INTO v_SeatsBooked, v_BusID
    FROM Reservations
    WHERE ReservationID = p_ReservationID;

    -- Delete the reservation
    DELETE FROM Reservations
    WHERE ReservationID = p_ReservationID;

    -- Update available seats
    UPDATE Buses
    SET AvailableSeats = AvailableSeats + v_SeatsBooked
    WHERE BusID = v_BusID;

    DBMS_OUTPUT.PUT_LINE('Reservation cancelled successfully.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Reservation not found.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/

-- Procedure to show available buses
CREATE OR REPLACE PROCEDURE ShowBuses AS
BEGIN
    FOR bus IN (
        SELECT BusID, BusName, Source, Destination, TotalSeats, AvailableSeats
        FROM Buses
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Bus ID: ' || bus.BusID || ', Name: ' || bus.BusName ||
                             ', Source: ' || bus.Source || ', Destination: ' || bus.Destination ||
                             ', Total Seats: ' || bus.TotalSeats || ', Available Seats: ' || bus.AvailableSeats);
    END LOOP;
END;
/

-- Procedure to show reservations
CREATE OR REPLACE PROCEDURE ShowReservations AS
BEGIN
    FOR res IN (
        SELECT r.ReservationID, b.BusName, p.PassengerName, r.SeatsBooked, r.ReservationDate
        FROM Reservations r
        JOIN Buses b ON r.BusID = b.BusID
        JOIN Passengers p ON r.PassengerID = p.PassengerID
    ) LOOP
        DBMS_OUTPUT.PUT_LINE('Reservation ID: ' || res.ReservationID || ', Bus: ' || res.BusName ||
                             ', Passenger: ' || res.PassengerName || ', Seats Booked: ' || res.SeatsBooked ||
                             ', Date: ' || res.ReservationDate);
    END LOOP;
END;
/

-- Trigger to update available seats after reservation cancellation
CREATE OR REPLACE TRIGGER UpdateAvailableSeats
AFTER DELETE ON Reservations
FOR EACH ROW
BEGIN
    UPDATE Buses
    SET AvailableSeats = AvailableSeats + :OLD.SeatsBooked
    WHERE BusID = :OLD.BusID;
END;
/

-- Package for reservation operations
CREATE OR REPLACE PACKAGE ReservationOperations AS
    PROCEDURE BookSeat (
        p_BusID IN NUMBER,
        p_PassengerID IN NUMBER,
        p_SeatsBooked IN NUMBER,
        p_PaymentMethod IN VARCHAR2
    );
    PROCEDURE CancelReservation (
        p_ReservationID IN NUMBER
    );
    PROCEDURE ShowBuses;
    PROCEDURE ShowReservations;
END ReservationOperations;
/

CREATE OR REPLACE PACKAGE BODY ReservationOperations AS
    PROCEDURE BookSeat (
        p_BusID IN NUMBER,
        p_PassengerID IN NUMBER,
        p_SeatsBooked IN NUMBER,
        p_PaymentMethod IN VARCHAR2
    ) IS
    BEGIN
        -- Call the existing BookSeat procedure
        BookSeat(p_BusID, p_PassengerID, p_SeatsBooked, p_PaymentMethod);
    END BookSeat;

    PROCEDURE CancelReservation (
        p_ReservationID IN NUMBER
    ) IS
    BEGIN
        -- Call the existing CancelReservation procedure
        CancelReservation(p_ReservationID);
    END CancelReservation;

    PROCEDURE ShowBuses IS
    BEGIN
        -- Call the existing ShowBuses procedure
        ShowBuses;
    END ShowBuses;

    PROCEDURE ShowReservations IS
    BEGIN
        -- Call the existing ShowReservations procedure
        ShowReservations;
    END ShowReservations;
END ReservationOperations;
/
