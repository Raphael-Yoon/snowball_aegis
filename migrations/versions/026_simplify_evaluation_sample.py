"""
Migration 026: sb_evaluation_sample 테이블 간소화

작성일: 2025-11-28
설명: 불필요한 고정 컬럼들을 제거하고 핵심 필드만 유지
      - 제거: request_number, requester_name, requester_department,
              approver_name, approver_department, approval_date
      - 유지: sample_id, line_id, sample_number, evidence, has_exception,
              mitigation, evaluation_type
      - 추가 속성이 필요한 경우 sb_rcm_detail_attributes 테이블 활용
"""

def upgrade(conn):
    """sb_evaluation_sample 테이블 간소화"""
    print("  sb_evaluation_sample 테이블 간소화 중...")

    # 1. 기존 데이터 백업
    conn.execute('''
        CREATE TABLE sb_evaluation_sample_backup AS
        SELECT * FROM sb_evaluation_sample
    ''')
    print("    - 기존 데이터 백업 완료")

    # 2. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_evaluation_sample')

    # 3. 간소화된 테이블 생성
    conn.execute('''
        CREATE TABLE sb_evaluation_sample (
            sample_id INTEGER PRIMARY KEY AUTOINCREMENT,
            line_id INTEGER,
            sample_number INTEGER,
            evidence TEXT,
            has_exception INTEGER DEFAULT 0,
            mitigation TEXT,
            evaluation_type TEXT DEFAULT 'operation',
            FOREIGN KEY (line_id) REFERENCES sb_operation_evaluation_line (line_id) ON DELETE CASCADE
        )
    ''')
    print("    - 간소화된 테이블 생성 완료")

    # 4. 핵심 데이터 복원
    conn.execute('''
        INSERT INTO sb_evaluation_sample
            (sample_id, line_id, sample_number, evidence, has_exception, mitigation, evaluation_type)
        SELECT
            sample_id, line_id, sample_number, evidence,
            COALESCE(has_exception, 0), mitigation,
            COALESCE(evaluation_type, 'operation')
        FROM sb_evaluation_sample_backup
    ''')
    print("    - 데이터 복원 완료")

    # 5. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_evaluation_sample_backup')
    print("    - 백업 테이블 삭제 완료")

    conn.commit()
    print("  [OK] sb_evaluation_sample 테이블 간소화 완료")
    print("      제거된 컬럼: request_number, requester_name, requester_department,")
    print("                   approver_name, approver_department, approval_date")
    print("      → 이제 sb_rcm_detail_attributes 테이블을 통해 유연하게 속성 관리 가능")


def downgrade(conn):
    """변경 사항 되돌리기"""
    print("  sb_evaluation_sample 테이블 복원 중...")

    # 기존 데이터 백업
    conn.execute('''
        CREATE TABLE sb_evaluation_sample_new AS
        SELECT * FROM sb_evaluation_sample
    ''')

    # 기존 테이블 삭제
    conn.execute('DROP TABLE sb_evaluation_sample')

    # 원래 구조로 복원
    conn.execute('''
        CREATE TABLE sb_evaluation_sample (
            sample_id INTEGER PRIMARY KEY AUTOINCREMENT,
            line_id INTEGER,
            sample_number INTEGER,
            evidence TEXT,
            has_exception INTEGER,
            mitigation TEXT,
            request_number TEXT,
            requester_name TEXT,
            requester_department TEXT,
            approver_name TEXT,
            approver_department TEXT,
            approval_date TEXT,
            evaluation_type TEXT DEFAULT 'operation',
            FOREIGN KEY (line_id) REFERENCES sb_operation_evaluation_line (line_id)
        )
    ''')

    # 데이터 복원
    conn.execute('''
        INSERT INTO sb_evaluation_sample
            (sample_id, line_id, sample_number, evidence, has_exception, mitigation, evaluation_type)
        SELECT
            sample_id, line_id, sample_number, evidence, has_exception, mitigation, evaluation_type
        FROM sb_evaluation_sample_new
    ''')

    conn.execute('DROP TABLE sb_evaluation_sample_new')

    conn.commit()
    print("  [OK] sb_evaluation_sample 테이블 복원 완료")
