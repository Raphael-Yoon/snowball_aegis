"""
RCM 통제별 모집단 attribute 개수 필드 추가
"""


def upgrade(conn):
    """sb_rcm_detail 테이블에 population_attribute_count 컬럼 추가"""

    try:
        # 모집단 attribute 개수 컬럼 추가 (기본값 2: 번호, 설명)
        try:
            conn.execute('''
                ALTER TABLE sb_rcm_detail
                ADD COLUMN population_attribute_count INTEGER DEFAULT 2
            ''')
            print("  population_attribute_count 컬럼 추가 완료")
        except Exception as e:
            # 이미 존재하는 컬럼이면 무시
            if 'duplicate column name' in str(e).lower():
                print("  population_attribute_count 컬럼 이미 존재")
            else:
                raise

        conn.commit()
        print("  sb_rcm_detail 테이블 population_attribute_count 컬럼 추가 완료")

    except Exception as e:
        print(f"  컬럼 추가 실패: {e}")
        raise


def downgrade(conn):
    """sb_rcm_detail 테이블에서 population_attribute_count 컬럼 삭제"""

    try:
        # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
        # 테이블 재생성 필요 (복잡하므로 주석으로만 표시)
        print("  [WARNING] SQLite에서는 컬럼 삭제가 복잡합니다.")
        print("  필요시 수동으로 테이블 재생성 필요")

    except Exception as e:
        print(f"  컬럼 삭제 실패: {e}")
        raise
