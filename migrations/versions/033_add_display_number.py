"""
display_number 컬럼 추가
- ID는 순차형(Q1-1, Q1-2...) 유지
- display_number는 화면에 표시되는 계층형 번호
- 2025 가이드라인 기반 26개 질문 구조에 맞춤
"""

# 031_seed_disclosure_questions.py 기준 ID -> 화면 표시 번호 매핑
DISPLAY_NUMBER_MAPPING = {
    # ============================================================================
    # 1. 정보보호 투자 (8개 질문)
    # ============================================================================
    "Q1-1": "Q1-1",           # 정보보호 투자 발생 여부 (L1)
    "Q1-2": "Q1-1-1",         # 정보기술부문 투자액(A)
    "Q1-3": "Q1-1-2",         # 정보보호부문 투자액(B) - Group
    "Q1-3-1": "Q1-1-2-1",     # 감가상각비
    "Q1-3-2": "Q1-1-2-2",     # 서비스 비용
    "Q1-3-3": "Q1-1-2-3",     # 인건비
    "Q1-4": "Q1-2",           # 향후 투자 계획 (L1)
    "Q1-4-1": "Q1-2-1",       # 예정 투자액

    # ============================================================================
    # 2. 정보보호 인력 (6개 질문)
    # ============================================================================
    "Q2-1": "Q2-1",           # 전담 부서/인력 여부 (L1)
    "Q2-2": "Q2-1-1",         # 총 임직원 수
    "Q2-3": "Q2-1-2",         # 내부 전담인력 수
    "Q2-4": "Q2-1-3",         # 외주 전담인력 수
    "Q2-5": "Q2-2",           # CISO/CPO 지정 여부 (L1)
    "Q2-5-1": "Q2-2-1",       # CISO/CPO 상세 현황

    # ============================================================================
    # 3. 정보보호 인증 (2개 질문)
    # ============================================================================
    "Q3-1": "Q3-1",           # 인증 보유 여부 (L1)
    "Q3-2": "Q3-1-1",         # 인증 보유 현황

    # ============================================================================
    # 4. 정보보호 활동 (10개 질문)
    # ============================================================================
    "Q4-1": "Q4-1",           # 이용자 보호 활동 여부 (L1)
    "Q4-2": "Q4-1-1",         # IT 자산 식별 및 관리
    "Q4-3": "Q4-1-2",         # 임직원 교육/훈련 실적
    "Q4-4": "Q4-1-3",         # 지침/절차서 수립
    "Q4-5": "Q4-1-4",         # 취약점 분석/평가
    "Q4-6": "Q4-1-5",         # 제로트러스트 도입
    "Q4-7": "Q4-1-6",         # SBOM 관리
    "Q4-8": "Q4-1-7",         # C-TAS 참여
    "Q4-9": "Q4-1-8",         # 모의훈련
    "Q4-10": "Q4-1-9",        # 배상책임보험
}


def upgrade(conn):
    """display_number 컬럼 추가 및 매핑 데이터 설정"""
    print("  display_number 컬럼 추가 중...")

    # 1. 컬럼 추가 (이미 있으면 무시)
    try:
        conn.execute('ALTER TABLE sb_disclosure_questions ADD COLUMN display_number TEXT')
        print("    - display_number 컬럼 추가 완료")
    except Exception as e:
        if "duplicate column" in str(e).lower():
            print("    - display_number 컬럼이 이미 존재합니다")
        else:
            # SQLite에서는 다른 에러 메시지일 수 있음
            pass

    # 2. 모든 display_number 초기화
    conn.execute('UPDATE sb_disclosure_questions SET display_number = NULL')

    # 3. 매핑 테이블에 따라 설정
    updated = 0
    for qid, display_num in DISPLAY_NUMBER_MAPPING.items():
        cursor = conn.execute('''
            UPDATE sb_disclosure_questions
            SET display_number = ?
            WHERE id = ?
        ''', (display_num, qid))
        if cursor.rowcount > 0:
            updated += 1

    # 4. 매핑에 없는 질문은 ID를 그대로 display_number로 설정
    conn.execute('''
        UPDATE sb_disclosure_questions
        SET display_number = id
        WHERE display_number IS NULL
    ''')

    conn.commit()
    print(f"  [OK] display_number 설정 완료 ({updated}개 매핑 적용)")


def downgrade(conn):
    """display_number 컬럼 제거 (SQLite는 DROP COLUMN 미지원으로 테이블 재생성 필요)"""
    print("  display_number 컬럼 제거 중...")

    # SQLite에서 컬럼 제거를 위한 테이블 재생성
    conn.execute('''
        CREATE TABLE sb_disclosure_questions_backup AS
        SELECT id, level, category_id, category, subcategory, text, type, options,
               parent_question_id, dependent_question_ids, required,
               help_text, evidence_list, sort_order, created_at, updated_at
        FROM sb_disclosure_questions
    ''')

    conn.execute('DROP TABLE sb_disclosure_questions')

    conn.execute('''
        CREATE TABLE sb_disclosure_questions (
            id TEXT PRIMARY KEY,
            level INTEGER NOT NULL,
            category_id INTEGER,
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

    conn.execute('''
        INSERT INTO sb_disclosure_questions
        SELECT * FROM sb_disclosure_questions_backup
    ''')

    conn.execute('DROP TABLE sb_disclosure_questions_backup')

    conn.commit()
    print("  [OK] display_number 컬럼 제거 완료")
