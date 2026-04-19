"""
마이그레이션 028: sb_operation_evaluation_line 테이블에 review_comment 컬럼 추가
"""

def upgrade(conn):
    """검토 의견 컬럼 추가"""
    print("  sb_operation_evaluation_line 테이블에 review_comment 컬럼 추가 중...")

    try:
        conn.execute('''
            ALTER TABLE sb_operation_evaluation_line
            ADD COLUMN review_comment TEXT
        ''')
        print("    - review_comment 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - review_comment 컬럼이 이미 존재합니다")
        else:
            raise

    conn.commit()
    print("  마이그레이션 028 완료")


def downgrade(conn):
    """review_comment 컬럼 제거"""
    print("  sb_operation_evaluation_line 테이블에서 review_comment 컬럼 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로 생략
    # 필요시 테이블 재생성 로직 추가

    print("  마이그레이션 028 롤백 완료 (SQLite는 컬럼 삭제를 지원하지 않음)")
