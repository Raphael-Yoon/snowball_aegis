"""
Trade 시스템 커넥터

trade.db 스키마:
  - my_stocks      : 보유 종목 (code, name, added_at, purchase_price, quantity, stop_loss_ratio)
  - stocks_master  : 종목 마스터 (code, name, market)
  - analysis_results: AI 분석 배치 결과 (filename, market, created_at, drive_link, ai_result)
  - watchlist      : 관심 종목
  - portfolio_ai_cache: AI 캐시

적용 가능한 ITGC 통제:
  CO-01  배치 작업 모니터링  - 당일 AI 분석 배치(analysis_results) 수행 여부
  CO-02  백업 수행 확인      - 당일 Drive 동기화(drive_link 존재) 여부
"""
import sqlite3
from datetime import date, timedelta
from pathlib import Path
from .base_connector import BaseConnector


class TradeConnector(BaseConnector):

    IMPLEMENTED_CONTROLS = frozenset(['CO-01', 'CO-02'])

    def _conn(self):
        db_path = Path(self.system.get('db_path', ''))
        if not db_path.exists():
            raise FileNotFoundError(f"trade DB 없음: {db_path}")
        conn = sqlite3.connect(str(db_path))
        conn.row_factory = sqlite3.Row
        return conn

    # ------------------------------------------------------------------
    # CO-01  배치 작업 모니터링
    # 점검: 당일 AI 분석 배치(analysis_results)가 정상 수행됐는가?
    # 예외: created_at이 오늘 날짜인 레코드가 없으면 배치 미수행으로 간주
    # ------------------------------------------------------------------
    def check_CO01(self) -> dict:
        today = self.run_date  # 'YYYY-MM-DD'
        conn = self._conn()
        try:
            rows = conn.execute('''
                SELECT filename, market, created_at, size, drive_link
                FROM analysis_results
                WHERE DATE(created_at) = ?
                ORDER BY created_at DESC
            ''', (today,)).fetchall()
            rows = [dict(r) for r in rows]

            if rows:
                return self.result(
                    rows=[],          # 정상 수행 → 예외 없음
                    total_count=len(rows),
                    message=f"당일 AI 분석 배치 {len(rows)}건 수행 완료"
                )
            else:
                # 배치 미수행 = 예외 1건
                return self.result(
                    rows=[{'date': today, 'status': '배치 미수행', 'note': 'analysis_results에 당일 레코드 없음'}],
                    total_count=0,
                    message="당일 AI 분석 배치 미수행"
                )
        finally:
            conn.close()

    # ------------------------------------------------------------------
    # CO-02  백업 수행 확인
    # 점검: 당일 분석 결과에 drive_link가 채워져 있는가? (Drive 동기화 완료)
    # 예외: drive_link가 NULL/빈 값인 레코드
    # ------------------------------------------------------------------
    def check_CO02(self) -> dict:
        today = self.run_date
        conn = self._conn()
        try:
            total_rows = conn.execute('''
                SELECT COUNT(*) as cnt FROM analysis_results WHERE DATE(created_at) = ?
            ''', (today,)).fetchone()
            total = dict(total_rows)['cnt'] if total_rows else 0

            if total == 0:
                return self.result(
                    rows=[{'date': today, 'note': '당일 분석 결과 없음 (백업 대상 없음)'}],
                    total_count=0,
                    message="당일 분석 결과 없음"
                )

            exception_rows = conn.execute('''
                SELECT filename, market, created_at, drive_link
                FROM analysis_results
                WHERE DATE(created_at) = ?
                  AND (drive_link IS NULL OR drive_link = '')
                ORDER BY created_at DESC
            ''', (today,)).fetchall()
            exception_rows = [dict(r) for r in exception_rows]

            return self.result(
                rows=exception_rows,
                total_count=total,
                message=f"Drive 미동기화 {len(exception_rows)}건" if exception_rows else "Drive 동기화 완료"
            )
        finally:
            conn.close()
