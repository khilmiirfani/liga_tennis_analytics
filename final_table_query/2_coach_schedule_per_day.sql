-- ================================================================
-- 7. Coach Schedule Per Day   
-- Aggregates scheduled hours per coach/day
-- ================================================================
DROP VIEW IF EXISTS 2_coach_schedule_per_day;
CREATE OR REPLACE VIEW 2_coach_schedule_per_day AS
SELECT 
    `date`,
    coach_id,
    court_id,
    -- Calculate scheduled duration in hours
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(`date`, ' ', time_from), '%Y-%m-%d %H:%i'), 
            STR_TO_DATE(CONCAT(`date`, ' ', time_to),   '%Y-%m-%d %H:%i')
        )) / 60.0
    ) AS total_scheduled_hours
FROM court_coaches_schedule
WHERE type = 'block' -- Updated to filter for 'block' availability
GROUP BY coach_id, court_id, `date`;