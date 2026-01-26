CREATE OR REPLACE VIEW 2_coach_booking_metrics AS
SELECT 
    cb.coach_id,
    cb.court_id,
    cb.`date` AS booking_date,
    COUNT(DISTINCT cb.id) AS total_sessions,
    COUNT(DISTINCT cb.user_id) AS unique_clients,
    
    -- Billable Hours
    SUM(
        GREATEST(0, TIMESTAMPDIFF(MINUTE, 
            STR_TO_DATE(CONCAT(cb.`date`, ' ', cb.time_from), '%Y-%m-%d %H:%i'), 
            STR_TO_DATE(CONCAT(cb.`date`, ' ', cb.time_to),   '%Y-%m-%d %H:%i')
        )) / 60.0
    ) AS billable_hours,

    -- Repeat Clients Logic (Count of clients who have >1 session with this coach ever)
    -- *Note: This is hard to do in a daily aggregation. We will approximate "Returning Clients" 
    -- as clients who have booked this coach before today.*
    0 AS repeat_client_proxy -- Placeholder for complex logic, better handled in Step 4
FROM court_bookings cb
WHERE cb.coach_id IS NOT NULL 
  AND cb.payment_status = 'paid'
  AND cb.deleted_at IS NULL
GROUP BY cb.coach_id, cb.court_id, cb.`date`;
