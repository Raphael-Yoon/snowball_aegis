"""
정보보호공시 모듈 테이블 생성
- 질문 테이블 (sb_disclosure_questions)
- 답변 테이블 (sb_disclosure_answers)
- 증빙 자료 테이블 (sb_disclosure_evidence)
- 공시 세션 테이블 (sb_disclosure_sessions)
- 공시 제출 기록 테이블 (sb_disclosure_submissions)
"""


def upgrade(conn):
    """정보보호공시 테이블 생성"""

    # 질문 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_disclosure_questions (
            id TEXT PRIMARY KEY,
            level INTEGER NOT NULL,
            category TEXT NOT NULL,
            subcategory TEXT,
            text TEXT NOT NULL,
            type TEXT NOT NULL,
            options TEXT,
            parent_question_id TEXT,
            dependent_question_ids TEXT,
            required INTEGER DEFAULT 1,
            help_text TEXT,
            evidence_list TEXT,
            sort_order INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')

    # 답변 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_disclosure_answers (
            id TEXT PRIMARY KEY,
            question_id TEXT NOT NULL,
            company_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            year INTEGER NOT NULL,
            value TEXT,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (question_id) REFERENCES sb_disclosure_questions(id),
            UNIQUE(question_id, company_id, year)
        )
    ''')

    # 인덱스 생성
    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_disclosure_answers_company_year
        ON sb_disclosure_answers(company_id, year)
    ''')

    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_disclosure_answers_question_company
        ON sb_disclosure_answers(question_id, company_id)
    ''')

    # 증빙 자료 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_disclosure_evidence (
            id TEXT PRIMARY KEY,
            answer_id TEXT,
            question_id TEXT,
            company_id TEXT NOT NULL,
            year INTEGER NOT NULL,
            file_name TEXT NOT NULL,
            file_url TEXT NOT NULL,
            file_size INTEGER,
            file_type TEXT,
            evidence_type TEXT,
            uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            uploaded_by TEXT,
            FOREIGN KEY (answer_id) REFERENCES sb_disclosure_answers(id),
            FOREIGN KEY (question_id) REFERENCES sb_disclosure_questions(id)
        )
    ''')

    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_disclosure_evidence_answer_id
        ON sb_disclosure_evidence(answer_id)
    ''')

    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_disclosure_evidence_company_year
        ON sb_disclosure_evidence(company_id, year)
    ''')

    # 공시 세션 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_disclosure_sessions (
            id TEXT PRIMARY KEY,
            company_id TEXT NOT NULL,
            user_id TEXT NOT NULL,
            year INTEGER NOT NULL,
            status TEXT DEFAULT 'draft',
            total_questions INTEGER DEFAULT 65,
            answered_questions INTEGER DEFAULT 0,
            completion_rate INTEGER DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            submitted_at TIMESTAMP,
            UNIQUE(company_id, year)
        )
    ''')

    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_disclosure_sessions_company_user
        ON sb_disclosure_sessions(company_id, user_id)
    ''')

    # 공시 제출 기록 테이블
    conn.execute('''
        CREATE TABLE IF NOT EXISTS sb_disclosure_submissions (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            company_id TEXT NOT NULL,
            year INTEGER NOT NULL,
            submitted_by TEXT NOT NULL,
            submission_data TEXT,
            submission_details TEXT,
            submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            confirmation_number TEXT,
            status TEXT DEFAULT 'draft',
            FOREIGN KEY (session_id) REFERENCES sb_disclosure_sessions(id)
        )
    ''')

    conn.execute('''
        CREATE INDEX IF NOT EXISTS idx_disclosure_submissions_company_year
        ON sb_disclosure_submissions(company_id, year)
    ''')


def downgrade(conn):
    """정보보호공시 테이블 삭제"""

    # 인덱스 삭제
    conn.execute('DROP INDEX IF EXISTS idx_disclosure_submissions_company_year')
    conn.execute('DROP INDEX IF EXISTS idx_disclosure_sessions_company_user')
    conn.execute('DROP INDEX IF EXISTS idx_disclosure_evidence_company_year')
    conn.execute('DROP INDEX IF EXISTS idx_disclosure_evidence_answer_id')
    conn.execute('DROP INDEX IF EXISTS idx_disclosure_answers_question_company')
    conn.execute('DROP INDEX IF EXISTS idx_disclosure_answers_company_year')

    # 테이블 삭제 (의존성 역순)
    conn.execute('DROP TABLE IF EXISTS sb_disclosure_submissions')
    conn.execute('DROP TABLE IF EXISTS sb_disclosure_sessions')
    conn.execute('DROP TABLE IF EXISTS sb_disclosure_evidence')
    conn.execute('DROP TABLE IF EXISTS sb_disclosure_answers')
    conn.execute('DROP TABLE IF EXISTS sb_disclosure_questions')
