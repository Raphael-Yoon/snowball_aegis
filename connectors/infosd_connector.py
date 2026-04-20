"""
Infosd 시스템 커넥터 (정보보호공시 시스템)

infosd.db 스키마:
  - isd_user         : 사용자 (id, user_name, user_email, is_admin,
                               effective_start_date, effective_end_date, last_login_at)
  - isd_sessions     : 공시 세션 (company_id, year, status, submitted_at)
  - isd_submissions  : 공시 제출 (session_id, submitted_at, status)
  - isd_answers      : 답변 (question_id, company_id, year, status, deleted_at)

적용 가능한 ITGC 통제:
  APD-01  사용자 계정 생성   - 최근 생성 계정 목록 (7일 이내)
  APD-03  계정 비활성화      - effective_end_date 경과했으나 마지막 로그인이 최근인 계정
  APD-04  주기적 접근권한 검토 - 90일 이상 미로그인 활성 계정
  CO-01   배치/운영 모니터링  - 제출 완료 후 status 불일치 세션
"""
import sqlite3
from datetime import date, timedelta
from pathlib import Path
from .base_connector import BaseConnector


class InfosdConnector(BaseConnector):

    IMPLEMENTED_CONTROLS = frozenset(['APD-01', 'APD-03', 'APD-04', 'CO-01'])

    def _conn(self):
        db_path = Path(self.system.get('db_path', ''))
        if not db_path.exists():
            raise FileNotFoundError(f"infosd DB 없음: {db_path}")
        conn = sqlite3.connect(str(db_path))
        conn.row_factory = sqlite3.Row
        return conn

    # ------------------------------------------------------------------
    # APD-01  사용자 계정 생성 및 부여
    # 점검: 최근 7일 이내 신규 생성 계정 목록 제공 (정기 검토용)
    # 예외: 신규 생성 계정 자체를 예외로 분류 (승인 증빙 검토 필요)
    # ------------------------------------------------------------------
    def check_APD01(self) -> dict:
        since = (date.fromisoformat(self.run_date) - timedelta(days=7)).isoformat()
        conn = self._conn()
        try:
            rows = conn.execute('''
                SELECT id, user_name, user_email, is_admin,
                       effective_start_date, created_at
                FROM isd_user
                WHERE DATE(effective_start_date) >= ?
                   OR DATE(created_at) >= ?
                ORDER BY effective_start_date DESC
            ''', (since, since)).fetchall()
            rows = [dict(r) for r in rows]
            return self.result(
                rows=rows,
                total_count=len(rows),
                message=f"최근 7일 신규 계정 {len(rows)}건 (승인 증빙 검토 필요)" if rows else "최근 7일 신규 계정 없음"
            )
        finally:
            conn.close()

    # ------------------------------------------------------------------
    # APD-03  사용자 계정 삭제 및 비활성화
    # 점검: effective_end_date가 오늘 이전인데 최근 로그인 이력이 있는 계정
    # 예외: 만료됐으나 last_login_at이 만료일 이후인 계정
    # ------------------------------------------------------------------
    def check_APD03(self) -> dict:
        today = self.run_date
        conn = self._conn()
        try:
            rows = conn.execute('''
                SELECT id, user_name, user_email,
                       effective_end_date, last_login_at
                FROM isd_user
                WHERE effective_end_date IS NOT NULL
                  AND DATE(effective_end_date) < ?
                  AND last_login_at IS NOT NULL
                  AND DATE(last_login_at) > DATE(effective_end_date)
                ORDER BY last_login_at DESC
            ''', (today,)).fetchall()
            rows = [dict(r) for r in rows]
            total = conn.execute(
                'SELECT COUNT(*) as cnt FROM isd_user WHERE effective_end_date IS NOT NULL AND DATE(effective_end_date) < ?',
                (today,)
            ).fetchone()
            return self.result(
                rows=rows,
                total_count=dict(total)['cnt'] if total else 0,
                message=f"만료 후 로그인 계정 {len(rows)}건" if rows else "만료 후 로그인 이력 없음"
            )
        finally:
            conn.close()

    # ------------------------------------------------------------------
    # APD-04  주기적 접근권한 검토
    # 점검: 활성 상태(end_date 없거나 미래)이지만 90일 이상 미로그인 계정
    # 예외: 휴면 가능성 있는 계정 → 접근권한 재검토 대상
    # ------------------------------------------------------------------
    def check_APD04(self) -> dict:
        today = date.fromisoformat(self.run_date)
        cutoff = (today - timedelta(days=90)).isoformat()
        conn = self._conn()
        try:
            rows = conn.execute('''
                SELECT id, user_name, user_email, last_login_at,
                       effective_start_date, effective_end_date
                FROM isd_user
                WHERE (effective_end_date IS NULL OR DATE(effective_end_date) >= ?)
                  AND (last_login_at IS NULL OR DATE(last_login_at) < ?)
                ORDER BY last_login_at ASC
            ''', (self.run_date, cutoff)).fetchall()
            rows = [dict(r) for r in rows]

            total = conn.execute('''
                SELECT COUNT(*) as cnt FROM isd_user
                WHERE effective_end_date IS NULL OR DATE(effective_end_date) >= ?
            ''', (self.run_date,)).fetchone()

            return self.result(
                rows=rows,
                total_count=dict(total)['cnt'] if total else 0,
                message=f"90일 이상 미로그인 활성 계정 {len(rows)}건" if rows else "90일 이상 미로그인 계정 없음"
            )
        finally:
            conn.close()

    # ------------------------------------------------------------------
    # CO-01  배치 작업 모니터링
    # 점검: submitted_at이 있으나 status가 'completed'가 아닌 세션
    # 예외: 제출 완료 처리가 안 된 세션 (처리 지연 또는 오류)
    # ------------------------------------------------------------------
    def check_CO01(self) -> dict:
        conn = self._conn()
        try:
            total = conn.execute(
                "SELECT COUNT(*) as cnt FROM isd_sessions WHERE submitted_at IS NOT NULL"
            ).fetchone()

            rows = conn.execute('''
                SELECT s.id, s.company_id, s.year, s.status,
                       s.submitted_at, c.company_name
                FROM isd_sessions s
                LEFT JOIN isd_companies c ON s.company_id = c.id
                WHERE s.submitted_at IS NOT NULL
                  AND s.status != 'completed'
                ORDER BY s.submitted_at DESC
            ''').fetchall()
            rows = [dict(r) for r in rows]

            return self.result(
                rows=rows,
                total_count=dict(total)['cnt'] if total else 0,
                message=f"처리 미완료 세션 {len(rows)}건" if rows else "모든 제출 세션 정상 처리됨"
            )
        finally:
            conn.close()
