-- Step 1: Create a new database
CREATE DATABASE Library;
USE Library;

-- Create Books Table
CREATE TABLE Books (
    BookID INT PRIMARY KEY AUTO_INCREMENT, 
    Title VARCHAR(255) NOT NULL, 
    Author VARCHAR(255) NOT NULL, 
    CopiesAvailable INT NOT NULL
);

-- Set auto increment start value for Books Table
ALTER TABLE Books AUTO_INCREMENT = 1000;

-- Create Members Table
CREATE TABLE Members (
    MemberID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    MembershipDate DATE NOT NULL
);

-- Set auto increment start value for Members Table
ALTER TABLE Members AUTO_INCREMENT = 202401;

-- Create Rental Table
CREATE TABLE Rental (
    RentalID INT PRIMARY KEY AUTO_INCREMENT,
    BookID INT NOT NULL,
    MemberID INT NOT NULL,
    RentalDate DATE NOT NULL,
    ReturnDate DATE,
    FOREIGN KEY (BookID) REFERENCES Books(BookID),
    FOREIGN KEY (MemberID) REFERENCES Members(MemberID)
);

-- Insert sample data into Books table
INSERT INTO Books (Title, Author, CopiesAvailable) 
VALUES 
    ('SQL Basics', 'John Doe', 5),
    ('Database Design', 'Jane Smith', 3),
    ('Advanced SQL', 'Albert Brown', 2),
    ('Machine Learning', 'Alice Green', 4),
    ('Python for Data Science', 'Bob White', 3),
    ('AI Foundations', 'Eve Black', 6),
    ('Networking Essentials', 'Charlie Blue', 5),
    ('Cybersecurity', 'David Yellow', 7),
    ('Operating Systems', 'Grace Red', 2),
    ('Java Programming', 'Hank Grey', 4);

-- Insert sample data into Members table
INSERT INTO Members (Name, Email, MembershipDate) 
VALUES 
    ('Alice', 'alice@example.com', '2024-01-01'),
    ('Bob', 'bob@example.com', '2024-01-02'),
    ('Charlie', 'charlie@example.com', '2024-01-03'),
    ('David', 'david@example.com', '2024-01-04'),
    ('Eve', 'eve@example.com', '2024-01-05'),
    ('Frank', 'frank@example.com', '2024-01-06'),
    ('Grace', 'grace@example.com', '2024-01-07'),
    ('Hank', 'hank@example.com', '2024-01-08'),
    ('Ivy', 'ivy@example.com', '2024-01-09'),
    ('Jack', 'jack@example.com', '2024-01-10'),
    ('Mckenzie', 'mckzie@example.com', '2024-07-07'),
    ('Malcolm', 'malc@example.com', '2024-08-18'),
    ('Sanders', 'sand@example.com', '2024-10-12'),
    ('Gilbert', 'gilb@example.com', '2024-10-12'),
    ('Boris', 'boris@example.com', '2024-11-10');

DROP PROCEDURE IF EXISTS AddNewMember;
DELIMITER $$

CREATE PROCEDURE AddNewMember(
    IN inp_email VARCHAR(255), 
    IN inp_name VARCHAR(255), 
    IN inp_join_date DATE)
BEGIN
    DECLARE email_count INT;
    
    -- Check if the email already exists
    SELECT COUNT(*) INTO email_count 
    FROM Members 
    WHERE Email = inp_email;

    IF email_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member with this email already exists';
    ELSE
        INSERT INTO Members (Name, Email, MembershipDate) 
        VALUES (inp_name, inp_email, inp_join_date);
    END IF;
END;
$$

DELIMITER ;

DROP PROCEDURE IF EXISTS RentBook;
DELIMITER $$

CREATE PROCEDURE RentBook(
    IN inp_memberid INT, 
    IN inp_bookid INT, 
    IN inp_rentaldate DATE)
BEGIN
    DECLARE qty_available INT;

    -- Check if book is available
    SELECT CopiesAvailable INTO qty_available 
    FROM Books 
    WHERE BookID = inp_bookid;

    IF qty_available <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient book quantity';
    ELSE
        -- Insert rental record into Rental table
        INSERT INTO Rental (BookID, MemberID, RentalDate)
        VALUES (inp_bookid, inp_memberid, inp_rentaldate);

        -- Reduce the available quantity of the book
        UPDATE Books 
        SET CopiesAvailable = CopiesAvailable - 1 
        WHERE BookID = inp_bookid;
    END IF;
END;
$$

DELIMITER ;

DROP PROCEDURE IF EXISTS ReturnBook;
DELIMITER $$

CREATE PROCEDURE ReturnBook(
    IN inp_rentalid INT, 
    IN inp_return_date DATE)
BEGIN
    DECLARE book_id INT;

    -- Get the BookID from Rental Table
    SELECT BookID INTO book_id 
    FROM Rental 
    WHERE RentalID = inp_rentalid AND ReturnDate IS NULL;

    IF book_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid Rental ID or Book already returned';
    ELSE
        -- Update ReturnDate in Rental Table
        UPDATE Rental 
        SET ReturnDate = inp_return_date 
        WHERE RentalID = inp_rentalid;

        -- Increase the book quantity in Books Table
        UPDATE Books 
        SET CopiesAvailable = CopiesAvailable + 1 
        WHERE BookID = book_id;
    END IF;
END;
$$

DELIMITER ;

-- Stored Procedure to Check Book Availability
DROP PROCEDURE IF EXISTS CheckBookAvailability;
DELIMITER $$

CREATE PROCEDURE CheckBookAvailability(
    IN inp_bookid INT)
BEGIN
    SELECT CopiesAvailable 
    FROM Books 
    WHERE BookID = inp_bookid;
END;
$$

DELIMITER ;

-- Report for Overdue Books with Penalty Charges
SELECT 
    RentalID, 
    Books.Title, 
    Members.Name, 
    GREATEST(DATEDIFF(COALESCE(Rental.ReturnDate, CURDATE()), Rental.RentalDate) - 15, 0) AS DelayDays, 
    GREATEST(DATEDIFF(COALESCE(Rental.ReturnDate, CURDATE()), Rental.RentalDate) - 15, 0) * 5 AS Penalty 
FROM Rental
JOIN Books ON Rental.BookID = Books.BookID
JOIN Members ON Rental.MemberID = Members.MemberID
WHERE COALESCE(Rental.ReturnDate, CURDATE()) > DATE_ADD(Rental.RentalDate, INTERVAL 15 DAY);


-- Report for Books Not Rented
SELECT BookID, Title 
FROM Books 
WHERE BookID NOT IN (SELECT BookID FROM Rental);

-- Report for Member's Rental History
SELECT 
    Members.Name, 
    Books.Title, 
    Rental.RentalDate, 
    Rental.ReturnDate 
FROM Rental
JOIN Members ON Rental.MemberID = Members.MemberID
JOIN Books ON Rental.BookID = Books.BookID;

-- Penalty Charges Report
SELECT 
    Members.Name, 
    Books.Title, 
    Rental.RentalDate, 
    COALESCE(Rental.ReturnDate, CURDATE()) AS ReturnDate, 
    DATEDIFF(COALESCE(Rental.ReturnDate, CURDATE()), Rental.RentalDate) * 5 AS Penalty
FROM Rental
JOIN Members ON Rental.MemberID = Members.MemberID
JOIN Books ON Rental.BookID = Books.BookID
WHERE (Rental.ReturnDate IS NULL OR Rental.ReturnDate > DATE_ADD(Rental.RentalDate, INTERVAL 7 DAY));

CALL RentBook(202402, 1001, '2024-10-05');
CALL ReturnBook(2, '2024-11-10');
CALL CheckBookAvailability(1001);
