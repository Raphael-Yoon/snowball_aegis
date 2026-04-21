import sqlite3
import random
import string
from datetime import datetime, timedelta
from functools import wraps
from flask import session, redirect, url_for, request, flash
import os
from dotenv import load_dotenv

load_dotenv()

USE_MYSQL = os.getenv('USE_MYSQL', 'false').lower() == 'true' or os.getenv('DB_TYPE', 'sqlite').lower() == 'mysql'
_DB_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE = os.getenv('SQLITE_DB_PATH', os.path.join(_DB_DIR, 'snowball.db'))

class IndexableDict(dict):
    def __getitem__(self, key):
        if isinstance(key, int):
            try: return list(self.values())[key]
            except IndexError: raise
        return super().__getitem__(key)

class DatabaseCursor:
    def __init__(self, cursor, db_conn):
        self._cursor = cursor
        self._db_conn = db_conn

    def fetchone(self):
        row = self._cursor.fetchone()
        converted = self._db_conn._convert_datetime_to_string(row)
        if converted and isinstance(converted, dict) and not isinstance(converted, IndexableDict):
            return IndexableDict(converted)
        return converted

    def fetchall(self):
        rows = self._cursor.fetchall()
        return [IndexableDict(self._db_conn._convert_datetime_to_string(r)) if isinstance(r, dict) else r for r in rows]

    @property
    def rowcount(self): return self._cursor.rowcount
    @property
    def lastrowid(self): return self._cursor.lastrowid

class DatabaseConnection:
    def __init__(self, conn, is_mysql=False):
        self._conn = conn
        self._is_mysql = is_mysql

    def _convert_datetime_to_string(self, row):
        if not self._is_mysql or not row: return row
        from datetime import datetime, date
        if hasattr(row, 'keys'):
            result = dict(row)
            for key in result:
                if isinstance(result[key], datetime): result[key] = result[key].strftime('%Y-%m-%d %H:%M:%S')
                elif isinstance(result[key], date): result[key] = result[key].strftime('%Y-%m-%d')
            return result
        return row

    def execute(self, query, params=None):
        if self._is_mysql:
            if params is not None:
                if isinstance(params, list): params = tuple(params)
                elif not isinstance(params, tuple): params = (params,)
            cursor = self._conn.cursor()
            cursor.execute(query, params or ())
            return DatabaseCursor(cursor, self)
        else:
            if '%s' in query: query = query.replace('%s', '?')
            return self._conn.execute(query, params or ())

    def commit(self): self._conn.commit()
    def close(self): self._conn.close()
    def __enter__(self): return self
    def __exit__(self, exc_type, exc_val, exc_tb):
        if exc_type is None: self._conn.commit()
        self._conn.close()

def _get_first_value(row):
    if row is None: return None
    if isinstance(row, dict): return next(iter(row.values()), None)
    return row[0]

def get_db():
    if USE_MYSQL:
        import pymysql
        conn = pymysql.connect(
            host=os.getenv('MYSQL_HOST', 'localhost'),
            user=os.getenv('MYSQL_USER', 'root'),
            password=os.getenv('MYSQL_PASSWORD', ''),
            database=os.getenv('MYSQL_DATABASE', 'snowball'),
            port=int(os.getenv('MYSQL_PORT', '3306')),
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor
        )
        return DatabaseConnection(conn, is_mysql=True)
    conn = sqlite3.connect(DATABASE); conn.row_factory = sqlite3.Row
    return DatabaseConnection(conn, is_mysql=False)

def find_user_by_email(email):
    with get_db() as conn:
        now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        user = conn.execute('SELECT * FROM sb_user WHERE user_email = %s AND effective_start_date <= %s AND (effective_end_date IS NULL OR effective_end_date >= %s)', (email, now, now)).fetchone()
        return dict(user) if user else None

def send_otp(user_email, method='email'):
    user = find_user_by_email(user_email)
    if not user: return False, "등록되지 않은 사용자입니다."
    otp_code = ''.join(random.choices(string.digits, k=6))
    expires_at = datetime.now() + timedelta(minutes=5)
    with get_db() as conn:
        conn.execute('UPDATE sb_user SET otp_code = %s, otp_expires_at = %s, otp_attempts = 0 WHERE user_email = %s', (otp_code, expires_at, user_email))
        conn.commit()
    if method == 'email':
        try:
            from snowball_mail import send_gmail
            send_gmail(user_email, "[Aegis] 인증 코드", f"인증 코드: {otp_code}")
            return True, "인증 코드가 전송되었습니다."
        except ImportError:
            print(f"[OTP] {user_email} -> {otp_code}"); return True, "인증 코드가 전송되었습니다. (콘솔 확인)"
    return True, "인증 완료 (테스트)"

def verify_otp(email, otp_code):
    user = find_user_by_email(email)
    if not user: return False, "사용자 없음"
    if not user['otp_expires_at'] or datetime.now() > datetime.fromisoformat(user['otp_expires_at']):
        return False, "만료됨"
    if user['otp_code'] == otp_code:
        with get_db() as conn:
            conn.execute('UPDATE sb_user SET otp_code = NULL, last_login_date = CURRENT_TIMESTAMP WHERE user_email = %s', (email,))
        return True, dict(user)
    return False, "코드 불일치"

def login_required(f):
    @wraps(f)
    def dec(*args, **kwargs):
        if 'user_id' not in session: return redirect(url_for('login'))
        return f(*args, **kwargs)
    return dec

def admin_required(f):
    @wraps(f)
    def dec(*args, **kwargs):
        if 'user_id' not in session:
            flash('관리자 로그인이 필요합니다.', 'error')
            return redirect(url_for('login'))
        user = get_current_user()
        if not user or user.get('admin_flag') != 'Y':
            flash('관리자 권한이 없습니다.', 'error')
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return dec

def get_current_user():
    user_id = session.get('user_id')
    if not user_id: return None
    with get_db() as conn:
        user = conn.execute('SELECT * FROM sb_user WHERE user_id = %s', (user_id,)).fetchone()
        return dict(user) if user else None

def log_user_activity(user_info, action_type, page_name, url_path, ip_address, user_agent, additional_info=None):
    if not user_info: return
    try:
        with get_db() as conn:
            conn.execute('INSERT INTO sb_user_activity_log (user_id, user_email, user_name, action_type, page_name, url_path, ip_address, user_agent, additional_info) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)', 
                        (user_info.get('user_id'), user_info.get('user_email'), user_info.get('user_name'), action_type, page_name, url_path, ip_address, user_agent[:500], str(additional_info)))
    except: pass

def get_user_activity_logs(limit=100, offset=0, user_id=None):
    with get_db() as conn:
        q = 'SELECT * FROM sb_user_activity_log'
        if user_id: q += f' WHERE user_id = {user_id}'
        q += f' ORDER BY access_time DESC LIMIT {limit} OFFSET {offset}'
        return [dict(r) for r in conn.execute(q).fetchall()]

def get_activity_log_count(user_id=None):
    with get_db() as conn:
        q = 'SELECT COUNT(*) FROM sb_user_activity_log'
        if user_id: q += f' WHERE user_id = {user_id}'
        return _get_first_value(conn.execute(q).fetchone()) or 0
