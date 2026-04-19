#!/usr/bin/env python
"""
Snowball 데이터베이스 마이그레이션 스크립트

사용법:
    python migrate.py status              # 현재 마이그레이션 상태 확인
    python migrate.py upgrade             # 모든 마이그레이션 적용
    python migrate.py upgrade --target 003 # 특정 버전까지 마이그레이션
    python migrate.py downgrade --target 001 # 특정 버전으로 롤백
"""
import sys
import argparse
from migrations.migration_manager import MigrationManager


def main():
    parser = argparse.ArgumentParser(
        description='Snowball 데이터베이스 마이그레이션 도구',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
예제:
  python migrate.py status                  # 마이그레이션 상태 확인
  python migrate.py upgrade                 # 모든 마이그레이션 적용
  python migrate.py upgrade --target 003    # 버전 003까지 적용
  python migrate.py downgrade --target 001  # 버전 001로 롤백
        '''
    )

    parser.add_argument(
        'command',
        choices=['status', 'upgrade', 'downgrade'],
        help='실행할 명령'
    )

    parser.add_argument(
        '--target',
        type=str,
        help='타겟 마이그레이션 버전 (upgrade 또는 downgrade 시)'
    )

    parser.add_argument(
        '--database',
        type=str,
        default='snowball.db',
        help='데이터베이스 파일 경로 (기본값: snowball.db)'
    )

    args = parser.parse_args()

    # MigrationManager 인스턴스 생성
    manager = MigrationManager(args.database)

    try:
        if args.command == 'status':
            # 마이그레이션 상태 확인
            manager.status()

        elif args.command == 'upgrade':
            # 마이그레이션 업그레이드
            print(f"\n데이터베이스: {args.database}")
            print("=" * 70)

            success = manager.upgrade(target_version=args.target)

            if success:
                print("\n마이그레이션이 성공적으로 완료되었습니다! [OK]")
                return 0
            else:
                print("\n마이그레이션 실패! [FAIL]")
                return 1

        elif args.command == 'downgrade':
            # 마이그레이션 다운그레이드
            if not args.target:
                print("오류: downgrade 명령에는 --target 옵션이 필요합니다.")
                print("예: python migrate.py downgrade --target 001")
                return 1

            print(f"\n데이터베이스: {args.database}")
            print(f"타겟 버전: {args.target}")
            print("=" * 70)

            # 확인 메시지
            response = input(f"\n정말로 버전 {args.target}로 롤백하시겠습니까? (yes/no): ")
            if response.lower() not in ['yes', 'y']:
                print("롤백이 취소되었습니다.")
                return 0

            success = manager.downgrade(target_version=args.target)

            if success:
                print("\n롤백이 성공적으로 완료되었습니다! [OK]")
                return 0
            else:
                print("\n롤백 실패! [FAIL]")
                return 1

    except KeyboardInterrupt:
        print("\n\n작업이 사용자에 의해 중단되었습니다.")
        return 130

    except Exception as e:
        print(f"\n오류 발생: {e}")
        import traceback
        traceback.print_exc()
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
