"""
운영평가 Line 테이블에 파일 경로 컬럼 추가
- population_path: 모집단 엑셀 파일 경로
- samples_path: 표본 데이터 JSON 파일 경로
- test_results_path: 테스트 결과 JSON 파일 경로
- population_count: 모집단 개수
"""


def upgrade(conn):
    """파일 경로 컬럼 추가"""

    # sb_operation_evaluation_line 테이블에 파일 경로 컬럼 추가
    conn.execute('''
        ALTER TABLE sb_operation_evaluation_line
        ADD COLUMN population_path TEXT DEFAULT NULL
    ''')

    conn.execute('''
        ALTER TABLE sb_operation_evaluation_line
        ADD COLUMN samples_path TEXT DEFAULT NULL
    ''')

    conn.execute('''
        ALTER TABLE sb_operation_evaluation_line
        ADD COLUMN test_results_path TEXT DEFAULT NULL
    ''')

    conn.execute('''
        ALTER TABLE sb_operation_evaluation_line
        ADD COLUMN population_count INTEGER DEFAULT 0
    ''')

    print("[OK] 운영평가 파일 경로 컬럼 추가 완료")


def downgrade(conn):
    """롤백 - SQLite는 ALTER TABLE DROP COLUMN 미지원"""

    # SQLite는 컬럼 삭제를 직접 지원하지 않으므로,
    # 필요시 테이블 재생성 방식으로 구현해야 함
    print("⚠️  SQLite는 컬럼 삭제를 지원하지 않습니다. 수동으로 처리 필요.")
