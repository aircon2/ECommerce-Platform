-- Sample Data for E-commerce Analytics Dashboard
-- This file contains realistic sample data for all tables

-- Insert sample customers
INSERT INTO customers (first_name, last_name, email, phone, address, city, state, zip_code, country, registration_date, customer_segment, total_spent, last_purchase_date) VALUES
('John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', '10001', 'USA', '2023-01-15', 'Gold', 1250.75, '2024-01-10'),
('Sarah', 'Johnson', 'sarah.j@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90210', 'USA', '2023-02-20', 'Platinum', 3200.50, '2024-01-12'),
('Mike', 'Davis', 'mike.davis@email.com', '555-0103', '789 Pine St', 'Chicago', 'IL', '60601', 'USA', '2023-03-10', 'Silver', 850.25, '2024-01-08'),
('Emily', 'Wilson', 'emily.wilson@email.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001', 'USA', '2023-04-05', 'Bronze', 450.00, '2023-12-15'),
('David', 'Brown', 'david.brown@email.com', '555-0105', '654 Maple Dr', 'Phoenix', 'AZ', '85001', 'USA', '2023-05-12', 'Gold', 1800.30, '2024-01-11'),
('Lisa', 'Garcia', 'lisa.garcia@email.com', '555-0106', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 'USA', '2023-06-18', 'Silver', 720.80, '2024-01-09'),
('Robert', 'Martinez', 'robert.m@email.com', '555-0107', '147 Birch St', 'San Antonio', 'TX', '78201', 'USA', '2023-07-22', 'Bronze', 320.45, '2023-12-20'),
('Jennifer', 'Anderson', 'jennifer.a@email.com', '555-0108', '258 Spruce Ave', 'San Diego', 'CA', '92101', 'USA', '2023-08-30', 'Platinum', 4500.75, '2024-01-13'),
('William', 'Taylor', 'william.taylor@email.com', '555-0109', '369 Walnut St', 'Dallas', 'TX', '75201', 'USA', '2023-09-14', 'Gold', 2100.60, '2024-01-07'),
('Amanda', 'Thomas', 'amanda.thomas@email.com', '555-0110', '741 Cherry Dr', 'San Jose', 'CA', '95101', 'USA', '2023-10-25', 'Silver', 680.90, '2024-01-06'),
('Christopher', 'Hernandez', 'chris.h@email.com', '555-0111', '852 Poplar Ln', 'Austin', 'TX', '73301', 'USA', '2023-11-08', 'Bronze', 280.15, '2023-12-18'),
('Jessica', 'Moore', 'jessica.moore@email.com', '555-0112', '963 Ash St', 'Jacksonville', 'FL', '32201', 'USA', '2023-12-01', 'Gold', 1650.40, '2024-01-05'),
('Daniel', 'Jackson', 'daniel.jackson@email.com', '555-0113', '159 Hickory Ave', 'Fort Worth', 'TX', '76101', 'USA', '2024-01-03', 'Bronze', 150.75, '2024-01-03'),
('Ashley', 'White', 'ashley.white@email.com', '555-0114', '357 Sycamore St', 'Columbus', 'OH', '43201', 'USA', '2024-01-08', 'Silver', 420.30, '2024-01-08'),
('Matthew', 'Harris', 'matt.harris@email.com', '555-0115', '468 Dogwood Dr', 'Charlotte', 'NC', '28201', 'USA', '2024-01-12', 'Gold', 950.85, '2024-01-12');

-- Insert sample products
INSERT INTO products (product_name, category, subcategory, brand, price, cost, stock_quantity, description, created_date, is_active, weight_kg, dimensions) VALUES
('Wireless Bluetooth Headphones', 'Electronics', 'Audio', 'TechSound', 89.99, 45.00, 150, 'High-quality wireless headphones with noise cancellation', '2023-01-10', TRUE, 0.3, '20x15x8 cm'),
('Smart Fitness Watch', 'Electronics', 'Wearables', 'FitTech', 199.99, 95.00, 75, 'Advanced fitness tracking with heart rate monitor', '2023-01-15', TRUE, 0.05, '4x4x1 cm'),
('Organic Cotton T-Shirt', 'Clothing', 'Tops', 'EcoWear', 24.99, 12.00, 300, 'Comfortable organic cotton t-shirt in various colors', '2023-02-01', TRUE, 0.2, 'M-L-XL'),
('Leather Crossbody Bag', 'Accessories', 'Bags', 'LeatherCraft', 79.99, 35.00, 50, 'Genuine leather crossbody bag with multiple compartments', '2023-02-10', TRUE, 0.8, '25x20x8 cm'),
('Stainless Steel Water Bottle', 'Home & Garden', 'Kitchen', 'HydroLife', 19.99, 8.00, 200, 'Insulated stainless steel water bottle, 32oz', '2023-02-15', TRUE, 0.4, '25x7x7 cm'),
('Wireless Phone Charger', 'Electronics', 'Accessories', 'PowerUp', 29.99, 15.00, 120, 'Fast wireless charging pad for smartphones', '2023-03-01', TRUE, 0.3, '10x10x1 cm'),
('Denim Jeans', 'Clothing', 'Bottoms', 'DenimCo', 59.99, 25.00, 180, 'Classic blue denim jeans with stretch', '2023-03-10', TRUE, 0.6, '30-40 inch waist'),
('Bluetooth Speaker', 'Electronics', 'Audio', 'SoundWave', 49.99, 22.00, 90, 'Portable Bluetooth speaker with 12-hour battery', '2023-03-15', TRUE, 0.5, '15x8x8 cm'),
('Ceramic Coffee Mug', 'Home & Garden', 'Kitchen', 'MugMaster', 12.99, 5.00, 250, 'Handcrafted ceramic coffee mug, dishwasher safe', '2023-04-01', TRUE, 0.3, '10x10x12 cm'),
('Running Shoes', 'Sports', 'Footwear', 'RunFast', 129.99, 65.00, 100, 'Lightweight running shoes with cushioned sole', '2023-04-10', TRUE, 0.7, 'US 7-12'),
('Laptop Stand', 'Electronics', 'Accessories', 'DeskPro', 39.99, 18.00, 60, 'Adjustable aluminum laptop stand for ergonomic work', '2023-04-15', TRUE, 0.8, '30x20x15 cm'),
('Yoga Mat', 'Sports', 'Fitness', 'FlexiMat', 34.99, 16.00, 80, 'Non-slip yoga mat with carrying strap', '2023-05-01', TRUE, 1.2, '180x60x0.5 cm'),
('LED Desk Lamp', 'Home & Garden', 'Lighting', 'BrightLight', 45.99, 20.00, 70, 'Adjustable LED desk lamp with USB charging port', '2023-05-10', TRUE, 0.6, '35x25x15 cm'),
('Canvas Backpack', 'Accessories', 'Bags', 'PackIt', 49.99, 22.00, 110, 'Durable canvas backpack with laptop compartment', '2023-05-15', TRUE, 0.9, '45x30x15 cm'),
('Protein Powder', 'Health', 'Supplements', 'FitFuel', 39.99, 18.00, 140, 'Whey protein powder, vanilla flavor, 2lb container', '2023-06-01', TRUE, 0.9, '15x15x20 cm');

-- Insert sample orders
INSERT INTO orders (customer_id, order_date, status, total_amount, shipping_address, shipping_city, shipping_state, shipping_zip, shipping_cost, tax_amount, discount_amount, promo_code, notes) VALUES
(1, '2024-01-10 14:30:00', 'Delivered', 89.99, '123 Main St', 'New York', 'NY', '10001', 5.99, 7.20, 0.00, NULL, 'Gift wrapping requested'),
(2, '2024-01-12 09:15:00', 'Delivered', 279.98, '456 Oak Ave', 'Los Angeles', 'CA', '90210', 7.99, 22.40, 20.00, 'SAVE20', 'Express shipping'),
(3, '2024-01-08 16:45:00', 'Shipped', 84.98, '789 Pine St', 'Chicago', 'IL', '60601', 5.99, 6.80, 0.00, NULL, 'Fragile items'),
(4, '2023-12-15 11:20:00', 'Delivered', 24.99, '321 Elm St', 'Houston', 'TX', '77001', 4.99, 2.00, 0.00, NULL, 'Standard shipping'),
(5, '2024-01-11 13:10:00', 'Processing', 199.99, '654 Maple Dr', 'Phoenix', 'AZ', '85001', 6.99, 16.00, 0.00, NULL, 'Priority handling'),
(6, '2024-01-09 10:30:00', 'Delivered', 109.98, '987 Cedar Ln', 'Philadelphia', 'PA', '19101', 5.99, 8.80, 10.00, 'WELCOME10', 'Customer service follow-up'),
(7, '2023-12-20 15:45:00', 'Delivered', 59.99, '147 Birch St', 'San Antonio', 'TX', '78201', 4.99, 4.80, 0.00, NULL, 'Standard delivery'),
(8, '2024-01-13 08:20:00', 'Shipped', 449.97, '258 Spruce Ave', 'San Diego', 'CA', '92101', 9.99, 36.00, 50.00, 'VIP50', 'White glove delivery'),
(9, '2024-01-07 12:15:00', 'Delivered', 169.98, '369 Walnut St', 'Dallas', 'TX', '75201', 6.99, 13.60, 0.00, NULL, 'Signature required'),
(10, '2024-01-06 14:40:00', 'Delivered', 49.99, '741 Cherry Dr', 'San Jose', 'CA', '95101', 4.99, 4.00, 0.00, NULL, 'Standard shipping'),
(11, '2023-12-18 09:30:00', 'Delivered', 19.99, '852 Poplar Ln', 'Austin', 'TX', '73301', 3.99, 1.60, 0.00, NULL, 'Economy shipping'),
(12, '2024-01-05 16:20:00', 'Delivered', 129.99, '963 Ash St', 'Jacksonville', 'FL', '32201', 5.99, 10.40, 0.00, NULL, 'Gift message included'),
(13, '2024-01-03 11:45:00', 'Delivered', 24.99, '159 Hickory Ave', 'Fort Worth', 'TX', '76101', 4.99, 2.00, 0.00, NULL, 'First-time customer'),
(14, '2024-01-08 13:25:00', 'Delivered', 34.99, '357 Sycamore St', 'Columbus', 'OH', '43201', 4.99, 2.80, 0.00, NULL, 'Standard delivery'),
(15, '2024-01-12 10:10:00', 'Processing', 89.99, '468 Dogwood Dr', 'Charlotte', 'NC', '28201', 5.99, 7.20, 0.00, NULL, 'Rush order');

-- Insert sample order items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
(1, 1, 1, 89.99, 89.99),
(2, 2, 1, 199.99, 199.99),
(2, 4, 1, 79.99, 79.99),
(3, 1, 1, 89.99, 89.99),
(3, 5, 1, 19.99, 19.99),
(4, 3, 1, 24.99, 24.99),
(5, 2, 1, 199.99, 199.99),
(6, 1, 1, 89.99, 89.99),
(6, 5, 1, 19.99, 19.99),
(7, 7, 1, 59.99, 59.99),
(8, 2, 1, 199.99, 199.99),
(8, 1, 1, 89.99, 89.99),
(8, 4, 1, 79.99, 79.99),
(8, 6, 1, 29.99, 29.99),
(8, 8, 1, 49.99, 49.99),
(9, 1, 1, 89.99, 89.99),
(9, 5, 1, 19.99, 19.99),
(9, 9, 1, 12.99, 12.99),
(9, 11, 1, 39.99, 39.99),
(10, 8, 1, 49.99, 49.99),
(11, 5, 1, 19.99, 19.99),
(12, 10, 1, 129.99, 129.99),
(13, 3, 1, 24.99, 24.99),
(14, 12, 1, 34.99, 34.99),
(15, 1, 1, 89.99, 89.99);

-- Insert sample reviews
INSERT INTO reviews (customer_id, product_id, order_id, rating, review_title, review_text, review_date, is_verified_purchase, helpful_votes) VALUES
(1, 1, 1, 5, 'Excellent sound quality!', 'These headphones have amazing sound quality and the noise cancellation works perfectly. Great value for money.', '2024-01-12 10:30:00', TRUE, 8),
(2, 2, 2, 4, 'Great fitness tracker', 'The watch tracks all my activities accurately. Battery life could be better but overall satisfied.', '2024-01-14 15:20:00', TRUE, 5),
(2, 4, 2, 5, 'Beautiful leather bag', 'High quality leather and perfect size. Love the multiple compartments.', '2024-01-14 15:25:00', TRUE, 3),
(3, 1, 3, 4, 'Good headphones', 'Sound is clear and comfortable to wear. Would recommend.', '2024-01-10 09:15:00', TRUE, 2),
(3, 5, 3, 5, 'Perfect water bottle', 'Keeps drinks cold all day. Great design and quality.', '2024-01-10 09:20:00', TRUE, 6),
(4, 3, 4, 4, 'Comfortable t-shirt', 'Soft material and good fit. True to size.', '2023-12-17 14:45:00', TRUE, 1),
(5, 2, 5, 5, 'Amazing smartwatch', 'All features work perfectly. Great for fitness tracking and notifications.', '2024-01-13 11:30:00', TRUE, 7),
(6, 1, 6, 3, 'Decent headphones', 'Sound is okay but not as good as expected for the price.', '2024-01-11 16:20:00', TRUE, 0),
(6, 5, 6, 4, 'Good water bottle', 'Works as expected. Good value.', '2024-01-11 16:25:00', TRUE, 2),
(7, 7, 7, 4, 'Nice jeans', 'Good fit and comfortable. Would buy again.', '2023-12-22 12:10:00', TRUE, 1),
(8, 2, 8, 5, 'Best smartwatch ever!', 'Incredible features and battery life. Worth every penny.', '2024-01-15 08:45:00', TRUE, 12),
(8, 1, 8, 5, 'Outstanding headphones', 'Best headphones I have ever owned. Crystal clear sound.', '2024-01-15 08:50:00', TRUE, 9),
(8, 4, 8, 4, 'Nice leather bag', 'Good quality and stylish design.', '2024-01-15 08:55:00', TRUE, 4),
(8, 6, 8, 3, 'Average charger', 'Works but charging is slower than expected.', '2024-01-15 09:00:00', TRUE, 1),
(8, 8, 8, 4, 'Good speaker', 'Loud and clear sound. Portable design is great.', '2024-01-15 09:05:00', TRUE, 3),
(9, 1, 9, 5, 'Perfect headphones', 'Amazing sound quality and very comfortable.', '2024-01-09 13:30:00', TRUE, 6),
(9, 5, 9, 4, 'Great water bottle', 'Keeps drinks cold for hours.', '2024-01-09 13:35:00', TRUE, 2),
(9, 9, 9, 5, 'Love this mug', 'Perfect size and beautiful design.', '2024-01-09 13:40:00', TRUE, 1),
(9, 11, 9, 4, 'Good laptop stand', 'Sturdy and adjustable. Helps with posture.', '2024-01-09 13:45:00', TRUE, 3),
(10, 8, 10, 4, 'Decent speaker', 'Good sound quality for the price.', '2024-01-08 15:20:00', TRUE, 1),
(11, 5, 11, 5, 'Excellent water bottle', 'Best water bottle I have ever used.', '2023-12-20 10:15:00', TRUE, 4),
(12, 10, 12, 4, 'Good running shoes', 'Comfortable and lightweight. Good for long runs.', '2024-01-07 17:30:00', TRUE, 2),
(13, 3, 13, 3, 'Okay t-shirt', 'Material is fine but sizing runs small.', '2024-01-05 14:20:00', TRUE, 0),
(14, 12, 14, 4, 'Nice yoga mat', 'Good grip and comfortable to use.', '2024-01-10 11:45:00', TRUE, 1),
(15, 1, 15, 5, 'Amazing headphones!', 'Outstanding sound quality and build. Highly recommended!', '2024-01-14 09:30:00', TRUE, 10);

-- Insert sample payments
INSERT INTO payments (order_id, payment_method, payment_status, amount, payment_date, transaction_id, gateway_response, refund_amount, refund_date) VALUES
(1, 'Credit Card', 'Completed', 103.18, '2024-01-10 14:35:00', 'TXN001234567', 'SUCCESS', 0.00, NULL),
(2, 'PayPal', 'Completed', 290.37, '2024-01-12 09:20:00', 'PP789012345', 'SUCCESS', 0.00, NULL),
(3, 'Credit Card', 'Completed', 97.77, '2024-01-08 16:50:00', 'TXN001234568', 'SUCCESS', 0.00, NULL),
(4, 'Debit Card', 'Completed', 32.98, '2023-12-15 11:25:00', 'TXN001234569', 'SUCCESS', 0.00, NULL),
(5, 'Credit Card', 'Completed', 222.98, '2024-01-11 13:15:00', 'TXN001234570', 'SUCCESS', 0.00, NULL),
(6, 'PayPal', 'Completed', 113.77, '2024-01-09 10:35:00', 'PP789012346', 'SUCCESS', 0.00, NULL),
(7, 'Credit Card', 'Completed', 69.78, '2023-12-20 15:50:00', 'TXN001234571', 'SUCCESS', 0.00, NULL),
(8, 'Credit Card', 'Completed', 496.96, '2024-01-13 08:25:00', 'TXN001234572', 'SUCCESS', 0.00, NULL),
(9, 'Bank Transfer', 'Completed', 186.57, '2024-01-07 12:20:00', 'BT001234567', 'SUCCESS', 0.00, NULL),
(10, 'Credit Card', 'Completed', 58.98, '2024-01-06 14:45:00', 'TXN001234573', 'SUCCESS', 0.00, NULL),
(11, 'Debit Card', 'Completed', 25.58, '2023-12-18 09:35:00', 'TXN001234574', 'SUCCESS', 0.00, NULL),
(12, 'Credit Card', 'Completed', 146.38, '2024-01-05 16:25:00', 'TXN001234575', 'SUCCESS', 0.00, NULL),
(13, 'PayPal', 'Completed', 31.98, '2024-01-03 11:50:00', 'PP789012347', 'SUCCESS', 0.00, NULL),
(14, 'Credit Card', 'Completed', 42.78, '2024-01-08 13:30:00', 'TXN001234576', 'SUCCESS', 0.00, NULL),
(15, 'Credit Card', 'Completed', 103.18, '2024-01-12 10:15:00', 'TXN001234577', 'SUCCESS', 0.00, NULL);

-- Update customer total_spent and last_purchase_date based on orders
UPDATE customers c
SET total_spent = (
    SELECT COALESCE(SUM(total_amount), 0)
    FROM orders o
    WHERE o.customer_id = c.customer_id
),
last_purchase_date = (
    SELECT MAX(order_date)
    FROM orders o
    WHERE o.customer_id = c.customer_id
);

-- Update customer segments based on total spending
UPDATE customers 
SET customer_segment = CASE
    WHEN total_spent >= 2000 THEN 'Platinum'
    WHEN total_spent >= 1000 THEN 'Gold'
    WHEN total_spent >= 500 THEN 'Silver'
    ELSE 'Bronze'
END;
