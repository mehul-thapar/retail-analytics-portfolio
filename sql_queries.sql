-- ============================================================================
-- RETAIL SALES ANALYTICS PROJECT
-- SQL Queries for Data Extraction and Transformation
-- ============================================================================

-- ============================================================================
-- 1. INITIAL DATA EXPLORATION
-- ============================================================================

-- Query 1.1: Overall Sales Summary
SELECT 
    COUNT(DISTINCT transaction_id) AS total_transactions,
    COUNT(DISTINCT store_id) AS total_stores,
    COUNT(DISTINCT product_id) AS total_products,
    MIN(transaction_date) AS earliest_date,
    MAX(transaction_date) AS latest_date,
    SUM(quantity) AS total_units_sold,
    SUM(sales_amount) AS total_revenue,
    ROUND(AVG(sales_amount), 2) AS avg_transaction_value
FROM sales_data;

-- Query 1.2: Store-Level Performance Overview
SELECT 
    s.store_id,
    s.store_name,
    s.location,
    COUNT(DISTINCT sd.transaction_id) AS num_transactions,
    SUM(sd.quantity) AS total_units_sold,
    SUM(sd.sales_amount) AS total_revenue,
    ROUND(AVG(sd.sales_amount), 2) AS avg_transaction_value,
    ROUND(SUM(sd.sales_amount) / COUNT(DISTINCT sd.transaction_id), 2) AS revenue_per_transaction
FROM stores s
LEFT JOIN sales_data sd ON s.store_id = sd.store_id
GROUP BY s.store_id, s.store_name, s.location
ORDER BY total_revenue DESC;

-- ============================================================================
-- 2. SALES TREND ANALYSIS
-- ============================================================================

-- Query 2.1: Monthly Sales Trends
SELECT 
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS month,
    DATEFROMPARTS(YEAR(transaction_date), MONTH(transaction_date), 1) AS month_start,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(quantity) AS units_sold,
    SUM(sales_amount) AS total_sales,
    ROUND(AVG(sales_amount), 2) AS avg_transaction_value,
    COUNT(DISTINCT store_id) AS active_stores
FROM sales_data
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY year DESC, month DESC;

-- Query 2.2: Week-over-Week Growth Analysis
SELECT 
    YEAR(transaction_date) AS year,
    MONTH(transaction_date) AS month,
    DATEPART(WEEK, transaction_date) AS week_num,
    MIN(transaction_date) AS week_start,
    MAX(transaction_date) AS week_end,
    SUM(sales_amount) AS weekly_sales,
    LAG(SUM(sales_amount)) OVER (ORDER BY YEAR(transaction_date), DATEPART(WEEK, transaction_date)) AS prev_week_sales,
    ROUND(
        (SUM(sales_amount) - LAG(SUM(sales_amount)) OVER (ORDER BY YEAR(transaction_date), DATEPART(WEEK, transaction_date))) 
        / LAG(SUM(sales_amount)) OVER (ORDER BY YEAR(transaction_date), DATEPART(WEEK, transaction_date)) * 100, 2
    ) AS wow_growth_pct
FROM sales_data
GROUP BY YEAR(transaction_date), MONTH(transaction_date), DATEPART(WEEK, transaction_date)
ORDER BY year DESC, week_num DESC;

-- Query 2.3: Day-of-Week Performance Pattern
SELECT 
    DATENAME(WEEKDAY, transaction_date) AS day_of_week,
    DATEPART(WEEKDAY, transaction_date) AS day_num,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(sales_amount) AS total_sales,
    ROUND(AVG(sales_amount), 2) AS avg_transaction_value,
    ROUND(SUM(sales_amount) / COUNT(DISTINCT transaction_id), 2) AS revenue_per_transaction
FROM sales_data
GROUP BY DATENAME(WEEKDAY, transaction_date), DATEPART(WEEKDAY, transaction_date)
ORDER BY day_num;

-- ============================================================================
-- 3. PRODUCT & CATEGORY ANALYSIS
-- ============================================================================

-- Query 3.1: Top Performing Products
SELECT TOP 20
    p.product_id,
    p.product_name,
    p.category,
    COUNT(DISTINCT sd.transaction_id) AS times_purchased,
    SUM(sd.quantity) AS total_units_sold,
    SUM(sd.sales_amount) AS total_revenue,
    ROUND(AVG(sd.sales_amount), 2) AS avg_price,
    ROUND(SUM(sd.sales_amount) / SUM(SUM(sd.sales_amount)) OVER() * 100, 2) AS pct_of_total_revenue
FROM products p
LEFT JOIN sales_data sd ON p.product_id = sd.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC;

-- Query 3.2: Category Performance Breakdown
SELECT 
    category,
    COUNT(DISTINCT product_id) AS num_products,
    COUNT(DISTINCT transaction_id) AS transactions,
    SUM(quantity) AS units_sold,
    SUM(sales_amount) AS total_revenue,
    ROUND(AVG(sales_amount), 2) AS avg_transaction_value,
    ROUND(SUM(sales_amount) / SUM(SUM(sales_amount)) OVER() * 100, 2) AS pct_of_total_revenue
FROM sales_data sd
JOIN products p ON sd.product_id = p.product_id
GROUP BY category
ORDER BY total_revenue DESC;

-- Query 3.3: Product Profitability Analysis
SELECT 
    p.product_id,
    p.product_name,
    p.category,
    p.cost_per_unit,
    ROUND(AVG(sd.sales_amount / sd.quantity), 2) AS avg_selling_price,
    ROUND(AVG(sd.sales_amount / sd.quantity) - p.cost_per_unit, 2) AS avg_profit_per_unit,
    SUM(sd.quantity) AS units_sold,
    SUM(sd.sales_amount) AS total_revenue,
    SUM(sd.quantity * p.cost_per_unit) AS total_cost,
    SUM(sd.sales_amount) - SUM(sd.quantity * p.cost_per_unit) AS total_profit,
    ROUND((SUM(sd.sales_amount) - SUM(sd.quantity * p.cost_per_unit)) / SUM(sd.sales_amount) * 100, 2) AS profit_margin_pct
FROM products p
LEFT JOIN sales_data sd ON p.product_id = sd.product_id
GROUP BY p.product_id, p.product_name, p.category, p.cost_per_unit
HAVING SUM(sd.quantity) > 0
ORDER BY total_profit DESC;

-- ============================================================================
-- 4. STORE PERFORMANCE & SEGMENTATION
-- ============================================================================

-- Query 4.1: Store Performance Ranking
SELECT 
    s.store_id,
    s.store_name,
    s.location,
    s.store_type,
    COUNT(DISTINCT sd.transaction_id) AS total_transactions,
    SUM(sd.quantity) AS total_units,
    SUM(sd.sales_amount) AS total_sales,
    ROUND(AVG(sd.sales_amount), 2) AS avg_transaction_value,
    ROUND(SUM(sd.sales_amount) / COUNT(DISTINCT sd.transaction_id), 2) AS revenue_per_transaction,
    NTILE(4) OVER (ORDER BY SUM(sd.sales_amount) DESC) AS performance_quartile
FROM stores s
LEFT JOIN sales_data sd ON s.store_id = sd.store_id
GROUP BY s.store_id, s.store_name, s.location, s.store_type
ORDER BY total_sales DESC;

-- Query 4.2: Store Type Comparison
SELECT 
    store_type,
    COUNT(DISTINCT store_id) AS num_stores,
    AVG(store_revenue.total_sales) AS avg_sales_per_store,
    MIN(store_revenue.total_sales) AS min_store_sales,
    MAX(store_revenue.total_sales) AS max_store_sales,
    STDEV(store_revenue.total_sales) AS sales_std_deviation
FROM (
    SELECT 
        s.store_id,
        s.store_type,
        SUM(sd.sales_amount) AS total_sales
    FROM stores s
    LEFT JOIN sales_data sd ON s.store_id = sd.store_id
    GROUP BY s.store_id, s.store_type
) AS store_revenue
GROUP BY store_type
ORDER BY avg_sales_per_store DESC;

-- ============================================================================
-- 5. CUSTOMER INSIGHTS
-- ============================================================================

-- Query 5.1: Customer Purchase Frequency & Value
SELECT 
    c.customer_id,
    c.customer_name,
    COUNT(DISTINCT sd.transaction_id) AS purchase_frequency,
    SUM(sd.sales_amount) AS customer_lifetime_value,
    ROUND(AVG(sd.sales_amount), 2) AS avg_purchase_value,
    ROUND(SUM(sd.sales_amount) / COUNT(DISTINCT sd.transaction_id), 2) AS avg_transaction_value,
    MIN(sd.transaction_date) AS first_purchase_date,
    MAX(sd.transaction_date) AS last_purchase_date,
    DATEDIFF(DAY, MIN(sd.transaction_date), MAX(sd.transaction_date)) AS customer_tenure_days
FROM customers c
LEFT JOIN sales_data sd ON c.customer_id = sd.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT sd.transaction_id) > 0
ORDER BY customer_lifetime_value DESC;

-- Query 5.2: Customer Segmentation (RFM Analysis)
WITH customer_rfm AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        DATEDIFF(DAY, MAX(sd.transaction_date), CAST(GETDATE() AS DATE)) AS recency_days,
        COUNT(DISTINCT sd.transaction_id) AS frequency,
        SUM(sd.sales_amount) AS monetary_value
    FROM customers c
    LEFT JOIN sales_data sd ON c.customer_id = sd.customer_id
    GROUP BY c.customer_id, c.customer_name
)
SELECT 
    customer_id,
    customer_name,
    recency_days,
    frequency,
    monetary_value,
    NTILE(4) OVER (ORDER BY recency_days DESC) AS recency_quartile,
    NTILE(4) OVER (ORDER BY frequency) AS frequency_quartile,
    NTILE(4) OVER (ORDER BY monetary_value) AS monetary_quartile
FROM customer_rfm
WHERE frequency > 0
ORDER BY monetary_value DESC;

-- ============================================================================
-- 6. DATA QUALITY & VALIDATION
-- ============================================================================

-- Query 6.1: Check for Null Values and Anomalies
SELECT 
    'NULL transaction_id' AS check_name,
    COUNT(*) AS count_issues
FROM sales_data
WHERE transaction_id IS NULL
UNION ALL
SELECT 'NULL sale_amount', COUNT(*)
FROM sales_data
WHERE sales_amount IS NULL OR sales_amount <= 0
UNION ALL
SELECT 'NULL quantity', COUNT(*)
FROM sales_data
WHERE quantity IS NULL OR quantity <= 0
UNION ALL
SELECT 'Duplicate transactions', COUNT(*)
FROM (
    SELECT transaction_id, COUNT(*) AS cnt
    FROM sales_data
    GROUP BY transaction_id
    HAVING COUNT(*) > 1
) AS dupes;

-- Query 6.2: Sales Amount Distribution (Outlier Detection)
SELECT 
    'Min Sales Amount' AS metric,
    CAST(MIN(sales_amount) AS VARCHAR) AS value
FROM sales_data
UNION ALL
SELECT 'Max Sales Amount', CAST(MAX(sales_amount) AS VARCHAR)
FROM sales_data
UNION ALL
SELECT 'Mean Sales Amount', CAST(ROUND(AVG(sales_amount), 2) AS VARCHAR)
FROM sales_data
UNION ALL
SELECT 'Median Sales Amount', CAST(ROUND(
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY sales_amount) OVER(), 2) AS VARCHAR)
FROM sales_data
UNION ALL
SELECT 'Std Dev Sales Amount', CAST(ROUND(STDEV(sales_amount), 2) AS VARCHAR)
FROM sales_data;

-- ============================================================================
-- 7. FORECASTING PREPARATION (Data for Time Series)
-- ============================================================================

-- Query 7.1: Daily Sales for Forecasting
SELECT 
    CAST(transaction_date AS DATE) AS sales_date,
    COUNT(DISTINCT transaction_id) AS daily_transactions,
    SUM(quantity) AS daily_units,
    SUM(sales_amount) AS daily_sales,
    COUNT(DISTINCT store_id) AS active_stores
FROM sales_data
GROUP BY CAST(transaction_date AS DATE)
ORDER BY sales_date DESC;

-- Query 7.2: Category-Level Daily Sales
SELECT 
    CAST(sd.transaction_date AS DATE) AS sales_date,
    p.category,
    COUNT(DISTINCT sd.transaction_id) AS transactions,
    SUM(sd.quantity) AS units_sold,
    SUM(sd.sales_amount) AS category_sales
FROM sales_data sd
JOIN products p ON sd.product_id = p.product_id
GROUP BY CAST(sd.transaction_date AS DATE), p.category
ORDER BY sales_date DESC, category;

-- ============================================================================
-- 8. EXECUTIVE SUMMARY QUERIES
-- ============================================================================

-- Query 8.1: Key Performance Indicators
SELECT 
    'Total Revenue (All Time)' AS kpi,
    CAST(ROUND(SUM(sales_amount), 2) AS VARCHAR) AS value,
    'Currency' AS unit
FROM sales_data
UNION ALL
SELECT 'Total Transactions', CAST(COUNT(DISTINCT transaction_id) AS VARCHAR), 'Count'
FROM sales_data
UNION ALL
SELECT 'Average Transaction Value', CAST(ROUND(AVG(sales_amount), 2) AS VARCHAR), 'Currency'
FROM sales_data
UNION ALL
SELECT 'Total Units Sold', CAST(SUM(quantity) AS VARCHAR), 'Units'
FROM sales_data
UNION ALL
SELECT 'Active Stores', CAST(COUNT(DISTINCT store_id) AS VARCHAR), 'Count'
FROM sales_data
UNION ALL
SELECT 'Active Products', CAST(COUNT(DISTINCT product_id) AS VARCHAR), 'Count'
FROM sales_data
UNION ALL
SELECT 'Active Customers', CAST(COUNT(DISTINCT customer_id) AS VARCHAR), 'Count'
FROM sales_data;

-- Query 8.2: YoY (Year-over-Year) Growth
WITH yearly_sales AS (
    SELECT 
        YEAR(transaction_date) AS year,
        SUM(sales_amount) AS annual_sales,
        COUNT(DISTINCT transaction_id) AS annual_transactions
    FROM sales_data
    GROUP BY YEAR(transaction_date)
)
SELECT 
    year,
    annual_sales,
    LAG(annual_sales) OVER (ORDER BY year) AS prev_year_sales,
    ROUND((annual_sales - LAG(annual_sales) OVER (ORDER BY year)) / LAG(annual_sales) OVER (ORDER BY year) * 100, 2) AS yoy_growth_pct,
    annual_transactions
FROM yearly_sales
ORDER BY year DESC;
