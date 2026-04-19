"""
초기 데이터베이스 스키마 생성
- 사용자 테이블
- RCM 관련 테이블
- 평가 관련 테이블
- 기준통제 테이블
"""


def upgrade(conn):
    """초기 스키마 생성"""

    # 사용자 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_user (
            user_id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_name TEXT,
            user_name TEXT NOT NULL,
            user_email TEXT UNIQUE NOT NULL,
            phone_number TEXT,
            admin_flag TEXT DEFAULT 'N',
            effective_start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            effective_end_date TIMESTAMP DEFAULT NULL,
            creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_login_date TIMESTAMP,
            otp_code TEXT,
            otp_expires_at TIMESTAMP,
            otp_attempts INTEGER DEFAULT 0,
            otp_method TEXT DEFAULT 'email',
            ai_review_count INTEGER DEFAULT 0,
            ai_review_limit INTEGER DEFAULT 3
        )
    ''')

    # 사용자 활동 로그 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_user_activity_log (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            user_email TEXT,
            user_name TEXT,
            action_type TEXT NOT NULL,
            page_name TEXT,
            url_path TEXT,
            ip_address TEXT,
            user_agent TEXT,
            access_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            additional_info TEXT,
            FOREIGN KEY (user_id) REFERENCES sb_user (user_id)
        )
    ''')

    # RCM 마스터 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_rcm (
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

    # RCM 상세 데이터 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_rcm_detail (
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

    # 사용자-RCM 매핑 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_user_rcm (
            mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            rcm_id INTEGER NOT NULL,
            permission_type TEXT DEFAULT 'READ',
            granted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            granted_by INTEGER,
            is_active TEXT DEFAULT 'Y',
            FOREIGN KEY (user_id) REFERENCES sb_user (user_id),
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (granted_by) REFERENCES sb_user (user_id),
            UNIQUE(user_id, rcm_id)
        )
    ''')

    # 설계평가 헤더 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_design_evaluation_header (
            header_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            evaluation_session TEXT NOT NULL,
            evaluation_status TEXT DEFAULT 'IN_PROGRESS',
            total_controls INTEGER DEFAULT 0,
            evaluated_controls INTEGER DEFAULT 0,
            progress_percentage REAL DEFAULT 0.0,
            start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completed_date TIMESTAMP DEFAULT NULL,
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (user_id) REFERENCES sb_user (user_id),
            UNIQUE(rcm_id, user_id, evaluation_session)
        )
    ''')

    # 설계평가 라인 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_design_evaluation_line (
            line_id INTEGER PRIMARY KEY AUTOINCREMENT,
            header_id INTEGER NOT NULL,
            control_code TEXT NOT NULL,
            control_sequence INTEGER DEFAULT 1,
            description_adequacy TEXT,
            improvement_suggestion TEXT,
            overall_effectiveness TEXT,
            evaluation_rationale TEXT,
            recommended_actions TEXT,
            evaluation_date TIMESTAMP DEFAULT NULL,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (header_id) REFERENCES sb_design_evaluation_header (header_id) ON DELETE CASCADE,
            UNIQUE(header_id, control_code)
        )
    ''')

    # 운영평가 Header 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_operation_evaluation_header (
            header_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            evaluation_session TEXT NOT NULL,
            design_evaluation_session TEXT NOT NULL,
            start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completed_date TIMESTAMP DEFAULT NULL,
            evaluation_status TEXT DEFAULT 'IN_PROGRESS',
            evaluated_controls INTEGER DEFAULT 0,
            total_controls INTEGER DEFAULT 0,
            progress_percentage REAL DEFAULT 0.0,
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (user_id) REFERENCES sb_user (user_id),
            UNIQUE(rcm_id, user_id, evaluation_session, design_evaluation_session)
        )
    ''')

    # 운영평가 Line 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_operation_evaluation_line (
            line_id INTEGER PRIMARY KEY AUTOINCREMENT,
            header_id INTEGER NOT NULL,
            control_code TEXT NOT NULL,
            control_sequence INTEGER DEFAULT 0,
            operating_effectiveness TEXT,
            sample_size INTEGER,
            exception_count INTEGER,
            exception_details TEXT,
            conclusion TEXT,
            improvement_plan TEXT,
            evaluation_date TIMESTAMP DEFAULT NULL,
            last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (header_id) REFERENCES sb_operation_evaluation_header (header_id) ON DELETE CASCADE,
            UNIQUE(header_id, control_code)
        )
    ''')

    # 평가 표본 테이블 (설계평가 및 운영평가 공통 사용)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_evaluation_sample (
            sample_id INTEGER PRIMARY KEY AUTOINCREMENT,
            line_id INTEGER,
            sample_number INTEGER,
            evidence TEXT,
            has_exception INTEGER,
            mitigation TEXT,
            request_number TEXT,
            requester_name TEXT,
            requester_department TEXT,
            approver_name TEXT,
            approver_department TEXT,
            approval_date TEXT,
            evaluation_type TEXT DEFAULT 'operation',
            FOREIGN KEY (line_id) REFERENCES sb_operation_evaluation_line (line_id)
        )
    ''')

    # 내부평가 진행상황 저장 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_internal_assessment (
            assessment_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            evaluation_session TEXT DEFAULT 'DEFAULT',
            step INTEGER NOT NULL,
            progress_data TEXT,
            status TEXT DEFAULT 'pending',
            created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (user_id) REFERENCES sb_user (user_id),
            UNIQUE(rcm_id, user_id, evaluation_session, step)
        )
    ''')

    # 기준통제 마스터 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_standard_control (
            std_control_id INTEGER PRIMARY KEY AUTOINCREMENT,
            control_category TEXT NOT NULL,
            control_code TEXT NOT NULL,
            control_name TEXT NOT NULL,
            control_description TEXT,
            ai_review_prompt TEXT,
            creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(control_category, control_code)
        )
    ''')

    # RCM과 기준통제 매핑 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_rcm_standard_mapping (
            mapping_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_id INTEGER NOT NULL,
            control_code TEXT NOT NULL,
            std_control_id INTEGER NOT NULL,
            mapping_confidence REAL DEFAULT 0.0,
            mapping_type TEXT DEFAULT 'auto',
            mapped_by INTEGER,
            mapping_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            is_active TEXT DEFAULT 'Y',
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (std_control_id) REFERENCES sb_standard_control (std_control_id),
            FOREIGN KEY (mapped_by) REFERENCES sb_user (user_id),
            UNIQUE(rcm_id, control_code, std_control_id)
        )
    ''')

    # RCM 완성도 평가 결과 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_rcm_completeness_eval (
            eval_id INTEGER PRIMARY KEY AUTOINCREMENT,
            rcm_id INTEGER NOT NULL,
            eval_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            completeness_score REAL DEFAULT 0.0,
            total_controls INTEGER DEFAULT 0,
            mapped_controls INTEGER DEFAULT 0,
            eval_details TEXT,
            eval_by INTEGER,
            FOREIGN KEY (rcm_id) REFERENCES sb_rcm (rcm_id),
            FOREIGN KEY (eval_by) REFERENCES sb_user (user_id)
        )
    ''')

    # Lookup 테이블 생성
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_lookup (
            lookup_code TEXT NOT NULL,
            lookup_name TEXT NOT NULL,
            description TEXT,
            lookup_type TEXT NOT NULL,
            PRIMARY KEY (lookup_code, lookup_type)
        )
    ''')

    print("  초기 스키마 생성 완료")


def downgrade(conn):
    """초기 스키마 제거"""
    tables = [
        'sb_rcm_completeness_eval',
        'sb_rcm_standard_mapping',
        'sb_standard_control',
        'sb_internal_assessment',
        'sb_evaluation_sample',
        'sb_operation_evaluation_line',
        'sb_operation_evaluation_header',
        'sb_design_evaluation_line',
        'sb_design_evaluation_header',
        'sb_user_rcm',
        'sb_rcm_detail',
        'sb_rcm',
        'sb_user_activity_log',
        'sb_user',
        'sb_lookup'
    ]

    for table in tables:
        conn.execute(f'DROP TABLE IF EXISTS {table}')

    print("  초기 스키마 제거 완료")
