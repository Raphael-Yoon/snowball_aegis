"""
정보보호공시 누락 질문 추가 (2026-02 가이드라인 검토 결과)

기존 구현에서 누락된 항목만 추가:
- 투자: 주요투자항목 (Q27)
- 인력: 정보기술인력(C) (Q28), CISO 활동내역 (Q29)

참고: 활동 카테고리의 정책/지침(Q20), 교육(Q19), 취약점분석(Q21)은 이미 구현됨
"""

import json


def upgrade(conn):
    """누락된 질문 추가"""
    print("  누락된 질문 추가 시작...")

    # 1. 기존 질문 조회
    cursor = conn.execute('SELECT MAX(sort_order) as max_sort FROM sb_disclosure_questions')
    max_sort = cursor.fetchone()[0] or 0

    # 새로 추가할 질문들 (실제 누락된 3개만)
    new_questions = [
        # ============================================================================
        # 투자 - 주요투자항목
        # ============================================================================
        {
            "id": "Q27",
            "display_number": "Q1-1-3",
            "level": 2,
            "category_id": 1,
            "category": "정보보호 투자",
            "subcategory": "투자",
            "text": "주요 투자 항목 (정보보호 투자의 주요 내역을 기재)",
            "type": "textarea",
            "parent_question_id": "Q1",  # 투자 발생 여부가 YES일 때
            "sort_order": max_sort + 1,
            "help_text": "예: 방화벽 도입, 보안관제 서비스, 취약점 진단 등"
        },

        # ============================================================================
        # 인력 - 정보기술인력(C)
        # ============================================================================
        {
            "id": "Q28",
            "display_number": "Q2-1-0",
            "level": 2,
            "category_id": 2,
            "category": "정보보호 인력",
            "subcategory": "인력",
            "text": "정보기술부문 인력 수(C) (IT 전체 인력)",
            "type": "number",
            "parent_question_id": "Q9",  # 전담 부서/인력 여부
            "sort_order": max_sort + 2,
            "help_text": "IT 관련 업무를 수행하는 전체 인력 수 (정보보호 인력 포함)"
        },

        # ============================================================================
        # 인력 - CISO 활동내역
        # ============================================================================
        {
            "id": "Q29",
            "display_number": "Q2-2-2",
            "level": 2,
            "category_id": 2,
            "category": "정보보호 인력",
            "subcategory": "CISO/CPO",
            "text": "CISO/CPO 주요 활동 내역",
            "type": "textarea",
            "parent_question_id": "Q13",  # CISO/CPO 지정 여부
            "sort_order": max_sort + 3,
            "help_text": "예: 보안정책 수립, 보안교육 실시, 보안점검 수행, 침해대응 등"
        },
    ]

    # 2. 질문 삽입
    for q in new_questions:
        conn.execute('''
            INSERT INTO sb_disclosure_questions
            (id, display_number, level, category_id, category, subcategory, text, type,
             options, parent_question_id, dependent_question_ids, sort_order, help_text)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (
            q["id"],
            q.get("display_number"),
            q["level"],
            q["category_id"],
            q["category"],
            q.get("subcategory"),
            q["text"],
            q["type"],
            q.get("options"),
            q.get("parent_question_id"),
            q.get("dependent_question_ids"),
            q["sort_order"],
            q.get("help_text")
        ))
        print(f"    + {q['id']}: {q['text'][:30]}...")

    # 3. Q1의 dependent_question_ids에 Q27 추가
    cursor = conn.execute('SELECT dependent_question_ids FROM sb_disclosure_questions WHERE id = ?', ('Q1',))
    row = cursor.fetchone()
    if row and row[0]:
        deps = json.loads(row[0])
        if 'Q27' not in deps:
            deps.append('Q27')
            conn.execute('''
                UPDATE sb_disclosure_questions
                SET dependent_question_ids = ?
                WHERE id = ?
            ''', (json.dumps(deps, ensure_ascii=False), 'Q1'))
            print("    * Q1의 dependent_question_ids에 Q27 추가")

    # 4. Q9의 dependent_question_ids에 Q28 추가
    cursor = conn.execute('SELECT dependent_question_ids FROM sb_disclosure_questions WHERE id = ?', ('Q9',))
    row = cursor.fetchone()
    if row and row[0]:
        deps = json.loads(row[0])
        if 'Q28' not in deps:
            deps.insert(0, 'Q28')  # 첫 번째에 추가 (총임직원 앞)
            conn.execute('''
                UPDATE sb_disclosure_questions
                SET dependent_question_ids = ?
                WHERE id = ?
            ''', (json.dumps(deps, ensure_ascii=False), 'Q9'))
            print("    * Q9의 dependent_question_ids에 Q28 추가")

    # 5. Q13의 dependent_question_ids에 Q29 추가
    cursor = conn.execute('SELECT dependent_question_ids FROM sb_disclosure_questions WHERE id = ?', ('Q13',))
    row = cursor.fetchone()
    if row and row[0]:
        deps = json.loads(row[0])
        if 'Q29' not in deps:
            deps.append('Q29')
            conn.execute('''
                UPDATE sb_disclosure_questions
                SET dependent_question_ids = ?
                WHERE id = ?
            ''', (json.dumps(deps, ensure_ascii=False), 'Q13'))
            print("    * Q13의 dependent_question_ids에 Q29 추가")

    conn.commit()
    print(f"  [OK] {len(new_questions)}개의 질문 추가 완료")


def downgrade(conn):
    """추가된 질문 삭제"""
    print("  추가된 질문 삭제 시작...")

    # 1. 추가된 질문 삭제
    new_ids = ['Q27', 'Q28', 'Q29']
    for qid in new_ids:
        conn.execute('DELETE FROM sb_disclosure_questions WHERE id = ?', (qid,))
        print(f"    - {qid} 삭제")

    # 2. dependent_question_ids에서 제거
    for parent_id in ['Q1', 'Q9', 'Q13']:
        cursor = conn.execute('SELECT dependent_question_ids FROM sb_disclosure_questions WHERE id = ?', (parent_id,))
        row = cursor.fetchone()
        if row and row[0]:
            deps = json.loads(row[0])
            deps = [d for d in deps if d not in new_ids]
            conn.execute('''
                UPDATE sb_disclosure_questions
                SET dependent_question_ids = ?
                WHERE id = ?
            ''', (json.dumps(deps, ensure_ascii=False), parent_id))

    conn.commit()
    print("  [OK] 추가된 질문 삭제 완료")
