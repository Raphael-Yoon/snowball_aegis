"""
Migration 027: sb_evaluation_sample 테이블에 attribute0~9 컬럼 추가

작성일: 2025-11-28
설명: sb_rcm_detail에 정의된 attribute 항목에 따라 표본 데이터를 저장하기 위한 컬럼 추가
      - sb_rcm_detail.attribute0~9: 어떤 데이터를 수집할지 정의 (예: "거래일자", "거래금액" 등)
      - sb_evaluation_sample.attribute0~9: 실제 표본 데이터 저장 (예: "2024-01-15", "1000000" 등)
"""

def upgrade(conn):
    """sb_evaluation_sample 테이블에 attribute0~9 컬럼 추가"""
    print("  sb_evaluation_sample 테이블에 attribute 컬럼 추가 중...")

    # attribute0~9 컬럼 추가
    for i in range(10):
        try:
            conn.execute(f'''
                ALTER TABLE sb_evaluation_sample
                ADD COLUMN attribute{i} TEXT
            ''')
            print(f"    - attribute{i} 컬럼 추가 완료")
        except Exception as e:
            if "duplicate column name" in str(e).lower():
                print(f"    - attribute{i} 컬럼 이미 존재 (스킵)")
            else:
                raise

    conn.commit()
    print("  [OK] sb_evaluation_sample 테이블 attribute 컬럼 추가 완료")
    print("      이제 sb_rcm_detail에 정의된 항목에 따라 표본 데이터를 유연하게 저장할 수 있습니다.")


def downgrade(conn):
    """sb_evaluation_sample 테이블에서 attribute0~9 컬럼 제거"""
    print("  sb_evaluation_sample 테이블에서 attribute 컬럼 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
    # 테이블을 재생성해야 함

    # 1. 백업 테이블 생성
    conn.execute('''
        CREATE TABLE sb_evaluation_sample_backup AS
        SELECT sample_id, line_id, sample_number, evidence, has_exception, mitigation, evaluation_type
        FROM sb_evaluation_sample
    ''')

    # 2. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_evaluation_sample')

    # 3. attribute 컬럼 없이 테이블 재생성
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

    # 4. 데이터 복원
    conn.execute('''
        INSERT INTO sb_evaluation_sample
        SELECT * FROM sb_evaluation_sample_backup
    ''')

    # 5. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_evaluation_sample_backup')

    conn.commit()
    print("  [OK] sb_evaluation_sample 테이블 attribute 컬럼 제거 완료")
