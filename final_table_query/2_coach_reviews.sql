-- ===============================================================
-- 2. Coach Reviews View
-- Aggregates coach reviews and calculates NPS per coach/month
-- ================================================================
DROP VIEW IF EXISTS 2_coach_reviews;
CREATE OR REPLACE VIEW 2_coach_reviews AS
SELECT 
    -- Dimensions
    r.coach_id,
    c.name AS coach_name,
    v.title AS branch_name, -- Added Branch Name
    DATE_FORMAT(r.created_at, '%Y-%m') AS review_month,
    
    -- Volume Metrics
    COUNT(r.id) AS total_reviews,
    
    -- Rating Metrics (Fixed column name 'rate')
    AVG(r.rate) AS avg_rating,
    
    -- NPS Components (Assuming 5-Star Scale)
    SUM(CASE WHEN r.rate = 5 THEN 1 ELSE 0 END) AS promoter_count,
    SUM(CASE WHEN r.rate = 4 THEN 1 ELSE 0 END) AS passive_count,
    SUM(CASE WHEN r.rate <= 3 THEN 1 ELSE 0 END) AS detractor_count,
    
    -- Calculated NPS Score
    ROUND(
        (
            (SUM(CASE WHEN r.rate = 5 THEN 1 ELSE 0 END) - 
             SUM(CASE WHEN r.rate <= 3 THEN 1 ELSE 0 END)) 
            / NULLIF(COUNT(r.id), 0) -- Protect against divide by zero
        ) * 100, 
    2) AS nps_score

FROM courts_customers_reviews r
LEFT JOIN court_coaches c ON r.coach_id = c.id
LEFT JOIN V_DETAIL_VENUES v ON c.court_id = v.item_id -- Join to get Branch Name from Coach's assigned court
WHERE r.deleted_at IS NULL
GROUP BY 
    r.coach_id, 
    c.name, 
    v.title,
    DATE_FORMAT(r.created_at, '%Y-%m');
