-- ================================================================
-- 4. Mart View: Court Utilization
-- DEPENDS ON: 1_court_bookings_base, 1_court_availability_summary
-- ================================================================
DROP VIEW IF EXISTS 1_court_utilization;
CREATE OR REPLACE VIEW 1_court_utilization AS
WITH 
-- 1. Get Actual Booked Hours (Summed by Court + Day)
actual_usage AS (
    SELECT 
        court_id,
        day_name, 
        SUM(booked_hours) AS total_booked_hours,
        COUNT(DISTINCT booking_date) AS number_of_days_recorded 
        -- This count is CRITICAL. If you have 4 Mondays of data, you need to know that 
        -- to compare against 4 * Monday Capacity, not 1 * Monday Capacity.
    FROM 1_court_bookings_base
    WHERE is_paid_fulfilled = 1  -- Only count valid bookings
    GROUP BY court_id, day_name
),

-- 2. Normalize Availability (Unpivot the wide columns into rows)
potential_capacity AS (
    SELECT court_id, 'Monday' AS day_name, monday_hours AS daily_capacity FROM 1_court_availability_summary
    UNION ALL
    SELECT court_id, 'Tuesday', tuesday_hours FROM 1_court_availability_summary
    UNION ALL
    SELECT court_id, 'Wednesday', wednesday_hours FROM 1_court_availability_summary
    UNION ALL
    SELECT court_id, 'Thursday', thursday_hours FROM 1_court_availability_summary
    UNION ALL
    SELECT court_id, 'Friday', friday_hours FROM 1_court_availability_summary
    UNION ALL
    SELECT court_id, 'Saturday', saturday_hours FROM 1_court_availability_summary
    UNION ALL
    SELECT court_id, 'Sunday', sunday_hours FROM 1_court_availability_summary
)

-- 3. Final Calculation
SELECT 
    p.court_id,
    vdv.title AS branch_name,
    vdv.court_title AS court_name,
    vdv.sport_title AS sport_type,
    p.day_name,
    
    -- Capacity Logic
    p.daily_capacity AS capacity_per_day,
    COALESCE(a.number_of_days_recorded, 0) AS days_in_dataset,
    (p.daily_capacity * COALESCE(a.number_of_days_recorded, 1)) AS total_potential_hours,
    
    -- Usage Logic
    COALESCE(a.total_booked_hours, 0) AS total_booked_hours,
    
    -- Utilization %
    CASE 
        WHEN (p.daily_capacity * COALESCE(a.number_of_days_recorded, 1)) = 0 THEN 0
        ELSE (COALESCE(a.total_booked_hours, 0) / (p.daily_capacity * COALESCE(a.number_of_days_recorded, 1))) * 100 
    END AS utilization_percentage

FROM potential_capacity p
LEFT JOIN actual_usage a 
    ON p.court_id = a.court_id 
    AND p.day_name = a.day_name
LEFT JOIN V_DETAIL_VENUES vdv ON p.court_id = vdv.BOOKING_COURT_ID
WHERE vdv.item_id IS NOT NULL
ORDER BY p.court_id, FIELD(p.day_name, 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday');

