"""
Generic 커넥터 - SQL 쿼리 기반 폴백

커넥터가 별도로 구현되지 않은 시스템에 사용.
aegis_control.monitor_query 또는 aegis_control_system.custom_query를
직접 실행하고 결과를 반환한다.
"""
import sqlite3
from pathlib import Path
from .base_connector import BaseConnector


class GenericConnector(BaseConnector):

    def __init__(self, system: dict, control_code: str = '', query: str = '', threshold: int = 0):
        super().__init__(system)
        self._control_code = control_code
        self._query = query
        self._threshold = threshold

    def _conn(self):
        db_type = self.system.get('db_type', 'sqlite')
        if db_type == 'sqlite':
            db_path = Path(self.system.get('db_path', ''))
            if not db_path.exists():
                raise FileNotFoundError(f"DB 파일 없음: {db_path}")
            conn = sqlite3.connect(str(db_path))
            conn.row_factory = sqlite3.Row
            return conn
        elif db_type in ('mysql', 'mariadb'):
            import pymysql
            import pymysql.cursors
            return pymysql.connect(
                host=self.system['db_host'],
                port=int(self.system.get('db_port') or 3306),
                user=self.system['db_user'],
                password=self.system['db_password'],
                database=self.system['db_name'],
                charset='utf8mb4',
                cursorclass=pymysql.cursors.DictCursor,
                connect_timeout=10,
            )
        raise ValueError(f"지원하지 않는 DB 타입: {db_type}")

    def run(self, control_code: str) -> dict:
        if not self._query or not self._query.strip():
            return self.not_implemented(control_code)
        try:
            conn = self._conn()
            try:
                if hasattr(conn, 'cursor'):
                    cur = conn.cursor()
                    cur.execute(self._query)
                    rows = [dict(r) for r in cur.fetchall()]
                else:
                    rows = [dict(r) for r in conn.execute(self._query).fetchall()]
            finally:
                conn.close()

            return self.result(
                rows=rows,
                total_count=len(rows),
                message=f"쿼리 실행 결과 {len(rows)}건"
            )
        except Exception as e:
            return {
                'exception_count': 0,
                'total_count': 0,
                'rows': [],
                'message': f'[오류] {str(e)}',
            }
