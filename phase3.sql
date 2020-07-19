/* 
CS4400: Introduction to Database Systems
Summer 2020
Phase III Template

Team 10
Ayush Nene (anene6)
Varun Vangala (vvangala3)
Akaash Para (apara3)


Directions:
Please follow all instructions from the Phase III assignment PDF.
This file must run without error for credit.
*/
/************** UTIL **************/
/* Feel free to add any utilty procedures you may need here */

-- Number:
-- Author: kachtani3@
-- Name: create_zero_inventory
-- Tested By: kachtani3@
DROP PROCEDURE IF EXISTS create_zero_inventory;
DELIMITER //
CREATE PROCEDURE create_zero_inventory(
	IN i_businessName VARCHAR(100),
    IN i_productId CHAR(5)
)
BEGIN
-- Type solution below
	IF (i_productId NOT IN (
		SELECT product_id FROM InventoryHasProduct WHERE inventory_business = i_businessName))
    THEN INSERT INTO InventoryHasProduct (inventory_business, product_id, count)
		VALUES (i_businessName, i_productId, 0);
	END IF;

-- End of solution
END //
DELIMITER ;


/************** INSERTS **************/

-- Number: I1
-- Author: anene6
-- Name: add_usage_log
DROP PROCEDURE IF EXISTS add_usage_log;
DELIMITER //
CREATE PROCEDURE add_usage_log(
	IN i_usage_log_id CHAR(5), 
    IN i_doctor_username VARCHAR(100),
    IN i_timestamp TIMESTAMP
)
BEGIN
-- Type solution below
IF (select count(*) from UsageLog where id = i_usage_log_id) = 0 THEN
    INSERT INTO UsageLog VALUES (i_usage_log_id, i_doctor_username, i_timestamp);
END IF;
-- End of solution
END //
DELIMITER ;

-- Number: I2
-- Author: anene6
-- Name: add_usage_log_entry
DROP PROCEDURE IF EXISTS add_usage_log_entry;
DELIMITER //
CREATE PROCEDURE add_usage_log_entry(
	IN i_usage_log_id CHAR(5), 
    IN i_product_id CHAR(5),
    IN i_count INT
)
BEGIN
-- Type solution below
declare hospitalname varchar(100);
declare item_count int;
if (select count(*) from UsageLog where id = i_usage_log_id) > 0 then
    select hospital
    into hospitalname 
    from Doctor
    where username in (
        select doctor from UsageLog 
        where id = i_usage_log_id
    );

    select `count` into item_count from InventoryHasProduct 
    where inventory_business = hospitalname
    and product_id = i_product_id;

    if (item_count >= i_count) then 
        update InventoryHasProduct 
        set `count` = item_count - i_count 
        where product_id = i_product_id
        and inventory_business = hospitalname;

        insert into UsageLogEntry values (i_usage_log_id, i_product_id, i_count);
    end if;
end if;


-- End of solution
END //
DELIMITER ;

-- Number: I3
-- Author: vvangala3
-- Name: add_business
DROP PROCEDURE IF EXISTS add_business;
DELIMITER //
CREATE PROCEDURE add_business(
	IN i_name VARCHAR(100),
    IN i_BusinessStreet VARCHAR(100),
    IN i_BusinessCity VARCHAR(100),
    IN i_BusinessState VARCHAR(30),
    IN i_BusinessZip CHAR(5),
    IN i_businessType ENUM('Hospital', 'Manufacturer'),
    IN i_maxDoctors INT,
    IN i_budget FLOAT(2),
    IN i_catalog_capacity INT,
    IN i_InventoryStreet VARCHAR(100),
    IN i_InventoryCity VARCHAR(100),
    IN i_InventoryState VARCHAR(30),
    IN i_InventoryZip CHAR(5)
)
BEGIN
-- Type solution below
    INSERT INTO Business(name, address_street, address_city, address_state, address_zip) VALUES (i_name, i_BusinessStreet, i_BusinessCity, i_BusinessState, i_BusinessZip);
    INSERT INTO inventory(owner, address_street, address_city, address_state, address_zip) VALUES (i_name, i_InventoryStreet, i_InventoryCity, i_InventoryState, i_InventoryZip);
    IF(i_businessType = 'Hospital') THEN
        INSERT INTO Hospital(name, max_doctors, budget) VALUES (i_name, i_maxDoctors, i_budget);
    END IF;
    IF (i_businessType = 'Manufacturer') THEN
        INSERT INTO Manufacturer(name, catalog_capacity) VALUES (i_name, i_catalog_capacity);
    END IF;
    -- End of solution
END //
DELIMITER ;

-- Number: I4
-- Author: kachtani3@
-- Name: add_transaction
DROP PROCEDURE IF EXISTS add_transaction;
DELIMITER //
CREATE PROCEDURE add_transaction(
	IN i_transaction_id CHAR(4), 
    IN i_hospital VARCHAR(100),
    IN i_date DATE
)
BEGIN
-- Type solution below

INSERT INTO Transaction(id, hospital, date) VALUES (i_transaction_id, i_hospital, i_date);

-- End of solution
END //
DELIMITER ;

-- Number: I5
-- Author: anene6
-- Name: add_transaction_item
DROP PROCEDURE IF EXISTS add_transaction_item;
DELIMITER //
CREATE PROCEDURE add_transaction_item(
    IN i_transactionId CHAR(4),
    IN i_productId CHAR(5),
    IN i_manufacturerName VARCHAR(100),
    IN i_purchaseCount INT)
BEGIN
-- Type solution below
declare hname varchar(100);
declare hBudget float(2) default 0.0;
declare manufcount int default 0;
declare pprice float(2) default 0.0;
declare cost double;
if (select count(*) from `Transaction` where id = i_transactionId) > 0 then
    select hospital
    into hname
    from `Transaction`
    where id = i_transactionId;

    select budget 
    into hBudget
    from Hospital
    where `name` = hname;

    select `count`
    into manufcount
    from InventoryHasProduct
    where inventory_business = i_manufacturerName
    and product_id = i_productId;
    
    select price into pprice
    from CatalogItem
    where manufacturer = i_manufacturerName and product_id = i_productId;

    set cost = pprice * i_purchaseCount;

    -- verify that manufacturer has the item (if not, then cost = 0) and 
    -- that total cost <= budget and manufacturer has enough items
    if cost > 0 and manufcount >= i_purchaseCount and cost <= hBudget then
        -- reduce budget
        update Hospital set budget = hBudget - cost where name = hname;
        
        -- increase hospital inventory
        if (select count(*) 
            from InventoryHasProduct 
            where inventory_business = hname
            and product_id = i_productId) > 0 
        then
            update InventoryHasProduct 
            set `count` = `count` + i_purchaseCount
            where inventory_business = hname
            and product_id = i_productId > 0;
        else
            insert into InventoryHasProduct
            values (hname, i_productId, i_purchaseCount);
        end if;

        -- decrease manufacturer inventory
        update InventoryHasProduct
        set `count` = `count` - i_purchaseCount
        where product_id = i_productId
        and inventory_business = i_manufacturerName;
        
        insert into transactionitem
        values (i_transactionId, i_manufacturerName, i_productId, i_purchaseCount);

    end if;
end if;
-- End of solution
END //
DELIMITER ;

-- Number: I6
-- Author: vvangala3
-- Name: add_user
DROP PROCEDURE IF EXISTS add_user;
DELIMITER //
CREATE PROCEDURE add_user(
	IN i_username VARCHAR(100),
    IN i_email VARCHAR(100),
    IN i_password VARCHAR(100),
    IN i_fname VARCHAR(50),
    IN i_lname VARCHAR(50),
    IN i_userType ENUM('Doctor', 'Admin', 'Doctor-Admin'),
    IN i_managingBusiness VARCHAR(100),
    IN i_workingHospital VARCHAR(100)
)
BEGIN
-- Type solution below
    INSERT INTO User(username, email, password, fname, lname) VALUES (i_username, i_email, sha(i_password), i_fname, i_lname);
    IF (i_userType like '%Doctor%') THEN
        INSERT INTO  Doctor(username, hospital, manager) VALUES(i_username, i_workingHospital, null);
    END IF;
    IF (i_userType like '%Admin%')THEN
        INSERT INTO Administrator(username, business) VALUES (i_username, i_managingBusiness);
    END IF;
-- End of solution
END //
DELIMITER ;

-- Number: I7
-- Author: vvangala3
-- Name: add_catalog_item
DROP PROCEDURE IF EXISTS add_catalog_item;
DELIMITER //
CREATE PROCEDURE add_catalog_item(
    IN i_manufacturerName VARCHAR(100),
	IN i_product_id CHAR(5),
    IN i_price FLOAT(2)
)
BEGIN
-- Type solution below
    INSERT into CatalogItem(manufacturer, product_id, price) VALUES (i_manufacturerName, i_product_id, i_price);
-- End of solution
END //
DELIMITER ;
    
-- Number: I8
-- Author: vvangala3
-- Name: add_product
DROP PROCEDURE IF EXISTS add_product;
DELIMITER //
CREATE PROCEDURE add_product(
	IN i_prod_id CHAR(5),
    IN i_color VARCHAR(30),
    IN i_name VARCHAR(30)
)
BEGIN
-- Type solution below
    INSERT INTO PRODUCT(id, name_color, name_type) VALUES (i_prod_id, i_color, i_name);
-- End of solution
END //
DELIMITER ;


/************** DELETES **************/
-- NOTE: Do not circumvent referential ON DELETE triggers by manually deleting parent rows

-- Number: D1
-- Author: vvangala3
-- Name: delete_product
DROP PROCEDURE IF EXISTS delete_product;
DELIMITER //
CREATE PROCEDURE delete_product(
    IN i_product_id CHAR(5)
)
BEGIN
-- Type solution below
DELETE FROM PRODUCT where product_id = i_prod_id;
-- End of solution
END //
DELIMITER ;

-- Number: D2
-- Author: vvangala3
-- Name: delete_zero_inventory
DROP PROCEDURE IF EXISTS delete_zero_inventory;
DELIMITER //
CREATE PROCEDURE delete_zero_inventory()
BEGIN
-- Type solution below
DELETE FROM Inventory where owner in (SELECT inventory_business from InventoryHasProduct GROUP BY inventory_business HAVING SUM(count) = 0);
-- End of solution
END //
DELIMITER ;

-- Number: D3
-- Author: ftsang3@
-- Name: delete_business
DROP PROCEDURE IF EXISTS delete_business;
DELIMITER //
CREATE PROCEDURE delete_business(
    IN i_businessName VARCHAR(100)
)
BEGIN
-- Type solution below
	DELETE FROM Business where name = i_businessName;
-- End of solution
END //
DELIMITER ;

-- Number: D4
-- Author: vvangala3
-- Name: delete_user
DROP PROCEDURE IF EXISTS delete_user;
DELIMITER //
CREATE PROCEDURE delete_user(
    IN i_username VARCHAR(100)
)
BEGIN
-- Type solution below
    DELETE FROM User where username = i_username;
-- End of solution
END //
DELIMITER ;	

-- Number: D5
-- Author: vvangala3
-- Name: delete_catalog_item
DROP PROCEDURE IF EXISTS delete_catalog_item;
DELIMITER //
CREATE PROCEDURE delete_catalog_item(
    IN i_manufacturer_name VARCHAR(100),
    IN i_product_id CHAR(5)
)
BEGIN
-- Type solution below
    DELETE FROM CatalogItem where (manufacturer = i_manufacturer_name AND product_id = i_product_id);
-- End of solution
END //
DELIMITER ;


/************** UPDATES **************/

-- Number: U1
-- Author: anene6
-- Name: add_subtract_inventory
DROP PROCEDURE IF EXISTS add_subtract_inventory;
DELIMITER //
CREATE PROCEDURE add_subtract_inventory(
	IN i_prod_id CHAR(5),
    IN i_businessName VARCHAR(100),
    IN i_delta INT
)
BEGIN
-- Type solution below
    declare amt int default 0;
    -- if there is no entry in the table, add one
    if (
        select count(*) 
        from InventoryHasProduct 
        where inventory_business = i_businessName
        and product_id = i_prod_id
    ) = 0 then 
        if i_delta > 0 then
            insert into InventoryHasProduct values (i_businessName, i_prod_id, i_delta);
        end if;
    else
        -- there is an entry already
        select count 
        into amt
        from InventoryHasProduct
        where inventory_business = i_businessName
        and product_id = i_prod_id;

        set amt = amt + i_delta;
        -- never have less than 0
        if amt < 0 then
            set amt = 0;
        end if;

        -- if the item isn't there anymore then delete the row
        if amt = 0 then
            delete from InventoryHasProduct 
            where inventory_business = i_businessName 
            and product_id = i_prod_id;
        else
            update InventoryHasProduct
            set count = amt
            where inventory_business = i_businessName 
            and product_id = i_prod_id;
        end if;
    end if;

-- End of solution
END //
DELIMITER ;

-- Number: U2
-- Author: anene6
-- Name: move_inventory
DROP PROCEDURE IF EXISTS move_inventory;
DELIMITER //
CREATE PROCEDURE move_inventory(
    IN i_supplierName VARCHAR(100),
    IN i_consumerName VARCHAR(100),
    IN i_productId CHAR(5),
    IN i_count INT)
BEGIN
-- Type solution below
    -- check if supplier has enough
    if (
        select count
        from InventoryHasProduct
        where product_id = i_productId
        and inventory_business = i_supplierName
    ) >= i_count then
        call add_subtract_inventory(i_productId, i_supplierName, i_count * -1);
        call add_subtract_inventory(i_productId, i_consumerName, i_count);
    end if;
-- End of solution
END //
DELIMITER ;

-- Number: U3
-- Author: anene6
-- Name: rename_product_id
DROP PROCEDURE IF EXISTS rename_product_id;
DELIMITER //
CREATE PROCEDURE rename_product_id(
    IN i_product_id CHAR(5),
    IN i_new_product_id CHAR(5)
)
BEGIN
-- Type solution below
    update Product
    set id = i_new_product_id
    where id = i_product_id;
-- End of solution
END //
DELIMITER ;

-- Number: U4
-- Author: anene6
-- Name: update_business_address
DROP PROCEDURE IF EXISTS update_business_address;
DELIMITER //
CREATE PROCEDURE update_business_address(
    IN i_name VARCHAR(100),
    IN i_address_street VARCHAR(100),
    IN i_address_city VARCHAR(100),
    IN i_address_state VARCHAR(30),
    IN i_address_zip CHAR(5)
)
BEGIN
-- Type solution below
update Business 
set
    address_city = i_address_city,
    address_street = i_address_street,
    address_zip = i_address_zip,
    address_state = i_address_state
where name = i_name;
-- End of solution
END //
DELIMITER ;

-- Number: U5
-- Author: anene6
-- Name: charge_hospital
DROP PROCEDURE IF EXISTS charge_hospital;
DELIMITER //
CREATE PROCEDURE charge_hospital(
    IN i_hospital_name VARCHAR(100),
    IN i_amount FLOAT(2))
BEGIN
-- Type solution below
declare hbudget float(2) default 0.0;
select budget
into hbudget
from Hospital
where name = i_hospital_name;

set hbudget = hbudget - i_amount;
if hbudget >= 0.0 then 
    update Hospital
    set budget = hbudget
    where name = i_hospital_name;
end if;
-- End of solution
END //
DELIMITER ;

-- Number: U6
-- Author: anene6
-- Name: update_business_admin
DROP PROCEDURE IF EXISTS update_business_admin;
DELIMITER //
CREATE PROCEDURE update_business_admin(
	IN i_admin_username VARCHAR(100),
	IN i_business_name VARCHAR(100)
)
BEGIN
-- Type solution below
-- ensure that no business is left without an admin
if (
    select count(*) 
    from Administrator
    where business = (
        select business from Administrator
        where username = i_admin_username
    )) > 1 then -- there are at least 2 administrators for this business
        update Administrator
        set business = i_business_name
        where username = i_admin_username;
    end if;
-- End of solution
END //
DELIMITER ;

-- Number: U7
-- Author: ftsang3@
-- Name: update_doctor_manager
DROP PROCEDURE IF EXISTS update_doctor_manager;
DELIMITER //
CREATE PROCEDURE update_doctor_manager(
    IN i_doctor_username VARCHAR(100),
    IN i_manager_username VARCHAR(100)
)
BEGIN
-- Type solution below
IF i_doctor_username <> i_manager_username
    THEN
		UPDATE Doctor SET manager = i_manager_username WHERE username = i_doctor_username;
	END IF;
-- End of solution
END //
DELIMITER ;

-- Number: U8
-- Author: anene6
-- Name: update_user_password
DROP PROCEDURE IF EXISTS update_user_password;
DELIMITER //
CREATE PROCEDURE update_user_password(
    IN i_username VARCHAR(100),
	IN i_new_password VARCHAR(100)
)
BEGIN
-- Type solution below
    update User
    set password = SHA(i_new_password)
    where username = i_username;
-- End of solution
END //
DELIMITER ;

-- Number: U9
-- Author: vvangala3
-- Name: batch_update_catalog_item
DROP PROCEDURE IF EXISTS batch_update_catalog_item;
DELIMITER //
CREATE PROCEDURE batch_update_catalog_item(
    IN i_manufacturer_name VARCHAR(100),
    IN i_factor FLOAT(2))
BEGIN
-- Type solution below
Update CatalogItem SET price = price*i_factor where (manufacturer = i_manufacturer_name);
-- End of solution
END //
DELIMITER ;

/************** SELECTS **************/
-- NOTE: "SELECT * FROM USER" is just a dummy query
-- to get the script to run. You will need to replace that line 
-- with your solution.

-- Number: S1
-- Author: apara3
-- Name: hospital_transactions_report
DROP PROCEDURE IF EXISTS hospital_transactions_report;
DELIMITER //
CREATE PROCEDURE hospital_transactions_report(
    IN i_hospital VARCHAR(100),
    IN i_sortBy ENUM('', 'id', 'date'),
    IN i_sortDirection ENUM('', 'DESC', 'ASC')
)
BEGIN
    DROP TABLE IF EXISTS hospital_transactions_report_result;
    CREATE TABLE hospital_transactions_report_result(
        id CHAR(4),
        manufacturer VARCHAR(100),
        hospital VARCHAR(100),
        total_price FLOAT,
        date DATE);

    INSERT INTO hospital_transactions_report_result
-- Type solution below
	SELECT id, transactionitem.manufacturer, hospital, ROUND(SUM(price * count), 2) as total_price, date
    FROM transaction JOIN transactionitem
    ON transaction.id = transactionitem.transaction_id
    JOIN catalogitem ON catalogitem.manufacturer = transactionitem.manufacturer
    AND catalogitem.product_id = transactionitem.product_id
    WHERE hospital = i_hospital
    GROUP BY id, manufacturer, hospital
    ORDER BY
		(CASE
			WHEN i_sortBy = 'id' and i_sortDirection = 'DESC'
				THEN id
			WHEN i_sortBy = 'date' and i_sortDirection = 'DESC'
				THEN date
		END) DESC,
        (CASE
			WHEN i_sortBy = 'id' and i_sortDirection = 'ASC'
				THEN id
			WHEN i_sortBy = 'date' and i_sortDirection = 'ASC'
				THEN date
		END) ASC;
        
        

-- End of solution
END //
DELIMITER ;

-- Number: S2
-- Author: apara3
-- Name: num_of_admin_list
DROP PROCEDURE IF EXISTS num_of_admin_list;
DELIMITER //
CREATE PROCEDURE num_of_admin_list()
BEGIN
    DROP TABLE IF EXISTS num_of_admin_list_result;
    CREATE TABLE num_of_admin_list_result(
        businessName VARCHAR(100),
        businessType VARCHAR(100),
        numOfAdmin INT);

    INSERT INTO num_of_admin_list_result
-- Type solution below
     SELECT H.name, 'Hospital', count(*)
    FROM Hospital AS H, Administrator AS A
    WHERE name = business
    GROUP BY H.name
    UNION
    SELECT M.name, 'Manufacturer', count(*)
    FROM Manufacturer AS M, Administrator AS A
    WHERE name = business
    GROUP BY M.name;
-- End of solution
END //
DELIMITER ;

-- Number: S3
-- Author: apara3
-- Name: product_usage_list
DROP PROCEDURE IF EXISTS product_usage_list;
DELIMITER //
CREATE PROCEDURE product_usage_list()

BEGIN
    DROP TABLE IF EXISTS product_usage_list_result;
    CREATE TABLE product_usage_list_result(
        product_id CHAR(5),
        product_color VARCHAR(30),
        product_type VARCHAR(30),
        num INT);

    INSERT INTO product_usage_list_result
-- Type solution below
    SELECT product_id, name_color, name_type, SUM(count) as num 
    FROM usagelogentry 
    JOIN product on product.id = usagelogentry.product_id 
    GROUP BY product_id 
    ORDER BY SUM(COUNT) DESC;
-- End of solution
END //
DELIMITER ;

-- Number: S4
-- Author: apara3
-- Name: hospital_total_expenditure
DROP PROCEDURE IF EXISTS hospital_total_expenditure;
DELIMITER //
CREATE PROCEDURE hospital_total_expenditure()

BEGIN
    DROP TABLE IF EXISTS hospital_total_expenditure_result;
    CREATE TABLE hospital_total_expenditure_result(
        hospitalName VARCHAR(100),
        totalExpenditure FLOAT,
        transaction_count INT,
        avg_cost FLOAT);

    INSERT INTO hospital_total_expenditure_result
-- Type solution below
	SELECT transaction.hospital, 
    ROUND(SUM(catalogitem.price * transactionitem.count), 2) as totalExpenditure,
    COUNT(DISTINCT id) as transaction_count,
    ROUND(ROUND(SUM(catalogitem.price * transactionitem.count), 2) /COUNT(DISTINCT id), 2) as avg_cost
    FROM transactionitem 
    join transaction on transaction.id = transactionitem.transaction_id
    join catalogitem on catalogitem.product_id = transactionitem.product_id
    AND catalogitem.manufacturer = transactionitem.manufacturer
    GROUP BY transaction.hospital;
-- End of solution
END //
DELIMITER ;

-- Number: S5
-- Author: apara3
-- Name: manufacturer_catalog_report
DROP PROCEDURE IF EXISTS manufacturer_catalog_report;
DELIMITER //
CREATE PROCEDURE manufacturer_catalog_report(
    IN i_manufacturer VARCHAR(100))
BEGIN
    DROP TABLE IF EXISTS manufacturer_catalog_report_result;
    CREATE TABLE manufacturer_catalog_report_result(
        name_color VARCHAR(30),
        name_type VARCHAR(30),
        price FLOAT(2),
        num_sold INT,
        revenue FLOAT(2));

    INSERT INTO manufacturer_catalog_report_result
-- Type solution below
	SELECT name_color, name_type, price, IFNULL(SUM(transactionitem.count), 0) as num_sold,  
	IFNULL(ROUND(SUM(price * transactionitem.count), 2), 0) as revenue
    FROM transaction join transactionitem ON
    transaction.id = transactionitem.transaction_id
    RIGHT OUTER JOIN catalogitem on catalogitem.manufacturer = transactionitem.manufacturer
    AND catalogitem.product_id = transactionitem.product_id
    RIGHT OUTER JOIN product on product.id = catalogitem.product_id
    WHERE catalogitem.manufacturer = "Marietta Mask Production Company"
    GROUP BY name_color, name_type;

-- End of solution
END //
DELIMITER ;

-- Number: S6
-- Author: apara3
-- Name: doctor_subordinate_usage_log_report
DROP PROCEDURE IF EXISTS doctor_subordinate_usage_log_report;
DELIMITER //
CREATE PROCEDURE doctor_subordinate_usage_log_report(
    IN i_drUsername VARCHAR(100))
BEGIN
    DROP TABLE IF EXISTS doctor_subordinate_usage_log_report_result;
    CREATE TABLE doctor_subordinate_usage_log_report_result(
        id CHAR(5),
        doctor VARCHAR(100),
        timestamp TIMESTAMP,
        product_id CHAR(5),
        count INT);

    INSERT INTO doctor_subordinate_usage_log_report_result
-- Type solution below
	SELECT id, doctor, timestamp, product_id, count from usagelog JOIN usagelogentry ON usagelogentry.usage_log_id = usagelog.id where doctor in (SELECT username from doctor where manager = 'drmcdaniel');
-- End of solution
END //
DELIMITER ;

-- Number: S7
-- Author: apara3
-- Name: explore_product
DROP PROCEDURE IF EXISTS explore_product;
DELIMITER //
CREATE PROCEDURE explore_product(
    IN i_product_id CHAR(5))
BEGIN
    DROP TABLE IF EXISTS explore_product_result;
    CREATE TABLE explore_product_result(
        manufacturer VARCHAR(100),
        count INT,
        price FLOAT(2));

    INSERT INTO explore_product_result
-- Type solution below
    SELECT catalogitem.manufacturer as manufacturer, inventoryhasproduct.count as count, catalogitem.price as price FROM catalogitem 
    JOIN inventoryhasproduct ON catalogitem.manufacturer = inventoryhasproduct.inventory_business
    AND catalogitem.product_id = inventoryhasproduct.product_id
    WHERE inventoryhasproduct.product_id = i_product_id;
-- End of solution
END //
DELIMITER ;

-- Number: S8
-- Author: apara3
-- Name: show_product_usage
DROP PROCEDURE IF EXISTS show_product_usage;
DELIMITER //
CREATE PROCEDURE show_product_usage()
BEGIN
    DROP TABLE IF EXISTS show_product_usage_result;
    CREATE TABLE show_product_usage_result(
        product_id CHAR(5),
        num_used INT,
        num_available INT,
        ratio FLOAT);

    INSERT INTO show_product_usage_result
-- Type solution below
	    SELECT used.id, IFNULL(num_used, 0) as num_used, IFNULL(num_available, 0) as num_available, ROUND(IFNULL(num_used/num_available, 0), 2) as ratio  FROM
(SELECT id from product) as p1
	LEFT OUTER JOIN
(SELECT id, SUM(count) as num_available
	FROM product
    RIGHT OUTER JOIN inventoryhasproduct on inventoryhasproduct.product_id = product.id
    WHERE inventory_business IN
    (SELECT name from manufacturer)
    GROUP BY id) as available ON available.id = p1.id
	RIGHT OUTER JOIN
(SELECT id, SUM(count) as num_used
	FROM product LEFT OUTER JOIN usagelogentry
    on product.id = usagelogentry.product_id
    GROUP BY id) as used
    ON used.id = available.id
    ORDER BY id;
-- End of solution
END //
DELIMITER ;

-- Number: S9
-- Author: apara3
-- Name: show_hospital_aggregate_usage
DROP PROCEDURE IF EXISTS show_hospital_aggregate_usage;
DELIMITER //
CREATE PROCEDURE show_hospital_aggregate_usage()
BEGIN
    DROP TABLE IF EXISTS show_hospital_aggregate_usage_result;
    CREATE TABLE show_hospital_aggregate_usage_result(
        hospital VARCHAR(100),
        items_used INT);

    INSERT INTO show_hospital_aggregate_usage_result
-- Type solution below

    -- with doctor_usage as (
    --     select Doctor.username as doctor, Doctor.hospital, sum(UsageLogEntry.count) as doctor_use
    --     from Doctor join UsageLog on Doctor.username = UsageLog.doctor
    --     join UsageLogEntry on UsageLogEntry.usage_log_id = UsageLog.id
    --     group by Doctor.username, Doctor.hospital
    -- )
    -- select hospital, sum(doctor_use)
    -- from doctor_usage 
    -- group by hospital;
    select Doctor.hospital, sum(UsageLogEntry.count)
    from Doctor join UsageLog on Doctor.username = UsageLog.doctor
    join UsageLogEntry on UsageLogEntry.usage_log_id = UsageLog.id
    group by Doctor.hospital;

-- End of solution
END //
DELIMITER ;

-- Number: S10
-- Author: apara3
-- Name: business_search
DROP PROCEDURE IF EXISTS business_search;
DELIMITER //
CREATE PROCEDURE business_search (
    IN i_search_parameter ENUM("name","street", "city", "state", "zip"),
    IN i_search_value VARCHAR(100))
BEGIN
	DROP TABLE IF EXISTS business_search_result;
    CREATE TABLE business_search_result(
        name VARCHAR(100),
		address_street VARCHAR(100),
		address_city VARCHAR(100),
		address_state VARCHAR(30),
		address_zip CHAR(5));

    INSERT INTO business_search_result
-- Type solution below
	SELECT * FROM business WHERE
		(CASE
			WHEN i_search_parameter = "name" 
				THEN name like CONCAT('%', i_search_value, '%')
			WHEN i_search_parameter = "street"
				THEN address_street like CONCAT('%', i_search_value, '%')
			WHEN i_search_parameter = "city"
				THEN address_city like CONCAT('%', i_search_value, '%')
			WHEN i_search_parameter = "state"
				THEN address_state like CONCAT('%', i_search_value, '%') 
			WHEN i_search_parameter = "zip"
				THEN address_zip like CONCAT('%', i_search_value, '%')
			ELSE
				1 = 1
		END);
-- End of solution
END //
DELIMITER ;

-- Number: S11
-- Author: apara3
-- Name: manufacturer_transaction_report
DROP PROCEDURE IF EXISTS manufacturer_transaction_report;
DELIMITER //
CREATE PROCEDURE manufacturer_transaction_report(
    IN i_manufacturer VARCHAR(100))
    
BEGIN
    DROP TABLE IF EXISTS manufacturer_transaction_report_result;
    CREATE TABLE manufacturer_transaction_report_result(
        id CHAR(4),
        hospital VARCHAR(100),
        `date` DATE,
        cost FLOAT(2),
        total_count INT);

    INSERT INTO manufacturer_transaction_report_result
-- Type solution below
    SELECT id, hospital, `date`, ROUND(SUM(price * count), 2) as cost, SUM(count) as total_count
    FROM transactionitem JOIN `transaction` ON transactionitem.transaction_id = `transaction`.id
    JOIN catalogitem on catalogitem.product_id = transactionitem.product_id and catalogitem.manufacturer = transactionitem.manufacturer
    WHERE transactionitem.manufacturer = 'PPE Empire'
    GROUP BY id;
-- End of solution
END //
DELIMITER ;

-- Number: S12
-- Author: apara3
-- Name: get_user_types
-- Tested By: apara3
DROP PROCEDURE IF EXISTS get_user_types;
DELIMITER //
CREATE PROCEDURE get_user_types()
BEGIN
DROP TABLE IF EXISTS get_user_types_result;
    CREATE TABLE get_user_types_result(
        username VARCHAR(100),
        UserType VARCHAR(50));
	INSERT INTO get_user_types_result
-- Type solution below
	SELECT username, 
	IF (username in (SELECT administrator.username from administrator) and username in (select doctor.username from doctor) and username in (select doctor.manager from doctor)
		,'Doctor-Admin-Manager', 
	IF (username in (SELECT doctor.username from doctor) and username in (SELECT administrator.username from administrator)
		,'Doctor-Admin',
	IF (username in (SELECT doctor.username from doctor) and username in (SELECT doctor.manager from doctor)
		, 'Doctor-Manager',
	IF (username in (SELECT doctor.username from doctor)
		,'Doctor', 'Admin')))) as UserType FROM User;
-- End of solution
END //
DELIMITER ;