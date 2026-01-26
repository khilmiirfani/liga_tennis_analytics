SELECT DISTINCT user_id, first_name, last_name
FROM v_courts_customers
WHERE user_id IS NULL
GROUP BY user_id, first_name, last_name
