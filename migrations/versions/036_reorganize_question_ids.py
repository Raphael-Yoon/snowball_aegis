"""
질문 ID 체계 재정비
- 기존: 계층형 ID (Q1-1, Q1-2, Q1-3-1...)
- 변경: 순차형 ID (Q1, Q2, Q3...) + display_number로 화면 표시

ID 매핑:
  기존 ID    →  신규 ID   display_number
  Q1-1       →  Q1        Q1-1           (정보보호 투자 발생 여부)
  Q1-2       →  Q2        Q1-1-1         (정보기술부문 투자액)
  Q1-3       →  Q3        Q1-1-2         (정보보호부문 투자액 Group)
  Q1-3-1     →  Q4        Q1-1-2-1       (감가상각비)
  Q1-3-2     →  Q5        Q1-1-2-2       (서비스비용)
  Q1-3-3     →  Q6        Q1-1-2-3       (인건비)
  Q1-4       →  Q7        Q1-2           (향후 투자 계획)
  Q1-4-1     →  Q8        Q1-2-1         (예정 투자액)
  Q2-1       →  Q9        Q2-1           (전담 부서/인력 여부)
  Q2-2       →  Q10       Q2-1-1         (총 임직원 수)
  Q2-3       →  Q11       Q2-1-2         (내부 전담인력 수)
  Q2-4       →  Q12       Q2-1-3         (외주 전담인력 수)
  Q2-5       →  Q13       Q2-2           (CISO/CPO 지정 여부)
  Q2-5-1     →  Q14       Q2-2-1         (CISO/CPO 상세 현황)
  Q3-1       →  Q15       Q3-1           (인증 보유 여부)
  Q3-2       →  Q16       Q3-1-1         (인증 보유 현황)
  Q4-1       →  Q17       Q4-1           (이용자 보호 활동 여부)
  Q4-2       →  Q18       Q4-1-1         (IT 자산 관리)
  Q4-3       →  Q19       Q4-1-2         (교육/훈련 실적)
  Q4-4       →  Q20       Q4-1-3         (지침/절차서)
  Q4-5       →  Q21       Q4-1-4         (취약점 분석)
  Q4-6       →  Q22       Q4-1-5         (제로트러스트)
  Q4-7       →  Q23       Q4-1-6         (SBOM)
  Q4-8       →  Q24       Q4-1-7         (C-TAS)
  Q4-9       →  Q25       Q4-1-8         (모의훈련)
  Q4-10      →  Q26       Q4-1-9         (배상책임보험)
"""

# ID 변환 매핑 (기존 ID → 신규 ID)
ID_MIGRATION_MAP = {
    "Q1-1": "Q1",
    "Q1-2": "Q2",
    "Q1-3": "Q3",
    "Q1-3-1": "Q4",
    "Q1-3-2": "Q5",
    "Q1-3-3": "Q6",
    "Q1-4": "Q7",
    "Q1-4-1": "Q8",
    "Q2-1": "Q9",
    "Q2-2": "Q10",
    "Q2-3": "Q11",
    "Q2-4": "Q12",
    "Q2-5": "Q13",
    "Q2-5-1": "Q14",
    "Q3-1": "Q15",
    "Q3-2": "Q16",
    "Q4-1": "Q17",
    "Q4-2": "Q18",
    "Q4-3": "Q19",
    "Q4-4": "Q20",
    "Q4-5": "Q21",
    "Q4-6": "Q22",
    "Q4-7": "Q23",
    "Q4-8": "Q24",
    "Q4-9": "Q25",
    "Q4-10": "Q26",
}

# 신규 ID의 display_number (화면 표시용)
DISPLAY_NUMBER_MAP = {
    "Q1": "Q1-1",
    "Q2": "Q1-1-1",
    "Q3": "Q1-1-2",
    "Q4": "Q1-1-2-1",
    "Q5": "Q1-1-2-2",
    "Q6": "Q1-1-2-3",
    "Q7": "Q1-2",
    "Q8": "Q1-2-1",
    "Q9": "Q2-1",
    "Q10": "Q2-1-1",
    "Q11": "Q2-1-2",
    "Q12": "Q2-1-3",
    "Q13": "Q2-2",
    "Q14": "Q2-2-1",
    "Q15": "Q3-1",
    "Q16": "Q3-1-1",
    "Q17": "Q4-1",
    "Q18": "Q4-1-1",
    "Q19": "Q4-1-2",
    "Q20": "Q4-1-3",
    "Q21": "Q4-1-4",
    "Q22": "Q4-1-5",
    "Q23": "Q4-1-6",
    "Q24": "Q4-1-7",
    "Q25": "Q4-1-8",
    "Q26": "Q4-1-9",
}

# 역방향 매핑 (신규 ID → 기존 ID)
REVERSE_ID_MAP = {v: k for k, v in ID_MIGRATION_MAP.items()}

import json


def upgrade(conn):
    """ID 체계를 순차형으로 변경"""
    print("  질문 ID 체계 재정비 시작...")

    # 1. 기존 질문 데이터 백업
    cursor = conn.execute('SELECT * FROM sb_disclosure_questions ORDER BY sort_order')
    questions = [dict(row) for row in cursor.fetchall()]
    print(f"    - 기존 질문 {len(questions)}개 백업")

    # 2. 기존 답변 데이터 백업
    cursor = conn.execute('SELECT * FROM sb_disclosure_answers')
    answers = [dict(row) for row in cursor.fetchall()]
    print(f"    - 기존 답변 {len(answers)}개 백업")

    # 3. 기존 증빙 데이터 백업
    cursor = conn.execute('SELECT * FROM sb_disclosure_evidence')
    evidence = [dict(row) for row in cursor.fetchall()]
    print(f"    - 기존 증빙 {len(evidence)}개 백업")

    # 4. 외래키 제약조건 임시 비활성화 (SQLite)
    conn.execute('PRAGMA foreign_keys = OFF')

    # 5. 질문 테이블 ID 변환
    for old_id, new_id in ID_MIGRATION_MAP.items():
        # parent_question_id도 업데이트
        conn.execute('''
            UPDATE sb_disclosure_questions
            SET parent_question_id = ?
            WHERE parent_question_id = ?
        ''', (new_id, old_id))

        # dependent_question_ids (JSON 배열) 업데이트
        cursor = conn.execute('''
            SELECT id, dependent_question_ids
            FROM sb_disclosure_questions
            WHERE dependent_question_ids IS NOT NULL AND dependent_question_ids LIKE ?
        ''', (f'%{old_id}%',))

        for row in cursor.fetchall():
            try:
                deps = json.loads(row[1]) if row[1] else []
                new_deps = [ID_MIGRATION_MAP.get(d, d) for d in deps]
                conn.execute('''
                    UPDATE sb_disclosure_questions
                    SET dependent_question_ids = ?
                    WHERE id = ?
                ''', (json.dumps(new_deps, ensure_ascii=False), row[0]))
            except json.JSONDecodeError:
                pass

    # 6. 질문 ID 자체를 변환 (역순으로 처리하여 충돌 방지)
    for old_id in sorted(ID_MIGRATION_MAP.keys(), key=lambda x: -len(x)):
        new_id = ID_MIGRATION_MAP[old_id]
        display_num = DISPLAY_NUMBER_MAP[new_id]

        conn.execute('''
            UPDATE sb_disclosure_questions
            SET id = ?, display_number = ?
            WHERE id = ?
        ''', (new_id, display_num, old_id))

    print("    - 질문 ID 변환 완료")

    # 7. 답변 테이블 question_id 변환
    for old_id, new_id in ID_MIGRATION_MAP.items():
        conn.execute('''
            UPDATE sb_disclosure_answers
            SET question_id = ?
            WHERE question_id = ?
        ''', (new_id, old_id))
    print("    - 답변 question_id 변환 완료")

    # 8. 증빙 테이블 question_id 변환
    for old_id, new_id in ID_MIGRATION_MAP.items():
        conn.execute('''
            UPDATE sb_disclosure_evidence
            SET question_id = ?
            WHERE question_id = ?
        ''', (new_id, old_id))
    print("    - 증빙 question_id 변환 완료")

    # 9. 외래키 제약조건 재활성화
    conn.execute('PRAGMA foreign_keys = ON')

    conn.commit()
    print("  [OK] 질문 ID 체계 재정비 완료")


def downgrade(conn):
    """ID 체계를 원래대로 복원"""
    print("  질문 ID 체계 복원 시작...")

    conn.execute('PRAGMA foreign_keys = OFF')

    # 역방향 변환 (신규 ID → 기존 ID)
    for new_id, old_id in REVERSE_ID_MAP.items():
        # parent_question_id 복원
        conn.execute('''
            UPDATE sb_disclosure_questions
            SET parent_question_id = ?
            WHERE parent_question_id = ?
        ''', (old_id, new_id))

        # dependent_question_ids 복원
        cursor = conn.execute('''
            SELECT id, dependent_question_ids
            FROM sb_disclosure_questions
            WHERE dependent_question_ids IS NOT NULL AND dependent_question_ids LIKE ?
        ''', (f'%{new_id}%',))

        for row in cursor.fetchall():
            try:
                deps = json.loads(row[1]) if row[1] else []
                old_deps = [REVERSE_ID_MAP.get(d, d) for d in deps]
                conn.execute('''
                    UPDATE sb_disclosure_questions
                    SET dependent_question_ids = ?
                    WHERE id = ?
                ''', (json.dumps(old_deps, ensure_ascii=False), row[0]))
            except json.JSONDecodeError:
                pass

    # ID 복원 (순차적으로)
    for new_id in sorted(REVERSE_ID_MAP.keys(), key=lambda x: int(x[1:])):
        old_id = REVERSE_ID_MAP[new_id]
        # display_number는 기존 ID와 동일하게 설정
        conn.execute('''
            UPDATE sb_disclosure_questions
            SET id = ?, display_number = ?
            WHERE id = ?
        ''', (old_id, old_id, new_id))

    # 답변 복원
    for new_id, old_id in REVERSE_ID_MAP.items():
        conn.execute('''
            UPDATE sb_disclosure_answers
            SET question_id = ?
            WHERE question_id = ?
        ''', (old_id, new_id))

    # 증빙 복원
    for new_id, old_id in REVERSE_ID_MAP.items():
        conn.execute('''
            UPDATE sb_disclosure_evidence
            SET question_id = ?
            WHERE question_id = ?
        ''', (old_id, new_id))

    conn.execute('PRAGMA foreign_keys = ON')
    conn.commit()
    print("  [OK] 질문 ID 체계 복원 완료")
