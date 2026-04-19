"""
Migration 028: sb_design_evaluation_line 테이블에 no_occurrence 관련 컬럼 추가

작성일: 2025-11-28
설명: 설계평가에서도 '당기 발생사실 없음' 체크박스 기능 지원
      - no_occurrence: 당기 발생사실 없음 여부 (0/1)
      - no_occurrence_reason: 발생사실 없음 사유
"""

def upgrade(conn):
    """sb_design_evaluation_line 테이블에 no_occurrence 관련 컬럼 추가"""
    print("  sb_design_evaluation_line 테이블에 no_occurrence 컬럼 추가 중...")

    # no_occurrence 컬럼 추가
    try:
        conn.execute('''
            ALTER TABLE sb_design_evaluation_line
            ADD COLUMN no_occurrence INTEGER DEFAULT 0
        ''')
        print("    - no_occurrence 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - no_occurrence 컬럼 이미 존재 (스킵)")
        else:
            raise

    # no_occurrence_reason 컬럼 추가
    try:
        conn.execute('''
            ALTER TABLE sb_design_evaluation_line
            ADD COLUMN no_occurrence_reason TEXT
        ''')
        print("    - no_occurrence_reason 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - no_occurrence_reason 컬럼 이미 존재 (스킵)")
        else:
            raise

    conn.commit()
    print("  [OK] sb_design_evaluation_line 테이블 no_occurrence 컬럼 추가 완료")
    print("      이제 설계평가에서도 '당기 발생사실 없음' 체크박스를 사용할 수 있습니다.")


def downgrade(conn):
    """sb_design_evaluation_line 테이블에서 no_occurrence 관련 컬럼 제거"""
    print("  sb_design_evaluation_line 테이블에서 no_occurrence 컬럼 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
    # 테이블을 재생성해야 함

    # 1. 백업 테이블 생성
    conn.execute('''
        CREATE TABLE sb_design_evaluation_line_backup AS
        SELECT line_id, header_id, control_code, control_sequence,
               description_adequacy, improvement_suggestion, overall_effectiveness,
               evaluation_evidence, evaluation_rationale, design_comment,
               recommended_actions, evaluation_date, last_updated
        FROM sb_design_evaluation_line
    ''')

    # 2. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_design_evaluation_line')

    # 3. no_occurrence 컬럼 없이 테이블 재생성
    conn.execute('''
        CREATE TABLE sb_design_evaluation_line (
            line_id INTEGER PRIMARY KEY AUTOINCREMENT,
            header_id INTEGER NOT NULL,
            control_code TEXT NOT NULL,
            control_sequence INTEGER DEFAULT 1,
            description_adequacy TEXT,
            improvement_suggestion TEXT,
            overall_effectiveness TEXT,
            evaluation_evidence TEXT,
            evaluation_rationale TEXT,
            design_comment TEXT,
            recommended_actions TEXT,
            evaluation_date TIMESTAMP DEFAULT NULL,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (header_id) REFERENCES sb_design_evaluation_header (header_id) ON DELETE CASCADE,
            UNIQUE(header_id, control_code)
        )
    ''')

    # 4. 데이터 복원
    conn.execute('''
        INSERT INTO sb_design_evaluation_line
        SELECT * FROM sb_design_evaluation_line_backup
    ''')

    # 5. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_design_evaluation_line_backup')

    conn.commit()
    print("  [OK] sb_design_evaluation_line 테이블 no_occurrence 컬럼 제거 완료")
