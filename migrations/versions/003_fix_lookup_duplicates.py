"""
중복된 sb_lookup 데이터 제거

lookup_type + lookup_code 조합이 중복되는 경우 하나만 남기고 삭제
"""

def upgrade(conn):
    """중복된 lookup 데이터 제거"""
    print("중복된 sb_lookup 데이터 제거 중...")

    # 중복 제거: lookup_type, lookup_code 조합별로 가장 오래된 것만 남기고 삭제
    conn.execute('''
        DELETE FROM sb_lookup
        WHERE rowid NOT IN (
            SELECT MIN(rowid)
            FROM sb_lookup
            GROUP BY lookup_type, UPPER(lookup_code)
        )
    ''')

    deleted_count = conn.total_changes
    print(f"  {deleted_count}개의 중복 데이터 제거 완료")

    # 중복 방지를 위한 UNIQUE 제약조건 추가
    # SQLite에서는 기존 테이블에 제약조건을 추가할 수 없으므로 새 테이블 생성 후 데이터 이동
    print("  UNIQUE 제약조건 추가 중...")

    # 백업 테이블 생성
    conn.execute('''
        CREATE TABLE sb_lookup_new (
            lookup_code TEXT NOT NULL,
            lookup_name TEXT NOT NULL,
            description TEXT,
            lookup_type TEXT NOT NULL,
            UNIQUE(lookup_type, lookup_code COLLATE NOCASE)
        )
    ''')

    # 데이터 복사
    conn.execute('''
        INSERT INTO sb_lookup_new (lookup_code, lookup_name, description, lookup_type)
        SELECT lookup_code, lookup_name, description, lookup_type
        FROM sb_lookup
    ''')

    # 기존 뷰 삭제 (뷰가 테이블을 참조하고 있으므로)
    conn.execute('DROP VIEW IF EXISTS sb_rcm_detail_v')

    # 기존 테이블 삭제 및 새 테이블로 교체
    conn.execute('DROP TABLE sb_lookup')
    conn.execute('ALTER TABLE sb_lookup_new RENAME TO sb_lookup')

    # 뷰 재생성
    conn.execute('''
        CREATE VIEW sb_rcm_detail_v AS
        SELECT
            d.detail_id,
            d.rcm_id,
            d.control_code,
            d.control_name,
            d.control_description,
            lk.lookup_name AS key_control,
            lf.lookup_name AS control_frequency,
            lt.lookup_name AS control_type,
            ln.lookup_name AS control_nature,
            d.population,
            d.population_completeness_check,
            d.population_count,
            d.test_procedure,
            d.mapped_std_control_id,
            d.mapped_date,
            d.mapped_by,
            d.ai_review_status,
            d.ai_review_recommendation,
            d.ai_reviewed_date,
            d.ai_reviewed_by,
            d.mapping_status
        FROM sb_rcm_detail d
        LEFT JOIN sb_lookup lk ON lk.lookup_type = 'key_control'
            AND UPPER(lk.lookup_code) = UPPER(d.key_control)
        LEFT JOIN sb_lookup lf ON lf.lookup_type = 'control_frequency'
            AND UPPER(lf.lookup_code) = UPPER(d.control_frequency)
        LEFT JOIN sb_lookup lt ON lt.lookup_type = 'control_type'
            AND UPPER(lt.lookup_code) = UPPER(d.control_type)
        LEFT JOIN sb_lookup ln ON ln.lookup_type = 'control_nature'
            AND UPPER(ln.lookup_code) = UPPER(d.control_nature)
    ''')

    print("  UNIQUE 제약조건 추가 완료")
    print("  뷰 재생성 완료")


def downgrade(conn):
    """롤백 - UNIQUE 제약조건 제거"""
    print("UNIQUE 제약조건 제거 중...")

    # 뷰 삭제
    conn.execute('DROP VIEW IF EXISTS sb_rcm_detail_v')

    # 제약조건 없는 테이블로 재생성
    conn.execute('''
        CREATE TABLE sb_lookup_old (
            lookup_code TEXT NOT NULL,
            lookup_name TEXT NOT NULL,
            description TEXT,
            lookup_type TEXT NOT NULL
        )
    ''')

    # 데이터 복사
    conn.execute('''
        INSERT INTO sb_lookup_old (lookup_code, lookup_name, description, lookup_type)
        SELECT lookup_code, lookup_name, description, lookup_type
        FROM sb_lookup
    ''')

    # 테이블 교체
    conn.execute('DROP TABLE sb_lookup')
    conn.execute('ALTER TABLE sb_lookup_old RENAME TO sb_lookup')

    # 뷰 재생성
    conn.execute('''
        CREATE VIEW sb_rcm_detail_v AS
        SELECT
            d.detail_id,
            d.rcm_id,
            d.control_code,
            d.control_name,
            d.control_description,
            lk.lookup_name AS key_control,
            lf.lookup_name AS control_frequency,
            lt.lookup_name AS control_type,
            ln.lookup_name AS control_nature,
            d.population,
            d.population_completeness_check,
            d.population_count,
            d.test_procedure,
            d.mapped_std_control_id,
            d.mapped_date,
            d.mapped_by,
            d.ai_review_status,
            d.ai_review_recommendation,
            d.ai_reviewed_date,
            d.ai_reviewed_by,
            d.mapping_status
        FROM sb_rcm_detail d
        LEFT JOIN sb_lookup lk ON lk.lookup_type = 'key_control'
            AND UPPER(lk.lookup_code) = UPPER(d.key_control)
        LEFT JOIN sb_lookup lf ON lf.lookup_type = 'control_frequency'
            AND UPPER(lf.lookup_code) = UPPER(d.control_frequency)
        LEFT JOIN sb_lookup lt ON lt.lookup_type = 'control_type'
            AND UPPER(lt.lookup_code) = UPPER(d.control_type)
        LEFT JOIN sb_lookup ln ON ln.lookup_type = 'control_nature'
            AND UPPER(ln.lookup_code) = UPPER(d.control_nature)
    ''')

    print("  제약조건 제거 완료")
    print("  뷰 재생성 완료")
