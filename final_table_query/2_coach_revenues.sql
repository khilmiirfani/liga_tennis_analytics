--- ================================================================
-- 8. Coach Revenues Summary
-- Combines revenue and schedule per coach/day
-- ================================================================
DROP VIEW IF EXISTS `2_coach_revenues`
CREATE OR REPLACE VIEW `2_coach_revenues` AS
WITH revenue_aggregated AS (
    -- 2. Group Revenue by Date/Coach
    SELECT 
        `date`,
        coach_id,
        coach_name,
        COUNT(booking_id) AS total_sessions,
        SUM(duration_hours) AS total_billable_hours,
        SUM(coach_final_price) AS total_revenue
    FROM 2_coach_revenue_per_booking_id
    GROUP BY `date`, coach_id, coach_name
),

schedule_aggregated AS (
    -- 3. Group Schedule by Date/Coach
    SELECT 
        `date`,
        coach_id,
        SUM(total_scheduled_hours) AS total_scheduled_hours
    FROM 2_coach_schedule_per_day
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
    AND r.`date` = s.`date`
WHERE YEAR(r.`date`) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1, YEAR(CURDATE()) - 2);

