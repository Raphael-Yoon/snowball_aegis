-- ============================================================
-- 외래키 인덱스 추가 (MySQL 운영 환경용)
-- ============================================================
-- 작성일: 2026-01-08
-- 목적: N+1 쿼리 문제 해결 및 조인 성능 향상
-- 실행 방법: MySQL Console에서 직접 복사/붙여넣기 실행
-- 롤백: add_indexes_mysql_rollback.sql 참조
-- ============================================================

USE itap$snowball;

-- 실행 전 확인
SELECT '=== 인덱스 추가 시작 ===' as status;
SELECT DATABASE() as current_database;
SELECT NOW() as start_time;

-- ============================================================
-- 1. 사용자 활동 로그 테이블
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_activity_log_user_id
ON sb_user_activity_log(user_id);

SELECT '✓ idx_user_activity_log_user_id 생성 완료' as status;

-- ============================================================
-- 2. RCM 테이블
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_rcm_user_id
ON sb_rcm(user_id);

SELECT '✓ idx_rcm_user_id 생성 완료' as status;

-- ============================================================
-- 3. RCM 상세 테이블 (4개 인덱스)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_rcm_detail_rcm_id
ON sb_rcm_detail(rcm_id);

CREATE INDEX IF NOT EXISTS idx_rcm_detail_mapped_std_control_id
ON sb_rcm_detail(mapped_std_control_id);

CREATE INDEX IF NOT EXISTS idx_rcm_detail_mapped_by
ON sb_rcm_detail(mapped_by);

CREATE INDEX IF NOT EXISTS idx_rcm_detail_ai_reviewed_by
ON sb_rcm_detail(ai_reviewed_by);

SELECT '✓ sb_rcm_detail 인덱스 4개 생성 완료' as status;

-- ============================================================
-- 4. 사용자-RCM 매핑 테이블 (3개 인덱스)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_user_rcm_user_id
ON sb_user_rcm(user_id);

CREATE INDEX IF NOT EXISTS idx_user_rcm_rcm_id
ON sb_user_rcm(rcm_id);

CREATE INDEX IF NOT EXISTS idx_user_rcm_granted_by
ON sb_user_rcm(granted_by);

SELECT '✓ sb_user_rcm 인덱스 3개 생성 완료' as status;

-- ============================================================
-- 5. 평가 헤더 테이블 (통합)
-- ============================================================
-- 주의: user_id 컬럼은 이전 마이그레이션에서 제거됨
CREATE INDEX IF NOT EXISTS idx_evaluation_header_rcm_id
ON sb_evaluation_header(rcm_id);

SELECT '✓ idx_evaluation_header_rcm_id 생성 완료' as status;

-- ============================================================
-- 6. 평가 라인 테이블 (통합)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_evaluation_line_header_id
ON sb_evaluation_line(header_id);

SELECT '✓ idx_evaluation_line_header_id 생성 완료' as status;

-- ============================================================
-- 7. 평가 샘플 테이블
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_evaluation_sample_line_id
ON sb_evaluation_sample(line_id);

SELECT '✓ idx_evaluation_sample_line_id 생성 완료' as status;

-- ============================================================
-- 8. 평가 이미지 테이블
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_evaluation_image_line_id
ON sb_evaluation_image(line_id);

SELECT '✓ idx_evaluation_image_line_id 생성 완료' as status;

-- ============================================================
-- 9. 내부평가 진행상황 테이블 (2개 인덱스)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_internal_assessment_rcm_id
ON sb_internal_assessment(rcm_id);

CREATE INDEX IF NOT EXISTS idx_internal_assessment_user_id
ON sb_internal_assessment(user_id);

SELECT '✓ sb_internal_assessment 인덱스 2개 생성 완료' as status;

-- ============================================================
-- 10. RCM-기준통제 매핑 테이블 (3개 인덱스)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_rcm_standard_mapping_rcm_id
ON sb_rcm_standard_mapping(rcm_id);

CREATE INDEX IF NOT EXISTS idx_rcm_standard_mapping_std_control_id
ON sb_rcm_standard_mapping(std_control_id);

CREATE INDEX IF NOT EXISTS idx_rcm_standard_mapping_mapped_by
ON sb_rcm_standard_mapping(mapped_by);

SELECT '✓ sb_rcm_standard_mapping 인덱스 3개 생성 완료' as status;

-- ============================================================
-- 11. RCM 완성도 평가 테이블 (2개 인덱스)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_rcm_completeness_eval_rcm_id
ON sb_rcm_completeness_eval(rcm_id);

CREATE INDEX IF NOT EXISTS idx_rcm_completeness_eval_eval_by
ON sb_rcm_completeness_eval(eval_by);

SELECT '✓ sb_rcm_completeness_eval 인덱스 2개 생성 완료' as status;

-- ============================================================
-- 완료 확인
-- ============================================================
SELECT '=== 인덱스 추가 완료 ===' as status;
SELECT NOW() as end_time;

-- 생성된 인덱스 확인 (주요 테이블만)
SELECT '=== 생성된 인덱스 확인 ===' as status;

SHOW INDEX FROM sb_evaluation_header WHERE Key_name LIKE 'idx_%';
SHOW INDEX FROM sb_evaluation_line WHERE Key_name LIKE 'idx_%';
SHOW INDEX FROM sb_evaluation_sample WHERE Key_name LIKE 'idx_%';
SHOW INDEX FROM sb_evaluation_image WHERE Key_name LIKE 'idx_%';
SHOW INDEX FROM sb_rcm_detail WHERE Key_name LIKE 'idx_%';
SHOW INDEX FROM sb_user_rcm WHERE Key_name LIKE 'idx_%';

-- 총 인덱스 개수 확인
SELECT
    TABLE_NAME,
    COUNT(*) as index_count
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'itap$snowball'
  AND INDEX_NAME LIKE 'idx_%'
GROUP BY TABLE_NAME
ORDER BY TABLE_NAME;

SELECT '=== 총 20개 인덱스가 추가되었습니다 ===' as status;
