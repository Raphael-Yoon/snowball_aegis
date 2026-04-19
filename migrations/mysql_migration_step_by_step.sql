-- ====================================================================
-- Snowball MySQL 운영서버 마이그레이션 - 단계별 실행 스크립트
-- 작성일: 2025-11-28
-- ====================================================================
-- 주의: 각 단계를 하나씩 실행하면서 결과를 확인하세요!
-- ====================================================================

-- ====================================================================
-- STEP 0: 백업 확인
-- ====================================================================
-- 터미널에서 실행:
-- mysqldump -u사용자명 -p 데이터베이스명 > backup_$(date +%Y%m%d_%H%M%S).sql

-- ====================================================================
-- STEP 1: 현재 테이블 구조 확인
-- ====================================================================

-- sb_rcm 테이블 확인 (upload_user_id가 있는지 확인)
DESCRIBE sb_rcm;

-- sb_evaluation_sample 테이블 확인
DESCRIBE sb_evaluation_sample;

-- ====================================================================
-- STEP 2: Migration 024 - upload_user_id를 user_id로 변경
-- ====================================================================

-- 현재 컬럼명 확인
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'sb_rcm'
  AND COLUMN_NAME IN ('upload_user_id', 'user_id');

-- upload_user_id가 존재하면 실행
ALTER TABLE sb_rcm
CHANGE COLUMN upload_user_id user_id INT NOT NULL;

-- 변경 확인
DESCRIBE sb_rcm;

-- ====================================================================
-- STEP 3: Migration 026 - sb_evaluation_sample 테이블 간소화
-- ====================================================================

-- 3-1. 백업 테이블 생성
DROP TABLE IF EXISTS sb_evaluation_sample_backup;
CREATE TABLE sb_evaluation_sample_backup
SELECT * FROM sb_evaluation_sample;

-- 백업 확인
SELECT COUNT(*) as backup_count FROM sb_evaluation_sample_backup;

-- 3-2. 불필요한 컬럼 제거 (있을 경우에만)
-- 먼저 어떤 컬럼이 있는지 확인
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'sb_evaluation_sample'
  AND COLUMN_NAME IN ('request_number', 'requester_name', 'requester_department',
                      'approver_name', 'approver_department', 'approval_date');

-- 있는 컬럼만 제거 (MySQL 8.0 미만은 IF NOT EXISTS 미지원)
-- MySQL 버전에 따라 다음 중 하나 실행:

-- MySQL 8.0 이상:
ALTER TABLE sb_evaluation_sample
  DROP COLUMN IF EXISTS request_number,
  DROP COLUMN IF EXISTS requester_name,
  DROP COLUMN IF EXISTS requester_department,
  DROP COLUMN IF EXISTS approver_name,
  DROP COLUMN IF EXISTS approver_department,
  DROP COLUMN IF EXISTS approval_date;

-- MySQL 5.7 이하는 각각 실행:
-- ALTER TABLE sb_evaluation_sample DROP COLUMN request_number;
-- ALTER TABLE sb_evaluation_sample DROP COLUMN requester_name;
-- ALTER TABLE sb_evaluation_sample DROP COLUMN requester_department;
-- ALTER TABLE sb_evaluation_sample DROP COLUMN approver_name;
-- ALTER TABLE sb_evaluation_sample DROP COLUMN approver_department;
-- ALTER TABLE sb_evaluation_sample DROP COLUMN approval_date;

-- 3-3. evaluation_type 컬럼 확인 및 추가
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'sb_evaluation_sample'
  AND COLUMN_NAME = 'evaluation_type';

-- evaluation_type이 없으면 추가 (있으면 에러 발생, 무시)
ALTER TABLE sb_evaluation_sample
ADD COLUMN evaluation_type VARCHAR(20) DEFAULT 'operation';

-- 변경 확인
DESCRIBE sb_evaluation_sample;

-- ====================================================================
-- STEP 4: Migration 027 - attribute0~9 컬럼 추가
-- ====================================================================

-- 4-1. 현재 attribute 컬럼 확인
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = 'sb_evaluation_sample'
  AND COLUMN_NAME LIKE 'attribute%'
ORDER BY COLUMN_NAME;

-- 4-2. attribute 컬럼 추가 (MySQL 8.0 이상)
ALTER TABLE sb_evaluation_sample
  ADD COLUMN IF NOT EXISTS attribute0 TEXT,
  ADD COLUMN IF NOT EXISTS attribute1 TEXT,
  ADD COLUMN IF NOT EXISTS attribute2 TEXT,
  ADD COLUMN IF NOT EXISTS attribute3 TEXT,
  ADD COLUMN IF NOT EXISTS attribute4 TEXT,
  ADD COLUMN IF NOT EXISTS attribute5 TEXT,
  ADD COLUMN IF NOT EXISTS attribute6 TEXT,
  ADD COLUMN IF NOT EXISTS attribute7 TEXT,
  ADD COLUMN IF NOT EXISTS attribute8 TEXT,
  ADD COLUMN IF NOT EXISTS attribute9 TEXT;

-- MySQL 5.7 이하는 각각 실행:
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute0 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute1 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute2 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute3 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute4 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute5 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute6 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute7 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute8 TEXT;
-- ALTER TABLE sb_evaluation_sample ADD COLUMN attribute9 TEXT;

-- 변경 확인
DESCRIBE sb_evaluation_sample;

-- ====================================================================
-- STEP 5: Migration 028 - no_occurrence 필드 추가
-- ====================================================================

-- 5-1. sb_design_evaluation_line에 추가
ALTER TABLE sb_design_evaluation_line
  ADD COLUMN IF NOT EXISTS no_occurrence TINYINT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS no_occurrence_reason TEXT;

-- 5-2. sb_design_evaluation_header에 추가
ALTER TABLE sb_design_evaluation_header
  ADD COLUMN IF NOT EXISTS no_occurrence_count INT DEFAULT 0;

-- 변경 확인
DESCRIBE sb_design_evaluation_line;
DESCRIBE sb_design_evaluation_header;

-- ====================================================================
-- STEP 6: 최종 확인
-- ====================================================================

-- 모든 변경사항 확인
SELECT 'sb_rcm 테이블' as table_name;
DESCRIBE sb_rcm;

SELECT 'sb_evaluation_sample 테이블' as table_name;
DESCRIBE sb_evaluation_sample;

SELECT 'sb_design_evaluation_line 테이블' as table_name;
DESCRIBE sb_design_evaluation_line;

SELECT 'sb_design_evaluation_header 테이블' as table_name;
DESCRIBE sb_design_evaluation_header;

-- 데이터 손실 확인
SELECT COUNT(*) as current_count FROM sb_evaluation_sample;
SELECT COUNT(*) as backup_count FROM sb_evaluation_sample_backup;

-- ====================================================================
-- STEP 7: 백업 테이블 삭제 (확인 후 실행)
-- ====================================================================

-- 문제없으면 백업 테이블 삭제
-- DROP TABLE sb_evaluation_sample_backup;
