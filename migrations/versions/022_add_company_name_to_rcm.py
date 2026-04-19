"""
Migration 022: sb_rcm 테이블에 company_name 컬럼 추가

작성일: 2025-11-28
설명: RCM에 회사명을 저장하기 위한 company_name 컬럼 추가
"""

def upgrade(conn):
    """sb_rcm 테이블에 company_name 컬럼 추가"""
    print("  sb_rcm 테이블에 company_name 필드 추가 중...")

    # company_name 컬럼 추가
    try:
        conn.execute('''
            ALTER TABLE sb_rcm
            ADD COLUMN company_name TEXT DEFAULT NULL
        ''')
        print("    - company_name 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - company_name 컬럼이 이미 존재합니다")
        else:
            raise

    conn.commit()
    print("  [OK] sb_rcm 테이블 company_name 추가 완료")


def downgrade(conn):
    """company_name 컬럼 제거"""
    print("  sb_rcm 테이블에서 company_name 필드 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 제한적으로 지원하므로
    # 테이블을 재생성해야 함

    # 1. 기존 컬럼 목록 조회
    cursor = conn.execute('PRAGMA table_info(sb_rcm)')
    columns = [row[1] for row in cursor.fetchall() if row[1] != 'company_name']
    columns_str = ', '.join(columns)

    # 2. 백업 테이블 생성
    conn.execute(f'''
        CREATE TABLE sb_rcm_backup AS
        SELECT {columns_str}
        FROM sb_rcm
    ''')

    # 3. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_rcm')

    # 4. 새 테이블 생성 (company_name 필드 제외)
    conn.execute('''
        CREATE TABLE sb_rcm (
            rcm_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_name TEXT NOT NULL,
            description TEXT,
            upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            upload_user_id INTEGER NOT NULL,
            is_active TEXT DEFAULT 'Y',
            completion_date TIMESTAMP DEFAULT NULL,
            original_filename TEXT,
            control_category TEXT DEFAULT NULL,
            FOREIGN KEY (upload_user_id) REFERENCES sb_user (user_id)
        )
    ''')

    # 5. 백업 데이터 복원
    conn.execute(f'''
        INSERT INTO sb_rcm ({columns_str})
        SELECT {columns_str}
        FROM sb_rcm_backup
    ''')

    # 6. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_rcm_backup')

    conn.commit()
    print("  [OK] sb_rcm 테이블 company_name 제거 완료")
