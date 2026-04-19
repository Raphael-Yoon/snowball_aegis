"""
Aegis Monitoring 전용 테이블 생성
- aegis_monitor_config: 모니터링 설정
- aegis_monitor_log: 모니터링 수행 결과 (매칭 결과)
- aegis_population_log: 추출된 모집단 원천 데이터 (시뮬레이션 용)
- aegis_csr_approval: CSR 시스템 승인 데이터 (시뮬레이션 용)
"""

def upgrade(conn):
    """Aegis Monitoring 테이블 생성"""

    # 1. 모니터링 설정 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_monitor_config (
            config_id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL, -- UserAccess, ProgramChange, BatchJob, Interface
            system_name TEXT,
            frequency TEXT DEFAULT 'Daily',
            is_active TEXT DEFAULT 'Y',
            last_run_date TIMESTAMP,
            creation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # 2. 모니터링 수행 로그 (매칭 결과 요약)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_monitor_log (
            log_id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            total_count INTEGER DEFAULT 0,
            match_count INTEGER DEFAULT 0,
            unmapped_count INTEGER DEFAULT 0,
            status TEXT, -- PASS, WARNING, FAIL
            log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            detail_report_path TEXT
        )
    ''')

    # 3. 추출된 모집단 원천 데이터 (시뮬레이션)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_population_log (
            pop_id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT NOT NULL,
            source_id TEXT, -- e.g. Commit Hash, User ID, Job Name
            source_description TEXT,
            occurence_date TIMESTAMP,
            extracted_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            raw_data TEXT -- JSON formatted raw log
        )
    ''')

    # 4. CSR 시스템 승인 데이터 (시뮬레이션)
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_csr_approval (
            csr_id INTEGER PRIMARY KEY AUTOINCREMENT,
            sr_no TEXT UNIQUE NOT NULL, -- SR 번호
            title TEXT,
            requester TEXT,
            approver TEXT,
            approval_date TIMESTAMP,
            system_category TEXT,
            status TEXT DEFAULT 'COMPLETED'
        )
    ''')

    # 초기 마스터 데이터 삽입 (설정)
    categories = ['UserAccess', 'ProgramChange', 'BatchJob', 'Interface']
    for cat in categories:
        conn.execute('''
            INSERT INTO aegis_monitor_config (category, system_name)
            VALUES (?, ?)
        ''', (cat, 'Core System A'))

    print("  Aegis Monitoring 테이블 생성 및 초기 데이터 설정 완료")

def downgrade(conn):
    """Aegis Monitoring 테이블 제거"""
    tables = [
        'aegis_csr_approval',
        'aegis_population_log',
        'aegis_monitor_log',
        'aegis_monitor_config'
    ]
    for table in tables:
        conn.execute(f'DROP TABLE IF EXISTS {table}')
    print("  Aegis Monitoring 테이블 제거 완료")
