"""
sb_operation_evaluation_line 테이블에서 operating_effectiveness 컬럼 제거
"""


def upgrade(conn):
    """operating_effectiveness 컬럼 제거"""

    try:
        # SQLite는 ALTER TABLE DROP COLUMN을 직접 지원하지 않으므로
        # 테이블을 재생성해야 함

        # 1. 기존 테이블 백업 (이미 존재하면 삭제)
        conn.execute('DROP TABLE IF EXISTS sb_operation_evaluation_line_backup')
        conn.execute('''
            CREATE TABLE sb_operation_evaluation_line_backup AS
            SELECT * FROM sb_operation_evaluation_line
        ''')

        # 2. 기존 테이블 삭제
        conn.execute('DROP TABLE sb_operation_evaluation_line')

        # 3. operating_effectiveness 없이 새 테이블 생성
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

        # 4. 백업 데이터에서 operating_effectiveness 제외하고 복원
        # 백업 테이블의 컬럼 목록 가져오기
        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line_backup)")
        backup_columns = [row[1] for row in cursor.fetchall() if row[1] != 'operating_effectiveness']

        # 새 테이블의 컬럼 목록 가져오기
        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line)")
        new_columns = [row[1] for row in cursor.fetchall()]

        # 공통 컬럼만 선택
        common_columns = [col for col in backup_columns if col in new_columns]
        columns_str = ', '.join(common_columns)

        conn.execute(f'''
            INSERT INTO sb_operation_evaluation_line ({columns_str})
            SELECT {columns_str}
            FROM sb_operation_evaluation_line_backup
        ''')

        # 5. 백업 테이블 삭제
        conn.execute('DROP TABLE sb_operation_evaluation_line_backup')

        print("[OK] sb_operation_evaluation_line 테이블에서 operating_effectiveness 컬럼 제거 완료")

    except Exception as e:
        print(f"[FAIL] operating_effectiveness 컬럼 제거 실패: {e}")
        # 백업이 있으면 복원 시도
        try:
            conn.execute('DROP TABLE IF EXISTS sb_operation_evaluation_line')
            conn.execute('ALTER TABLE sb_operation_evaluation_line_backup RENAME TO sb_operation_evaluation_line')
            print("[WARN] 백업에서 복원됨")
        except:
            pass
        raise


def downgrade(conn):
    """operating_effectiveness 컬럼 복원"""

    try:
        # 1. 기존 테이블 백업 (이미 존재하면 삭제)
        conn.execute('DROP TABLE IF EXISTS sb_operation_evaluation_line_backup')
        conn.execute('''
            CREATE TABLE sb_operation_evaluation_line_backup AS
            SELECT * FROM sb_operation_evaluation_line
        ''')

        # 2. 기존 테이블 삭제
        conn.execute('DROP TABLE sb_operation_evaluation_line')

        # 3. operating_effectiveness 포함하여 테이블 재생성
        conn.execute('''
            CREATE TABLE sb_operation_evaluation_line (
                line_id INTEGER PRIMARY KEY AUTOINCREMENT,
                header_id INTEGER NOT NULL,
                control_code TEXT NOT NULL,
                control_sequence INTEGER,
                operating_effectiveness TEXT,
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

        # 4. 백업 데이터 복원 (operating_effectiveness는 NULL)
        # 백업 테이블의 컬럼 목록 가져오기
        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line_backup)")
        backup_columns = [row[1] for row in cursor.fetchall()]

        # 새 테이블의 컬럼 목록 가져오기 (operating_effectiveness 제외)
        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line)")
        new_columns = [row[1] for row in cursor.fetchall() if row[1] != 'operating_effectiveness']

        # 공통 컬럼만 선택
        common_columns = [col for col in backup_columns if col in new_columns]
        columns_str = ', '.join(common_columns)
        select_str = ', '.join([col if col != 'operating_effectiveness' else 'NULL' for col in common_columns])

        # operating_effectiveness를 포함한 전체 컬럼 리스트
        all_columns = ['operating_effectiveness'] + common_columns if 'operating_effectiveness' in [row[1] for row in conn.execute("PRAGMA table_info(sb_operation_evaluation_line)")] else common_columns
        all_columns_sorted = sorted(set(all_columns), key=lambda x: ([row[0] for row in conn.execute("PRAGMA table_info(sb_operation_evaluation_line)") if row[1] == x] + [999])[0])

        # 실제 복원 (operating_effectiveness를 NULL로)
        cursor = conn.execute("PRAGMA table_info(sb_operation_evaluation_line)")
        target_columns = [row[1] for row in cursor.fetchall()]
        select_parts = []
        for col in target_columns:
            if col == 'operating_effectiveness':
                select_parts.append('NULL')
            elif col in backup_columns:
                select_parts.append(col)
            else:
                select_parts.append('NULL')

        conn.execute(f'''
            INSERT INTO sb_operation_evaluation_line ({', '.join(target_columns)})
            SELECT {', '.join(select_parts)}
            FROM sb_operation_evaluation_line_backup
        ''')

        # 5. 백업 테이블 삭제
        conn.execute('DROP TABLE sb_operation_evaluation_line_backup')

        print("[OK] sb_operation_evaluation_line 테이블에 operating_effectiveness 컬럼 복원 완료")

    except Exception as e:
        print(f"[FAIL] operating_effectiveness 컬럼 복원 실패: {e}")
        # 백업이 있으면 복원 시도
        try:
            conn.execute('DROP TABLE IF EXISTS sb_operation_evaluation_line')
            conn.execute('ALTER TABLE sb_operation_evaluation_line_backup RENAME TO sb_operation_evaluation_line')
            print("[WARN] 백업에서 복원됨")
        except:
            pass
        raise
