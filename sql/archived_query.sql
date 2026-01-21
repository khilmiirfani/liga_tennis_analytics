
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