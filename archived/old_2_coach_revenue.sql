CREATE OR REPLACE VIEW 2_coach_revenues AS (
SELECT 
    a.`date`,
    a.id AS booking_id,
    a.court_id,
    a.coach_id,
    b.coach_name,
    -- Duration (Hours)
    (GREATEST(0, TIMESTAMPDIFF(MINUTE, 
        STR_TO_DATE(CONCAT(a.`date`,' ',a.time_from), '%Y-%m-%d %H:%i'), 
        STR_TO_DATE(CONCAT(a.`date`,' ',a.time_to),   '%Y-%m-%d %H:%i')
    )) / 60.0) AS duration_hours,
    -- Coach Details (from View)
    b.coach_type,
    d.sport_title,
    b.price AS coach_price,
   CASE 
         -- 1a. Condition when the court_price is zero 
         WHEN a.price = 0 THEN 0 
         -- 1. Handle NULL/Empty
         WHEN c.discount IS NULL OR c.discount = '' THEN b.price
         -- 2. Handle Percentage (Check if string ends with '%')
         -- We use TRIM() to remove invisible spaces
         WHEN RIGHT(TRIM(c.discount), 1) = '%' THEN 
             b.price * (1 - (CAST(REPLACE(c.discount, '%', '') AS DECIMAL(10,2)) / 100.0))
         -- 3. Handle Fixed Amount
         ELSE GREATEST(0, b.price - CAST(c.discount AS DECIMAL(10,2)))
    END AS coach_final_price,
    -- Financials
    a.price AS court_booking_price,
    a.discount_id,
    c.discount AS discount_value,
    a.user_id

FROM court_bookings a
-- Join with the new View
LEFT JOIN 2_coach_price b     
          ON a.coach_id = b.coach_id 
          AND a.coach_type_id = b.type_id
-- Join with Discount Table
LEFT JOIN court_discounts   c     ON a.discount_id = c.id
LEFT JOIN v_detail_venues   d     ON a.court_id = d.booking_court_id
WHERE a.`date` > '2026-01-01'
AND a.payment_status ='paid'
AND a.coach_id IS NOT NULL
ORDER BY a.date desc
)



