"""
Migration 020: Add design_comment column to sb_design_evaluation_line table
설계평가 라인 테이블에 설계 평가 코멘트 컬럼 추가
"""

def upgrade(conn):
    """Add design_comment column to sb_design_evaluation_line table"""
    print("Adding design_comment column to sb_design_evaluation_line table...")

    # 컬럼 존재 여부 확인
    cursor = conn.execute("PRAGMA table_info(sb_design_evaluation_line)")
    columns = [row[1] for row in cursor.fetchall()]

    # effectiveness_comment가 있으면 design_comment로 이름 변경 (데이터 유지)
    if 'effectiveness_comment' in columns and 'design_comment' not in columns:
        print(">> Renaming effectiveness_comment to design_comment...")

        # SQLite는 ALTER TABLE RENAME COLUMN을 지원하지 않으므로 테이블 재생성
        conn.execute('''
            CREATE TABLE sb_design_evaluation_line_temp AS
            SELECT line_id, header_id, control_code, control_sequence,
                   description_adequacy, improvement_suggestion,
                   overall_effectiveness, evaluation_evidence,
                   evaluation_rationale, effectiveness_comment as design_comment,
                   recommended_actions, evaluation_date, last_updated
            FROM sb_design_evaluation_line
        ''')

        conn.execute('DROP TABLE sb_design_evaluation_line')

        conn.execute('''
            CREATE TABLE sb_design_evaluation_line (
                line_id INTEGER PRIMARY KEY AUTOINCREMENT,
                header_id INTEGER NOT NULL,
                control_code TEXT NOT NULL,
                control_sequence INTEGER DEFAULT 1,
                description_adequacy TEXT,
                improvement_suggestion TEXT,
                overall_effectiveness TEXT,
                evaluation_evidence TEXT,
                evaluation_rationale TEXT,
                design_comment TEXT,
                recommended_actions TEXT,
                evaluation_date TIMESTAMP DEFAULT NULL,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (header_id) REFERENCES sb_design_evaluation_header (header_id) ON DELETE CASCADE,
                UNIQUE(header_id, control_code)
            )
        ''')

        conn.execute('''
            INSERT INTO sb_design_evaluation_line
            SELECT * FROM sb_design_evaluation_line_temp
        ''')

        conn.execute('DROP TABLE sb_design_evaluation_line_temp')
        print(">> effectiveness_comment renamed to design_comment successfully")

    # design_comment가 이미 있으면 스킵
    elif 'design_comment' in columns:
        print(">> design_comment column already exists, skipping...")

    # 둘 다 없으면 design_comment 추가
    elif 'design_comment' not in columns and 'effectiveness_comment' not in columns:
        conn.execute('''
            ALTER TABLE sb_design_evaluation_line
            ADD COLUMN design_comment TEXT
        ''')
        print(">> design_comment column added successfully")

def downgrade(conn):
    """Remove design_comment column from sb_design_evaluation_line table"""
    print("Removing design_comment column from sb_design_evaluation_line table...")

    cursor = conn.execute("PRAGMA table_info(sb_design_evaluation_line)")
    columns = [row[1] for row in cursor.fetchall()]

    if 'design_comment' in columns:
        # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로 테이블 재생성
        conn.execute('''
            CREATE TABLE sb_design_evaluation_line_backup AS
            SELECT line_id, header_id, control_code, control_sequence,
                   description_adequacy, improvement_suggestion,
                   overall_effectiveness, evaluation_evidence,
                   evaluation_rationale, recommended_actions,
                   evaluation_date, last_updated
            FROM sb_design_evaluation_line
        ''')

        conn.execute('DROP TABLE sb_design_evaluation_line')

        conn.execute('''
            CREATE TABLE sb_design_evaluation_line (
                line_id INTEGER PRIMARY KEY AUTOINCREMENT,
                header_id INTEGER NOT NULL,
                control_code TEXT NOT NULL,
                control_sequence INTEGER DEFAULT 1,
                description_adequacy TEXT,
                improvement_suggestion TEXT,
                overall_effectiveness TEXT,
                evaluation_evidence TEXT,
                evaluation_rationale TEXT,
                recommended_actions TEXT,
                evaluation_date TIMESTAMP DEFAULT NULL,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (header_id) REFERENCES sb_design_evaluation_header (header_id) ON DELETE CASCADE,
                UNIQUE(header_id, control_code)
            )
        ''')

        conn.execute('''
            INSERT INTO sb_design_evaluation_line
            SELECT * FROM sb_design_evaluation_line_backup
        ''')

        conn.execute('DROP TABLE sb_design_evaluation_line_backup')
        print(">> design_comment column removed successfully")
    else:
        print(">> design_comment column not found, skipping...")
