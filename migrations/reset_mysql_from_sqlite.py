"""
MySQL 운영 서버 초기화 및 SQLite 데이터 마이그레이션
- MySQL의 모든 테이블 삭제
- SQLite의 스키마를 기반으로 MySQL 테이블 재생성
- SQLite의 모든 데이터를 MySQL로 이관

주의: 이 스크립트는 MySQL의 모든 데이터를 삭제합니다!
"""

import sqlite3
import pymysql
import sys
import os
from datetime import datetime

# .env 파일 로드
def load_env():
    """프로젝트 루트의 .env 파일을 로드"""
    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), '.env')
    if os.path.exists(env_path):
        with open(env_path, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    # 환경변수에 없으면 .env 값 사용
                    if not os.getenv(key.strip()):
                        os.environ[key.strip()] = value.strip()

load_env()

# 환경 변수에서 MySQL 설정 로드
MYSQL_CONFIG = {
    'host': os.getenv('MYSQL_HOST', 'itap.mysql.pythonanywhere-services.com'),
    'user': os.getenv('MYSQL_USER', 'itap'),
    'password': os.getenv('MYSQL_PASSWORD'),  # None if not set
    'database': os.getenv('MYSQL_DATABASE', 'itap$snowball'),
    'port': int(os.getenv('MYSQL_PORT', '3306')),
    'charset': 'utf8mb4',
    'connect_timeout': 10,
}

# SQLite 데이터베이스 경로
SQLITE_DB = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'snowball.db')

# 마이그레이션 제외 테이블
EXCLUDED_TABLES = ['sqlite_sequence', 'temp']


def convert_sql_type(sqlite_type):
    """SQLite 데이터 타입을 MySQL 타입으로 변환"""
    type_mapping = {
        'INTEGER': 'INT',
        'TEXT': 'TEXT',
        'REAL': 'DOUBLE',
        'BLOB': 'LONGBLOB',
        'TIMESTAMP': 'DATETIME',
        'DATETIME': 'DATETIME',
        'DATE': 'DATE',
        'BOOLEAN': 'TINYINT(1)'
    }

    sqlite_type_upper = sqlite_type.upper()
    for sqlite_key, mysql_type in type_mapping.items():
        if sqlite_key in sqlite_type_upper:
            return mysql_type
    return 'TEXT'


def get_table_schema(sqlite_conn, table_name):
    """SQLite 테이블 스키마 조회"""
    cursor = sqlite_conn.execute(f"PRAGMA table_info({table_name})")
    columns = cursor.fetchall()
    return columns


def drop_all_mysql_tables(mysql_conn):
    """MySQL의 모든 테이블 및 뷰 삭제"""
    cursor = mysql_conn.cursor()

    # 외래 키 제약 조건 비활성화
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0")

    print("\n" + "=" * 80)
    print("MySQL 테이블 및 뷰 삭제 시작")
    print("=" * 80)

    # 모든 뷰 삭제 (먼저 뷰를 삭제)
    cursor.execute("""
        SELECT TABLE_NAME
        FROM information_schema.VIEWS
        WHERE TABLE_SCHEMA = DATABASE()
    """)
    views = cursor.fetchall()

    for view_tuple in views:
        if isinstance(view_tuple, dict):
            view_name = list(view_tuple.values())[0]
        else:
            view_name = view_tuple[0]
        print(f"🗑️  뷰 삭제: {view_name}")
        cursor.execute(f"DROP VIEW IF EXISTS `{view_name}`")

    # 모든 테이블 조회
    cursor.execute("SHOW TABLES")
    tables = cursor.fetchall()

    for table_tuple in tables:
        # tuple 또는 dict 모두 처리
        if isinstance(table_tuple, dict):
            table_name = list(table_tuple.values())[0]
        else:
            table_name = table_tuple[0]
        print(f"🗑️  테이블 삭제: {table_name}")
        cursor.execute(f"DROP TABLE IF EXISTS `{table_name}`")

    # 외래 키 제약 조건 재활성화
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1")
    mysql_conn.commit()

    print(f"\n✅ 총 {len(views)}개 뷰, {len(tables)}개 테이블 삭제 완료\n")


def create_mysql_table(mysql_conn, table_name, columns):
    """MySQL 테이블 생성"""
    cursor = mysql_conn.cursor()

    # CREATE TABLE 문 생성
    col_definitions = []
    primary_keys = []

    for col in columns:
        col_id, col_name, col_type, not_null, default_val, is_pk = col

        mysql_type = convert_sql_type(col_type)

        # 컬럼 정의
        col_def = f"`{col_name}` {mysql_type}"

        # PRIMARY KEY인 경우 AUTO_INCREMENT 추가
        if is_pk and 'INT' in mysql_type:
            col_def += " AUTO_INCREMENT"
            primary_keys.append(col_name)

        # NOT NULL
        if not_null and not is_pk:
            col_def += " NOT NULL"

        # DEFAULT 값
        if default_val is not None:
            if default_val == 'CURRENT_TIMESTAMP':
                col_def += " DEFAULT CURRENT_TIMESTAMP"
            elif isinstance(default_val, str) and default_val.replace('.', '').replace('-', '').isdigit():
                col_def += f" DEFAULT {default_val}"
            else:
                col_def += f" DEFAULT '{default_val}'"

        col_definitions.append(col_def)

    # PRIMARY KEY 추가
    if primary_keys:
        col_definitions.append(f"PRIMARY KEY (`{'`, `'.join(primary_keys)}`)")

    create_sql = f"CREATE TABLE `{table_name}` (\n  " + ",\n  ".join(col_definitions) + "\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci"

    print(f"\n📋 테이블 생성: {table_name}")
    cursor.execute(create_sql)
    mysql_conn.commit()


def migrate_table_data(sqlite_conn, mysql_conn, table_name):
    """테이블 데이터 마이그레이션"""
    # SQLite에서 데이터 조회
    sqlite_cursor = sqlite_conn.execute(f"SELECT * FROM {table_name}")
    rows = sqlite_cursor.fetchall()

    if not rows:
        print(f"   ⚠️  데이터 없음")
        return 0

    # 컬럼 이름 가져오기
    columns = [description[0] for description in sqlite_cursor.description]

    # MySQL에 데이터 삽입
    mysql_cursor = mysql_conn.cursor()

    placeholders = ', '.join(['%s'] * len(columns))
    column_names = ', '.join([f"`{col}`" for col in columns])
    insert_sql = f"INSERT INTO `{table_name}` ({column_names}) VALUES ({placeholders})"

    # 배치 단위로 데이터 삽입
    batch_size = 1000
    total_inserted = 0

    for i in range(0, len(rows), batch_size):
        batch = rows[i:i + batch_size]
        mysql_cursor.executemany(insert_sql, batch)
        mysql_conn.commit()
        total_inserted += len(batch)

        if len(rows) > batch_size:
            print(f"   📦 {total_inserted}/{len(rows)} rows 삽입 중...")

    print(f"   ✅ {total_inserted} rows 삽입 완료")
    return total_inserted


def migrate_all_tables():
    """모든 테이블 마이그레이션"""
    # UTF-8 출력 설정 (Windows용)
    if sys.platform == 'win32':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

    print("\n" + "=" * 80)
    print("SQLite → MySQL 완전 마이그레이션")
    print("=" * 80)
    print(f"SQLite DB: {SQLITE_DB}")
    print(f"MySQL Host: {MYSQL_CONFIG['host']}")
    print(f"MySQL DB: {MYSQL_CONFIG['database']}")
    print("=" * 80)

    # 연결 확인
    if not os.path.exists(SQLITE_DB):
        print(f"\n❌ SQLite 데이터베이스를 찾을 수 없습니다: {SQLITE_DB}")
        return

    # SQLite 연결
    print("\n🔌 SQLite 연결 중...")
    sqlite_conn = sqlite3.connect(SQLITE_DB)
    print("✅ SQLite 연결 성공")

    # MySQL 연결
    print(f"🔌 MySQL 연결 중... ({MYSQL_CONFIG['host']})")
    try:
        mysql_conn = pymysql.connect(**MYSQL_CONFIG)
        print("✅ MySQL 연결 성공")
    except Exception as e:
        print(f"❌ MySQL 연결 실패: {e}")
        sqlite_conn.close()
        return

    try:
        # 1. MySQL의 모든 테이블 삭제
        drop_all_mysql_tables(mysql_conn)

        # 2. SQLite에서 모든 테이블 조회
        cursor = sqlite_conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        )
        tables = [row[0] for row in cursor.fetchall() if row[0] not in EXCLUDED_TABLES]

        print("=" * 80)
        print(f"마이그레이션 대상 테이블: {len(tables)}개")
        print("=" * 80)

        total_rows = 0
        success_count = 0

        # 3. 각 테이블 마이그레이션
        for i, table_name in enumerate(tables, 1):
            print(f"\n[{i}/{len(tables)}] {table_name}")
            print("-" * 80)

            try:
                # 스키마 조회
                columns = get_table_schema(sqlite_conn, table_name)

                # MySQL 테이블 생성
                create_mysql_table(mysql_conn, table_name, columns)

                # 데이터 마이그레이션
                row_count = migrate_table_data(sqlite_conn, mysql_conn, table_name)
                total_rows += row_count
                success_count += 1

            except Exception as e:
                print(f"   ❌ 오류 발생: {e}")
                import traceback
                traceback.print_exc()

        # 최종 결과
        print("\n" + "=" * 80)
        print("마이그레이션 완료")
        print("=" * 80)
        print(f"✅ 성공: {success_count}/{len(tables)} 테이블")
        print(f"📊 총 마이그레이션된 데이터: {total_rows:,} rows")
        print("=" * 80)

    except Exception as e:
        print(f"\n❌ 마이그레이션 중 오류 발생: {e}")
        import traceback
        traceback.print_exc()

    finally:
        # 연결 종료
        sqlite_conn.close()
        mysql_conn.close()
        print("\n🔌 데이터베이스 연결 종료")


def verify_migration():
    """마이그레이션 결과 검증"""
    print("\n" + "=" * 80)
    print("마이그레이션 결과 검증")
    print("=" * 80)

    sqlite_conn = sqlite3.connect(SQLITE_DB)
    mysql_conn = pymysql.connect(**MYSQL_CONFIG)

    try:
        # SQLite 테이블 목록
        sqlite_cursor = sqlite_conn.execute(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"
        )
        sqlite_tables = {row[0]: 0 for row in sqlite_cursor.fetchall() if row[0] not in EXCLUDED_TABLES}

        # 각 테이블의 row 수 카운트
        for table in sqlite_tables.keys():
            count = sqlite_conn.execute(f"SELECT COUNT(*) FROM {table}").fetchone()[0]
            sqlite_tables[table] = count

        # MySQL 테이블 목록
        mysql_cursor = mysql_conn.cursor()
        mysql_cursor.execute("SHOW TABLES")
        mysql_tables = {}
        for row in mysql_cursor.fetchall():
            # tuple 또는 dict 모두 처리
            if isinstance(row, dict):
                table_name = list(row.values())[0]
            else:
                table_name = row[0]
            mysql_cursor.execute(f"SELECT COUNT(*) FROM `{table_name}`")
            count = mysql_cursor.fetchone()
            # tuple 또는 dict 모두 처리
            if isinstance(count, dict):
                mysql_tables[table_name] = list(count.values())[0]
            else:
                mysql_tables[table_name] = count[0]

        # 비교 결과 출력
        print(f"\n{'테이블명':<40} {'SQLite':<15} {'MySQL':<15} {'상태':<10}")
        print("-" * 80)

        all_match = True
        for table_name in sorted(sqlite_tables.keys()):
            sqlite_count = sqlite_tables[table_name]
            mysql_count = mysql_tables.get(table_name, 0)
            status = "✅" if sqlite_count == mysql_count else "❌"

            if sqlite_count != mysql_count:
                all_match = False

            print(f"{table_name:<40} {sqlite_count:<15,} {mysql_count:<15,} {status:<10}")

        print("-" * 80)
        if all_match:
            print("✅ 모든 테이블 데이터가 정확히 마이그레이션되었습니다!")
        else:
            print("⚠️  일부 테이블의 데이터 개수가 일치하지 않습니다.")

    finally:
        sqlite_conn.close()
        mysql_conn.close()


if __name__ == '__main__':
    # UTF-8 출력 설정
    if sys.platform == 'win32':
        import io
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

    # 비밀번호가 환경변수에 없으면 입력받기
    if not MYSQL_CONFIG['password']:
        import getpass
        MYSQL_CONFIG['password'] = getpass.getpass("MySQL 비밀번호를 입력하세요: ")

    print("\n⚠️  경고: 이 스크립트는 MySQL의 모든 테이블을 삭제합니다!")
    print(f"대상 서버: {MYSQL_CONFIG['host']}")
    print(f"대상 데이터베이스: {MYSQL_CONFIG['database']}")

    response = input("\n계속하시겠습니까? (yes/no): ")

    if response.lower() == 'yes':
        migrate_all_tables()

        # 검증 수행
        verify_response = input("\n마이그레이션 결과를 검증하시겠습니까? (yes/no): ")
        if verify_response.lower() == 'yes':
            verify_migration()
    else:
        print("취소되었습니다.")
