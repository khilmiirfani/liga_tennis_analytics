-- ================================================================
-- 3. Base View: Court Bookings Detail
-- Depends only on raw tables (court_bookings, courts, V_DETAIL_VENUES)
-- ================================================================
DROP VIEW IF EXISTS 1_court_bookings_base;
CREATE OR REPLACE VIEW 1_court_bookings_base AS
SELECT
    cb.id AS booking_id,
    cb.court_id AS court_id,
    vdv.title AS branch_name,
    vdv.court_title AS court_name,
    vdv.sport_title AS sport_type,

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
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) <= 0 THEN 'b - Same Day'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) = 1  THEN 'a - Next Day'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 2 AND 7 THEN 'c - 1 Week Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 8 AND 14 THEN 'd - 2 Weeks Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 15 AND 21 THEN 'e - 3 Weeks Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) BETWEEN 22 AND 30 THEN 'f - 1 Month Before'
    WHEN DATEDIFF(cb.`date`, DATE(cb.created_at)) > 30 THEN 'g - > 1 Month Before'
    ELSE 'Unknown' -- Handles potential negative dates if data is messy
  END AS lead_time_category

FROM court_bookings cb
LEFT JOIN courts c            ON cb.court_id = c.court_id  -- or c.id depending on your schema key
LEFT JOIN V_DETAIL_VENUES vdv ON cb.court_id = vdv.BOOKING_COURT_ID 
WHERE vdv.item_id IS NOT NULL
  AND YEAR(cb.`date`) IN (YEAR(CURDATE()), YEAR(CURDATE()) - 1, YEAR(CURDATE()) - 2)



  
