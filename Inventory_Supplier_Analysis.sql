-- Create a new database
CREATE DATABASE inventory_db;

-- Use the database
USE inventory_db;

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100),
    location VARCHAR(100),
    contact_email VARCHAR(100)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    supplier_id INT,
    unit_cost DECIMAL(10,2),
    unit_price DECIMAL(10,2),
    stock_on_hand INT,
    reorder_point INT,
    lead_time_days INT,
    annual_sales_units INT,
    FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);

USE inventory_db;

DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS suppliers;

USE inventory_db;

SELECT * FROM suppliers LIMIT 10;
SELECT * FROM products LIMIT 10;

-- ==========================================
-- Stock Levels & Reorder Alerts
-- Identify products that are below their reorder points or running low on stock.
-- Helps prioritize procurement and avoid stockouts.
-- ==========================================
SELECT product_id, product_name, category, stock_on_hand, reorder_point,
       CASE 
           WHEN stock_on_hand <= reorder_point THEN 'Reorder Needed'
           ELSE 'Sufficient Stock'
       END AS stock_status
FROM products
ORDER BY stock_status DESC, stock_on_hand ASC;

-- ==========================================
-- Supplier Dependency Analysis
-- Analyze the proportion of products supplied by each supplier to understand dependency risks.
-- Helps identify suppliers to diversify for better supply chain stability.
-- ==========================================
SELECT s.supplier_id, s.supplier_name, COUNT(p.product_id) AS total_products,
       ROUND(COUNT(p.product_id) * 100.0 / (SELECT COUNT(*) FROM products),2) AS percent_of_total_products
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_id, s.supplier_name
ORDER BY total_products DESC;

-- ==========================================
-- Product Inventory Turnover
-- Calculate turnover ratio for each product using annual sales and current stock.
-- High turnover products sell fast and may need more frequent restocking.
-- ==========================================
SELECT product_id, product_name, annual_sales_units, stock_on_hand,
       ROUND(annual_sales_units / NULLIF(stock_on_hand,0), 2) AS turnover_ratio
FROM products
ORDER BY turnover_ratio DESC;

-- ==========================================
-- Category-wise Inventory Performance
-- Aggregate inventory metrics by product category to assess sales efficiency.
-- Highlights which categories are performing well and which need stock optimization.
-- ==========================================
SELECT category,
       SUM(annual_sales_units) AS total_units_sold,
       SUM(stock_on_hand) AS total_stock_on_hand,
       ROUND(SUM(annual_sales_units) / NULLIF(SUM(stock_on_hand),0),2) AS category_turnover_ratio
FROM products
GROUP BY category
ORDER BY category_turnover_ratio DESC;

-- ==========================================
-- Reorder Priority Ranking
-- Combine stock levels and turnover ratios to prioritize products for reordering.
-- Identifies high-priority products that are low in stock but have high sales velocity.
-- ==========================================
SELECT product_id, product_name, stock_on_hand, reorder_point, annual_sales_units,
       ROUND(annual_sales_units / NULLIF(stock_on_hand,0), 2) AS turnover_ratio,
       CASE 
           WHEN stock_on_hand <= reorder_point THEN 'High Priority'
           ELSE 'Normal'
       END AS reorder_priority
FROM products
ORDER BY reorder_priority DESC, turnover_ratio DESC;

SELECT s.supplier_name, COUNT(p.product_id) AS total_products
FROM suppliers s
JOIN products p ON s.supplier_id = p.supplier_id
GROUP BY s.supplier_name
ORDER BY total_products DESC;

