-- ================================================================
-- 5. Coach Price View
-- Standardizes coach types and prices per court
-- ================================================================
DROP VIEW IF EXISTS `2_coach_price`;
CREATE OR REPLACE VIEW `2_coach_price` AS
WITH coach_type_std AS (
  -- A) main type_id (always 1 row per coach)
  SELECT
    c.id AS coach_id,
    c.name AS coach_name,
    c.court_id AS court_id_coach,
    CAST(c.type_id AS UNSIGNED) AS coach_type_id
  FROM court_coaches c

  UNION ALL

  -- B) additional_type_id array -> rows (0..N rows per coach)
  SELECT
    c.id AS coach_id,
    c.name AS coach_name,
    c.court_id AS court_id_coach,
    CAST(jt.type_id AS UNSIGNED) AS coach_type_id
  FROM court_coaches c
  JOIN JSON_TABLE(
        c.additional_type_id,
        '$[*]' COLUMNS (
          type_id VARCHAR(50) PATH '$'
        )
      ) jt
  WHERE c.additional_type_id IS NOT NULL
    AND JSON_VALID(c.additional_type_id)
),
coach_type_std_distinct AS (
  -- Optional: remove duplicates (in case additional list repeats the main type)
  SELECT DISTINCT
    coach_id, coach_name, court_id_coach, coach_type_id
  FROM coach_type_std
)
SELECT
  s.coach_id,
  s.coach_name,
  s.court_id_coach,
  s.coach_type_id as type_id,
  t.title AS coach_type,
  t.court_id AS court_id_type,
  t.price
FROM coach_type_std_distinct s
LEFT JOIN court_coaches_types t
  ON t.id = s.coach_type_id;
