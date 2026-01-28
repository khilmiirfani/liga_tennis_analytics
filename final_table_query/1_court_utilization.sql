-- ================================================================
-- 4. Mart View: Court Utilization
-- DEPENDS ON: 1_court_bookings_base, 1_court_availability_summary
-- ================================================================
DROP VIEW IF EXISTS 1_court_utilization;
CREATE OR REPLACE VIEW 1_court_utilization AS
SELECT 
    -- 1. Date Dimensions (The "Sortable" Columns)
    b.booking_date,
    YEAR(b.booking_date) AS year_num,               -- 2026
    QUARTER(b.booking_date) AS quarter_num,         -- 1 to 4
    MONTH(b.booking_date) AS month_num,             -- 1 to 12

    -- Day Sorting Logic (1=Mon, 7=Sun)
    -- Standard WEEKDAY() returns 0=Mon...6=Sun. We add 1 to make it 1=Mon...7=Sun
    WEEKDAY(b.booking_date) + 1 AS day_of_week_num, 
    DAYNAME(b.booking_date) AS day_name,            -- 'Monday'

    -- 2. Business Context
    b.court_id,
    b.branch_name,
    b.court_name,
    b.sport_type,

    -- 3. Supply (Capacity)
    MAX(CASE 
        WHEN DAYNAME(b.booking_date) = 'Monday' THEN s.monday_hours
        WHEN DAYNAME(b.booking_date) = 'Tuesday' THEN s.tuesday_hours
        WHEN DAYNAME(b.booking_date) = 'Wednesday' THEN s.wednesday_hours
        WHEN DAYNAME(b.booking_date) = 'Thursday' THEN s.thursday_hours
        WHEN DAYNAME(b.booking_date) = 'Friday' THEN s.friday_hours
        WHEN DAYNAME(b.booking_date) = 'Saturday' THEN s.saturday_hours
        WHEN DAYNAME(b.booking_date) = 'Sunday' THEN s.sunday_hours
        ELSE 0 
    END) as daily_capacity_hours,

    -- 4. Demand (Actual Usage)
    SUM(b.booked_hours) as total_hours_sold,
    SUM(b.gross_revenue) as daily_revenue,

    -- 5. Utilization KPI
    ROUND(
        (SUM(b.booked_hours) / 
        NULLIF(
            MAX(CASE 
                WHEN DAYNAME(b.booking_date) = 'Monday' THEN s.monday_hours
                WHEN DAYNAME(b.booking_date) = 'Tuesday' THEN s.tuesday_hours
                WHEN DAYNAME(b.booking_date) = 'Wednesday' THEN s.wednesday_hours
                WHEN DAYNAME(b.booking_date) = 'Thursday' THEN s.thursday_hours
                WHEN DAYNAME(b.booking_date) = 'Friday' THEN s.friday_hours
                WHEN DAYNAME(b.booking_date) = 'Saturday' THEN s.saturday_hours
                WHEN DAYNAME(b.booking_date) = 'Sunday' THEN s.sunday_hours
                ELSE 0 
            END), 0)
        ) * 100, 
    2) as utilization_pct

FROM 1_court_bookings_base b
LEFT JOIN `1_court_availability_summary` s ON b.court_id = s.court_id
WHERE b.is_paid_fulfilled = 1 
GROUP BY 
    b.booking_date, 
    b.court_id, 
    b.branch_name, 
    b.court_name, 
    b.sport_type;
