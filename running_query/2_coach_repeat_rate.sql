CREATE OR REPLACE VIEW mart_coach_client_retention AS
SELECT 
    coach_id,
    user_id,
    COUNT(id) AS lifetime_sessions,
    MIN(`date`) AS first_session,
    MAX(`date`) AS last_session,
    CASE WHEN COUNT(id) > 1 THEN 1 ELSE 0 END AS is_repeat_client
FROM court_bookings
WHERE coach_id IS NOT NULL 
  AND payment_status = 'paid'
GROUP BY coach_id, user_id;
