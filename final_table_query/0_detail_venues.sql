-- ================================================================
-- 1. Detail Venues:
-- This view enriches court bookings with venue and sport type details.
-- ================================================================
DROP VIEW IF EXISTS v_detail_venues;
CREATE OR REPLACE VIEW v_detail_venues AS 
SELECT 
    a.title, 
    a.item_id,
    b.court_id,
    c.court_id AS booking_court_id, -- Added alias to avoid duplicate column name in output
    b.title AS court_title,
    d.title AS sport_title          -- Added alias for clarity
FROM V_VENUES a
LEFT JOIN COURTS b ON a.item_id = b.COURT_ID 
LEFT JOIN court_bookings c ON b.id = c.court_id
LEFT JOIN v_sport_types d ON b.sport_type_id = d.item_id
WHERE 
    a.item_id IN (2616, 7365, 21833, 44741, 49596, 55085, 60911, 107489)
GROUP BY 
    a.title, 
    a.item_id,
    b.court_id, 
    c.court_id,
    b.title,
    d.title;