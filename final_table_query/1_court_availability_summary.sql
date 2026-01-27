-- ================================================================
-- 2. Base View: Court Availability Summary
-- Aggregates open hours per court/day
-- ================================================================
DROP VIEW IF EXISTS 1_court_availability_summary;
CREATE OR REPLACE VIEW 1_court_availability_summary AS
SELECT 
    a.item_id AS court_id,
    
    -- Calculate hours for Monday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_monday
    ) AS monday_hours,

    -- Calculate hours for Tuesday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_tuesday
    ) AS tuesday_hours,

    -- Calculate hours for Wednesday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_wednesday
    ) AS wednesday_hours,

    -- Calculate hours for Thursday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_thursday
    ) AS thursday_hours,

    -- Calculate hours for Friday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_friday
    ) AS friday_hours,

    -- Calculate hours for Saturday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_saturday
    ) AS saturday_hours,

    -- Calculate hours for Sunday
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(a.time_from), '%H:%i'), 
            STR_TO_DATE(CONCAT(a.time_to),   '%H:%i')
        )) / 60.0 * a.is_sunday
    ) AS sunday_hours

FROM courts_hours_availability a 
WHERE a.deleted_at IS NULL -- Important: Exclude deleted schedules
GROUP BY a.item_id;
