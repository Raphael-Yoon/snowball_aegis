"""
MySQL -> SQLite 백업

gmail_schedule.py 에서 사용하는 함수 제공:
  MYSQL_CONFIG, get_mysql_table_schema, create_sqlite_table,
  migrate_table_data, backup_mysql_to_sqlite
"""

import os
import sys
import sqlite3
from datetime import datetime

project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

try:
    import pymysql
    import pymysql.cursors
except ImportError:
    print("pip install pymysql")
    sys.exit(1)

from dotenv import load_dotenv
load_dotenv(os.path.join(project_root, '.env'))

MYSQL_CONFIG = {
    'host':        os.getenv('MYSQL_HOST', 'itap.mysql.pythonanywhere-services.com'),
    'user':        os.getenv('MYSQL_USER', 'itap'),
    'password':    os.getenv('MYSQL_PASSWORD', ''),
    'database':    os.getenv('MYSQL_DATABASE', 'itap$snowball'),
    'port':        int(os.getenv('MYSQL_PORT', '3306')),
    'charset':     'utf8mb4',
    'connect_timeout': 10,
    'cursorclass': pymysql.cursors.DictCursor,
}


def get_mysql_table_schema(mysql_conn, table_name):
    with mysql_conn.cursor() as cursor:
        cursor.execute(f"DESCRIBE `{table_name}`")
        return cursor.fetchall()


def _to_sqlite_type(mysql_type):
    t = mysql_type.upper()
    if any(x in t for x in ('INT', 'TINYINT', 'SMALLINT', 'MEDIUMINT', 'BIGINT')):
        return 'INTEGER'
    if any(x in t for x in ('FLOAT', 'DOUBLE', 'DECIMAL', 'NUMERIC', 'REAL')):
        return 'REAL'
    if any(x in t for x in ('BLOB', 'BINARY', 'VARBINARY')):
        return 'BLOB'
    return 'TEXT'


def create_sqlite_table(sqlite_conn, table_name, columns):
    sqlite_conn.execute(f"DROP TABLE IF EXISTS `{table_name}`")
    col_defs = []
    for col in columns:
        name = col['Field']
        stype = _to_sqlite_type(col['Type'])
        pk = ' PRIMARY KEY' if col['Key'] == 'PRI' else ''
        col_defs.append(f'  `{name}` {stype}{pk}')
    ddl = f"CREATE TABLE `{table_name}` (\n{chr(44)+chr(10)}.join(col_defs)\n)"
    sqlite_conn.execute(f"CREATE TABLE `{table_name}` ({', '.join(col_defs)})")
    sqlite_conn.commit()


def migrate_table_data(mysql_conn, sqlite_conn, table_name):
    with mysql_conn.cursor() as cursor:
        cursor.execute(f"SELECT * FROM `{table_name}`")
        rows = cursor.fetchall()

    if not rows:
        print(f"  -> 데이터 없음")
        return 0

    keys = list(rows[0].keys())
    placeholders = ', '.join(['?' for _ in keys])
    cols = ', '.join([f'`{k}`' for k in keys])
    sql = f"INSERT OR IGNORE INTO `{table_name}` ({cols}) VALUES ({placeholders})"

    for row in rows:
        sqlite_conn.execute(sql, [row[k] for k in keys])
    sqlite_conn.commit()
    print(f"  -> {len(rows):,}행 완료")
    return len(rows)


def backup_mysql_to_sqlite(output_path=None):
    if output_path is None:
        backup_dir = os.path.join(project_root, 'backups')
        os.makedirs(backup_dir, exist_ok=True)
        today = datetime.now().strftime('%Y%m%d')
        output_path = os.path.join(backup_dir, f'snowball_{today}.db')

    print("[CONNECT] MySQL 연결 중...")
    mysql_conn = pymysql.connect(**MYSQL_CONFIG)
    print("  MySQL 연결 성공")

    print(f"[CONNECT] SQLite 생성: {output_path}")
    sqlite_conn = sqlite3.connect(output_path)
    print("  SQLite 준비 완료\n")

    try:
        with mysql_conn.cursor() as cursor:
            cursor.execute("SHOW TABLES")
            results = cursor.fetchall()

        tables = [list(r.values())[0] for r in results]
        print(f"백업 대상: {len(tables)}개 테이블\n")

        total_rows = 0
        success_count = 0

        for i, tbl in enumerate(tables, 1):
            print(f"[{i}/{len(tables)}] {tbl}")
            try:
                cols = get_mysql_table_schema(mysql_conn, tbl)
                create_sqlite_table(sqlite_conn, tbl, cols)
                cnt = migrate_table_data(mysql_conn, sqlite_conn, tbl)
                total_rows += cnt
                success_count += 1
            except Exception as e:
                print(f"  ERROR: {e}")

        print(f"\n완료: {success_count}/{len(tables)} 테이블, {total_rows:,}행")
        print(f"파일: {output_path} ({os.path.getsize(output_path)/1024/1024:.2f} MB)")

    finally:
        sqlite_conn.close()
        mysql_conn.close()

    return output_path


if __name__ == '__main__':
    backup_mysql_to_sqlite()
