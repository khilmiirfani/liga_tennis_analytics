-- ================================================================
-- 1. Detail Venues:
-- This view enriches court bookings with venue and sport type details.
-- ================================================================
CREATE OR REPLACE VIEW v_detail_venues AS 
SELECT 
    a.title, 
    a.item_id,
    b.court_id,
    c.court_id AS booking_court_id, -- Added alias to avoid duplicate column name in output
    b.title AS court_title,
    d.title AS sport_title          -- Added alias for clarity
FROM V_VENUES a
LEFT JOIN COURTS b ON a.item_id = b.COURT_ID 
LEFT JOIN court_bookings c ON b.id = c.court_id
LEFT JOIN v_sport_types d ON b.sport_type_id = d.item_id
WHERE 
    a.item_id IN (2616, 7365, 21833, 44741, 49596, 55085, 60911, 107489)
GROUP BY 
    a.title, 
    a.item_id,
    b.court_id, 
    c.court_id,
    b.title,
    d.title;

-- ================================================================
-- 2. Base View: Court Availability Summary
-- Aggregates open hours per court/day
-- ================================================================
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


-- ================================================================
-- 3. Base View: Court Bookings Detail
-- Depends only on raw tables (court_bookings, courts, V_DETAIL_VENUES)
-- ================================================================
CREATE OR REPLACE VIEW 1_court_bookings_base AS
SELECT
  cb.id AS booking_id,
  cb.court_id,
  vdv.title AS branch_name,
  vdv.court_title AS court_name,
  vdv.sport_title AS sport_type,   -- e.g., Tennis, Padel

  -- Date & Time Dimensions
  cb.`date` AS booking_date,
  DAYNAME(cb.`date`) AS day_name,
  DAYOFWEEK(cb.`date`) AS day_of_week_num, -- 1=Sunday, 2=Monday...
  
  -- Time Parsing (assuming HH:MM format strings)
  cb.time_from,
  cb.time_to,
  HOUR(STR_TO_DATE(cb.time_from, '%H:%i')) AS start_hour,
  
  -- Peak/Off-Peak Logic (Example: Mon-Fri 17-21 is Peak)
  CASE 
    WHEN DAYOFWEEK(cb.`date`) IN (2,3,4,5,6) AND HOUR(STR_TO_DATE(cb.time_from, '%H:%i')) BETWEEN 17 AND 21 THEN 'Peak'
    WHEN DAYOFWEEK(cb.`date`) IN (1,7) AND HOUR(STR_TO_DATE(cb.time_from, '%H:%i')) BETWEEN 8 AND 20 THEN 'Peak'
    ELSE 'Off-Peak'
  END AS time_band,

  -- Duration (Booked Hours)
  GREATEST(0, TIMESTAMPDIFF(MINUTE, 
      STR_TO_DATE(CONCAT(cb.`date`,' ',cb.time_from), '%Y-%m-%d %H:%i'), 
      STR_TO_DATE(CONCAT(cb.`date`,' ',cb.time_to),   '%Y-%m-%d %H:%i')
  )) / 60.0 AS booked_hours,

  -- Lead Time (Days)
  DATEDIFF(cb.`date`, DATE(cb.created_at)) AS lead_time_days,

  -- Financials
  (COALESCE(cb.price,0) + COALESCE(cb.additional_payment,0)) AS gross_revenue,
  
  -- Status Flags
  cb.payment_status,
  cb.canceled_at,
  cb.cancelled_no_fee,
  
  CASE 
    WHEN cb.canceled_at IS NOT NULL THEN 'Cancelled'
    WHEN cb.payment_status = 'paid' THEN 'Completed'
    ELSE 'Unpaid/Other' 
  END AS booking_status_derived,

  -- Metrics Helpers (0/1 flags for easy SUM in Looker)
  CASE WHEN cb.payment_status = 'paid' AND cb.canceled_at IS NULL THEN 1 ELSE 0 END AS is_paid_fulfilled,
  CASE WHEN cb.canceled_at IS NOT NULL THEN 1 ELSE 0 END AS is_cancelled,

  CASE 
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) <= 0 THEN 'Same Day'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) = 1  THEN 'Next Day'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 2 AND 7 THEN '1 Week Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 8 AND 14 THEN '2 Weeks Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 15 AND 21 THEN '3 Weeks Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 22 AND 30 THEN '1 Month Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) > 30 THEN '> 1 Month Before'
    ELSE 'Unknown' -- Handles potential negative dates if data is messy
  END AS lead_time_category

FROM court_bookings cb
LEFT JOIN courts c            ON cb.court_id = c.court_id  -- or c.id depending on your schema key
LEFT JOIN V_DETAIL_VENUES vdv ON cb.court_id = vdv.BOOKING_COURT_ID 
WHERE vdv.item_id IS NOT NULL
  AND YEAR(cb.`date`) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1, YEAR(CURDATE()) - 2)



-- ================================================================
-- 4. Mart View: Court Utilization
-- DEPENDS ON: 1_court_bookings_base, 1_court_availability_summary
-- ================================================================
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
    FROM v_bookings_base
    WHERE is_paid_fulfilled = 1  -- Only count valid bookings
    GROUP BY court_id, day_name
),

-- 2. Normalize Availability (Unpivot the wide columns into rows)
potential_capacity AS (
    SELECT court_id, 'Monday' AS day_name, monday_hours AS daily_capacity FROM v_court_availability_summary
    UNION ALL
    SELECT court_id, 'Tuesday', tuesday_hours FROM v_court_availability_summary
    UNION ALL
    SELECT court_id, 'Wednesday', wednesday_hours FROM v_court_availability_summary
    UNION ALL
    SELECT court_id, 'Thursday', thursday_hours FROM v_court_availability_summary
    UNION ALL
    SELECT court_id, 'Friday', friday_hours FROM v_court_availability_summary
    UNION ALL
    SELECT court_id, 'Saturday', saturday_hours FROM v_court_availability_summary
    UNION ALL
    SELECT court_id, 'Sunday', sunday_hours FROM v_court_availability_summary
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


-- ================================================================
-- 5. Coach Price View
-- Standardizes coach types and prices per court
-- ================================================================

CREATE OR REPLACE VIEW `2_coach_price` AS
WITH coach_type_std AS (
  -- A) main type_id (always 1 row per coach)
  SELECT
    c.id AS coach_id,
    c.name AS coach_name,
    c.court_id AS court_id_coach,
    CAST(c.type_id AS UNSIGNED) AS coach_type_id
  FROM court_coaches c

  UNION ALL

  -- B) additional_type_id array -> rows (0..N rows per coach)
  SELECT
    c.id AS coach_id,
    c.name AS coach_name,
    c.court_id AS court_id_coach,
    CAST(jt.type_id AS UNSIGNED) AS coach_type_id
  FROM court_coaches c
  JOIN JSON_TABLE(
        c.additional_type_id,
        '$[*]' COLUMNS (
          type_id VARCHAR(50) PATH '$'
        )
      ) jt
  WHERE c.additional_type_id IS NOT NULL
    AND JSON_VALID(c.additional_type_id)
),
coach_type_std_distinct AS (
  -- Optional: remove duplicates (in case additional list repeats the main type)
  SELECT DISTINCT
    coach_id, coach_name, court_id_coach, coach_type_id
  FROM coach_type_std
)
SELECT
  s.coach_id,
  s.coach_name,
  s.court_id_coach,
  s.coach_type_id as type_id,
  t.title AS coach_type,
  t.court_id AS court_id_type,
  t.price
FROM coach_type_std_distinct s
LEFT JOIN court_coaches_types t
  ON t.id = s.coach_type_id;

-- ================================================================
-- 6. Coach Revenues Per Booking
-- Joins bookings with coach prices to get revenue per booking
-- ================================================================
CREATE OR REPLACE VIEW 2_coach_revenue_per_booking_id AS (
SELECT 
    a.`date`,
    a.id AS booking_id,
    e.title AS branch_name,
    e.court_title AS court_name,
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
LEFT JOIN v_detail_venues   e     ON a.court_id = e.booking_court_id
WHERE a.payment_status ='paid'
AND e.item_id IS NOT NULL
AND YEAR(a.`date`) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1, YEAR(CURDATE()) - 2)
 -- filter the date for last 3 years
-- AND a.`date` > '2026-01-01' -- filter the date for testing
-- AND a.coach_id IS NOT NULL -- Removed to include all bookings
ORDER BY a.date desc
);

-- ================================================================
-- 7. Coach Schedule Per Day   
-- Aggregates scheduled hours per coach/day
-- ================================================================
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


--- ================================================================
-- 8. Coach Revenues Summary
-- Combines revenue and schedule per coach/day
-- ================================================================

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


--- ================================================================
-- 9. Coach Client Retention
-- Identifies repeat clients per coach
--- ================================================================
CREATE OR REPLACE VIEW 2_coach_client_retention AS
SELECT 
    a.coach_id,
    b.name as coach_name,
    a.user_id,
    c.first_name,
    c.last_name,
    COUNT(a.id) AS lifetime_sessions,
    MIN(a.`date`) AS first_session,
    MAX(a.`date`) AS last_session,
    CASE WHEN COUNT(a.id) > 1 THEN 1 ELSE 0 END AS is_repeat_client
FROM court_bookings a
LEFT JOIN court_coaches b ON a.coach_id = b.id
LEFT JOIN v_courts_customers c ON a.user_id = c.user_id
WHERE a.coach_id IS NOT NULL 
  AND a.payment_status = 'paid'     -- filter only paid sessions
  AND a.user_id IS NOT NULL         -- filter only valid users
  AND ( a.coach_id IS NOT NULL AND a.coach_id != '0' ) -- filter only valid coaches
GROUP BY a.coach_id, b.name, a.user_id, c.first_name, c.last_name; --group by coach and user to get lifetime sessions per user per coach

