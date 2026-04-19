"""
sb_user_rcm 테이블에 last_updated 컬럼 추가
"""


def upgrade(conn):
    """last_updated 컬럼 추가"""

    # sb_user_rcm 테이블에 last_updated 컬럼 추가
    # SQLite는 CURRENT_TIMESTAMP를 기본값으로 직접 추가할 수 없으므로 NULL로 추가
    try:
        conn.execute('''
            ALTER TABLE sb_user_rcm
            ADD COLUMN last_updated TIMESTAMP DEFAULT NULL
        ''')

        # 기존 데이터에 granted_date 값 또는 현재 시간 설정
        conn.execute('''
            UPDATE sb_user_rcm
            SET last_updated = COALESCE(granted_date, CURRENT_TIMESTAMP)
            WHERE last_updated IS NULL
        ''')

        print("[OK] sb_user_rcm 테이블에 last_updated 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("[OK] last_updated 컬럼이 이미 존재합니다 (스킵)")
        else:
            raise


def downgrade(conn):
    """롤백 - SQLite는 ALTER TABLE DROP COLUMN 미지원"""

    print("⚠️  SQLite는 컬럼 삭제를 지원하지 않습니다. 수동으로 처리 필요.")
