"""
sb_operation_evaluation_line 테이블에 mitigating_factors 컬럼 추가
"""


def upgrade(conn):
    """mitigating_factors 컬럼 추가"""

    try:
        # SQLite는 ALTER TABLE ADD COLUMN을 지원
        conn.execute('''
            ALTER TABLE sb_operation_evaluation_line
            ADD COLUMN mitigating_factors TEXT
        ''')

        print("[OK] sb_operation_evaluation_line 테이블에 mitigating_factors 컬럼 추가 완료")

    except Exception as e:
        # 이미 컬럼이 존재하는 경우
        if 'duplicate column name' in str(e).lower():
            print("[OK] mitigating_factors 컬럼이 이미 존재합니다 (스킵)")
        else:
            print(f"[FAIL] mitigating_factors 컬럼 추가 실패: {e}")
            raise


def downgrade(conn):
    """mitigating_factors 컬럼 제거"""

    try:
        # SQLite는 ALTER TABLE DROP COLUMN을 직접 지원하지 않으므로
        # 테이블을 재생성해야 함

        # 1. 기존 테이블 백업
        conn.execute('''
            CREATE TABLE sb_operation_evaluation_line_backup AS
            SELECT * FROM sb_operation_evaluation_line
        ''')

        # 2. 기존 테이블 삭제
        conn.execute('DROP TABLE sb_operation_evaluation_line')

        # 3. mitigating_factors 없이 테이블 재생성
        conn.execute('''
            CREATE TABLE sb_operation_evaluation_line (
                line_id INTEGER PRIMARY KEY AUTOINCREMENT,
                header_id INTEGER NOT NULL,
                control_code TEXT NOT NULL,
                control_sequence INTEGER,
                sample_size INTEGER DEFAULT 0,
                exception_count INTEGER DEFAULT 0,
                exception_details TEXT,
                conclusion TEXT,
                improvement_plan TEXT,
                evaluation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                population_path TEXT DEFAULT NULL,
                samples_path TEXT DEFAULT NULL,
                test_results_path TEXT DEFAULT NULL,
                population_count INTEGER DEFAULT 0,
                last_updated TIMESTAMP DEFAULT NULL,
                sample_details TEXT DEFAULT NULL,
                no_occurrence INTEGER DEFAULT 0,
                no_occurrence_reason TEXT,
                FOREIGN KEY (header_id) REFERENCES sb_operation_evaluation_header(header_id)
            )
        ''')

        # 4. 백업 데이터 복원 (mitigating_factors 제외)
        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line_backup)")
        backup_columns = [row[1] for row in cursor.fetchall() if row[1] != 'mitigating_factors']

        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line)")
        new_columns = [row[1] for row in cursor.fetchall()]

        common_columns = [col for col in backup_columns if col in new_columns]
        columns_str = ', '.join(common_columns)

        conn.execute(f'''
            INSERT INTO sb_operation_evaluation_line ({columns_str})
            SELECT {columns_str}
            FROM sb_operation_evaluation_line_backup
        ''')

        # 5. 백업 테이블 삭제
        conn.execute('DROP TABLE sb_operation_evaluation_line_backup')

        print("[OK] sb_operation_evaluation_line 테이블에서 mitigating_factors 컬럼 제거 완료")

    except Exception as e:
        print(f"[FAIL] mitigating_factors 컬럼 제거 실패: {e}")
        # 백업이 있으면 복원 시도
        try:
            conn.execute('DROP TABLE IF EXISTS sb_operation_evaluation_line')
            conn.execute('ALTER TABLE sb_operation_evaluation_line_backup RENAME TO sb_operation_evaluation_line')
            print("[WARN] 백업에서 복원됨")
        except:
            pass
        raise
