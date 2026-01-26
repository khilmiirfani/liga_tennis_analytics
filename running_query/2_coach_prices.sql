CREATE OR REPLACE VIEW 2_coach_price AS (
SELECT 
    a.id AS coach_id,
    a.name AS coach_name,
    a.type_id AS type_id,
    b.title AS coach_type,
    a.court_id AS court_id_coach,    -- Renamed for clarity (court_id from table A)
    b.court_id AS court_id_type,     -- Renamed for clarity (court_id from table B)
    b.title AS type_title,
    b.price AS price
FROM court_coaches a
LEFT JOIN court_coaches_types b 
    ON a.court_id = b.court_id
)
