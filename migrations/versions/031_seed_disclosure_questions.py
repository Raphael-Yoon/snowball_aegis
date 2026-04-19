"""
정보보호공시 2025 가이드라인 기반 질문 데이터 시드
"""

DISCLOSURE_QUESTIONS = [
    # ============================================================================
    # 1. 정보보호 투자 (Q1)
    # ============================================================================
    {
        "id": "Q1-1", "level": 1, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
        "text": "공시대상연도(1~12월)에 정보보호 투자가 발생했나요?", "type": "yes_no",
        "dependent_question_ids": ["Q1-2", "Q1-3"], "sort_order": 1,
        "help_text": "정보보호 관련 설비 구입, 서비스 이용, 인건비 등 투자가 있었는지 확인합니다.",
        "evidence_list": ["예산서", "품의서"]
    },
    {
        "id": "Q1-2", "level": 2, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
        "text": "정보기술부문 투자액(A) (원)", "type": "number",
        "parent_question_id": "Q1-1", "sort_order": 2, "help_text": "발생주의 원칙에 따른 1년 간의 총 IT 투자액",
        "evidence_list": ["정보기술 투자 내역 보고서"]
    },
    {
        "id": "Q1-3", "level": 2, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
        "text": "정보보호부문 투자액(B) - 다음 3개 항목의 합계", "type": "group",
        "parent_question_id": "Q1-1", "dependent_question_ids": ["Q1-3-1", "Q1-3-2", "Q1-3-3"], "sort_order": 3,
        "help_text": "정보보호 투자액은 감가상각비, 서비스비용, 인건비의 합으로 구성됩니다."
    },
    {
        "id": "Q1-3-1", "level": 3, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
        "text": "1) 유/무형자산 당기 감가상각비", "type": "number",
        "parent_question_id": "Q1-3", "sort_order": 4, "help_text": "보안 장비, S/W 등의 당기 감가상각비"
    },
    {
        "id": "Q1-3-2", "level": 3, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
        "text": "2) 비용(서비스 이용료, 외주용역비 등)", "type": "number",
        "parent_question_id": "Q1-3", "sort_order": 5, "help_text": "클라우드 보안 서비스, 보안 관제, 컨설팅 비용 등"
    },
    {
        "id": "Q1-3-3", "level": 3, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자",
        "text": "3) 내부 전담인력 인건비(급여, 상여, 퇴직급여 등)", "type": "number",
        "parent_question_id": "Q1-3", "sort_order": 6, "help_text": "정보보호 업무만을 전담하는 인력의 인건비"
    },
    {
        "id": "Q1-4", "level": 1, "category_id": 1, "category": "정보보호 투자", "subcategory": "투자 계획",
        "text": "향후(차기 연도) 정보보호 투자 계획이 있으신가요?", "type": "yes_no",
        "dependent_question_ids": ["Q1-4-1"], "sort_order": 7
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
        "dependent_question_ids": ["Q2-2", "Q2-3", "Q2-4"], "sort_order": 9
    },
    {
        "id": "Q2-2", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "인력",
        "text": "총 임직원 수 (월평균 간이세액 인원)", "type": "number",
        "parent_question_id": "Q2-1", "sort_order": 10, "help_text": "매월 간이세액 신고 인원의 12개월 평균"
    },
    {
        "id": "Q2-3", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "인력",
        "text": "내부 전담인력 수 (월평균, 소수점 포함)", "type": "number",
        "parent_question_id": "Q2-1", "sort_order": 11, "help_text": "정보보호 전담 조직에 속한 내부 인원(월평균)"
    },
    {
        "id": "Q2-4", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "인력",
        "text": "외주 전담인력 수 (계약서 M/M 기반 월평균)", "type": "number",
        "parent_question_id": "Q2-1", "sort_order": 12, "help_text": "외주 인력 중 정보보호 업무 전담 인원(월평균)"
    },
    {
        "id": "Q2-5", "level": 1, "category_id": 2, "category": "정보보호 인력", "subcategory": "CISO/CPO",
        "text": "최고책임자(CISO/CPO) 지정 현황", "type": "yes_no",
        "dependent_question_ids": ["Q2-5-1"], "sort_order": 13
    },
    {
        "id": "Q2-5-1", "level": 2, "category_id": 2, "category": "정보보호 인력", "subcategory": "CISO/CPO",
        "text": "CISO/CPO 상세 현황", "type": "table",
        "parent_question_id": "Q2-5", "sort_order": 14,
        "options": ["이름", "직급", "임원여부(Y/N)", "겸직여부(Y/N)"]
    },

    # ============================================================================
    # 3. 정보보호 인증 (Q3)
    # ============================================================================
    {
        "id": "Q3-1", "level": 1, "category_id": 3, "category": "정보보호 인증", "subcategory": "인증/평가",
        "text": "ISMS, ISO27001 등 유효한 인증이 있나요?", "type": "yes_no",
        "dependent_question_ids": ["Q3-2"], "sort_order": 15,
        "evidence_list": ["인증서 사본", "인증 유효기간 증빙"]
    },
    {
        "id": "Q3-2", "level": 2, "category_id": 3, "category": "정보보호 인증", "subcategory": "인증/평가",
        "text": "인증 보유 현황", "type": "table",
        "parent_question_id": "Q3-1", "sort_order": 16,
        "options": ["인증종류", "유효기간", "발행기관"]
    },

    # ============================================================================
    # 4. 정보보호 활동 (Q4)
    # ============================================================================
    {
        "id": "Q4-1", "level": 1, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
        "text": "이용자 보호를 위한 활동이 있나요?", "type": "yes_no",
        "dependent_question_ids": ["Q4-2", "Q4-3", "Q4-4", "Q4-5", "Q4-6", "Q4-7", "Q4-8", "Q4-9", "Q4-10"], "sort_order": 17,
        "help_text": "가이드라인에 명시된 주요 정보보호 관련 활동 수행 현황을 입력합니다."
    },
    {
        "id": "Q4-2", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "관리적 활동",
        "text": "IT 자산 식별 및 관리 현황", "type": "select",
        "options": ["미수행", "기초관리(엑셀 등)", "자산관리시스템 운영", "정기적 현행화 및 점검"],
        "parent_question_id": "Q4-1", "sort_order": 18, "help_text": "정보보호의 기본인 IT 자산(H/W, S/W) 목록 관리 및 최신화 여부"
    },
    {
        "id": "Q4-3", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "관리적 활동",
        "text": "임직원 정보보호 교육 및 훈련 실적", "type": "table",
        "options": ["교육구분(임직원/협력사)", "실시횟수(연간)", "이수율(%)"],
        "parent_question_id": "Q4-1", "sort_order": 19, "help_text": "정기 보안 교육, 캠페인 등 인식 제고 활동"
    },
    {
        "id": "Q4-4", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "관리적 활동",
        "text": "정보보호 지침 및 절차서 수립/관리", "type": "yes_no",
        "parent_question_id": "Q4-1", "sort_order": 20, "help_text": "정보보호 정책, 지침, 매뉴얼 등의 제정 및 개정 관리"
    },
    {
        "id": "Q4-5", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "기술적 활동",
        "text": "정보시스템 취약점 분석 및 평가", "type": "select",
        "options": ["미수행", "자체 점검(간이)", "정기 점검(연 1회 이상)", "상시 취약점 관리체계"],
        "parent_question_id": "Q4-1", "sort_order": 21, "help_text": "서버, 네트워크, DB, 웹/앱 등에 대한 보안 취약점 점검"
    },
    {
        "id": "Q4-6", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "기술적 활동",
        "text": "제로트러스트(Zero Trust) 도입 단계", "type": "select",
        "options": ["도입전", "계획수립", "기초운영", "고도화단계"],
        "parent_question_id": "Q4-1", "sort_order": 22
    },
    {
        "id": "Q4-7", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "기술적 활동",
        "text": "공급망 보안(SBOM) 관리 및 조치 (건)", "type": "number",
        "parent_question_id": "Q4-1", "sort_order": 23
    },
    {
        "id": "Q4-8", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
        "text": "사이버 위협정보 분석/공유시스템(C-TAS) 참여", "type": "checkbox",
        "options": ["C-TAS 정회원", "C-TAS 준회원", "기타 보안커뮤니티 활동"],
        "parent_question_id": "Q4-1", "sort_order": 24
    },
    {
        "id": "Q4-9", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
        "text": "사이버 위기대응 모의훈련 (DDoS, 랜섬웨어 등)", "type": "table",
        "options": ["훈련종류", "실시일자", "참여인원"],
        "parent_question_id": "Q4-1", "sort_order": 25
    },
    {
        "id": "Q4-10", "level": 2, "category_id": 4, "category": "정보보호 활동", "subcategory": "보호 활동",
        "text": "침해사고 배상책임보험 또는 준비금 가입", "type": "yes_no",
        "parent_question_id": "Q4-1", "sort_order": 26, "help_text": "사고 발생 시 이용자 피해 보상을 위한 보험 가입 또는 적립금 여부"
    }
]

import json

def upgrade(conn):
    # 기존 질문 데이터 삭제
    conn.execute('DELETE FROM sb_disclosure_questions')
    
    # 신규 질문 데이터 삽입
    for q in DISCLOSURE_QUESTIONS:
        conn.execute('''
            INSERT INTO sb_disclosure_questions
            (id, level, category_id, category, subcategory, text, type, options, parent_question_id, dependent_question_ids, sort_order, help_text, evidence_list)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            q["id"], q["level"], q["category_id"], q["category"], q.get("subcategory"),
            q["text"], q["type"], json.dumps(q.get("options"), ensure_ascii=False) if q.get("options") else None,
            q.get("parent_question_id"), 
            json.dumps(q.get("dependent_question_ids"), ensure_ascii=False) if q.get("dependent_question_ids") else None,
            q["sort_order"], q.get("help_text"),
            json.dumps(q.get("evidence_list"), ensure_ascii=False) if q.get("evidence_list") else None
        ))

def downgrade(conn):
    pass
