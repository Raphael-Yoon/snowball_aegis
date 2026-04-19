"""
sb_rcm_detail_v 뷰 생성
- sb_lookup 테이블과 조인하여 코드값을 실제 이름으로 변환
"""


def upgrade(conn):
    """sb_rcm_detail_v 뷰 생성"""

    # 기존 뷰 삭제
    conn.execute('DROP VIEW IF EXISTS sb_rcm_detail_v')
    conn.execute('DROP VIEW IF EXISTS v_rcm_detail_with_lookup')

    # sb_lookup 테이블이 있는지 확인
    cursor = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='sb_lookup'"
    )
    table_exists = cursor.fetchone()

    if table_exists:
        # sb_lookup 테이블과 조인하는 뷰 생성 (값이 있으면 그대로 사용)
        conn.execute('''
            CREATE VIEW sb_rcm_detail_v AS
            SELECT
                d.detail_id,
                d.rcm_id,
                d.control_code,
                d.control_name,
                d.control_description,
                COALESCE(lk.lookup_name, d.key_control) AS key_control,
                COALESCE(lf.lookup_name, d.control_frequency) AS control_frequency,
                COALESCE(lt.lookup_name, d.control_type) AS control_type,
                COALESCE(ln.lookup_name, d.control_nature) AS control_nature,
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
        print("  sb_rcm_detail_v 뷰 생성 완료 (sb_lookup 조인)")
    else:
        # sb_lookup 테이블이 없으면 CASE 문만 사용하는 뷰 생성
        conn.execute('''
            CREATE VIEW sb_rcm_detail_v AS
            SELECT
                detail_id,
                rcm_id,
                control_code,
                control_name,
                control_description,
                CASE
                    WHEN UPPER(COALESCE(key_control, '')) IN ('Y', 'YES', '핵심', 'KEY', 'KEY CONTROL', '중요') THEN '핵심'
                    ELSE '비핵심'
                END AS key_control,
                control_frequency,
                control_type,
                control_nature,
                population,
                population_completeness_check,
                population_count,
                test_procedure,
                mapped_std_control_id,
                mapped_date,
                mapped_by,
                ai_review_status,
                ai_review_recommendation,
                ai_reviewed_date,
                ai_reviewed_by,
                mapping_status
            FROM sb_rcm_detail
        ''')
        print("  sb_rcm_detail_v 뷰 생성 완료 (CASE 문 사용)")


def downgrade(conn):
    """sb_rcm_detail_v 뷰 제거"""
    conn.execute('DROP VIEW IF EXISTS sb_rcm_detail_v')
    conn.execute('DROP VIEW IF EXISTS v_rcm_detail_with_lookup')
    print("  sb_rcm_detail_v 뷰 제거 완료")
