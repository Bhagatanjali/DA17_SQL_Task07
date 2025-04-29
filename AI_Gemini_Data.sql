--1) Table : Customers
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE
);

Select * from Customers

-- Inserting 50 rows into Orders
INSERT INTO Customers (first_name, last_name, email)
SELECT
    'FirstName' || generate_series(1, 50),
    'LastName' || generate_series(1, 50),
    'email' || generate_series(1, 50) || '@example.com';

	
-- Update the email address of a specific customer
UPDATE Customers
SET email = 'updated.email@example.com'
WHERE customer_id = 5;

-- Add a NOT NULL constraint to the 'phone_number' column in the Customers table
ALTER TABLE Customers
ADD COLUMN phone_number VARCHAR(20);

ALTER TABLE Customers
ALTER COLUMN phone_number SET NOT NULL;

UPDATE Customers
SET phone_number = 'N/A'
WHERE phone_number IS NULL;

ALTER TABLE Customers
ALTER COLUMN phone_number SET NOT NULL;

--------------------------------------------------------------------

--2) Table: Orders
CREATE TABLE Orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES Customers(customer_id),
    order_date DATE NOT NULL,
    total_amount NUMERIC(10, 2)
);

select * from Orders
-- Inserting 50 rows into Orders
INSERT INTO Orders (customer_id, order_date, total_amount)
SELECT
    (random() * 49 + 1)::integer,
    NOW() - interval '1 day' * generate_series(1, 50),
    (random() * 100 + 1)::numeric(10, 2);

ALTER TABLE Orders
ALTER COLUMN total_amount TYPE NUMERIC(12, 2);	

	
	
-------------------------------------------------------------------
-- 3)Table: Products
CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    price NUMERIC(8, 2)
);

select * from Products

INSERT INTO Products (product_name, category, price)
SELECT
    'Product' || generate_series(1, 50),
    CASE (generate_series(1, 50) % 3)
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Books'
        ELSE 'Clothing'
    END,
    (random() * 50 + 5)::numeric(8, 2);
---------Revised Query---------

INSERT INTO Products (product_name, category, price)
SELECT
    'Product' || s.i,
    CASE s.i % 3
        WHEN 0 THEN 'Electronics'
        WHEN 1 THEN 'Books'
        ELSE 'Clothing'
    END,
    (random() * 50 + 5)::numeric(8, 2)
FROM generate_series(1, 50) AS s(i);

-- Increase the price of products in the 'Books' category by 10%
UPDATE Products
SET price = price * 1.10
WHERE category = 'Books';

--ADD-
ALTER TABLE Products
ALTER COLUMN category SET DEFAULT 'General';

 --Remove Constraint-- Remove the default value for the 'category' column in the Products table
ALTER TABLE Products
ALTER COLUMN category DROP DEFAULT;



-------------------------------------------------------------------	
--4) Table: OrderDetails
CREATE TABLE OrderDetails (
    order_detail_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES Orders(order_id),
    product_id INTEGER REFERENCES Products(product_id),
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(8, 2)
);

select * from OrderDetails

INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price)
SELECT
    (random() * 49 + 1)::integer,
    (random() * 49 + 1)::integer,
    (random() * 5 + 1)::integer,
    (random() * 20 + 1)::numeric(8, 2);
------Revised query------------

INSERT INTO OrderDetails (order_id, product_id, quantity, unit_price)
SELECT
    (random() * (SELECT COUNT(*) FROM Orders) + 1)::integer,
    (SELECT product_id FROM Products ORDER BY RANDOM() LIMIT 1),
    (random() * 5 + 1)::integer,
    (random() * 20 + 1)::numeric(8, 2)
FROM generate_series(1, 50); -- Generate 50 rows


-- Add a new column 'discount' to OrderDetails
ALTER TABLE OrderDetails
ADD COLUMN discount NUMERIC(4, 2) DEFAULT 0.00;

-- Change the data type of the 'quantity' column
ALTER TABLE OrderDetails
ALTER COLUMN quantity TYPE SMALLINT;


-- Add a CHECK constraint to ensure quantity is always positive
ALTER TABLE OrderDetails
ADD CONSTRAINT positive_quantity CHECK (quantity > 0);

-- Add a NOT NULL constraint to the 'discount' column
ALTER TABLE OrderDetails
ALTER COLUMN discount SET NOT NULL;

-- Remove the 'positive_quantity' CHECK constraint
ALTER TABLE OrderDetails
DROP CONSTRAINT positive_quantity;

-- Remove the foreign key constraint referencing the Products table
ALTER TABLE OrderDetails
DROP CONSTRAINT orderdetails_product_id_fkey;

-- Increase the quantity of a specific order detail
UPDATE OrderDetails
SET quantity = quantity + 2
WHERE order_detail_id = 10;

-- Apply a 10% discount to all order details for a specific order
UPDATE OrderDetails
SET discount = unit_price * 0.10
WHERE order_id = 5;


-- Create a view showing order details with product names
CREATE VIEW OrderDetailsWithProductNames AS--blank
SELECT
    od.order_detail_id,
    o.order_id,
    p.product_name,
    od.quantity,
    od.unit_price,
    od.discount
FROM OrderDetails od
JOIN Products p ON od.product_id = p.product_id
LEFT JOIN Orders o ON od.order_id = o.order_id;
-- Retrieve data from the view
SELECT * FROM OrderDetailsWithProductNames;--------blank

-------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW OrderDetailsWithProductNames AS
SELECT
    od.order_detail_id,
    o.order_id,
    p.product_name,
    od.quantity,
    od.unit_price,
    od.discount
FROM OrderDetails od
LEFT JOIN Products p ON od.product_id = p.product_id
LEFT JOIN Orders o ON od.order_id = o.order_id;
-- Retrieve data from the view
SELECT * FROM OrderDetailsWithProductNames

-- Create a view showing total price per order detail
CREATE VIEW OrderDetailTotalPrice AS
SELECT
    order_detail_id,
    quantity * unit_price * (1 - discount) AS total_price
FROM OrderDetails;

-- Retrieve data from the total price view
SELECT * FROM OrderDetailTotalPrice;
----------------------------------------------------------------


--------------------JOINS----------------------------

-- Inner Join: Get customers and their orders
SELECT c.first_name, c.last_name, o.order_id
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id;

-- Left Join: Get all customers and their orders (if any)
SELECT c.first_name, c.last_name, o.order_id
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id;

-- Right Join: Get all orders and the corresponding customers (if any)
SELECT c.first_name, c.last_name, o.order_id
FROM Customers c
RIGHT JOIN Orders o ON c.customer_id = o.customer_id;

-- Full Outer Join: Get all customers and all orders, matching where possible
SELECT c.first_name, c.last_name, o.order_id
FROM Customers c
FULL OUTER JOIN Orders o ON c.customer_id = o.customer_id;

-- Multi-Join: Get customer names, order IDs, and product names for each order item
SELECT c.first_name, c.last_name, o.order_id, p.product_name, od.quantity
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id
INNER JOIN OrderDetails od ON o.order_id = od.order_id
INNER JOIN Products p ON od.product_id = p.product_id;--blank

SELECT c.first_name, c.last_name, o.order_id
FROM Customers c
INNER JOIN Orders o ON c.customer_id = o.customer_id;

SELECT o.order_id, od.order_detail_id
FROM Orders o
INNER JOIN OrderDetails od ON o.order_id = od.order_id;

SELECT od.order_detail_id, p.product_name
FROM OrderDetails od
INNER JOIN Products p ON od.product_id = p.product_id;--blank

SELECT c.first_name, c.last_name, o.order_id, p.product_name, od.quantity
FROM Customers c
LEFT JOIN Orders o ON c.customer_id = o.customer_id
LEFT JOIN OrderDetails od ON o.order_id = od.order_id
LEFT JOIN Products p ON od.product_id = p.product_id;

SELECT c.first_name, c.last_name, o.order_id, od.quantity, p.product_name
FROM OrderDetails od
RIGHT JOIN Products p ON od.product_id = p.product_id
LEFT JOIN Orders o ON od.order_id = o.order_id
LEFT JOIN Customers c ON o.customer_id = c.customer_id;


---------------	VIEW----------------------------
-- Create a simple view showing customer names and their order dates
CREATE VIEW CustomerOrders AS
SELECT c.first_name, c.last_name, o.order_date
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id;

-- Retrieve data from the view
SELECT * FROM CustomerOrders;

-- Create a view showing product names and their prices
CREATE VIEW ProductPrices AS
SELECT product_name, price
FROM Products;

-- Retrieve data from the product prices view
SELECT * FROM ProductPrices WHERE price > 20;


