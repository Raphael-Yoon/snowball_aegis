"""
마이그레이션: 운영평가 Line 테이블에 당기 발생사실 없음 필드 추가

작성일: 2025-10-14
"""

def upgrade(conn):
    """운영평가 Line 테이블에 no_occurrence 관련 컬럼 추가"""
    print("  sb_operation_evaluation_line 테이블에 no_occurrence 필드 추가 중...")

    # no_occurrence 컬럼 추가 (당기 발생사실 없음 여부)
    try:
        conn.execute('''
            ALTER TABLE sb_operation_evaluation_line
            ADD COLUMN no_occurrence INTEGER DEFAULT 0
        ''')
        print("    - no_occurrence 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - no_occurrence 컬럼이 이미 존재합니다")
        else:
            raise

    # no_occurrence_reason 컬럼 추가 (발생하지 않은 사유)
    try:
        conn.execute('''
            ALTER TABLE sb_operation_evaluation_line
            ADD COLUMN no_occurrence_reason TEXT
        ''')
        print("    - no_occurrence_reason 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - no_occurrence_reason 컬럼이 이미 존재합니다")
        else:
            raise

    conn.commit()
    print("  마이그레이션 006 완료")


def downgrade(conn):
    """no_occurrence 관련 컬럼 제거"""
    print("  sb_operation_evaluation_line 테이블에서 no_occurrence 필드 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
    # 테이블을 재생성해야 합니다

    # 1. 기존 데이터 백업
    conn.execute('''
        CREATE TABLE sb_operation_evaluation_line_backup AS
        SELECT
            line_id, header_id, control_code, control_sequence,
            operating_effectiveness, sample_size, exception_count,
            exception_details, conclusion, improvement_plan,
            evaluation_date, last_updated
        FROM sb_operation_evaluation_line
    ''')

    # 2. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_operation_evaluation_line')

    # 3. 새 테이블 생성 (no_occurrence 필드 제외)
    conn.execute('''
        CREATE TABLE sb_operation_evaluation_line (
            line_id INTEGER PRIMARY KEY AUTOINCREMENT,
            header_id INTEGER NOT NULL,
            control_code TEXT NOT NULL,
            control_sequence INTEGER DEFAULT 0,
            operating_effectiveness TEXT,
            sample_size INTEGER,
            exception_count INTEGER,
            exception_details TEXT,
            conclusion TEXT,
            improvement_plan TEXT,
            evaluation_date TIMESTAMP DEFAULT NULL,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (header_id) REFERENCES sb_operation_evaluation_header (header_id) ON DELETE CASCADE,
            UNIQUE(header_id, control_code)
        )
    ''')

    # 4. 데이터 복원
    conn.execute('''
        INSERT INTO sb_operation_evaluation_line
        SELECT * FROM sb_operation_evaluation_line_backup
    ''')

    # 5. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_operation_evaluation_line_backup')

    conn.commit()
    print("  마이그레이션 006 롤백 완료")
