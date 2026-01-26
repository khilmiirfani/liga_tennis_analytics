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
GROUP BY a.coach_id, b.name, a.user_id, c.first_name, c.last_name --group by coach and user to get lifetime sessions per user per coach