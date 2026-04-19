"""
SQLite에서 MySQL로 전체 데이터 마이그레이션

실행 방법:
    python migrations/migrate_sqlite_to_mysql.py

주요 변경사항 (2026-02):
- TEXT PRIMARY KEY → VARCHAR(50) 변환
- 정보보호공시 테이블(sb_disclosure_*) 스키마 지원
- UNIQUE 제약조건 및 인덱스 이관
- deleted_at 컬럼 지원
"""

import sys
import os
import sqlite3

# 프로젝트 루트를 Python 경로에 추가
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, project_root)

# 현재 디렉토리를 프로젝트 루트로 변경
os.chdir(project_root)

try:
    import pymysql
except ImportError:
    print("PyMySQL이 설치되어 있지 않습니다.")
    print("pip install pymysql")
    sys.exit(1)

from dotenv import load_dotenv
load_dotenv()

SQLITE_DB = 'snowball.db'

# TEXT PRIMARY KEY를 VARCHAR로 변환할 컬럼 매핑
# 테이블별로 PRIMARY KEY가 TEXT인 경우 적절한 VARCHAR 길이 지정
TEXT_PK_VARCHAR_LENGTH = {
    # 정보보호공시 테이블
    'sb_disclosure_questions': {'id': 50},
    'sb_disclosure_answers': {'id': 100},
    'sb_disclosure_evidence': {'id': 100},
    'sb_disclosure_sessions': {'id': 100},
    'sb_disclosure_submissions': {'id': 100},
    # 기존 테이블
    'sb_migration_history': {'id': 50},
}

# 특정 컬럼의 VARCHAR 길이 지정 (FK 참조 등)
COLUMN_VARCHAR_LENGTHS = {
    'question_id': 50,
    'parent_question_id': 50,
    'company_id': 100,
    'user_id': 100,
    'session_id': 100,
    'answer_id': 100,
    'display_number': 50,
    'status': 50,
    'type': 50,
    'evaluation_type': 50,
    'is_active': 10,
    'category': 100,
    'role': 50,
    'ai_review_status': 50,
    'control_category': 100,
    'control_id': 50,
}


def get_mysql_connection():
    """MySQL 연결"""
    return pymysql.connect(
        host=os.getenv('MYSQL_HOST', 'localhost'),
        user=os.getenv('MYSQL_USER', 'root'),
        password=os.getenv('MYSQL_PASSWORD', ''),
        database=os.getenv('MYSQL_DATABASE', 'snowball'),
        port=int(os.getenv('MYSQL_PORT', '3306')),
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )


def get_sqlite_connection():
    """SQLite 연결"""
    conn = sqlite3.connect(SQLITE_DB)
    conn.row_factory = sqlite3.Row
    return conn


def get_table_schema(sqlite_cursor, table_name):
    """SQLite 테이블 스키마 조회"""
    sqlite_cursor.execute(f'PRAGMA table_info({table_name})')
    return sqlite_cursor.fetchall()


def get_table_indexes(sqlite_cursor, table_name):
    """SQLite 테이블 인덱스 조회 (UNIQUE 제약조건 포함)"""
    sqlite_cursor.execute(f"PRAGMA index_list({table_name})")
    indexes = sqlite_cursor.fetchall()

    result = []
    unique_constraints = []

    for idx in indexes:
        idx_name = idx['name']
        is_unique = idx['unique']

        # 인덱스 컬럼 조회
        sqlite_cursor.execute(f"PRAGMA index_info({idx_name})")
        columns = [row['name'] for row in sqlite_cursor.fetchall()]

        # autoindex는 UNIQUE 제약조건으로 자동 생성된 것
        if idx_name.startswith('sqlite_autoindex'):
            # UNIQUE 제약조건 (나중에 ALTER TABLE로 추가)
            unique_constraints.append({
                'name': f"uq_{table_name}_{'_'.join(columns)}",
                'unique': True,
                'columns': columns,
                'is_constraint': True
            })
        else:
            result.append({
                'name': idx_name,
                'unique': is_unique,
                'columns': columns,
                'is_constraint': False
            })

    return result + unique_constraints


def convert_sqlite_type_to_mysql(sqlite_type, col_name, table_name, is_pk=False, has_default=False):
    """SQLite 타입을 MySQL 타입으로 변환"""
    sqlite_type_upper = (sqlite_type or '').upper()

    # VARCHAR, DATETIME 등은 그대로 사용
    if 'VARCHAR' in sqlite_type_upper or 'CHAR' in sqlite_type_upper:
        return sqlite_type
    if 'DATETIME' in sqlite_type_upper:
        return 'DATETIME'

    # PRIMARY KEY이거나 기본값이 있는 TEXT(또는 타입없음)는 VARCHAR로 변환 (MySQL 제약)
    if is_pk or has_default:
        # 실제 SQLite 타입이 정수나 날짜형인 경우는 제외 (원래 타입을 유지해야 함)
        if not any(t in sqlite_type_upper for t in ['INTEGER', 'INT', 'DATETIME', 'TIMESTAMP', 'DATE']):
            # 명시적 지정이 있으면 사용, 없으면 기본 255 (PK는 좀 더 짧게 100)
            if table_name in TEXT_PK_VARCHAR_LENGTH and col_name in TEXT_PK_VARCHAR_LENGTH[table_name]:
                length = TEXT_PK_VARCHAR_LENGTH[table_name][col_name]
            elif col_name in COLUMN_VARCHAR_LENGTHS:
                length = COLUMN_VARCHAR_LENGTHS[col_name]
            else:
                length = 100 if is_pk else 500
            return f'VARCHAR({length})'

    # TIMESTAMP → DATETIME
    if 'TIMESTAMP' in sqlite_type_upper:
        return 'DATETIME'

    # INTEGER → INT
    if 'INTEGER' in sqlite_type_upper or 'INT' in sqlite_type_upper:
        return 'INT'

    # REAL → DOUBLE
    if 'REAL' in sqlite_type_upper:
        return 'DOUBLE'

    # BLOB → BLOB
    if 'BLOB' in sqlite_type_upper:
        return 'BLOB'

    return 'TEXT'


def create_mysql_table(mysql_cursor, sqlite_cursor, table_name, schema):
    """MySQL 테이블 생성"""
    columns = []
    primary_keys = []

    for col in schema:
        col_name = col['name']
        is_pk = bool(col['pk'])
        has_default = col['dflt_value'] is not None
        col_type = convert_sqlite_type_to_mysql(col['type'], col_name, table_name, is_pk, has_default)

        # PRIMARY KEY 처리
        if is_pk:
            primary_keys.append(col_name)
            # AUTO_INCREMENT 처리 (INT PK만)
            if col_type == 'INT':
                col_def = f"`{col_name}` {col_type} AUTO_INCREMENT"
            else:
                col_def = f"`{col_name}` {col_type} NOT NULL"
        else:
            col_def = f"`{col_name}` {col_type}"
            # NOT NULL 처리
            if col['notnull']:
                col_def += ' NOT NULL'

        # DEFAULT 처리
        if col['dflt_value'] is not None:
            dflt = col['dflt_value']
            dflt_upper = dflt.upper() if dflt else ''

            # DATETIME/TIMESTAMP 컬럼의 특수 처리
            if 'DATETIME' in col_type.upper() or 'TIMESTAMP' in col_type.upper():
                if 'CURRENT_TIMESTAMP' in dflt_upper or '(' in dflt_upper:
                    col_def += ' DEFAULT CURRENT_TIMESTAMP'
                elif dflt_upper == 'NULL':
                    col_def += ' DEFAULT NULL'
                elif "'" in dflt or '"' in dflt:
                    # '0000-00-00' 같은 잘못된 날짜 형식 필터링
                    if '0000-00-00' in dflt:
                        # 기본값 없이 진행하거나 NULL 허용 시 NULL로
                        pass
                    else:
                        col_def += f" DEFAULT {dflt}"
                else:
                    # 숫자만 있는 경우 등은 그대로
                    col_def += f" DEFAULT {dflt}"
            # 일반 컬럼 처리
            elif dflt_upper == 'NULL':
                col_def += ' DEFAULT NULL'
            elif 'CURRENT_TIMESTAMP' in dflt_upper:
                col_def += ' DEFAULT CURRENT_TIMESTAMP'
            else:
                col_def += f" DEFAULT {dflt}"

        columns.append(col_def)

    # PRIMARY KEY 추가
    if primary_keys:
        pk_cols = ', '.join([f'`{pk}`' for pk in primary_keys])
        columns.append(f"PRIMARY KEY ({pk_cols})")

    create_sql = f"CREATE TABLE IF NOT EXISTS `{table_name}` (\n  " + ",\n  ".join(columns) + "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"

    mysql_cursor.execute(f"DROP TABLE IF EXISTS `{table_name}`")
    mysql_cursor.execute(create_sql)
    print(f"  테이블 생성: {table_name}")

    # 인덱스 생성
    indexes = get_table_indexes(sqlite_cursor, table_name)
    for idx in indexes:
        idx_type = "UNIQUE INDEX" if idx['unique'] else "INDEX"
        idx_cols = ', '.join([f'`{c}`' for c in idx['columns']])
        try:
            mysql_cursor.execute(f"CREATE {idx_type} `{idx['name']}` ON `{table_name}` ({idx_cols})")
            print(f"    인덱스 생성: {idx['name']}")
        except Exception as e:
            print(f"    인덱스 생성 실패 ({idx['name']}): {e}")


def migrate_table_data(sqlite_conn, mysql_conn, table_name):
    """테이블 데이터 마이그레이션"""
    sqlite_cursor = sqlite_conn.cursor()
    mysql_cursor = mysql_conn.cursor()

    # 데이터 조회
    sqlite_cursor.execute(f'SELECT * FROM {table_name}')
    rows = sqlite_cursor.fetchall()

    if not rows:
        print(f"  데이터 없음: {table_name}")
        return 0

    # 컬럼명 가져오기
    columns = [description[0] for description in sqlite_cursor.description]

    # INSERT 쿼리 생성
    placeholders = ', '.join(['%s'] * len(columns))
    column_names = ', '.join([f'`{col}`' for col in columns])
    insert_sql = f"INSERT INTO `{table_name}` ({column_names}) VALUES ({placeholders})"

    # 데이터 삽입
    count = 0
    for row in rows:
        try:
            mysql_cursor.execute(insert_sql, tuple(row))
            count += 1
        except Exception as e:
            print(f"    오류 (row {count}): {str(e)}")
            print(f"    데이터: {dict(row)}")

    mysql_conn.commit()
    print(f"  데이터 마이그레이션 완료: {table_name} ({count}개 행)")
    return count


def print_create_table_sql(table_name, schema, sqlite_cursor):
    """CREATE TABLE SQL 출력 (dry-run용)"""
    columns = []
    primary_keys = []

    for col in schema:
        col_name = col['name']
        is_pk = bool(col['pk'])
        has_default = col['dflt_value'] is not None
        col_type = convert_sqlite_type_to_mysql(col['type'], col_name, table_name, is_pk, has_default)

        if is_pk:
            primary_keys.append(col_name)
            if col_type == 'INT':
                col_def = f"`{col_name}` {col_type} AUTO_INCREMENT"
            else:
                col_def = f"`{col_name}` {col_type} NOT NULL"
        else:
            col_def = f"`{col_name}` {col_type}"
            if col['notnull']:
                col_def += ' NOT NULL'

        if col['dflt_value'] is not None:
            dflt = col['dflt_value']
            dflt_upper = dflt.upper() if dflt else ''
            if 'CURRENT_TIMESTAMP' in dflt_upper:
                col_def += ' DEFAULT CURRENT_TIMESTAMP'
            elif dflt_upper == 'NULL':
                col_def += ' DEFAULT NULL'
            else:
                col_def += f" DEFAULT {dflt}"

        columns.append(col_def)

    if primary_keys:
        pk_cols = ', '.join([f'`{pk}`' for pk in primary_keys])
        columns.append(f"PRIMARY KEY ({pk_cols})")

    create_sql = f"CREATE TABLE `{table_name}` (\n  " + ",\n  ".join(columns) + "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;"
    print(create_sql)

    # 인덱스 출력
    indexes = get_table_indexes(sqlite_cursor, table_name)
    for idx in indexes:
        idx_type = "UNIQUE INDEX" if idx['unique'] else "INDEX"
        idx_cols = ', '.join([f'`{c}`' for c in idx['columns']])
        print(f"CREATE {idx_type} `{idx['name']}` ON `{table_name}` ({idx_cols});")


def get_all_tables(sqlite_conn):
    """모든 테이블 목록 조회 (외래키 순서 고려)"""
    cursor = sqlite_conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
    all_tables = [row['name'] for row in cursor.fetchall()]

    # 정보보호공시 테이블 순서 (외래키 참조 순서)
    disclosure_order = [
        'sb_disclosure_questions',   # 먼저 (참조됨)
        'sb_disclosure_sessions',    # 두번째 (참조됨)
        'sb_disclosure_answers',     # 세번째 (questions 참조)
        'sb_disclosure_evidence',    # 네번째 (answers, questions 참조)
        'sb_disclosure_submissions', # 마지막 (sessions 참조)
    ]

    # 우선순위 테이블을 먼저 배치
    ordered = []
    for table in disclosure_order:
        if table in all_tables:
            ordered.append(table)
            all_tables.remove(table)

    # 나머지 테이블 추가
    ordered.extend(all_tables)

    return ordered


def main():
    import argparse
    parser = argparse.ArgumentParser(description='SQLite에서 MySQL로 데이터 마이그레이션')
    parser.add_argument('--dry-run', action='store_true', help='실제 실행 없이 SQL만 출력')
    parser.add_argument('--disclosure-only', action='store_true', help='정보보호공시 테이블만 마이그레이션')
    parser.add_argument('--tables', nargs='+', help='특정 테이블만 마이그레이션')
    args = parser.parse_args()

    print("=" * 60)
    print("SQLite에서 MySQL로 전체 데이터 마이그레이션")
    if args.dry_run:
        print("  [DRY-RUN 모드]")
    print("=" * 60)

    # 연결
    print("\n[1/4] 데이터베이스 연결 중...")
    sqlite_conn = get_sqlite_connection()

    if args.dry_run:
        mysql_conn = None
        print("  (dry-run: MySQL 연결 건너뜀)")
    else:
        mysql_conn = get_mysql_connection()

    try:
        # 테이블 목록 조회
        print("\n[2/4] 테이블 목록 조회 중...")
        tables = get_all_tables(sqlite_conn)

        # 필터링
        if args.disclosure_only:
            tables = [t for t in tables if t.startswith('sb_disclosure_')]
            print(f"  정보보호공시 테이블만 선택: {len(tables)}개")
        elif args.tables:
            tables = [t for t in tables if t in args.tables]
            print(f"  지정된 테이블만 선택: {len(tables)}개")

        print(f"  총 {len(tables)}개 테이블 발견")
        for t in tables:
            print(f"    - {t}")

        # 스키마 생성
        print("\n[3/4] MySQL 테이블 생성 중...")
        sqlite_cursor = sqlite_conn.cursor()

        if args.dry_run:
            # Dry-run: SQL만 출력
            for table in tables:
                schema = get_table_schema(sqlite_cursor, table)
                print(f"\n-- 테이블: {table}")
                print_create_table_sql(table, schema, sqlite_cursor)
        else:
            mysql_cursor = mysql_conn.cursor()
            for table in tables:
                schema = get_table_schema(sqlite_cursor, table)
                create_mysql_table(mysql_cursor, sqlite_cursor, table, schema)
            mysql_conn.commit()

        # 데이터 마이그레이션
        print("\n[4/4] 데이터 마이그레이션 중...")
        total_rows = 0

        if args.dry_run:
            for table in tables:
                sqlite_cursor.execute(f'SELECT COUNT(*) as cnt FROM {table}')
                cnt = sqlite_cursor.fetchone()['cnt']
                print(f"  {table}: {cnt}개 행 (dry-run)")
                total_rows += cnt
        else:
            for table in tables:
                count = migrate_table_data(sqlite_conn, mysql_conn, table)
                total_rows += count

        print("\n" + "=" * 60)
        if args.dry_run:
            print(f"[DRY-RUN 완료] 마이그레이션 예정:")
        else:
            print(f"[완료] 마이그레이션이 성공적으로 완료되었습니다!")
        print(f"  총 {len(tables)}개 테이블, {total_rows}개 행 {'예정' if args.dry_run else '마이그레이션'}")
        print("=" * 60)

    except Exception as e:
        print(f"\n[오류] 오류 발생: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

    finally:
        sqlite_conn.close()
        if mysql_conn:
            mysql_conn.close()


if __name__ == '__main__':
    main()
