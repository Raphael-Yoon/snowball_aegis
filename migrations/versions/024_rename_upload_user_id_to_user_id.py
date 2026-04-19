"""
Migration 024: sb_rcm 테이블의 upload_user_id를 user_id로 변경

작성일: 2025-11-28
설명: 더 명확하고 간결한 컬럼명으로 변경
      upload_user_id -> user_id
"""

def upgrade(conn):
    """sb_rcm 테이블의 upload_user_id를 user_id로 변경"""
    print("  sb_rcm 테이블의 upload_user_id를 user_id로 변경 중...")

    # SQLite는 ALTER TABLE RENAME COLUMN을 지원하지만
    # 외래키 제약조건이 있어서 테이블 재생성 필요

    # 1. 기존 데이터 확인
    cursor = conn.execute('SELECT COUNT(*) FROM sb_rcm')
    count = cursor.fetchone()[0]
    print(f"    - 기존 RCM 레코드 수: {count}")

    # 2. 백업 테이블 생성
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

    # 4. 새 테이블 생성 (user_id로 변경)
    conn.execute('''
        CREATE TABLE sb_rcm (
            rcm_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_name TEXT NOT NULL,
            description TEXT,
            upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            user_id INTEGER NOT NULL,
            is_active TEXT DEFAULT 'Y',
            completion_date TIMESTAMP DEFAULT NULL,
            original_filename TEXT,
            control_category TEXT DEFAULT NULL,
            FOREIGN KEY (user_id) REFERENCES sb_user (user_id)
        )
    ''')
    print("    - 새 테이블 생성 완료 (upload_user_id -> user_id)")

    # 5. 백업 데이터 복원
    conn.execute('''
        INSERT INTO sb_rcm (rcm_id, rcm_name, description, upload_date, user_id,
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
    print("  [OK] sb_rcm 테이블 upload_user_id -> user_id 변경 완료")


def downgrade(conn):
    """user_id를 upload_user_id로 되돌림"""
    print("  sb_rcm 테이블의 user_id를 upload_user_id로 변경 중...")

    # 1. 기존 데이터 확인
    cursor = conn.execute('SELECT COUNT(*) FROM sb_rcm')
    count = cursor.fetchone()[0]
    print(f"    - 기존 RCM 레코드 수: {count}")

    # 2. 백업 테이블 생성
    conn.execute('''
        CREATE TABLE sb_rcm_new AS
        SELECT rcm_id, rcm_name, description, upload_date, user_id,
               is_active, completion_date, original_filename, control_category
        FROM sb_rcm
    ''')
    print("    - 백업 테이블 생성 완료")

    # 3. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_rcm')
    print("    - 기존 테이블 삭제 완료")

    # 4. 새 테이블 생성 (upload_user_id로 변경)
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
    print("    - 새 테이블 생성 완료 (user_id -> upload_user_id)")

    # 5. 백업 데이터 복원
    conn.execute('''
        INSERT INTO sb_rcm (rcm_id, rcm_name, description, upload_date, upload_user_id,
                           is_active, completion_date, original_filename, control_category)
        SELECT rcm_id, rcm_name, description, upload_date, user_id,
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
    print("  [OK] sb_rcm 테이블 user_id -> upload_user_id 변경 완료")
