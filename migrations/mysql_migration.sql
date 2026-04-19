-- ====================================================================
-- Snowball MySQL 운영서버 마이그레이션 스크립트
-- 작성일: 2025-11-28
-- 설명: SQLite 마이그레이션 024~028을 MySQL 버전으로 변환
-- ====================================================================

-- 실행 전 반드시 백업!
-- mysqldump -u사용자명 -p 데이터베이스명 > backup_$(date +%Y%m%d_%H%M%S).sql

START TRANSACTION;

-- ====================================================================
-- Migration 024: sb_rcm 테이블의 upload_user_id를 user_id로 변경
-- ====================================================================

-- 1. 기존 컬럼이 upload_user_id인지 확인
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'sb_rcm'
  AND COLUMN_NAME IN ('upload_user_id', 'user_id');

-- 2. upload_user_id가 존재하면 user_id로 변경
ALTER TABLE sb_rcm
CHANGE COLUMN upload_user_id user_id INT NOT NULL;

-- ====================================================================
-- Migration 025: evaluation unique 제약조건에서 user 제거
-- (이미 처리되어 있을 수 있음, 에러 무시)
-- ====================================================================

-- 기존 unique 제약조건 확인 및 제거 (있을 경우)
-- ALTER TABLE sb_design_evaluation_header
-- DROP INDEX IF EXISTS unique_index_name;

-- ====================================================================
-- Migration 026: sb_evaluation_sample 테이블 간소화
-- ====================================================================

-- 1. 기존 테이블 백업
CREATE TABLE IF NOT EXISTS sb_evaluation_sample_backup
SELECT * FROM sb_evaluation_sample;

-- 2. 불필요한 컬럼 제거 (MySQL은 ALTER TABLE DROP COLUMN 지원)
ALTER TABLE sb_evaluation_sample
  DROP COLUMN IF EXISTS request_number,
  DROP COLUMN IF EXISTS requester_name,
  DROP COLUMN IF EXISTS requester_department,
  DROP COLUMN IF EXISTS approver_name,
  DROP COLUMN IF EXISTS approver_department,
  DROP COLUMN IF EXISTS approval_date;

-- 3. evaluation_type 컬럼 추가 (없을 경우)
ALTER TABLE sb_evaluation_sample
  ADD COLUMN IF NOT EXISTS evaluation_type VARCHAR(20) DEFAULT 'operation';

-- ====================================================================
-- Migration 027: sb_evaluation_sample에 attribute0~9 컬럼 추가
-- ====================================================================

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

-- ====================================================================
-- Migration 028: sb_design_evaluation_line에 no_occurrence 필드 추가
-- ====================================================================

ALTER TABLE sb_design_evaluation_line
  ADD COLUMN IF NOT EXISTS no_occurrence TINYINT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS no_occurrence_reason TEXT;

ALTER TABLE sb_design_evaluation_header
  ADD COLUMN IF NOT EXISTS no_occurrence_count INT DEFAULT 0;

-- ====================================================================
-- 변경 사항 확인
-- ====================================================================

-- sb_rcm 테이블 확인
SELECT 'sb_rcm 테이블 구조:' AS info;
DESCRIBE sb_rcm;

-- sb_evaluation_sample 테이블 확인
SELECT 'sb_evaluation_sample 테이블 구조:' AS info;
DESCRIBE sb_evaluation_sample;

-- sb_design_evaluation_line 테이블 확인
SELECT 'sb_design_evaluation_line 테이블 구조:' AS info;
DESCRIBE sb_design_evaluation_line;

-- ====================================================================
-- 커밋 (문제없으면 주석 해제)
-- ====================================================================

-- COMMIT;

-- 롤백이 필요한 경우:
-- ROLLBACK;
