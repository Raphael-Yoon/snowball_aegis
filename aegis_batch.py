"""
Aegis 일배치 스케줄러
실행: python aegis_batch.py
cron 예시: 0 1 * * * /usr/bin/python /path/to/aegis_batch.py
"""
import sys
import argparse
from datetime import date
from pathlib import Path

# Flask 앱 컨텍스트 없이 실행 가능하도록 환경 설정
_APP_DIR = Path(__file__).parent.resolve()
sys.path.insert(0, str(_APP_DIR))

from dotenv import load_dotenv
load_dotenv(_APP_DIR / '.env')

from logger_config import get_logger
from aegis_monitor import run_batch

logger = get_logger('aegis_batch')


def main():
    parser = argparse.ArgumentParser(description='Aegis 일배치 모니터링 실행')
    parser.add_argument('--date', type=str, default=date.today().isoformat(),
                        help='실행 기준일 (YYYY-MM-DD, 기본값: 오늘)')
    parser.add_argument('--system', type=int, default=None,
                        help='특정 시스템 ID만 실행')
    parser.add_argument('--control', type=int, default=None,
                        help='특정 통제 ID만 실행')
    args = parser.parse_args()

    logger.info(f"[Batch] 배치 시작 - date={args.date}, system={args.system}, control={args.control}")
    print(f"Aegis 배치 실행: {args.date}")

    try:
        results = run_batch(run_date=args.date, system_id=args.system, control_id=args.control)

        pass_cnt  = sum(1 for r in results if r['status'] == 'PASS')
        fail_cnt  = sum(1 for r in results if r['status'] == 'FAIL')
        warn_cnt  = sum(1 for r in results if r['status'] == 'WARNING')
        error_cnt = sum(1 for r in results if r['status'] == 'ERROR')

        print(f"\n===== 배치 결과 요약 ({args.date}) =====")
        print(f"  총 처리: {len(results)}건")
        print(f"  PASS   : {pass_cnt}건")
        print(f"  FAIL   : {fail_cnt}건")
        print(f"  WARNING: {warn_cnt}건")
        print(f"  ERROR  : {error_cnt}건")

        if fail_cnt > 0 or error_cnt > 0:
            print("\n[주의] FAIL/ERROR 항목:")
            for r in results:
                if r['status'] in ('FAIL', 'ERROR'):
                    print(f"  - {r['system_code']} / {r['control_code']}: {r['status']}")

        logger.info(f"[Batch] 완료 - PASS={pass_cnt}, FAIL={fail_cnt}, ERROR={error_cnt}")
        sys.exit(0)

    except Exception as e:
        logger.error(f"[Batch] 배치 실행 중 치명적 오류: {e}")
        print(f"배치 실행 오류: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
