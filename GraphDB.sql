USE master;
GO

IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'BarkovskyGraphDB')
BEGIN
    ALTER DATABASE BarkovskyGraphDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BarkovskyGraphDB;
END
GO

CREATE DATABASE BarkovskyGraphDB;
GO

USE BarkovskyGraphDB;
GO

--Nodes
CREATE TABLE Cities (
    city_id INT PRIMARY KEY,
    city_name NVARCHAR(50) NOT NULL,
) AS NODE;

CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    username NVARCHAR(50) NOT NULL,
) AS NODE;

CREATE TABLE Books (
    book_id INT PRIMARY KEY,
    book_title NVARCHAR(100) NOT NULL,
) AS NODE;

--Edges
CREATE TABLE Visits AS EDGE;
CREATE TABLE Friends AS EDGE;
CREATE TABLE Reads AS EDGE;


INSERT INTO Cities (city_id, city_name) VALUES
(1, 'New York'),
(2, 'London'),
(3, 'Tokyo'),
(4, 'Paris'),
(5, 'Sydney'),
(6, 'Berlin'),
(7, 'Rome'),
(8, 'Moscow'),
(9, 'Beijing'),
(10, 'Cairo');

INSERT INTO Users (user_id, username) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie'),
(4, 'David'),
(5, 'Eve'),
(6, 'Frank'),
(7, 'Grace'),
(8, 'Hannah'),
(9, 'Isaac'),
(10, 'Julia');

INSERT INTO Books (book_id, book_title) VALUES
(1, 'To Kill a Mockingbird'),
(2, 'Harry Potter and the Sorcerer''s Stone'),
(3, '1984'),
(4, 'The Great Gatsby'),
(5, 'Pride and Prejudice'),
(6, 'The Catcher in the Rye'),
(7, 'Lord of the Rings'),
(8, 'The Hunger Games'),
(9, 'The Da Vinci Code'),
(10, 'The Alchemist');

INSERT INTO Visits
VALUES 
((SELECT $node_id FROM Users WHERE user_id = 1), (SELECT $node_id FROM Cities WHERE city_id = 1)),
((SELECT $node_id FROM Users WHERE user_id = 2), (SELECT $node_id FROM Cities WHERE city_id = 3)),
((SELECT $node_id FROM Users WHERE user_id = 3), (SELECT $node_id FROM Cities WHERE city_id = 3)),
((SELECT $node_id FROM Users WHERE user_id = 4), (SELECT $node_id FROM Cities WHERE city_id = 3)),
((SELECT $node_id FROM Users WHERE user_id = 5), (SELECT $node_id FROM Cities WHERE city_id = 5)),
((SELECT $node_id FROM Users WHERE user_id = 6), (SELECT $node_id FROM Cities WHERE city_id = 5)),
((SELECT $node_id FROM Users WHERE user_id = 7), (SELECT $node_id FROM Cities WHERE city_id = 7)),
((SELECT $node_id FROM Users WHERE user_id = 8), (SELECT $node_id FROM Cities WHERE city_id = 2)),
((SELECT $node_id FROM Users WHERE user_id = 9), (SELECT $node_id FROM Cities WHERE city_id = 9)),
((SELECT $node_id FROM Users WHERE user_id = 10), (SELECT $node_id FROM Cities WHERE city_id = 10));


INSERT INTO Friends
VALUES 
((SELECT $node_id FROM Users WHERE user_id = 1), (SELECT $node_id FROM Users WHERE user_id = 2)),
((SELECT $node_id FROM Users WHERE user_id = 2), (SELECT $node_id FROM Users WHERE user_id = 3)),
((SELECT $node_id FROM Users WHERE user_id = 3), (SELECT $node_id FROM Users WHERE user_id = 6)),
((SELECT $node_id FROM Users WHERE user_id = 4), (SELECT $node_id FROM Users WHERE user_id = 6)),
((SELECT $node_id FROM Users WHERE user_id = 5), (SELECT $node_id FROM Users WHERE user_id = 6)),
((SELECT $node_id FROM Users WHERE user_id = 6), (SELECT $node_id FROM Users WHERE user_id = 7)),
((SELECT $node_id FROM Users WHERE user_id = 7), (SELECT $node_id FROM Users WHERE user_id = 4)),
((SELECT $node_id FROM Users WHERE user_id = 8), (SELECT $node_id FROM Users WHERE user_id = 6)),
((SELECT $node_id FROM Users WHERE user_id = 9), (SELECT $node_id FROM Users WHERE user_id = 10)),
((SELECT $node_id FROM Users WHERE user_id = 10), (SELECT $node_id FROM Users WHERE user_id = 1));


INSERT INTO Reads
VALUES 
((SELECT $node_id FROM Users WHERE user_id = 1), (SELECT $node_id FROM Books WHERE book_id = 1)),
((SELECT $node_id FROM Users WHERE user_id = 2), (SELECT $node_id FROM Books WHERE book_id = 2)),
((SELECT $node_id FROM Users WHERE user_id = 3), (SELECT $node_id FROM Books WHERE book_id = 4)),
((SELECT $node_id FROM Users WHERE user_id = 4), (SELECT $node_id FROM Books WHERE book_id = 4)),
((SELECT $node_id FROM Users WHERE user_id = 5), (SELECT $node_id FROM Books WHERE book_id = 5)),
((SELECT $node_id FROM Users WHERE user_id = 6), (SELECT $node_id FROM Books WHERE book_id = 6)),
((SELECT $node_id FROM Users WHERE user_id = 7), (SELECT $node_id FROM Books WHERE book_id = 7)),
((SELECT $node_id FROM Users WHERE user_id = 8), (SELECT $node_id FROM Books WHERE book_id = 8)),
((SELECT $node_id FROM Users WHERE user_id = 9), (SELECT $node_id FROM Books WHERE book_id = 3)),
((SELECT $node_id FROM Users WHERE user_id = 10), (SELECT $node_id FROM Books WHERE book_id = 10));


--match queries
SELECT u.username, c.city_name
FROM Users u, Visits v, Cities c
WHERE MATCH(u-(v)->c)
AND c.city_name = 'London';

SELECT u1.username AS User1, u2.username AS User2
FROM Users u1, Friends f, Users u2
WHERE MATCH(u1-(f)->u2);

SELECT u.username, b.book_title
FROM Users u, Reads r, Books b
WHERE MATCH(u-(r)->b)
AND b.book_title = '1984';

SELECT u1.username AS User1, u2.username AS User2, c.city_name
FROM Users u1, Friends f, Users u2, Visits v, Cities c
WHERE MATCH(u1-(f)->u2-(v)->c)
AND u1.$node_id <> u2.$node_id;

SELECT u1.username AS User1, u2.username AS User2, b.book_title
FROM Users u1, Friends f, Users u2, Reads r, Books b
WHERE MATCH(u1-(f)->u2-(r)->b)
AND u1.$node_id <> u2.$node_id;


--shortest path
WITH T1 AS
(
    SELECT u1.username AS Username,
           STRING_AGG(u2.username, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
           LAST_VALUE(u2.username) WITHIN GROUP (GRAPH PATH) AS LastNode
    FROM Users AS u1
         ,Friends FOR PATH AS fo
         ,Users FOR PATH AS u2
    WHERE MATCH(SHORTEST_PATH(u1(-(fo)->u2)+))
          AND u1.username = 'Alice'
)
SELECT Username, Friends
FROM T1
WHERE LastNode = 'David';

WITH T1 AS
(
    SELECT u1.username AS Username,
           STRING_AGG(c2.city_name, '->') WITHIN GROUP (GRAPH PATH) AS VisitedCities,
           LAST_VALUE(c2.city_name) WITHIN GROUP (GRAPH PATH) AS LastCity
    FROM Users AS u1
         ,Visits FOR PATH AS v
         ,Cities FOR PATH AS c2
    WHERE MATCH(SHORTEST_PATH(u1(-(v)->c2)+))
          AND u1.username = 'Alice'
)
SELECT Username, VisitedCities
FROM T1
WHERE LastCity = 'New York';
