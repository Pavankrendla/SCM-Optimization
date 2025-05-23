CREATE DATABASE IF NOT EXISTS SupplyChain;
USE SupplyChain;

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255),
    category VARCHAR(100),
    price FLOAT CHECK (price > 0)
);

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(255),
    location VARCHAR(255)
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT,
    warehouse_id INT,
    stock_quantity INT,
    last_updated DATE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    product_id INT,
    order_date DATE,
    quantity_ordered INT,
    status VARCHAR(50),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE shipments (
    shipment_id INT PRIMARY KEY,
    order_id INT,
    warehouse_id INT,
    shipped_date DATE,
    delivery_status VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id)
);


-- Trigger to auto-update inventory when a shipment is delivered
DELIMITER //
CREATE TRIGGER update_inventory_on_delivery
AFTER UPDATE ON shipments
FOR EACH ROW
BEGIN
    IF NEW.delivery_status = 'Delivered' THEN
        UPDATE inventory
        SET stock_quantity = stock_quantity - (
            SELECT quantity_ordered FROM orders WHERE order_id = NEW.order_id
        )
        WHERE product_id = (SELECT product_id FROM orders WHERE order_id = NEW.order_id)
        AND warehouse_id = NEW.warehouse_id;
    END IF;
END;
//
DELIMITER ;

-- Stored procedure to reorder stock when below threshold
DELIMITER //
CREATE PROCEDURE AutoReorder()
BEGIN
    INSERT INTO orders (product_id, order_date, quantity_ordered, status)
    SELECT product_id, CURDATE(), 50, 'Pending'
    FROM inventory
    WHERE stock_quantity < 10;
END;
//
DELIMITER ;
