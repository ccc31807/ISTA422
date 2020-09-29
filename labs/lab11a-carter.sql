-- Name: lab11a-carter.sql
-- Author: Charles Carter
-- Date: September 28, 2020

---------------------------------------------------------------------
-- Microsoft SQL Server T-SQL Fundamentals
-- Chapter 11 - Programmable Objects
-- © Itzik Ben-Gan 
---------------------------------------------------------------------

SET NOCOUNT ON;
USE TSQLV4;

---------------------------------------------------------------------
-- Variables
---------------------------------------------------------------------

-- Declare a variable and initialize it with a value
DECLARE @i AS INT;
SET @i = 15;
select @i;
GO
-- Declare and initialize a variable in the same statement
DECLARE @i AS INT = 50;
select @i;
GO

-- Store the result of a subquery in a variable
DECLARE @empname AS NVARCHAR(61);
SET @empname = (SELECT firstname + N' ' + lastname
                FROM HR.Employees
                WHERE empid = 3);
SELECT @empname AS empname;
GO

-- Using the SET command to assign one variable at a time
DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);
SET @firstname = (SELECT firstname
                  FROM HR.Employees
                  WHERE empid = 3);
SET @lastname = (SELECT lastname
                  FROM HR.Employees
                  WHERE empid = 3);
SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- Using the SELECT command to assign multiple variables in the same statement
DECLARE @firstname AS NVARCHAR(20), @lastname AS NVARCHAR(40);


SELECT
  @firstname = firstname,
  @lastname  = lastname
FROM HR.Employees
WHERE empid = 3;

SELECT @firstname AS firstname, @lastname AS lastname;
GO

-- SELECT doesn't fail when multiple rows qualify
DECLARE @empname AS NVARCHAR(61);
SELECT @empname = firstname + N' ' + lastname
FROM HR.Employees
WHERE mgrid = 2;
SELECT @empname AS empname;
GO

-- SET fails when multiple rows qualify
DECLARE @empname AS NVARCHAR(61);
SET @empname = (SELECT firstname + N' ' + lastname
                FROM HR.Employees
                WHERE mgrid = 2);
SELECT @empname AS empname;
GO

---------------------------------------------------------------------
-- Batches
---------------------------------------------------------------------

-- A Batch as a Unit of Parsing

-- Valid batch
PRINT 'First batch';
USE TSQLV4;
GO
-- Invalid batch
PRINT 'Second batch';
SELECT top (10) custid FROM Sales.Customers;
SELECT top (10) orderid FROM Sales.Orders;
GO
-- Valid batch
PRINT 'Third batch';
SELECT empid FROM HR.Employees;
GO

-- Batches and Variables

DECLARE @i AS INT = 80;
-- Succeeds
PRINT @i;
--GO

-- Fails
PRINT @i;
GO

-- Statements That Cannot Be Combined in the same Batch

DROP VIEW IF EXISTS Sales.MyView;
go
CREATE VIEW Sales.MyView
AS

SELECT YEAR(orderdate) AS orderyear, COUNT(*) AS numorders
FROM Sales.Orders
GROUP BY YEAR(orderdate);
GO

-- A Batch as a Unit of Resolution

-- Create T1 with one column
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT);
GO

-- Following fails
ALTER TABLE dbo.T1 ADD col2 INT;
SELECT col1, col2 FROM dbo.T1;
GO

-- Following succeeds
ALTER TABLE dbo.T1 ADD col2 INT;
GO
SELECT col1, col2 FROM dbo.T1;
GO

-- The GO n Option

-- Create T1 with identity column
DROP TABLE IF EXISTS dbo.T1;
CREATE TABLE dbo.T1(col1 INT IDENTITY CONSTRAINT PK_T1 PRIMARY KEY);
GO

-- Suppress insert messages
--SET NOCOUNT Off;
--GO

-- Execute batch 100 times
INSERT INTO dbo.T1 DEFAULT VALUES;
GO 23

SELECT * FROM dbo.T1;

---------------------------------------------------------------------
-- Flow Elements
---------------------------------------------------------------------

-- The IF ... ELSE Flow Element
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Today is the last day of the year.';
ELSE
  PRINT 'Today is not the last day of the year.';
GO

IF month(SYSDATETIME()) = month(DATEADD(day, 3, SYSDATETIME()))
  PRINT 'Same month.';
ELSE
  PRINT 'Next month.';
GO

-- IF ELSE IF
IF YEAR(SYSDATETIME()) <> YEAR(DATEADD(day, 1, SYSDATETIME()))
  PRINT 'Today is the last day of the year.';
ELSE IF MONTH(SYSDATETIME()) <> MONTH(DATEADD(day, 3, SYSDATETIME()))
    PRINT 'Today is the last day of the month but not the last day of the year.';
ELSE 
    PRINT 'Today is not the last day of the month.';
GO

-- Statement Block
IF DAY(SYSDATETIME()) = 28
BEGIN
  PRINT 'Today is the first day of the month.';
  PRINT 'Starting first-of-month-day process.';
  /* ... process code goes here ... */
  PRINT 'Finished first-of-month-day database process.';
END;
ELSE
BEGIN
  PRINT 'Today is not the first day of the month.';
  PRINT 'Starting non-first-of-month-day process.';
  /* ... process code goes here ... */
  PRINT 'Finished non-first-of-month-day process.';
END;
GO

-- The WHILE Flow Element
DECLARE @i AS INT = 1; -- priming read
WHILE @i <= 10
BEGIN
  PRINT @i;
  SET @i = @i + 1;
END;
GO

-- BREAK
DECLARE @i AS INT = 1;
WHILE @i <= 10
BEGIN
  IF @i = 6 BREAK;
  PRINT @i;
  SET @i = @i + 1;
END;
GO

-- CONTINUE
-- if wanted to print even numbers only
DECLARE @i AS INT = 0;
WHILE @i < 10
BEGIN
  SET @i = @i + 1;
  IF @i % 2 <> 0 CONTINUE;
  PRINT @i;
END;
GO

-- Using a WHILE loop to populate a table of numbers
SET NOCOUNT ON;
DROP TABLE IF EXISTS dbo.Numbers;
CREATE TABLE dbo.Numbers(n INT NOT NULL PRIMARY KEY);
GO

DECLARE @i AS INT = 1;
WHILE @i <= 1000
BEGIN
  INSERT INTO dbo.Numbers(n) VALUES(@i);
  SET @i = @i + 1;
END;
GO

---------------------------------------------------------------------
-- Cursors
---------------------------------------------------------------------

-- Example: Running Aggregations
SET NOCOUNT ON;

DECLARE @Result AS TABLE
(
  custid     INT,
  ordermonth DATE,
  qty        INT, 
  runqty     INT,
  PRIMARY KEY(custid, ordermonth)
);

DECLARE
  @custid     AS INT,
  @prvcustid  AS INT,
  @ordermonth AS DATE,
  @qty        AS INT,
  @runqty     AS INT;

DECLARE C CURSOR FAST_FORWARD /* read only, forward only */ FOR
  SELECT custid, ordermonth, qty
  FROM Sales.CustOrders
  ORDER BY custid, ordermonth;

OPEN C;

FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;

SELECT @prvcustid = @custid, @runqty = 0;

WHILE @@FETCH_STATUS = 0
BEGIN
  IF @custid <> @prvcustid
    SELECT @prvcustid = @custid, @runqty = 0;

  SET @runqty = @runqty + @qty;

  INSERT INTO @Result VALUES(@custid, @ordermonth, @qty, @runqty);
  
  FETCH NEXT FROM C INTO @custid, @ordermonth, @qty;
END;

CLOSE C;

DEALLOCATE C;

SELECT 
  custid,
  CONVERT(VARCHAR(7), ordermonth, 121) AS ordermonth,
  qty,
  runqty
FROM @Result
ORDER BY custid, ordermonth;
GO

-- Using a window aggregate function
SELECT custid, ordermonth, qty,
  SUM(qty) OVER(PARTITION BY custid
                ORDER BY ordermonth
                ROWS UNBOUNDED PRECEDING) AS runqty
FROM Sales.CustOrders
ORDER BY custid, ordermonth;

---------------------------------------------------------------------
-- Temporary Tables
---------------------------------------------------------------------

-- Local Temporary Tables

DROP TABLE IF EXISTS #MyOrderTotalsByYear;
GO

CREATE TABLE #MyOrderTotalsByYear
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);
go
INSERT INTO #MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    INNER JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM dbo.#MyOrderTotalsByYear AS Cur
  LEFT OUTER JOIN dbo.#MyOrderTotalsByYear AS Prv
    ON Cur.orderyear = Prv.orderyear + 1;
GO

-- Try accessing the table from another session
SELECT orderyear, qty FROM dbo.#MyOrderTotalsByYear;

-- cleanup from the original session
DROP TABLE IF EXISTS #MyOrderTotalsByYear;

-- Global Temporary Tables
CREATE TABLE ##Globals
(
  id  sysname     NOT NULL PRIMARY KEY,
  val SQL_VARIANT NOT NULL
);

-- Run from any session
INSERT INTO ##Globals(id, val) VALUES(N'i', CAST(10 AS INT));

-- Run from any session
SELECT val FROM ##Globals WHERE id = N'i';

-- Run from any session
DROP TABLE IF EXISTS ##Globals;
GO

-- Table Variables
DECLARE @MyOrderTotalsByYear TABLE
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    INNER JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT Cur.orderyear, Cur.qty AS curyearqty, Prv.qty AS prvyearqty
FROM @MyOrderTotalsByYear AS Cur
  LEFT OUTER JOIN @MyOrderTotalsByYear AS Prv
    ON Cur.orderyear = Prv.orderyear + 1;
GO

-- with the LAG function
SELECT
  YEAR(O.orderdate) AS orderyear,
  SUM(OD.qty) AS curyearqty,
  LAG(SUM(OD.qty)) OVER(ORDER BY YEAR(orderdate)) AS prvyearqty
FROM Sales.Orders AS O
  INNER JOIN Sales.OrderDetails AS OD
    ON OD.orderid = O.orderid
GROUP BY YEAR(orderdate);
GO

-- Table Types
DROP TYPE IF EXISTS dbo.OrderTotalsByYear;

CREATE TYPE dbo.OrderTotalsByYear AS TABLE
(
  orderyear INT NOT NULL PRIMARY KEY,
  qty       INT NOT NULL
);
GO

-- Use table type
DECLARE @MyOrderTotalsByYear AS dbo.OrderTotalsByYear;

INSERT INTO @MyOrderTotalsByYear(orderyear, qty)
  SELECT
    YEAR(O.orderdate) AS orderyear,
    SUM(OD.qty) AS qty
  FROM Sales.Orders AS O
    INNER JOIN Sales.OrderDetails AS OD
      ON OD.orderid = O.orderid
  GROUP BY YEAR(orderdate);

SELECT orderyear, qty FROM @MyOrderTotalsByYear;
go
GO
