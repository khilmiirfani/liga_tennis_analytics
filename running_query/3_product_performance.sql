CREATE OR REPLACE VIEW 3_product_performance AS
SELECT 
    -- Dimensions
    source.sale_date,
    source.court_id,
    v.title AS branch_name,
    source.product_type, 
    source.category_name, 
    source.product_name,
    
    -- Sales Metrics
    COUNT(DISTINCT source.transaction_id) AS transaction_count,
    SUM(source.qty) AS units_sold,
    SUM(source.revenue) AS total_revenue,
    
    -- Inventory / Capacity Metrics
    MAX(source.total_capacity) AS total_capacity,
    
    -- Sell-Through Rate
    CASE 
        WHEN MAX(source.total_capacity) > 0 
        THEN (SUM(source.qty) / MAX(source.total_capacity)) * 100 
        ELSE NULL 
    END AS sell_through_rate_pct,

    0 AS cross_sell_rate_placeholder 

FROM (
    -- 1. PACKAGES
    SELECT 
        DATE(cb.created_at) AS sale_date,
        cb.court_id,
        'Package' AS product_type,
        cp.type AS category_name,
        cp.title AS product_name,
        cb.id AS transaction_id,
        1 AS qty,
        (COALESCE(cb.price, 0) + COALESCE(cb.additional_payment, 0)) AS revenue,
        NULL AS total_capacity
    FROM court_bookings cb
    JOIN courts_packages cp ON cb.package_id = cp.id
    WHERE cb.payment_status = 'paid'

    UNION ALL

    -- 2. EVENTS
    SELECT 
        DATE(ceu.created_at) AS sale_date,
        ce.court_id,
        'Event' AS product_type,
        'Event' AS category_name,
        ce.title AS product_name,
        ceu.id AS transaction_id,
        1 AS qty,
        ceu.price AS revenue,
        ce.limit AS total_capacity
    FROM court_event_users ceu
    JOIN court_events ce ON ceu.event_id = ce.id
    WHERE ceu.payment_status = 'paid'

    UNION ALL

    -- 3. EXTRAS / ADD-ONS
    SELECT 
        DATE(cbe.created_at) AS sale_date,
        ce.court_id,
        'Add-on' AS product_type,
        'Extra' AS category_name,
        ce.title AS product_name,
        cbe.id AS transaction_id,
        cbe.qty,
        (cbe.price * cbe.qty) AS revenue,
        NULL AS total_capacity
    FROM court_booking_extras cbe
    JOIN court_extras ce ON cbe.extra_id = ce.id
    WHERE cbe.deleted_at IS NULL
) source

LEFT JOIN V_DETAIL_VENUES v ON source.court_id = v.item_id

-- FIXED LINE BELOW: Removed .date and simplified logic
WHERE YEAR(source.sale_date) >= YEAR(CURDATE()) - 2
AND v.title IS NOT NULL

GROUP BY 
    source.sale_date, 
    source.court_id, 
    v.title,
    source.product_type, 
    source.category_name, 
    source.product_name;
