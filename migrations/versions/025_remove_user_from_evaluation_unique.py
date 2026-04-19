"""
Migration 025: 평가 테이블의 UNIQUE 제약조건에서 user_id 제거

작성일: 2025-11-28
설명: RCM별 평가 세션을 여러 사용자가 협업할 수 있도록 변경
      - UNIQUE(rcm_id, user_id, evaluation_session) → UNIQUE(rcm_id, evaluation_session)
      - user_id는 생성자 또는 마지막 수정자 추적용으로만 사용
"""

def upgrade(conn):
    """평가 테이블의 UNIQUE 제약조건 수정"""
    print("  평가 테이블의 UNIQUE 제약조건 수정 중...")

    # 1. 설계평가 헤더 테이블 재생성
    print("    - sb_design_evaluation_header 테이블 재구성...")

    # 기존 데이터 백업
    conn.execute('''
        CREATE TABLE sb_design_evaluation_header_backup AS
        SELECT * FROM sb_design_evaluation_header
    ''')

    # 기존 테이블 삭제
    conn.execute('DROP TABLE sb_design_evaluation_header')

    # 새 테이블 생성 (UNIQUE 제약조건 변경)
    conn.execute('''
        CREATE TABLE sb_design_evaluation_header (
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
            UNIQUE(rcm_id, evaluation_session)
        )
    ''')

    # 중복 데이터 제거하고 복원 (rcm_id, evaluation_session 기준으로 가장 최신 것만)
    conn.execute('''
        INSERT INTO sb_design_evaluation_header
        SELECT * FROM sb_design_evaluation_header_backup
        WHERE header_id IN (
            SELECT MAX(header_id)
            FROM sb_design_evaluation_header_backup
            GROUP BY rcm_id, evaluation_session
        )
    ''')

    # 백업 테이블 삭제
    conn.execute('DROP TABLE sb_design_evaluation_header_backup')
    print("      설계평가 헤더 테이블 재구성 완료")

    # 2. 운영평가 헤더 테이블 재생성
    print("    - sb_operation_evaluation_header 테이블 재구성...")

    # 기존 데이터 백업
    conn.execute('''
        CREATE TABLE sb_operation_evaluation_header_backup AS
        SELECT * FROM sb_operation_evaluation_header
    ''')

    # 기존 테이블 삭제
    conn.execute('DROP TABLE sb_operation_evaluation_header')

    # 새 테이블 생성 (UNIQUE 제약조건 변경)
    conn.execute('''
        CREATE TABLE sb_operation_evaluation_header (
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
            UNIQUE(rcm_id, evaluation_session, design_evaluation_session)
        )
    ''')

    # 중복 데이터 제거하고 복원
    conn.execute('''
        INSERT INTO sb_operation_evaluation_header
        SELECT * FROM sb_operation_evaluation_header_backup
        WHERE header_id IN (
            SELECT MAX(header_id)
            FROM sb_operation_evaluation_header_backup
            GROUP BY rcm_id, evaluation_session, design_evaluation_session
        )
    ''')

    # 백업 테이블 삭제
    conn.execute('DROP TABLE sb_operation_evaluation_header_backup')
    print("      운영평가 헤더 테이블 재구성 완료")

    conn.commit()
    print("  [OK] 평가 테이블 UNIQUE 제약조건 수정 완료")
    print("      - 설계평가: UNIQUE(rcm_id, evaluation_session)")
    print("      - 운영평가: UNIQUE(rcm_id, evaluation_session, design_evaluation_session)")


def downgrade(conn):
    """변경 사항 되돌리기"""
    print("  평가 테이블의 UNIQUE 제약조건 복원 중...")

    # 1. 설계평가 헤더 테이블 복원
    conn.execute('DROP TABLE IF EXISTS sb_design_evaluation_header')
    conn.execute('''
        CREATE TABLE sb_design_evaluation_header (
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

    # 2. 운영평가 헤더 테이블 복원
    conn.execute('DROP TABLE IF EXISTS sb_operation_evaluation_header')
    conn.execute('''
        CREATE TABLE sb_operation_evaluation_header (
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

    conn.commit()
    print("  [OK] 평가 테이블 UNIQUE 제약조건 복원 완료")
