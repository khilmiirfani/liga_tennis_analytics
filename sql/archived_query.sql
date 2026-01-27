
"""
Check the bookings with price 0
"""
SELECT 
a.id,
b.title AS branch_name,
a.date,
a.time_from,
a.time_to,
a.price,
a.payment_resolved
FROM court_bookings a
LEFT JOIN v_detail_venues b ON a.court_id = b.booking_court_id
WHERE b.item_id IS NOT NULL


===========================================================================

SELECT DISTINCT user_id, first_name, last_name
FROM v_courts_customers
WHERE user_id IS NULL
GROUP BY user_id, first_name, last_name



============================================================================================================
"""
For the Bundling Funnel (Bar Chart):
You need to count distinct bookings that have reached each 'level'.

Level 1 (Booking): Count of all paid bookings.
Level 2 (+Coach): Count of bookings where coach_id IS NOT NULL.
Level 3 (+Extras): Count of bookings present in court_booking_extras.
Level 4 (+Products): Count of bookings where the user also bought a product on the same day (requires joining court_orders).

Query for Funnel Data (Create as mart_funnel_summary):
"""

SELECT
  '1. Bookings' AS step, COUNT(DISTINCT cb.id) AS cnt FROM court_bookings cb WHERE cb.payment_status='paid' AND cb.deleted_at IS NULL
UNION ALL
SELECT
  '2. + Coach', COUNT(DISTINCT cb.id) FROM court_bookings cb WHERE cb.payment_status='paid' AND cb.coach_id IS NOT NULL AND cb.deleted_at IS NULL
UNION ALL
SELECT
  '3. + Extras', COUNT(DISTINCT cb.id) FROM court_bookings cb JOIN court_booking_extras be ON cb.id = be.booking_id WHERE cb.payment_status='paid' AND cb.deleted_at IS NULL
UNION ALL
SELECT
  '4. + Products', COUNT(DISTINCT cb.id) 
  FROM court_bookings cb 
  JOIN court_orders co ON cb.user_id = co.customer_id AND cb.`date` = DATE(co.created_at)
  WHERE cb.payment_status='paid' AND cb.deleted_at IS NULL;
