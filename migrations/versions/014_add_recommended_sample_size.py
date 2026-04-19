"""
마이그레이션 014: sb_rcm_detail 테이블에 recommended_sample_size 컬럼 추가

운영평가 시 각 통제 항목별로 권장 표본수를 미리 설정할 수 있도록 함
"""

def upgrade(conn):
    """recommended_sample_size 컬럼 추가 (MySQL/SQLite 호환)"""
    print("  sb_rcm_detail 테이블에 recommended_sample_size 필드 추가 중...")

    # DB 타입 확인
    db_type = 'sqlite'
    try:
        # MySQL 확인 시도
        conn.execute("SELECT VERSION()")
        db_type = 'mysql'
    except:
        pass

    if db_type == 'mysql':
        # MySQL용 ALTER TABLE
        conn.execute('''
            ALTER TABLE sb_rcm_detail
            ADD COLUMN recommended_sample_size INT DEFAULT NULL
        ''')
    else:
        # SQLite용 ALTER TABLE
        conn.execute('''
            ALTER TABLE sb_rcm_detail
            ADD COLUMN recommended_sample_size INTEGER DEFAULT NULL
        ''')

    conn.commit()
    print(f"  마이그레이션 014 완료 (DB: {db_type})")


def downgrade(conn):
    """recommended_sample_size 컬럼 제거 (MySQL/SQLite 호환)"""
    print("  sb_rcm_detail 테이블에서 recommended_sample_size 필드 제거 중...")

    # DB 타입 확인
    db_type = 'sqlite'
    try:
        # MySQL 확인 시도
        conn.execute("SELECT VERSION()")
        db_type = 'mysql'
    except:
        pass

    if db_type == 'mysql':
        # MySQL은 ALTER TABLE DROP COLUMN 지원
        conn.execute('''
            ALTER TABLE sb_rcm_detail
            DROP COLUMN recommended_sample_size
        ''')
        conn.commit()
        print(f"  마이그레이션 014 다운그레이드 완료 (DB: {db_type})")
    else:
        # SQLite는 ALTER TABLE DROP COLUMN을 제한적으로 지원하므로
        # 테이블을 재생성해야 합니다

        # 1. 기존 컬럼 목록 조회
        cursor = conn.execute('PRAGMA table_info(sb_rcm_detail)')
        columns = [row[1] for row in cursor.fetchall() if row[1] != 'recommended_sample_size']
        columns_str = ', '.join(columns)

        # 2. 기존 데이터 백업
        conn.execute(f'''
            CREATE TABLE sb_rcm_detail_backup AS
            SELECT {columns_str}
            FROM sb_rcm_detail
        ''')

        # 3. 기존 테이블 삭제
        conn.execute('DROP TABLE sb_rcm_detail')

        # 4. 새 테이블 생성 (recommended_sample_size 필드 제외)
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
                control_category TEXT DEFAULT 'ITGC',
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
            SELECT {columns_str}
            FROM sb_rcm_detail_backup
        ''')

        # 6. 백업 테이블 삭제
        conn.execute('DROP TABLE sb_rcm_detail_backup')

        conn.commit()
        print(f"  마이그레이션 014 다운그레이드 완료 (DB: {db_type})")
