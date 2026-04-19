-- ============================================================
-- 외래키 인덱스 제거 (롤백용 - MySQL 운영 환경)
-- ============================================================
-- 작성일: 2026-01-08
-- 목적: add_indexes_mysql.sql 롤백
-- 주의: 인덱스를 제거하면 성능이 저하될 수 있습니다!
-- 실행 방법: MySQL Console에서 직접 복사/붙여넣기 실행
-- ============================================================

USE itap$snowball;

-- 실행 전 확인
SELECT '=== 인덱스 제거 시작 (롤백) ===' as status;
SELECT DATABASE() as current_database;
SELECT NOW() as start_time;

-- 경고 메시지
SELECT '경고: 인덱스를 제거하면 쿼리 성능이 저하될 수 있습니다!' as warning;
SELECT '계속 진행하려면 아래 쿼리를 실행하세요.' as info;

-- ============================================================
-- 인덱스 제거 (역순으로 제거)
-- ============================================================

-- 1. RCM 완성도 평가 테이블
DROP INDEX IF EXISTS idx_rcm_completeness_eval_eval_by ON sb_rcm_completeness_eval;
DROP INDEX IF EXISTS idx_rcm_completeness_eval_rcm_id ON sb_rcm_completeness_eval;

-- 2. RCM-기준통제 매핑 테이블
DROP INDEX IF EXISTS idx_rcm_standard_mapping_mapped_by ON sb_rcm_standard_mapping;
DROP INDEX IF EXISTS idx_rcm_standard_mapping_std_control_id ON sb_rcm_standard_mapping;
DROP INDEX IF EXISTS idx_rcm_standard_mapping_rcm_id ON sb_rcm_standard_mapping;

-- 3. 내부평가 진행상황 테이블
DROP INDEX IF EXISTS idx_internal_assessment_user_id ON sb_internal_assessment;
DROP INDEX IF EXISTS idx_internal_assessment_rcm_id ON sb_internal_assessment;

-- 4. 평가 이미지 테이블
DROP INDEX IF EXISTS idx_evaluation_image_line_id ON sb_evaluation_image;

-- 5. 평가 샘플 테이블
DROP INDEX IF EXISTS idx_evaluation_sample_line_id ON sb_evaluation_sample;

-- 6. 평가 라인 테이블 (통합)
DROP INDEX IF EXISTS idx_evaluation_line_header_id ON sb_evaluation_line;

-- 7. 평가 헤더 테이블 (통합)
DROP INDEX IF EXISTS idx_evaluation_header_rcm_id ON sb_evaluation_header;

-- 8. 사용자-RCM 매핑 테이블
DROP INDEX IF EXISTS idx_user_rcm_granted_by ON sb_user_rcm;
DROP INDEX IF EXISTS idx_user_rcm_rcm_id ON sb_user_rcm;
DROP INDEX IF EXISTS idx_user_rcm_user_id ON sb_user_rcm;

-- 9. RCM 상세 테이블
DROP INDEX IF EXISTS idx_rcm_detail_ai_reviewed_by ON sb_rcm_detail;
DROP INDEX IF EXISTS idx_rcm_detail_mapped_by ON sb_rcm_detail;
DROP INDEX IF EXISTS idx_rcm_detail_mapped_std_control_id ON sb_rcm_detail;
DROP INDEX IF EXISTS idx_rcm_detail_rcm_id ON sb_rcm_detail;

-- 10. RCM 테이블
DROP INDEX IF EXISTS idx_rcm_user_id ON sb_rcm;

-- 11. 사용자 활동 로그 테이블
DROP INDEX IF EXISTS idx_user_activity_log_user_id ON sb_user_activity_log;

-- ============================================================
-- 완료 확인
-- ============================================================
SELECT '=== 인덱스 제거 완료 ===' as status;
SELECT NOW() as end_time;

-- 제거 확인 (주요 테이블에 idx_ 인덱스가 없어야 함)
SELECT '=== 제거 확인 (결과가 없어야 정상) ===' as status;

SELECT TABLE_NAME, INDEX_NAME
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'itap$snowball'
  AND INDEX_NAME LIKE 'idx_%'
  AND INDEX_NAME IN (
    'idx_user_activity_log_user_id',
    'idx_rcm_user_id',
    'idx_rcm_detail_rcm_id',
    'idx_rcm_detail_mapped_std_control_id',
    'idx_rcm_detail_mapped_by',
    'idx_rcm_detail_ai_reviewed_by',
    'idx_user_rcm_user_id',
    'idx_user_rcm_rcm_id',
    'idx_user_rcm_granted_by',
    'idx_evaluation_header_rcm_id',
    'idx_evaluation_line_header_id',
    'idx_evaluation_sample_line_id',
    'idx_evaluation_image_line_id',
    'idx_internal_assessment_rcm_id',
    'idx_internal_assessment_user_id',
    'idx_rcm_standard_mapping_rcm_id',
    'idx_rcm_standard_mapping_std_control_id',
    'idx_rcm_standard_mapping_mapped_by',
    'idx_rcm_completeness_eval_rcm_id',
    'idx_rcm_completeness_eval_eval_by'
);

SELECT '=== 총 20개 인덱스가 제거되었습니다 ===' as status;
