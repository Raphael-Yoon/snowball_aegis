"""
답변 테이블에 deleted_at 컬럼 추가 (소프트 삭제 지원)
"""

def upgrade(conn):
    """sb_disclosure_answers 테이블에 deleted_at 컬럼 추가"""
    print("  sb_disclosure_answers 테이블 구조 변경 중...")
    try:
        conn.execute('ALTER TABLE sb_disclosure_answers ADD COLUMN deleted_at TIMESTAMP')
        print("    - deleted_at 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - deleted_at 컬럼이 이미 존재합니다.")
        else:
            raise e

def downgrade(conn):
    """SQLite는 컬럼 삭제를 직접 지원하지 않으므로 생략"""
    pass
