-- ============================================================
-- SOLE STORE - Database Schema
-- Run: mysql -u root -p < schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS sole_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sole_store;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Addresses table
CREATE TABLE IF NOT EXISTS addresses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    label VARCHAR(50) DEFAULT 'Home',
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    zip VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL DEFAULT 'United States',
    is_default BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    image_url VARCHAR(500)
);

-- Products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(255) NOT NULL UNIQUE,
    brand VARCHAR(100) NOT NULL,
    category_id INT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    original_price DECIMAL(10,2),
    image_url VARCHAR(500),
    image_url_2 VARCHAR(500),
    image_url_3 VARCHAR(500),
    is_featured BOOLEAN DEFAULT FALSE,
    is_new BOOLEAN DEFAULT FALSE,
    is_sale BOOLEAN DEFAULT FALSE,
    rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

-- Product sizes & stock
CREATE TABLE IF NOT EXISTS product_inventory (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    size VARCHAR(10) NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    UNIQUE KEY unique_product_size (product_id, size)
);

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE,
    user_id INT,
    guest_email VARCHAR(255),
    status ENUM('pending','processing','shipped','delivered','cancelled') DEFAULT 'pending',
    subtotal DECIMAL(10,2) NOT NULL,
    shipping_cost DECIMAL(10,2) DEFAULT 0.00,
    tax DECIMAL(10,2) DEFAULT 0.00,
    total DECIMAL(10,2) NOT NULL,
    shipping_name VARCHAR(200),
    shipping_street VARCHAR(255),
    shipping_city VARCHAR(100),
    shipping_state VARCHAR(100),
    shipping_zip VARCHAR(20),
    shipping_country VARCHAR(100),
    payment_method VARCHAR(50) DEFAULT 'card',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Order items table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    size VARCHAR(10) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    user_id INT,
    reviewer_name VARCHAR(100) NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    title VARCHAR(200),
    body TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
-- SEED DATA
-- ============================================================

INSERT INTO categories (name, slug, description, image_url) VALUES
('Running', 'running', 'High-performance running shoes', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800'),
('Basketball', 'basketball', 'Court-ready basketball shoes', 'https://images.unsplash.com/photo-1579338559194-a162d19bf842?w=800'),
('Lifestyle', 'lifestyle', 'Everyday casual sneakers', 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800'),
('Training', 'training', 'Cross-training and gym shoes', 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800');

INSERT INTO products (name, slug, brand, category_id, description, price, original_price, image_url, image_url_2, image_url_3, is_featured, is_new, is_sale, rating, review_count) VALUES
('Air Phantom Pro', 'air-phantom-pro', 'NovaSole', 1, 'Engineered for elite runners, the Air Phantom Pro features our latest cushioning technology with a carbon-fiber plate for explosive energy return. The breathable mesh upper keeps your feet cool over long distances.', 189.99, NULL, 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=800', 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?w=800', TRUE, TRUE, FALSE, 4.8, 234),
('Street Legend Low', 'street-legend-low', 'UrbanKick', 3, 'Born on the courts, perfected for the streets. The Street Legend Low blends iconic style with all-day comfort. Premium leather upper with suede accents and a cushioned insole for 24/7 wearability.', 129.99, 159.99, 'https://images.unsplash.com/photo-1560769629-975ec94e6a86?w=800', 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800', 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800', TRUE, FALSE, TRUE, 4.6, 189),
('CourtDom Elite', 'courtdom-elite', 'ProHoops', 2, 'Dominate the paint with the CourtDom Elite. High-ankle support, explosive traction pattern, and responsive foam cushioning make this the go-to shoe for serious ballers.', 159.99, NULL, 'https://images.unsplash.com/photo-1579338559194-a162d19bf842?w=800', 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800', 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=800', TRUE, FALSE, FALSE, 4.7, 156),
('SwiftRun X2', 'swiftrun-x2', 'NovaSole', 1, 'Lightweight speed trainer with a zero-drop platform for natural running mechanics. The X2 features recycled materials throughout and a durable rubber outsole.', 139.99, NULL, 'https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=800', NULL, NULL, FALSE, TRUE, FALSE, 4.5, 98),
('CloudWalk Comfort', 'cloudwalk-comfort', 'EasyStep', 3, 'Step into a cloud. The CloudWalk features our signature foam technology with 37 cloud pods for unparalleled cushioning. Perfect for all-day wear whether commuting or exploring.', 119.99, 149.99, 'https://images.unsplash.com/photo-1515955656352-a1fa3ffcd111?w=800', NULL, NULL, FALSE, FALSE, TRUE, 4.4, 312),
('Iron Grip Trainer', 'iron-grip-trainer', 'FitForce', 4, 'Built for the gym and beyond. The Iron Grip Trainer offers lateral stability for weightlifting, a flexible forefoot for cardio, and a durable build that withstands the toughest workouts.', 109.99, NULL, 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?w=800', NULL, NULL, FALSE, FALSE, FALSE, 4.3, 77),
('Retro Wave 88', 'retro-wave-88', 'UrbanKick', 3, 'Vintage vibes meet modern comfort. The Retro Wave 88 draws inspiration from 80s court classics with a bold colorblocked design, padded collar, and timeless cupsole construction.', 99.99, NULL, 'https://images.unsplash.com/photo-1539185441755-769473a23570?w=800', NULL, NULL, FALSE, FALSE, FALSE, 4.5, 203),
('Marathon Pacer', 'marathon-pacer', 'NovaSole', 1, 'Your ultimate race day companion. Ultra-light, incredibly responsive, with our highest stack height yet. The Marathon Pacer delivers record-breaking performance for every distance.', 219.99, NULL, 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=800', NULL, NULL, TRUE, TRUE, FALSE, 4.9, 67);

-- Inventory for each product (sizes 6-13 US)
INSERT INTO product_inventory (product_id, size, stock) 
SELECT p.id, s.size, FLOOR(RAND() * 15) + 2
FROM products p
CROSS JOIN (
    SELECT '6' AS size UNION SELECT '6.5' UNION SELECT '7' UNION SELECT '7.5'
    UNION SELECT '8' UNION SELECT '8.5' UNION SELECT '9' UNION SELECT '9.5'
    UNION SELECT '10' UNION SELECT '10.5' UNION SELECT '11' UNION SELECT '12' UNION SELECT '13'
) s;

-- Sample reviews
INSERT INTO reviews (product_id, reviewer_name, rating, title, body) VALUES
(1, 'Alex M.', 5, 'Best running shoe I\'ve ever owned', 'Incredible energy return on long runs. My marathon PR improved by 4 minutes. The fit is true to size and the cushioning is phenomenal.'),
(1, 'Sarah K.', 5, 'Worth every penny', 'Initially hesitant about the price but these shoes paid for themselves. Extremely comfortable for both short sprints and 20-mile training runs.'),
(2, 'Jordan P.', 4, 'Great everyday shoe', 'Clean look that goes with almost anything. Comfortable right out of the box. Docked one star because sizing runs slightly narrow.'),
(3, 'Marcus T.', 5, 'Lockdown fit is incredible', 'Played 5 straight games in these. Zero ankle concerns, great court feel, and the traction is elite. Highly recommend for serious players.'),
(5, 'Linda R.', 5, 'I wear these every single day', 'As someone who stands all day at work, these are a lifesaver. My feet never hurt anymore. Already bought a second pair.');
