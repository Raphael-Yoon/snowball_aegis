"""
설계평가 라인 테이블에 evaluation_evidence 컬럼 추가
- 평가 시 확인한 증빙 자료를 텍스트로 입력
"""


def upgrade(conn):
    """evaluation_evidence 컬럼 추가"""

    # SQLite와 MySQL 모두 지원
    try:
        conn.execute('''
            ALTER TABLE sb_design_evaluation_line
            ADD COLUMN evaluation_evidence TEXT
        ''')
        print("  evaluation_evidence 컬럼 추가 완료")
    except Exception as e:
        if 'duplicate column name' in str(e).lower() or 'Duplicate column name' in str(e):
            print("  evaluation_evidence 컬럼이 이미 존재합니다.")
        else:
            raise


def downgrade(conn):
    """evaluation_evidence 컬럼 제거"""

    # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로 경고만 출력
    print("  경고: SQLite는 컬럼 삭제를 지원하지 않습니다.")
    print("  MySQL의 경우 수동으로 제거하세요:")
    print("  ALTER TABLE sb_design_evaluation_line DROP COLUMN evaluation_evidence;")
