"""
Migration 012: sb_rcm 테이블에 control_category 컬럼 추가

작성일: 2025-01-10
설명: RCM 레벨에서 ELC/TLC/ITGC를 구분하기 위한 control_category 컬럼 추가
"""

def upgrade(conn):
    """sb_rcm 테이블에 control_category 컬럼 추가 및 기존 데이터 업데이트"""
    print("  sb_rcm 테이블에 control_category 필드 추가 중...")

    # 1. control_category 컬럼 추가
    try:
        conn.execute('''
            ALTER TABLE sb_rcm
            ADD COLUMN control_category TEXT DEFAULT NULL
        ''')
        print("    - control_category 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - control_category 컬럼이 이미 존재합니다")
        else:
            raise

    # 2. 기존 RCM 데이터에 control_category 설정
    # RCM 이름을 기반으로 카테고리 자동 설정
    print("    - 기존 RCM 데이터에 control_category 설정 중...")

    # ITGC 카테고리 설정
    result = conn.execute('''
        UPDATE sb_rcm
        SET control_category = 'ITGC'
        WHERE control_category IS NULL
          AND (
              rcm_name LIKE '%ITGC%'
              OR rcm_name LIKE '%IT일반통제%'
              OR rcm_name LIKE '%IT 일반통제%'
          )
    ''')
    print(f"      * ITGC: {result.rowcount}개 업데이트")

    # ELC 카테고리 설정
    result = conn.execute('''
        UPDATE sb_rcm
        SET control_category = 'ELC'
        WHERE control_category IS NULL
          AND (
              rcm_name LIKE '%ELC%'
              OR rcm_name LIKE '%전사수준통제%'
              OR rcm_name LIKE '%전사 수준 통제%'
              OR rcm_name LIKE '%Entity Level%'
          )
    ''')
    print(f"      * ELC: {result.rowcount}개 업데이트")

    # TLC 카테고리 설정
    result = conn.execute('''
        UPDATE sb_rcm
        SET control_category = 'TLC'
        WHERE control_category IS NULL
          AND (
              rcm_name LIKE '%TLC%'
              OR rcm_name LIKE '%거래수준통제%'
              OR rcm_name LIKE '%거래 수준 통제%'
              OR rcm_name LIKE '%Transaction Level%'
          )
    ''')
    print(f"      * TLC: {result.rowcount}개 업데이트")

    # 3. sb_rcm_detail의 control_category를 기반으로 나머지 RCM 업데이트
    # (이름으로 판단할 수 없는 경우, detail의 다수결로 결정)
    print("    - detail 기반으로 나머지 RCM 카테고리 설정 중...")

    conn.execute('''
        UPDATE sb_rcm
        SET control_category = (
            SELECT rd.control_category
            FROM sb_rcm_detail rd
            WHERE rd.rcm_id = sb_rcm.rcm_id
            GROUP BY rd.control_category
            ORDER BY COUNT(*) DESC
            LIMIT 1
        )
        WHERE control_category IS NULL
          AND EXISTS (
              SELECT 1 FROM sb_rcm_detail rd2
              WHERE rd2.rcm_id = sb_rcm.rcm_id
          )
    ''')
    print("    - 나머지 RCM 카테고리 설정 완료")

    # 4. 설정된 카테고리 통계 출력
    categories = conn.execute('''
        SELECT
            control_category,
            COUNT(*) as count
        FROM sb_rcm
        WHERE control_category IS NOT NULL
        GROUP BY control_category
    ''').fetchall()

    print("    - 카테고리별 RCM 통계:")
    for cat in categories:
        print(f"      * {cat['control_category']}: {cat['count']}개")

    # 5. 카테고리가 설정되지 않은 RCM 확인
    unset_count = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_rcm
        WHERE control_category IS NULL
    ''').fetchone()['count']

    if unset_count > 0:
        print(f"    ⚠ 주의: 카테고리가 설정되지 않은 RCM {unset_count}개 존재")

    conn.commit()
    print("  [OK] sb_rcm 테이블 control_category 추가 완료")


def downgrade(conn):
    """control_category 컬럼 제거"""
    print("  sb_rcm 테이블에서 control_category 필드 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 제한적으로 지원하므로
    # 테이블을 재생성해야 함

    # 1. 기존 컬럼 목록 조회
    cursor = conn.execute('PRAGMA table_info(sb_rcm)')
    columns = [row[1] for row in cursor.fetchall() if row[1] != 'control_category']
    columns_str = ', '.join(columns)

    # 2. 백업 테이블 생성
    conn.execute(f'''
        CREATE TABLE sb_rcm_backup AS
        SELECT {columns_str}
        FROM sb_rcm
    ''')

    # 3. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_rcm')

    # 4. 새 테이블 생성 (control_category 필드 제외)
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
    print("  [OK] sb_rcm 테이블 control_category 제거 완료")
