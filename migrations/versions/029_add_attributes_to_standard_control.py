"""
기준통제(sb_standard_control)에 attribute 필드 추가
- attribute0~9: 통제별 attribute 필드명 저장 (VARCHAR 100)
- population_attribute_count: 모집단 attribute 개수 (INTEGER, 기본값 2)
"""


def upgrade(conn):
    """sb_standard_control 테이블에 attribute 컬럼 추가"""

    try:
        # attribute0~9 컬럼 추가 (필드명 저장)
        for i in range(10):
            try:
                conn.execute(f'''
                    ALTER TABLE sb_standard_control
                    ADD COLUMN attribute{i} VARCHAR(100)
                ''')
                print(f"  attribute{i} 컬럼 추가 완료")
            except Exception as e:
                # 이미 존재하는 컬럼이면 무시
                if 'duplicate column name' in str(e).lower() or 'already exists' in str(e).lower():
                    print(f"  attribute{i} 컬럼 이미 존재")
                else:
                    raise

        # population_attribute_count 컬럼 추가
        try:
            conn.execute('''
                ALTER TABLE sb_standard_control
                ADD COLUMN population_attribute_count INTEGER DEFAULT 2
            ''')
            print("  population_attribute_count 컬럼 추가 완료")
        except Exception as e:
            if 'duplicate column name' in str(e).lower() or 'already exists' in str(e).lower():
                print("  population_attribute_count 컬럼 이미 존재")
            else:
                raise

        conn.commit()
        print("  sb_standard_control 테이블 attribute 컬럼 추가 완료")

    except Exception as e:
        print(f"  컬럼 추가 실패: {e}")
        raise


def downgrade(conn):
    """sb_standard_control 테이블에서 attribute 컬럼 삭제"""

    try:
        # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
        # 테이블 재생성 필요 (복잡하므로 주석으로만 표시)
        print("  [WARNING] SQLite에서는 컬럼 삭제가 복잡합니다.")
        print("  필요시 수동으로 테이블 재생성 필요")

        # MySQL의 경우 (운영환경)
        # for i in range(10):
        #     conn.execute(f'ALTER TABLE sb_standard_control DROP COLUMN attribute{i}')
        # conn.execute('ALTER TABLE sb_standard_control DROP COLUMN population_attribute_count')

    except Exception as e:
        print(f"  컬럼 삭제 실패: {e}")
        raise
