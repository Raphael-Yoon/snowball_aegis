"""
sb_rcm_detail_v 뷰에 recommended_sample_size 컬럼 추가
"""


def upgrade(conn):
    """뷰를 재생성하여 recommended_sample_size 컬럼 추가"""

    try:
        # 기존 뷰 삭제
        conn.execute('DROP VIEW IF EXISTS sb_rcm_detail_v')

        # recommended_sample_size를 포함한 새 뷰 생성
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
                d.mapping_status,
                d.control_category,
                d.recommended_sample_size,
                d.control_frequency AS control_frequency_code,
                d.control_type AS control_type_code,
                d.control_nature AS control_nature_code,
                lf.lookup_name AS control_frequency_name,
                lt.lookup_name AS control_type_name,
                ln.lookup_name AS control_nature_name
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

        conn.commit()
        print("  sb_rcm_detail_v 뷰에 recommended_sample_size 컬럼 추가 완료")

    except Exception as e:
        print(f"  뷰 업데이트 실패: {e}")
        raise


def downgrade(conn):
    """이전 버전의 뷰로 롤백"""

    try:
        # 기존 뷰 삭제
        conn.execute('DROP VIEW IF EXISTS sb_rcm_detail_v')

        # recommended_sample_size 없는 이전 버전 뷰 재생성
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
                d.mapping_status,
                d.control_category
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

        conn.commit()
        print("  sb_rcm_detail_v 뷰를 이전 버전으로 롤백 완료")

    except Exception as e:
        print(f"  뷰 롤백 실패: {e}")
        raise
