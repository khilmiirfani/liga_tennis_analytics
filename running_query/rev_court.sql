CREATE OR REPLACE VIEW v_rev_booking_paid AS
SELECT
  cb.`date`              AS txn_date,
  cb.court_id            AS court_id,
  cb.user_id             AS user_id,
  'court_booking'        AS stream,
  (COALESCE(cb.price,0) + COALESCE(cb.additional_payment,0)) AS gross_amount,
  cb.id                  AS ref_id,
  b.sport_title
FROM court_bookings cb
LEFT JOIN v_detail_venues b ON cb.COURT_ID = b.BOOKING_COURT_ID 
WHERE cb.deleted_at IS NULL
  AND cb.payment_status = 'paid'
  AND b.item_id IS NOT null
