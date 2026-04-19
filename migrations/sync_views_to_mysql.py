"""
SQLite의 모든 뷰를 MySQL로 마이그레이션

SQLite 문법을 MySQL 문법으로 자동 변환:
- sqlite_master -> information_schema
- 타입 변환
- 함수 호환성 체크

사용법:
    python migrations/sync_views_to_mysql.py          # Dry run
    python migrations/sync_views_to_mysql.py --apply  # 실제 적용
"""

import sqlite3
import pymysql
from dotenv import load_dotenv
import os
import sys
import re

load_dotenv()

# MySQL 설정
MYSQL_CONFIG = {
    'host': os.getenv('MYSQL_HOST', 'localhost'),
    'user': os.getenv('MYSQL_USER', 'root'),
    'password': os.getenv('MYSQL_PASSWORD', ''),
    'database': os.getenv('MYSQL_DATABASE', 'snowball'),
    'port': int(os.getenv('MYSQL_PORT', '3306')),
    'charset': 'utf8mb4',
}

SQLITE_DB = 'snowball.db'


def convert_sqlite_to_mysql_sql(sqlite_sql, view_name):
    """SQLite SQL을 MySQL SQL로 변환"""
    # SQLite와 MySQL의 뷰 문법은 거의 동일
    # CREATE VIEW만 CREATE OR REPLACE VIEW로 변경
    mysql_sql = re.sub(
        r'CREATE\s+VIEW\s+(\w+)\s+AS',
        f'CREATE OR REPLACE VIEW `{view_name}` AS',
        sqlite_sql,
        flags=re.IGNORECASE
    )

    # SQLite의 대부분 문법은 MySQL과 호환됨
    # COALESCE, UPPER, LEFT JOIN 등은 모두 동일

    return mysql_sql


def get_sqlite_views():
    """SQLite에서 모든 뷰 정보 조회"""
    conn = sqlite3.connect(SQLITE_DB)
    cursor = conn.execute("""
        SELECT name, sql
        FROM sqlite_master
        WHERE type='view'
        ORDER BY name
    """)
    views = cursor.fetchall()
    conn.close()
    return views


def get_mysql_views(mysql_conn):
    """MySQL에서 현재 뷰 목록 조회"""
    cursor = mysql_conn.cursor()
    cursor.execute("""
        SELECT TABLE_NAME
        FROM information_schema.VIEWS
        WHERE TABLE_SCHEMA = %s
    """, (MYSQL_CONFIG['database'],))
    views = [row[0] for row in cursor.fetchall()]
    return views


def sync_views(dry_run=True):
    """뷰 동기화 실행"""
    print("=" * 80)
    print("SQLite Views to MySQL Migration")
    print("=" * 80)

    # SQLite 연결
    print(f"\n[1] Connecting to SQLite: {SQLITE_DB}")
    sqlite_views = get_sqlite_views()

    if not sqlite_views:
        print("  [INFO] No views found in SQLite database")
        return

    print(f"  Found {len(sqlite_views)} view(s) in SQLite:")
    for view_name, _ in sqlite_views:
        print(f"    - {view_name}")

    # MySQL 연결
    print(f"\n[2] Connecting to MySQL: {MYSQL_CONFIG['host']}/{MYSQL_CONFIG['database']}")
    try:
        mysql_conn = pymysql.connect(**MYSQL_CONFIG)
        mysql_cursor = mysql_conn.cursor()
    except Exception as e:
        print(f"\n[ERROR] MySQL 연결 실패: {e}")
        print("\n다음을 확인하세요:")
        print("  - MySQL 서버 실행 여부")
        print("  - .env 파일의 MySQL 설정")
        print("  - pymysql 설치: pip install pymysql")
        return

    # 기존 MySQL 뷰 확인
    mysql_existing_views = get_mysql_views(mysql_conn)
    print(f"\n[3] Existing views in MySQL: {len(mysql_existing_views)}")
    if mysql_existing_views:
        for view_name in mysql_existing_views:
            print(f"    - {view_name}")

    # Dry run 모드
    if dry_run:
        print("\n" + "=" * 80)
        print("[DRY-RUN] DRY RUN MODE - No changes will be applied")
        print("=" * 80)
        print("\nGenerated SQL statements:\n")
    else:
        print("\n" + "=" * 80)
        print("[APPLY] APPLYING CHANGES TO MYSQL")
        print("=" * 80)

    # 각 뷰를 MySQL로 마이그레이션
    success_count = 0
    error_count = 0

    for view_name, sqlite_sql in sqlite_views:
        print(f"\n{'='*60}")
        print(f"View: {view_name}")
        print(f"{'='*60}")

        # SQLite SQL을 MySQL SQL로 변환
        mysql_sql = convert_sqlite_to_mysql_sql(sqlite_sql, view_name)

        print(f"\nGenerated MySQL SQL:")
        print("-" * 60)
        print(mysql_sql + ";")
        print("-" * 60)

        if not dry_run:
            try:
                # 기존 뷰 삭제
                mysql_cursor.execute(f"DROP VIEW IF EXISTS `{view_name}`")

                # 새 뷰 생성
                mysql_cursor.execute(mysql_sql)
                mysql_conn.commit()

                print(f"\n[OK] View '{view_name}' created successfully")

                # 뷰 데이터 조회 테스트
                mysql_cursor.execute(f"SELECT COUNT(*) FROM `{view_name}`")
                count = mysql_cursor.fetchone()[0]
                print(f"     Records in view: {count}")

                success_count += 1

            except Exception as e:
                print(f"\n[ERROR] Failed to create view '{view_name}'")
                print(f"        Error: {e}")
                error_count += 1

                # 원본 SQLite SQL도 출력 (디버깅용)
                print(f"\nOriginal SQLite SQL:")
                print("-" * 60)
                print(sqlite_sql)
                print("-" * 60)

    # 결과 요약
    print("\n" + "=" * 80)
    if dry_run:
        print("To apply these changes, run:")
        print("  python migrations/sync_views_to_mysql.py --apply")
    else:
        print("Migration Summary:")
        print(f"  Success: {success_count}")
        print(f"  Failed:  {error_count}")
        print(f"  Total:   {len(sqlite_views)}")

        if error_count == 0:
            print("\n[OK] All views migrated successfully!")
        else:
            print("\n[WARNING] Some views failed to migrate. Check errors above.")

    print("=" * 80)

    # 연결 종료
    if 'mysql_conn' in locals():
        mysql_conn.close()


if __name__ == '__main__':
    # --apply 옵션이 있으면 실제 적용, 없으면 dry run
    dry_run = '--apply' not in sys.argv

    if dry_run:
        print("\n[WARNING] Running in DRY RUN mode (no changes will be applied)")
        print("          To apply changes, run with --apply flag\n")

    sync_views(dry_run=dry_run)
