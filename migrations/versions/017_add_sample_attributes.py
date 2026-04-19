"""
평가 표본 테이블에 attribute 필드 추가 (설계평가 및 운영평가 공통)

⚠️ DEPRECATED WARNING:
이 마이그레이션은 Migration 026에 의해 무효화되었습니다.
Migration 026은 sb_evaluation_sample 테이블을 DROP하고 재생성하면서
이 마이그레이션에서 추가한 attribute 컬럼들을 제거합니다.

실제 attribute 컬럼 추가는 Migration 027에서 이루어집니다.

마이그레이션 시퀀스:
- 017: attribute0-9 추가 (이후 026에서 제거됨)
- 021: evaluation_type 추가 (이후 026에서 제거됨)
- 026: 테이블 DROP & 재생성 (attribute 컬럼 없음)
- 027: attribute0-9 재추가 (실제 구현)

⚠️ 주의: 이미 적용된 데이터베이스에서는 이 마이그레이션을 삭제하지 마세요!
"""


def upgrade(conn):
    """sb_evaluation_sample 테이블에 attribute0~9 컬럼 추가"""

    try:
        cursor = conn.cursor()

        # 먼저 기존 sb_operation_evaluation_sample 테이블이 있으면 sb_evaluation_sample로 이름 변경
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='sb_operation_evaluation_sample'")
        if cursor.fetchone():
            print("  기존 sb_operation_evaluation_sample 테이블을 sb_evaluation_sample로 이름 변경 중...")
            cursor.execute("ALTER TABLE sb_operation_evaluation_sample RENAME TO sb_evaluation_sample")
            conn.commit()
            print("  테이블 이름 변경 완료")

        # sb_evaluation_sample 테이블이 존재하는지 확인
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='sb_evaluation_sample'")
        if not cursor.fetchone():
            print("  [WARNING] sb_evaluation_sample 테이블이 없습니다. 마이그레이션 001을 먼저 실행하세요.")
            return

        # attribute0~9 컬럼 추가 (실제 증빙 데이터 저장)
        for i in range(10):
            try:
                conn.execute(f'''
                    ALTER TABLE sb_evaluation_sample
                    ADD COLUMN attribute{i} TEXT
                ''')
                print(f"  attribute{i} 컬럼 추가 완료")
            except Exception as e:
                # 이미 존재하는 컬럼이면 무시
                if 'duplicate column name' in str(e).lower():
                    print(f"  attribute{i} 컬럼 이미 존재")
                else:
                    raise

        conn.commit()
        print("  sb_evaluation_sample 테이블 attribute 컬럼 추가 완료")

    except Exception as e:
        print(f"  컬럼 추가 실패: {e}")
        raise


def downgrade(conn):
    """sb_evaluation_sample 테이블에서 attribute0~9 컬럼 삭제"""

    try:
        # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
        # 테이블 재생성 필요 (복잡하므로 주석으로만 표시)
        print("  [WARNING] SQLite에서는 컬럼 삭제가 복잡합니다.")
        print("  필요시 수동으로 테이블 재생성 필요")

    except Exception as e:
        print(f"  컬럼 삭제 실패: {e}")
        raise
