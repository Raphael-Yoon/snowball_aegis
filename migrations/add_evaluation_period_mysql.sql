ALTER TABLE sb_evaluation_header
ADD COLUMN evaluation_period_start DATE NULL COMMENT '평가 대상 기간 시작일' AFTER evaluation_name,
ADD COLUMN evaluation_period_end DATE NULL COMMENT '평가 대상 기간 종료일' AFTER evaluation_period_start;

UPDATE sb_evaluation_header
SET
    evaluation_period_start = CONCAT('20', SUBSTRING_INDEX(SUBSTRING_INDEX(evaluation_name, 'FY', -1), '_', 1), '-01-01'),
    evaluation_period_end = CONCAT('20', SUBSTRING_INDEX(SUBSTRING_INDEX(evaluation_name, 'FY', -1), '_', 1), '-12-31')
WHERE evaluation_name REGEXP 'FY[0-9]{2}'
  AND evaluation_period_start IS NULL;

UPDATE sb_evaluation_header
SET
    evaluation_period_start = CONCAT(SUBSTRING_INDEX(SUBSTRING_INDEX(evaluation_name, '20', -1), '_', 1), '-01-01'),
    evaluation_period_end = CONCAT(SUBSTRING_INDEX(SUBSTRING_INDEX(evaluation_name, '20', -1), '_', 1), '-12-31')
WHERE evaluation_name REGEXP '20[0-9]{2}'
  AND evaluation_period_start IS NULL;
