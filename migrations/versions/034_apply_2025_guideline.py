"""
정보보호공시 2025 가이드라인 개정 반영 (질문 세트 축소 및 구조 고도화)
"""

def upgrade(conn):
    """기존 질문 삭제 및 2025 가이드라인 기준 신규 질문 삽입"""
    print("  SB_DISCLOSURE_QUESTIONS 테이블 정리 중...")
    conn.execute('DELETE FROM sb_disclosure_questions')
    
    # 2025 가이드라인 질문 데이터
    questions = [
        # ============================================================================
        # 1. 정보보호 투자 (Q1)
        # ============================================================================
        {
            "id": "Q1-1", "level": 1, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
            "text": "공시대상연도(1~12월)에 정보보호 투자가 발생했나요?", "type": "yes_no",
            "dependent_question_ids": '["Q1-2", "Q1-3"]', "sort_order": 1
        },
        {
            "id": "Q1-2", "level": 2, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
            "text": "정보기술부문 투자액(A) (원)", "type": "number",
            "parent_question_id": "Q1-1", "sort_order": 2, "help_text": "발생주의 원칙에 따른 1년 간의 총 IT 투자액"
        },
        {
            "id": "Q1-3", "level": 2, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
            "text": "정보보호부문 투자액(B) - 다음 3개 항목의 합계", "type": "group",
            "parent_question_id": "Q1-1", "dependent_question_ids": '["Q1-3-1", "Q1-3-2", "Q1-3-3"]', "sort_order": 3
        },
        {
            "id": "Q1-3-1", "level": 3, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
            "text": "1) 유/무형자산 당기 감가상각비", "type": "number",
            "parent_question_id": "Q1-3", "sort_order": 4
        },
        {
            "id": "Q1-3-2", "level": 3, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
            "text": "2) 비용(서비스 이용료, 외주용역비 등)", "type": "number",
            "parent_question_id": "Q1-3", "sort_order": 5
        },
        {
            "id": "Q1-3-3", "level": 3, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
            "text": "3) 내부 전담인력 인건비(급여, 상여, 퇴직급여 등)", "type": "number",
            "parent_question_id": "Q1-3", "sort_order": 6, "help_text": "정보보호 업무만을 전담하는 인력의 인건비"
        },
        {
            "id": "Q1-4", "level": 1, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자 계획",
            "text": "향후(차기 연도) 정보보호 투자 계획이 있으신가요?", "type": "yes_no",
            "dependent_question_ids": '["Q1-4-1"]', "sort_order": 7
        },
        {
            "id": "Q1-4-1", "level": 2, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자 계획",
            "text": "예정 투자액 (원)", "type": "number",
            "parent_question_id": "Q1-4", "sort_order": 8
        },

        # ============================================================================
        # 2. 정보보호 인력 (Q2)
        # ============================================================================
        {
            "id": "Q2-1", "level": 1, "category_id": 2, "category": "정보보호 인력", "subcategory": "정보보호 인력",
            "text": "정보보호 전담 부서 또는 전담 인력이 있나요? ", "type": "yes_no",
            "dependent_question_ids": '["Q2-2", "Q2-3", "Q2-4"]', "sort_order": 9
        },
        {
            "id": "Q2-2", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "인력",
            "text": "총 임직원 수 (월평균 간이세액 인원)", "type": "number",
            "parent_question_id": "Q2-1", "sort_order": 10, "help_text": "매월 간이세액 신고 인원의 12개월 평균"
        },
        {
            "id": "Q2-3", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "인력",
            "text": "내부 전담인력 수 (월평균, 소수점 포함)", "type": "number",
            "parent_question_id": "Q2-1", "sort_order": 11, "help_text": "소수점 첫째자리까지 입력 가능"
        },
        {
            "id": "Q2-4", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "인력",
            "text": "외주 전담인력 수 (계약서 M/M 기반 월평균)", "type": "number",
            "parent_question_id": "Q2-1", "sort_order": 12
        },
        {
            "id": "Q2-5", "level": 1, "category_id": 2, "category": "정보보호 인력", "subcategory": "CISO/CPO",
            "text": "최고책임자(CISO/CPO) 지정 현황", "type": "yes_no",
            "dependent_question_ids": '["Q2-5-1"]', "sort_order": 13
        },
        {
            "id": "Q2-5-1", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "CISO/CPO",
            "text": "CISO/CPO 이름, 직급, 임원여부, 겸직여부", "type": "table",
            "parent_question_id": "Q2-5", "sort_order": 14,
            "options": '["이름", "직급", "임원여부(Y/N)", "겸직여부(Y/N)"]'
        },

        # ============================================================================
        # 3. 정보보호 인증 (Q3)
        # ============================================================================
        {
            "id": "Q3-1", "level": 1, "category_id": 3, "category": "정보보호 인증", "subcategory": "인증/평가",
            "text": "ISMS, ISO27001 등 유효한 인증이 있나요?", "type": "yes_no",
            "dependent_question_ids": '["Q3-2"]', "sort_order": 15
        },
        {
            "id": "Q3-2", "level": 2, "category_id": 3, "category": "정보보호 인증", "subcategory": "인증/평가",
            "text": "인증 종류, 유효기간, 발행기관", "type": "table",
            "parent_question_id": "Q3-1", "sort_order": 16,
            "options": '["인증종류", "유효기간", "발행기관"]'
        },

        # ============================================================================
        # 4. 정보보호 활동 (Q4)
        # ============================================================================
        {
            "id": "Q4-1", "level": 1, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
            "text": "이용자 보호를 위한 활동(최신 2025 기준)이 있나요?", "type": "yes_no",
            "dependent_question_ids": '["Q4-2", "Q4-3", "Q4-4", "Q4-5", "Q4-6"]', "sort_order": 17
        },
        {
            "id": "Q4-2", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
            "text": "제로트러스트(Zero Trust) 도입/운영 단계", "type": "select",
            "options": '["도입전", "기초단계", "운영단계", "고도화단계"]',
            "parent_question_id": "Q4-1", "sort_order": 18
        },
        {
            "id": "Q4-3", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
            "text": "공급망 보안(SBOM) 및 취약점 관리 실적", "type": "number",
            "parent_question_id": "Q4-1", "sort_order": 19, "help_text": "연간 관리 건수 입력"
        },
        {
            "id": "Q4-4", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
            "text": "사이버 위협정보 분석/공유시스템(C-TAS) 참여", "type": "checkbox",
            "options": '["C-TAS 참여 중", "기타 위협정보 공유 채널 운영"]',
            "parent_question_id": "Q4-1", "sort_order": 20
        },
        {
            "id": "Q4-5", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
            "text": "사이버 위기대응 모의훈련(DDoS, 랜섬웨어 등)", "type": "table",
            "options": '["훈련종류", "실시일자", "참여인원"]',
            "parent_question_id": "Q4-1", "sort_order": 21
        },
        {
            "id": "Q4-6", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
            "text": "침해사고 배상책임보험 가입 여부", "type": "yes_no",
            "parent_question_id": "Q4-1", "sort_order": 22
        }
    ]

    for q in questions:
        conn.execute('''
            INSERT INTO sb_disclosure_questions
            (id, level, category_id, category, subcategory, text, type, options, parent_question_id, dependent_question_ids, sort_order, help_text)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            q["id"], q["level"], q["category_id"], q["category"], q.get("subcategory"),
            q["text"], q["type"], q.get("options"), q.get("parent_question_id"),
            q.get("dependent_question_ids"), q["sort_order"], q.get("help_text")
        ))
    
    print(f"  [OK] {len(questions)}개의 신규 질문 삽입 완료.")

def downgrade(conn):
    """이전 시드로 복구 (생략 가능하나 구조상 유지)"""
    pass
