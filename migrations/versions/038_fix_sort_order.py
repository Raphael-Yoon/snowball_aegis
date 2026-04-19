"""
sort_order 전면 재정비

수정 사항:
- Bug 1: Q12(외주 전담인력), Q13(CISO/CPO) sort_order 중복(=13) 해소
- Bug 3: Q27(주요 투자 항목), Q29(CISO 활동내역) sort_order가
         카테고리 범위를 벗어나는 문제 해소

변경 전 → 변경 후:
  Q1:10, Q2:20, Q3:30, Q4:35, Q5:40, Q6:45
  Q27:50  ← 투자 카테고리 내 Q6 직후 (Q1-1-3 위치 반영)
  Q7:60,  Q8:70
  Q9:80,  Q10:90, Q28:95, Q11:100, Q12:110
  Q13:120, Q14:130
  Q29:135 ← 인력 카테고리 내 Q14 직후 (Q2-2-2 위치 반영)
  Q15:140, Q16:150
  Q17:160, Q18:170, Q19:180, Q20:190, Q21:200,
  Q22:210, Q23:220, Q24:230, Q25:240, Q26:250
"""

SORT_ORDER_MAP = {
    # 카테고리 1: 정보보호 투자
    "Q1":  10,
    "Q2":  20,
    "Q3":  30,
    "Q4":  35,
    "Q5":  40,
    "Q6":  45,
    "Q27": 50,   # 주요 투자 항목 (Q1-1-3) — Q6 직후, Q7 이전
    "Q7":  60,
    "Q8":  70,
    # 카테고리 2: 정보보호 인력
    "Q9":  80,
    "Q10": 90,
    "Q28": 95,   # 정보기술인력(C) (Q2-1-2)
    "Q11": 100,
    "Q12": 110,
    "Q13": 120,
    "Q14": 130,
    "Q29": 135,  # CISO 활동내역 (Q2-2-2) — Q14 직후, Q15 이전
    # 카테고리 3: 정보보호 인증
    "Q15": 140,
    "Q16": 150,
    # 카테고리 4: 정보보호 활동
    "Q17": 160,
    "Q18": 170,
    "Q19": 180,
    "Q20": 190,
    "Q21": 200,
    "Q22": 210,
    "Q23": 220,
    "Q24": 230,
    "Q25": 240,
    "Q26": 250,
}


def upgrade(conn):
    """sort_order 전면 재정비"""
    print("  sort_order 재정비 시작...")

    for qid, new_sort in SORT_ORDER_MAP.items():
        conn.execute(
            "UPDATE sb_disclosure_questions SET sort_order = ? WHERE id = ?",
            (new_sort, qid)
        )
        print(f"    {qid}: sort_order → {new_sort}")

    conn.commit()
    print(f"  [OK] {len(SORT_ORDER_MAP)}개 질문 sort_order 재정비 완료")


def downgrade(conn):
    """038 이전 sort_order로 복원 (036/037 적용 직후 값)"""
    prev = {
        "Q1": 1, "Q2": 2, "Q3": 3, "Q4": 4, "Q5": 5, "Q6": 6,
        "Q7": 7, "Q8": 8,
        "Q9": 9, "Q10": 10, "Q28": 11, "Q11": 12, "Q12": 13,
        "Q13": 13, "Q14": 15,
        "Q29": 30,
        "Q15": 16, "Q16": 17,
        "Q17": 18, "Q18": 19, "Q19": 20, "Q20": 21, "Q21": 22,
        "Q22": 23, "Q23": 24, "Q24": 25, "Q25": 26, "Q26": 27,
        "Q27": 28,
    }
    for qid, old_sort in prev.items():
        conn.execute(
            "UPDATE sb_disclosure_questions SET sort_order = ? WHERE id = ?",
            (old_sort, qid)
        )
    conn.commit()
    print("  [OK] sort_order 복원 완료")
