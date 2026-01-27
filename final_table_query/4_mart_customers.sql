--- ================================================================
-- 9. Customer Mart
-- Combines customer membership and booking activity for LTV and churn analysis
--- ================================================================
DROP VIEW IF EXISTS 4_mart_customer;
CREATE OR REPLACE VIEW 4_mart_customer AS
WITH user_activity AS (
    -- 1. Summarize Booking Behavior (Last Active Date & Spending)
    SELECT 
        user_id,
        MIN(`date`) as first_booking_date,
        MAX(`date`) as last_booking_date,
        COUNT(DISTINCT id) as total_bookings,
        SUM(COALESCE(price,0) + COALESCE(additional_payment,0)) as total_spend_bookings,
        DATEDIFF(CURDATE(), MAX(`date`)) as days_since_last_booking
    FROM court_bookings
    WHERE payment_status = 'paid'
    GROUP BY user_id
),

membership_status AS (
    -- 2. Define Membership Lifecycle
    SELECT 
        user_id,
        first_name,
        last_name,
        created_at as join_date,
        is_member,
        member_type,
        membership_valid_to,
        -- Check if membership is currently valid
        CASE 
            WHEN is_member = 1 AND membership_valid_to >= CURDATE() THEN 'Active Member'
            WHEN is_member = 1 AND membership_valid_to < CURDATE() THEN 'Expired Member'
            ELSE 'Non-Member' 
        END as membership_state
    FROM v_courts_customers
    WHERE deleted_at IS NULL
)

SELECT 
    m.user_id,
    CONCAT(m.first_name, ' ', m.last_name) as full_name,
    m.member_type,
    m.membership_state,
    
    -- Dates
    DATE(m.join_date) as join_date,
    DATE_FORMAT(m.join_date, '%Y-%m') as cohort_month,
    ua.first_booking_date,
    ua.last_booking_date,
    
    -- Activity Metrics
    COALESCE(ua.total_bookings, 0) as lifetime_bookings,
    COALESCE(ua.total_spend_bookings, 0) as lifetime_revenue, -- Add Package/Event revenue joins here if needed
    
    -- Retention Logic
    COALESCE(ua.days_since_last_booking, 9999) as days_inactive,
    
    CASE 
        WHEN m.membership_state = 'Active Member' THEN 'Active'
        WHEN ua.days_since_last_booking <= 30 THEN 'Active User'
        WHEN ua.days_since_last_booking BETWEEN 31 AND 90 THEN 'At Risk'
        ELSE 'Churned' 
    END as churn_status,

    -- LTV Calculation (Simple version)
    COALESCE(ua.total_spend_bookings, 0) as current_ltv

FROM membership_status m
LEFT JOIN user_activity ua ON m.user_id = ua.user_id;
