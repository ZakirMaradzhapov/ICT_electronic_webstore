CREATE TABLE Cities(
city_ID INT PRIMARY KEY,
city_name VARCHAR(32) not null
);

CREATE TABLE Pickup_points(
point_ID INT PRIMARY KEY,
city_ID INT not null,
pickup_name VARCHAR(32) not null,--we will rename this column afterwards(point_name)
FOREIGN KEY (city_ID) REFERENCES Cities(city_ID)--in what city pick-up point is located
);

/*3 tables (Visitors, Customers, Cart) have a joint primary key, but primary key itself originates from Visitors table.
Cart table is linked with Customers table, not with Visitors, in order to avoid mistakes where a visitor who didn't add 
anything to cart has a cartID (according to DB rules, until a visitor adds at least one item to the cart, 
he or she will not be connected to Cart table). */

CREATE TABLE Visitors(
IP_address VARCHAR(15) PRIMARY KEY,
city_ID INT not null,
gender CHAR(6) not null,--we will delete this column afterwards
FOREIGN KEY (city_ID) REFERENCES Cities(city_ID)--city of a visitor
);

CREATE TABLE Customers(
IP_address VARCHAR(15)  PRIMARY KEY,--as every customer is a visitor, but not every visitor is a customer
f_name VARCHAR(32) not null,
l_name VARCHAR(32) not null,
birth_date DATE not null,
phone_num DEC(16) not null,
--email CHAR(50) not null,--we will add this column afterwards
FOREIGN KEY (IP_address) REFERENCES Visitors(IP_address) /*as a customer and visitor is the same person, 
but he or she is recorded in 2 tables*/
);

---------------

CREATE TABLE Cart(
cart_ID INT PRIMARY KEY,
IP_address VARCHAR(15),--we will add not null constraint to this column afterwards (IP_address VARCHAR(15) not null)
FOREIGN KEY (IP_address) REFERENCES Customers(IP_address)/*we link ID address with Customer table 
because visitors refers to people who haven't added anything to cart yet*/
);

CREATE FUNCTION get_city_of_point(pointID INT)
RETURNS INT
LANGUAGE plpgsql
AS
$$
DECLARE
correct_city INT;
BEGIN
SELECT city_ID INTO correct_city FROM Pickup_points WHERE point_ID = pointID;
RETURN correct_city;
END;
$$;
/*we need that function in order to get the city of a given pick-up point in the following CHECK constraint 
from ORDERS table (that’s because only scalar expressions are allowed in CHECK constraint)*/

CREATE FUNCTION get_city_of_customer(cartID INT)
RETURNS INT
LANGUAGE plpgsql
AS
$$
DECLARE
correct_city INT;
BEGIN
SELECT city_ID INTO correct_city FROM Visitors WHERE IP_address = (SELECT IP_address FROM Cart WHERE cart_ID = cartID);
RETURN correct_city;
END;
$$;
/*we need that function in order to get the city of a given customer in the following CHECK constraint 
from ORDERS table (that’s because only scalar expressions are allowed in CHECK constraint)*/

CREATE TABLE Orders(
cart_ID INT PRIMARY KEY,
point_ID INT,/*(is null only if delivered by a courier) in case the order is delivered by a courier, 
we don't have to go to the pick-up point*/
purchase_time DATE not null,--we need purchase time in order to know when the warranty of bought products ends
arrival_time DATE not null,
delivery_method CHAR(7) not null, --only two variants exist('courier' or 'pickup')
--CONSTRAINT arrival_after_purchase CHECK (arrival_time > purchase_time),--we will add this CHECK constraint afterwards
CONSTRAINT correct_city CHECK (get_city_of_customer(cart_ID) = get_city_of_point(point_ID)),/*a CHECK constraint that 
verifies that every paid order is shipped to the correct pick-up point, which must be in the same city as the buyer 
of the order*/
CONSTRAINT correct_delivery_method CHECK ((point_ID is null AND delivery_method = 'courier') 
										  OR (point_ID is not null AND delivery_method = 'pickup')),
/*if an order will be delivered by a courier, a customer doesn't have to to to the pick-up point, so point_ID shouldn't 
be mentioned. In case the customer decided to pick up the order in the available pick-up point, point_ID is mandatory*/
FOREIGN KEY (Cart_ID) REFERENCES Cart(Cart_ID), /*link the Orders table with Cart table so we can know what products 
an order cointains, the products's price etc*/
FOREIGN KEY (Point_ID) REFERENCES Pickup_points(Point_ID)--to what pick-up point the order must be delivered
);

------------------------

CREATE TABLE Categories(
category_ID INT PRIMARY KEY,
category_name VARCHAR(32) not null
);

CREATE TABLE Producers(
producer_ID INT PRIMARY KEY,
producer_name VARCHAR(32) not null
);

CREATE TABLE Products(
product_ID INT PRIMARY KEY,
category_ID INT not null,
producer_ID INT not null,
price INT not null CONSTRAINT no_free_products CHECK (price > 0),/*(the price in the column have already 
included discounts) we need no_free_products CHECK constraint in order not to skip mistakes that make products free*/
discount_amount DECIMAL(3,2) CONSTRAINT allowed_disc_range CHECK (discount_amount > 0 AND discount_amount < 1),
/* We need allowed_disc_range CHECK constraint in order to prevent a 100%(1.00) discount on a product. 
In case a discount wasn't set to the product, discount_amount is null*/
remain_quantity INT not null,
warranty_period VARCHAR(50),/*(is null only if a product doesn't have a warranty) 
also unclear is DATE (or DAY) data type appropriate to this column?*/
FOREIGN KEY (category_ID) REFERENCES Categories(category_ID),
FOREIGN KEY (producer_ID) REFERENCES Producers(producer_ID)
);

-----------------------

CREATE TABLE Cart_product(
product_ID INT not null,
cart_ID INT not null,
quantity INT not null CONSTRAINT existing_product CHECK (quantity > 0),/*because a customer must buy at least 
1 product in order to add it into the cart*/
FOREIGN KEY (product_ID) REFERENCES Products(product_ID),
FOREIGN KEY (cart_ID) REFERENCES Cart(cart_ID)
);


-------------------------------------------------------------------------
ALTER TABLE Customers ADD email CHAR(50);

ALTER TABLE Cart ALTER COLUMN IP_address SET not null;

ALTER TABLE Orders ADD CONSTRAINT arrival_after_purchase CHECK (arrival_time > purchase_time);/* because the order can't be 
delivered before purchase */

ALTER TABLE Visitors DROP COLUMN gender;

ALTER TABLE Pickup_points RENAME COLUMN pickup_name TO point_name;
---------------------------------------------------------------------------


INSERT INTO Cities(city_ID, city_name) VALUES
(40111, 'Astana'),
(40222, 'Almaty'),
(40333, 'Shymkent'),
(40444, 'Aktau'),
(40555, 'Atyrau'),
(40666, 'Aktobe'),
(40777, 'Turkistan'),
(40888, 'Kyzylorda'),
(40999, 'Karaganda'),
(40000, 'Ust-Kamenogorsk')
;

INSERT INTO Pickup_points(point_ID, city_ID, point_name) VALUES
(50111, 40111, 'Sulpak'),
(50222, 40222, 'Technodom'),
(50333, 40333, 'Mechta'),
(50444, 40444, 'Electricworld'),
(50555, 40555, 'Energy Life'),
(50666, 40666, 'MEGABiT'),
(50777, 40777, 'Electrobots'),
(50888, 40888, 'Istyleshop'),
(50999, 40999, 'MosBlack'),
(50000, 40000, 'Electro+')
;

INSERT INTO Visitors(IP_address, city_ID) VALUES
('101.231.41.111', 40111),
('102.232.42.122', 40222),
('103.233.43.133', 40333),
('104.234.44.144', 40444),
('105.235.45.155', 40555),
('106.236.46.166', 40666),
('107.237.47.177', 40777),
('108.238.48.188', 40888),
('109.239.49.199', 40999),
('110.240.50.100', 40000)
;

INSERT INTO Customers(IP_address, f_name, l_name, birth_date, phone_num, email) VALUES
('101.231.41.111', 'Michael', 'Aleksandrovich', '1999-01-11', 87788787878, 'michael1999@gmail.com'),
('102.232.42.122', 'Edil', 'Kanatbekov', '1989-02-01', 87786866868, 'k_edil@mail.ru'),
('103.233.43.133', 'Ilim', 'Kabaev', '2000-01-12', 87013012595, 'Kabev_I@mail.ru'),
('104.234.44.144', 'Seitek', 'Serikov', '1995-05-25', 87757757557, 'seitek95@gmail.com'),
('105.235.45.155', 'Darkhan', 'Anuarbekov', '2001-01-07', 87077078899, 'darkhan4ik@mail.ru'),
('106.236.46.166', 'Sanzhar', 'Temirbekovich', '1991-11-19', 87089634215, 'sanzhik@mail.ru'),
('107.237.47.177', 'Serik', 'Akhmetov', '1965-06-16', 87758597732, 'Serik1965@gmail.com'),
('108.238.48.188', 'Ainur', 'Mugauova', '1974-08-10', 87013014585, 'mugauovaa@mail.ru'),
('109.239.49.199', 'Adilet', 'Kenzhebaev', '1999-09-17', 87789699669, 'adikenti@mail.ru'),
('110.240.50.100', 'Aigul', 'Kushalieva', '2002-02-22', 87022226296, 'aigulchik@gmail.com')
;

INSERT INTO Cart(cart_ID, IP_address) VALUES
(1011, '101.231.41.111'),
(1022, '102.232.42.122'),
(1033, '103.233.43.133'),
(1044, '104.234.44.144'),
(1055, '105.235.45.155'),
(1066, '106.236.46.166'),
(1077, '107.237.47.177'),
(1088, '108.238.48.188'),
(1099, '109.239.49.199'),
(1100, '110.240.50.100')
;

INSERT INTO Orders(cart_ID, point_ID, purchase_time, arrival_time, delivery_method) VALUES
(1011, null, '2015-01-01', '2015-02-01', 'courier'),
(1022, 50222, '2015-02-02', '2015-02-05', 'pickup'),
(1033, 50333, '2016-05-10', '2016-05-15', 'pickup'),
(1044, 50444, '2016-06-06', '2016-06-09', 'pickup'),
(1055, null, '2017-05-08', '2017-06-07', 'courier'),
(1066, 50666, '2017-07-09', '2017-07-14', 'pickup'),
(1077, null, '2018-03-03', '2018-04-04', 'courier'),
(1088, null, '2018-04-06', '2018-05-07', 'courier'),
(1099, 50999, '2019-01-06', '2019-01-11', 'pickup'),
(1100, null, '2020-02-02', '2020-03-04', 'courier')
;

INSERT INTO Categories(category_ID, category_name) VALUES
(1111, 'computers'),
(2222, 'smartphones'),
(3333, 'laptops'),
(4444, 'cameras'),
(5555, 'household appliances'),
(6666, 'audio equipment'),
(7777, 'game consoles'),
(8888, 'TVs'),
(9999, 'home theater'),
(1000, 'tablets')
;

INSERT INTO Producers(producer_ID, producer_name) VALUES
(20001, 'Beko'),
(20002, 'Apple'),
(20003, 'Samsung'),
(20004, 'Panasonic'),
(20005, 'Xiaomi'),
(20006, 'LG'),
(20007, 'Sony'),
(20008, 'RAZER'),
(20009, 'HP'),
(20010, 'Lenovo')
;

INSERT INTO Products(product_ID, category_ID, producer_ID, price, discount_amount, remain_quantity, warranty_period) VALUES
(10001, 1111, 20002, 1300, null, 10, null),
(10002, 2222, 20002, 700, 0.20, 50, null),
(10003, 3333, 20008, 1990, 0.15, 200, '3 years 3 months 15 days'),
(10004, 5555, 20001, 351, 0.10, 150,  '2 years 0 months 0 days'),
(10005, 4444, 20004, 1440, null, 45, null),
(10006, 8888, 20003, 350, 0.20, 80, null),
(10007, 6666, 20005, 23, 0.15, 100,  '1 year 0 months 0 days'),
(10008, 1000, 20010, 239, null, 35, '1 year 0 months 0 days'),
(10009, 9999, 20006, 383, null, 48, '7 years 5 months 20 days'),
(10010, 7777, 20007, 770, 0.05, 170, '3 years 0 months 0 days'),
(10011, 1111, 20009, 1305, null, 33, null),
(10012, 6666, 20002, 140,0.10, 39, null),
(10013, 5555, 20006, 1612, 0.15, 50,  null),
(10014, 8888, 20004, 415, null, 36,  null),
(10015, 4444, 20007, 1014, 0.07, 100,  '2 years 2 months 20 days'),
(10016, 7777, 20007, 447, null, 40,  null),
(10017, 2222, 20005, 836, null, 150, '1 yeas 10 months 25 days'),
(10018, 1111, 20010, 813, null, 75,  '5 years 2 months 2 days'),
(10019, 3333, 20009, 2200, 0.30, 45,  null),
(10020, 1000, 20002, 2450, null, 35, null),
(10021, 6666, 20003, 150, 0.10, 200,  '5 years 11 months 1 day'),
(10022, 2222, 20003, 125, null, 62, null),
(10023, 3333, 20005, 1532, null, 24, '10 years 2 months 20 days'),
(10024, 5555, 20001, 176, null, 29, null),
(10025, 1111, 20010, 695, 0.25, 55, null)
;

INSERT INTO Cart_product(product_ID,cart_ID, quantity) VALUES
(10001, 1011, 1),
(10002, 1022, 3),
(10003, 1033, 1),
(10004, 1044, 5),
(10005, 1055, 2),
(10006, 1066, 4),
(10007, 1077, 8),
(10008, 1088, 5),
(10009, 1099, 3),
(10010, 1100, 2)
;