"""
Aegis 핵심 모니터링 테이블 생성
- aegis_system: 모니터링 대상 시스템 등록
- aegis_control: ITGC 기준통제 정의 (APD/PC/PD/CO)
- aegis_control_system: 통제-시스템 매핑
- aegis_result: 일배치 모니터링 결과
"""


def upgrade(conn):
    # 1. 모니터링 대상 시스템
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_system (
            system_id   INTEGER PRIMARY KEY AUTOINCREMENT,
            system_code TEXT UNIQUE NOT NULL,
            system_name TEXT NOT NULL,
            description TEXT,
            db_type     TEXT DEFAULT 'sqlite',
            db_host     TEXT,
            db_port     INTEGER,
            db_name     TEXT,
            db_user     TEXT,
            db_password TEXT,
            db_path     TEXT,
            is_active   TEXT DEFAULT 'Y',
            created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # 2. ITGC 기준통제 정의
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_control (
            control_id   INTEGER PRIMARY KEY AUTOINCREMENT,
            control_code TEXT UNIQUE NOT NULL,
            category     TEXT NOT NULL CHECK(category IN ('APD','PC','PD','CO')),
            control_name TEXT NOT NULL,
            description  TEXT,
            monitor_query TEXT,
            is_active    TEXT DEFAULT 'Y',
            created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # 3. 통제-시스템 매핑
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_control_system (
            mapping_id    INTEGER PRIMARY KEY AUTOINCREMENT,
            control_id    INTEGER NOT NULL REFERENCES aegis_control(control_id),
            system_id     INTEGER NOT NULL REFERENCES aegis_system(system_id),
            custom_query  TEXT,
            threshold_count INTEGER DEFAULT 0,
            is_active     TEXT DEFAULT 'Y',
            created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE(control_id, system_id)
        )
    ''')

    # 4. 일배치 모니터링 결과
    conn.execute('''
        CREATE TABLE IF NOT EXISTS aegis_result (
            result_id       INTEGER PRIMARY KEY AUTOINCREMENT,
            control_id      INTEGER NOT NULL REFERENCES aegis_control(control_id),
            system_id       INTEGER NOT NULL REFERENCES aegis_system(system_id),
            run_date        DATE NOT NULL,
            total_count     INTEGER DEFAULT 0,
            exception_count INTEGER DEFAULT 0,
            status          TEXT DEFAULT 'PENDING' CHECK(status IN ('PASS','FAIL','WARNING','ERROR','PENDING')),
            result_detail   TEXT,
            run_at          TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # 인덱스
    conn.execute('CREATE INDEX IF NOT EXISTS idx_aegis_result_run_date ON aegis_result(run_date)')
    conn.execute('CREATE INDEX IF NOT EXISTS idx_aegis_result_status ON aegis_result(status)')
    conn.execute('CREATE INDEX IF NOT EXISTS idx_aegis_control_category ON aegis_control(category)')

    # 기본 통제 시드 데이터 (APD/PC/PD/CO 각 대표 통제)
    controls = [
        ('APD-01', 'APD', '사용자 계정 생성 및 부여',      '신규 사용자 계정 생성 시 승인 절차 준수 여부 모니터링'),
        ('APD-02', 'APD', '사용자 접근권한 변경',           '접근권한 변경 시 승인 절차 준수 여부 모니터링'),
        ('APD-03', 'APD', '사용자 계정 삭제 및 비활성화',   '퇴직/부서이동 시 계정 즉시 비활성화 여부 모니터링'),
        ('APD-04', 'APD', '주기적 접근권한 검토',           '정기 접근권한 검토 수행 여부 모니터링'),
        ('PC-01',  'PC',  '변경 요청 등록 및 승인',         '프로그램 변경 요청에 대한 정식 승인 여부 모니터링'),
        ('PC-02',  'PC',  '변경 테스트 수행',               '운영 배포 전 테스트 수행 증빙 모니터링'),
        ('PC-03',  'PC',  '운영 배포 승인',                 '변경 배포 시 승인자 서명 여부 모니터링'),
        ('PD-01',  'PD',  '개발 방법론 준수',               '개발 표준 및 방법론 준수 여부 모니터링'),
        ('PD-02',  'PD',  '개발-운영 환경 분리',            '개발/운영 환경 분리 상태 모니터링'),
        ('CO-01',  'CO',  '배치 작업 모니터링',             '정기 배치 작업 성공/실패 여부 모니터링'),
        ('CO-02',  'CO',  '백업 수행 확인',                 '데이터 백업 정상 수행 여부 모니터링'),
        ('CO-03',  'CO',  '장애 및 이슈 처리',              '시스템 장애 발생 시 처리 절차 준수 여부 모니터링'),
    ]
    for code, cat, name, desc in controls:
        conn.execute('''
            INSERT OR IGNORE INTO aegis_control (control_code, category, control_name, description)
            VALUES (?, ?, ?, ?)
        ''', (code, cat, name, desc))

    print("  041: Aegis 핵심 테이블 및 기준통제 시드 데이터 생성 완료")


def downgrade(conn):
    conn.execute('DROP TABLE IF EXISTS aegis_result')
    conn.execute('DROP TABLE IF EXISTS aegis_control_system')
    conn.execute('DROP TABLE IF EXISTS aegis_control')
    conn.execute('DROP TABLE IF EXISTS aegis_system')
    print("  041: Aegis 핵심 테이블 제거 완료")
