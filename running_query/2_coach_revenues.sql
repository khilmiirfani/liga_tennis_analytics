CREATE OR REPLACE VIEW `2_coach_revenues` AS
WITH revenue_data AS (
    -- 1. Get Revenue Details (Detail Level)
    SELECT 
        a.`date`,
        a.coach_id,
        b.coach_name,
        a.id AS booking_id,
        -- Duration
        (GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.`date`,' ',a.time_from), '%Y-%m-%d %H:%i'), 
            STR_TO_DATE(CONCAT(a.`date`,' ',a.time_to),   '%Y-%m-%d %H:%i')
        )) / 60.0) AS billable_hours,
        -- Price Logic
        CASE 
             WHEN a.price = 0 THEN 0 
             WHEN c.discount IS NULL OR c.discount = '' THEN b.price
             WHEN RIGHT(TRIM(c.discount), 1) = '%' THEN 
                 b.price * (1 - (CAST(REPLACE(c.discount, '%', '') AS DECIMAL(10,2)) / 100.0))
             ELSE GREATEST(0, b.price - CAST(c.discount AS DECIMAL(10,2)))
        END AS coach_final_price
    FROM court_bookings a
    LEFT JOIN `2_coach_price` b     
            ON a.coach_id = b.coach_id 
            AND a.coach_type_id = b.type_id
    LEFT JOIN court_discounts c   
            ON a.discount_id = c.id
    WHERE a.`date` > '2026-01-01'
      AND a.payment_status ='paid'
      AND a.coach_id IS NOT NULL
),

revenue_aggregated AS (
    -- 2. Group Revenue by Date/Coach
    SELECT 
        `date`,
        coach_id,
        coach_name,
        COUNT(booking_id) AS total_sessions,
        SUM(billable_hours) AS total_billable_hours,
        SUM(coach_final_price) AS total_revenue
    FROM revenue_data
    GROUP BY `date`, coach_id, coach_name
),

schedule_aggregated AS (
    -- 3. Group Schedule by Date/Coach
    SELECT 
        coach_id,
        `date`,
        SUM(
            GREATEST(0, TIMESTAMPDIFF(MINUTE, 
                STR_TO_DATE(CONCAT(`date`, ' ', time_from), '%Y-%m-%d %H:%i'), 
                STR_TO_DATE(CONCAT(`date`, ' ', time_to),   '%Y-%m-%d %H:%i')
            )) / 60.0
        ) AS total_scheduled_hours
    FROM court_coaches_schedule
    WHERE type = 'block'
    GROUP BY coach_id, `date`
)

-- 4. Final Join
SELECT 
    r.`date`,
    r.coach_id,
    r.coach_name,
    r.total_sessions,
    r.total_billable_hours,
    COALESCE(s.total_scheduled_hours, 0) AS total_scheduled_hours,
    r.total_revenue
FROM revenue_aggregated r
LEFT JOIN schedule_aggregated s 
    ON r.coach_id = s.coach_id 
    AND r.`date` = s.`date`;
