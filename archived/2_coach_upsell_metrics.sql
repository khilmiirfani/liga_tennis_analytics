CREATE OR REPLACE VIEW 2_coach_upsell_metrics AS
SELECT 
    cb.coach_id,
    cb.`date` AS txn_date,
    COUNT(DISTINCT co.id) AS upsell_orders,
    SUM(co.amount) AS upsell_revenue
FROM court_bookings cb
JOIN court_orders co 
    ON cb.user_id = co.customer_id 
    AND cb.`date` = DATE(co.created_at)
WHERE cb.coach_id IS NOT NULL
  AND cb.payment_status = 'paid'
  AND co.payment_status = 'paid'
GROUP BY cb.coach_id, cb.`date`;
