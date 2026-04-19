"""
정보보호 투자 질문 수정
- Q1-2: 정보보호 투자액 → 전체 IT 투자금액
- Q1-3: IT 예산 대비 비율 → 정보보호 관련 투자액 (비율 자동 계산)
"""


def upgrade(conn):
    """질문 텍스트 및 도움말 업데이트"""
    print("  Q1-2, Q1-3 질문 텍스트 업데이트 중...")

    # Q1-2 업데이트: 전체 IT 투자금액
    conn.execute('''
        UPDATE sb_disclosure_questions
        SET text = '최근 1년간 회사 전체 IT 투자금액은 얼마인가? (원)',
            help_text = '최근 회계연도 기준 전체 IT 투자 금액을 입력하세요.',
            evidence_list = '["IT 예산서", "투자내역서", "예산문서"]'
        WHERE id = 'Q1-2'
    ''')
    print("    - Q1-2 업데이트 완료")

    # Q1-3 업데이트: 정보보호 관련 투자액
    conn.execute('''
        UPDATE sb_disclosure_questions
        SET text = '그 중 정보보호 관련 투자액은 얼마인가? (원)',
            help_text = '전체 IT 투자금액 중 정보보호 관련 투자 금액을 입력하세요. (비율 자동 계산)',
            evidence_list = '["투자내역서", "영수증", "예산문서"]'
        WHERE id = 'Q1-3'
    ''')
    print("    - Q1-3 업데이트 완료")

    conn.commit()
    print("  [OK] 질문 업데이트 완료")


def downgrade(conn):
    """원래 질문으로 복원"""
    print("  Q1-2, Q1-3 질문 텍스트 복원 중...")

    # Q1-2 복원
    conn.execute('''
        UPDATE sb_disclosure_questions
        SET text = '최근 1년간 정보보호 관련 총 투자액은 얼마인가? (원)',
            help_text = '최근 회계연도 기준 정보보호 투자 금액을 입력하세요.',
            evidence_list = '["투자내역서", "영수증", "예산문서"]'
        WHERE id = 'Q1-2'
    ''')

    # Q1-3 복원
    conn.execute('''
        UPDATE sb_disclosure_questions
        SET text = '투자액은 회사 전체 IT 예산의 몇 %인가?',
            help_text = 'IT 예산 대비 정보보호 투자 비율을 입력하세요.',
            evidence_list = '["예산대비 산출자료"]'
        WHERE id = 'Q1-3'
    ''')

    conn.commit()
    print("  [OK] 질문 복원 완료")
