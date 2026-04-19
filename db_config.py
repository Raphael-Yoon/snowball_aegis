"""
데이터베이스 설정 및 연결 관리
SQLite와 MySQL을 환경에 따라 자동 전환
"""
import os
from contextlib import contextmanager

# 환경 변수에서 데이터베이스 타입 결정
DB_TYPE = os.getenv('DB_TYPE', 'sqlite')  # 기본값: sqlite

# SQLite 설정
# 항상 이 파일이 위치한 디렉토리(snowball)에 DB 파일 생성
_DB_DIR = os.path.dirname(os.path.abspath(__file__))
_DEFAULT_SQLITE_PATH = os.path.join(_DB_DIR, 'snowball.db')
SQLITE_DATABASE = os.getenv('SQLITE_DB_PATH', _DEFAULT_SQLITE_PATH)

# MySQL 설정 (환경 변수에서 로드)
MYSQL_CONFIG = {
    'host': os.getenv('MYSQL_HOST', 'itap.mysql.pythonanywhere-services.com'),
    'user': os.getenv('MYSQL_USER', 'itap'),
    'password': os.getenv('MYSQL_PASSWORD', ''),
    'database': os.getenv('MYSQL_DATABASE', 'itap$snowball'),
    'port': int(os.getenv('MYSQL_PORT', '3306')),
    'charset': 'utf8mb4',
    'connect_timeout': 10,
}

def get_db_connection():
    """
    환경에 따라 SQLite 또는 MySQL 연결 반환
    """
    if DB_TYPE == 'mysql':
        import pymysql
        import pymysql.cursors

        conn = pymysql.connect(
            host=MYSQL_CONFIG['host'],
            user=MYSQL_CONFIG['user'],
            password=MYSQL_CONFIG['password'],
            database=MYSQL_CONFIG['database'],
            port=MYSQL_CONFIG['port'],
            charset=MYSQL_CONFIG['charset'],
            cursorclass=pymysql.cursors.DictCursor,
            connect_timeout=MYSQL_CONFIG['connect_timeout'],
            autocommit=False
        )
        return MySQLConnection(conn)
    else:
        import sqlite3
        conn = sqlite3.connect(SQLITE_DATABASE)
        conn.row_factory = sqlite3.Row
        return SQLiteConnection(conn)

class SQLiteConnection:
    """SQLite 연결 래퍼 (기존 동작 유지)"""
    def __init__(self, conn):
        self.conn = conn
        self._in_transaction = False

    def execute(self, query, params=None):
        cursor = self.conn.execute(query, params or ())
        return cursor

    def commit(self):
        self.conn.commit()

    def rollback(self):
        self.conn.rollback()

    def close(self):
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        self.close()

class MySQLConnection:
    """MySQL 연결 래퍼 (SQLite와 동일한 인터페이스 제공)"""
    def __init__(self, conn):
        self.conn = conn
        self._cursor = None

    def execute(self, query, params=None):
        """쿼리 실행 (SQLite 호환)"""
        # SQLite 스타일 파라미터(?)를 MySQL 스타일(%s)로 변환
        if params and '?' in query:
            query = query.replace('?', '%s')

        cursor = self.conn.cursor()
        cursor.execute(query, params or ())
        self._cursor = cursor
        return MySQLCursor(cursor)

    def commit(self):
        self.conn.commit()

    def rollback(self):
        self.conn.rollback()

    def close(self):
        if self._cursor:
            self._cursor.close()
        self.conn.close()

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type:
            self.rollback()
        self.close()

class MySQLCursor:
    """MySQL 커서 래퍼 (SQLite Row 인터페이스 제공)"""
    def __init__(self, cursor):
        self.cursor = cursor
        self.lastrowid = cursor.lastrowid
        self.rowcount = cursor.rowcount

    def fetchone(self):
        row = self.cursor.fetchone()
        return DictRow(row) if row else None

    def fetchall(self):
        rows = self.cursor.fetchall()
        return [DictRow(row) for row in rows]

    def __iter__(self):
        for row in self.cursor:
            yield DictRow(row)

class DictRow(dict):
    """딕셔너리를 SQLite Row처럼 사용 가능하게 하는 래퍼"""
    def __getitem__(self, key):
        if isinstance(key, int):
            # 인덱스 접근 지원
            return list(self.values())[key]
        return super().__getitem__(key)

@contextmanager
def get_db():
    """
    컨텍스트 매니저로 데이터베이스 연결 제공
    기존 코드와 호환성 유지
    """
    conn = get_db_connection()
    try:
        yield conn
    finally:
        conn.close()

def get_db_type():
    """현재 사용 중인 데이터베이스 타입 반환"""
    return DB_TYPE

def is_mysql():
    """MySQL 사용 여부"""
    return DB_TYPE == 'mysql'

def is_sqlite():
    """SQLite 사용 여부"""
    return DB_TYPE == 'sqlite'
