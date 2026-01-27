-- Run files in specific order
SOURCE 0_detail_venues.sql;
SOURCE 1_court_availability_summary.sql;
SOURCE 1_court_bookings_base.sql;
SOURCE 1_court_utilization.sql;
SOURCE 2_coach_prices.sql;
SOURCE 2_coach_revenue_per_booking_id.sql;
SOURCE 2_coach_revenues.sql;
SOURCE 2_coach_reviews.sql;
SOURCE 2_coach_schedule_per_day.sql;
SOURCE 2_coach_client_retention.sql;
SOURCE 3_product_performance.sql;
SOURCE 4_mart_customers.sql;
