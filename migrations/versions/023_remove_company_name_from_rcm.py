"""
Migration 023: sb_rcm 테이블에서 company_name 컬럼 제거

작성일: 2025-11-28
설명: company_name은 sb_user와 JOIN으로 가져올 수 있으므로 불필요한 컬럼 제거
      RCM 수정 시 upload_user_id를 변경하는 방식으로 전환
"""

def upgrade(conn):
    """sb_rcm 테이블에서 company_name 컬럼 제거"""
    print("  sb_rcm 테이블에서 company_name 필드 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 제한적으로 지원하므로
    # 테이블을 재생성해야 함

    # 1. 기존 데이터 확인
    cursor = conn.execute('SELECT COUNT(*) FROM sb_rcm')
    count = cursor.fetchone()[0]
    print(f"    - 기존 RCM 레코드 수: {count}")

    # 2. 백업 테이블 생성 (company_name 제외)
    conn.execute('''
        CREATE TABLE sb_rcm_new AS
        SELECT rcm_id, rcm_name, description, upload_date, upload_user_id,
               is_active, completion_date, original_filename, control_category
        FROM sb_rcm
    ''')
    print("    - 백업 테이블 생성 완료")

    # 3. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_rcm')
    print("    - 기존 테이블 삭제 완료")

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
    print("    - 새 테이블 생성 완료")

    # 5. 백업 데이터 복원
    conn.execute('''
        INSERT INTO sb_rcm (rcm_id, rcm_name, description, upload_date, upload_user_id,
                           is_active, completion_date, original_filename, control_category)
        SELECT rcm_id, rcm_name, description, upload_date, upload_user_id,
               is_active, completion_date, original_filename, control_category
        FROM sb_rcm_new
    ''')
    print("    - 데이터 복원 완료")

    # 6. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_rcm_new')
    print("    - 백업 테이블 삭제 완료")

    # 7. 데이터 확인
    cursor = conn.execute('SELECT COUNT(*) FROM sb_rcm')
    new_count = cursor.fetchone()[0]
    print(f"    - 복원된 RCM 레코드 수: {new_count}")

    if count != new_count:
        raise Exception(f"데이터 불일치! 기존: {count}, 복원: {new_count}")

    conn.commit()
    print("  [OK] sb_rcm 테이블 company_name 제거 완료")


def downgrade(conn):
    """company_name 컬럼 다시 추가"""
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
