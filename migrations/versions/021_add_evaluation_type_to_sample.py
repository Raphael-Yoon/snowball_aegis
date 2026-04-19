"""
표본 테이블에 evaluation_type 컬럼 추가
설계평가와 운영평가를 구분하기 위한 필드

⚠️ DEPRECATED WARNING:
이 마이그레이션은 Migration 026에 의해 무효화되었습니다.
Migration 026은 sb_evaluation_sample 테이블을 DROP하고 재생성하면서
evaluation_type 컬럼을 포함하여 다시 생성합니다.

마이그레이션 시퀀스:
- 017: attribute0-9 추가 (이후 026에서 제거됨)
- 021: evaluation_type 추가 (이후 026에서 제거되고 재생성됨)
- 026: 테이블 DROP & 재생성 (evaluation_type 포함)
- 027: attribute0-9 재추가

⚠️ 주의: 이미 적용된 데이터베이스에서는 이 마이그레이션을 삭제하지 마세요!
"""


def upgrade(conn):
    """sb_evaluation_sample 테이블에 evaluation_type 컬럼 추가"""

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

        # evaluation_type 컬럼 추가 (design, operation 구분)
        try:
            conn.execute('''
                ALTER TABLE sb_evaluation_sample
                ADD COLUMN evaluation_type TEXT DEFAULT 'operation'
            ''')
            print("  evaluation_type 컬럼 추가 완료")
        except Exception as e:
            # 이미 존재하는 컬럼이면 무시
            if 'duplicate column name' in str(e).lower():
                print("  evaluation_type 컬럼 이미 존재")
            else:
                raise

        conn.commit()
        print("  sb_evaluation_sample 테이블 evaluation_type 컬럼 추가 완료")

    except Exception as e:
        print(f"  컬럼 추가 실패: {e}")
        raise


def downgrade(conn):
    """sb_evaluation_sample 테이블에서 evaluation_type 컬럼 삭제"""

    try:
        # SQLite는 ALTER TABLE DROP COLUMN을 지원하지 않으므로
        # 테이블 재생성 필요 (복잡하므로 주석으로만 표시)
        print("  [WARNING] SQLite에서는 컬럼 삭제가 복잡합니다.")
        print("  필요시 수동으로 테이블 재생성 필요")

    except Exception as e:
        print(f"  컬럼 삭제 실패: {e}")
        raise
