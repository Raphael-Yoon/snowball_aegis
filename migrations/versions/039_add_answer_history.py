"""
039 - Audit Trail: sb_disclosure_answer_history 테이블 생성

K-SOX 감사 대응을 위한 답변 변경 이력 추적 테이블.
답변 저장(생성/수정) 시 old_value → new_value를 자동 기록한다.
"""


def upgrade(conn):
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_disclosure_answer_history (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id  TEXT    NOT NULL,
            year        INTEGER NOT NULL,
            question_id TEXT    NOT NULL,
            old_value   TEXT,
            new_value   TEXT,
            changed_by  TEXT,
            changed_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_answer_history_lookup
        ON sb_disclosure_answer_history (company_id, year, question_id)
    ''')
    conn.commit()
    print("  [OK] sb_disclosure_answer_history 테이블 생성 완료")


def downgrade(conn):
    conn.execute('DROP INDEX IF EXISTS idx_answer_history_lookup')
    conn.execute('DROP TABLE IF EXISTS sb_disclosure_answer_history')
    conn.commit()
    print("  [OK] sb_disclosure_answer_history 테이블 삭제 완료")
