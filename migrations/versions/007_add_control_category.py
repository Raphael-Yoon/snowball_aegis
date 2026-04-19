"""
마이그레이션: RCM Detail 테이블에 통제 카테고리 필드 추가

작성일: 2025-10-28
설명: ITGC, ELC, TLC를 구분하기 위한 control_category 컬럼 추가
"""

def upgrade(conn):
    """sb_rcm_detail 테이블에 control_category 컬럼 추가"""
    print("  sb_rcm_detail 테이블에 control_category 필드 추가 중...")

    # control_category 컬럼 추가 (ITGC, ELC, TLC 구분)
    try:
        conn.execute('''
            ALTER TABLE sb_rcm_detail
            ADD COLUMN control_category TEXT DEFAULT 'ITGC'
        ''')
        print("    - control_category 컬럼 추가 완료 (기본값: ITGC)")
    except Exception as e:
        if "duplicate column name" in str(e).lower():
            print("    - control_category 컬럼이 이미 존재합니다")
        else:
            raise

    # 기존 데이터를 control_code 기반으로 자동 분류
    print("  기존 통제 데이터를 자동 분류 중...")

    # ITGC 패턴: ITGC, AC, PC, CM, SD 등으로 시작
    conn.execute('''
        UPDATE sb_rcm_detail
        SET control_category = 'ITGC'
        WHERE control_code LIKE 'ITGC%'
           OR control_code LIKE 'AC%'
           OR control_code LIKE 'PC%'
           OR control_code LIKE 'CM%'
           OR control_code LIKE 'SD%'
           OR control_code LIKE 'APD%'
    ''')

    # ELC 패턴: ELC로 시작하거나 Entity, COSO, 전사 등의 키워드 포함
    conn.execute('''
        UPDATE sb_rcm_detail
        SET control_category = 'ELC'
        WHERE control_code LIKE 'ELC%'
           OR control_code LIKE 'ENTITY%'
           OR control_code LIKE 'COSO%'
           OR UPPER(control_name) LIKE '%전사%'
           OR UPPER(control_name) LIKE '%ENTITY LEVEL%'
    ''')

    # TLC 패턴: TLC로 시작하거나 Transaction, 거래 등의 키워드 포함
    conn.execute('''
        UPDATE sb_rcm_detail
        SET control_category = 'TLC'
        WHERE control_code LIKE 'TLC%'
           OR control_code LIKE 'TRANS%'
           OR UPPER(control_name) LIKE '%거래%'
           OR UPPER(control_name) LIKE '%TRANSACTION%'
    ''')

    print("    - 기존 데이터 분류 완료")

    conn.commit()
    print("  마이그레이션 007 완료")


def downgrade(conn):
    """control_category 컬럼 제거"""
    print("  sb_rcm_detail 테이블에서 control_category 필드 제거 중...")

    # SQLite는 ALTER TABLE DROP COLUMN을 제한적으로 지원하므로
    # 테이블을 재생성해야 합니다

    # 1. 기존 컬럼 목록 조회
    cursor = conn.execute('PRAGMA table_info(sb_rcm_detail)')
    columns = [row[1] for row in cursor.fetchall() if row[1] != 'control_category']
    columns_str = ', '.join(columns)

    # 2. 기존 데이터 백업
    conn.execute(f'''
        CREATE TABLE sb_rcm_detail_backup AS
        SELECT {columns_str}
        FROM sb_rcm_detail
    ''')

    # 3. 기존 테이블 삭제
    conn.execute('DROP TABLE sb_rcm_detail')

    # 4. 새 테이블 생성 (control_category 필드 제외)
    conn.execute('''
        CREATE TABLE sb_rcm_detail (
            detail_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_id INTEGER NOT NULL,
            control_code TEXT NOT NULL,
            control_name TEXT NOT NULL,
            control_description TEXT,
            key_control TEXT,
            control_frequency TEXT,
            control_type TEXT,
            control_nature TEXT,
            population TEXT,
            population_completeness_check TEXT,
            population_count TEXT,
            test_procedure TEXT,
            mapped_std_control_id INTEGER,
            mapped_date TIMESTAMP,
            mapped_by INTEGER,
            ai_review_status TEXT DEFAULT 'not_reviewed',
            ai_review_recommendation TEXT,
            ai_reviewed_date TIMESTAMP,
            ai_reviewed_by INTEGER,
            mapping_status TEXT,
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (mapped_std_control_id) REFERENCES sb_standard_control (std_control_id),
            FOREIGN KEY (mapped_by) REFERENCES sb_user (user_id),
            FOREIGN KEY (ai_reviewed_by) REFERENCES sb_user (user_id),
            UNIQUE(rcm_id, control_code)
        )
    ''')

    # 5. 데이터 복원
    conn.execute(f'''
        INSERT INTO sb_rcm_detail ({columns_str})
        SELECT {columns_str} FROM sb_rcm_detail_backup
    ''')

    # 6. 백업 테이블 삭제
    conn.execute('DROP TABLE sb_rcm_detail_backup')

    conn.commit()
    print("  마이그레이션 007 롤백 완료")
