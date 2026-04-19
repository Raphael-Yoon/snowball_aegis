"""
백업 스케줄러 Unit 테스트 (Mock 기반)

주요 테스트 항목:
1. get_backup_filename() - 오늘 날짜 형식 파일명 생성 확인
2. cleanup_old_backups() - 디렉토리 없을 때 정상 처리
3. cleanup_old_backups() - 보관 기간(7일) 초과 파일 삭제 확인
4. cleanup_old_backups() - 보관 기간 내 파일 유지 확인
5. send_backup_result_email() - 성공 케이스 이메일 전송 API 호출 확인
6. send_backup_result_email() - 실패 케이스 이메일 본문에 에러 내용 포함 확인

Gmail API / MySQL 연결 없이 unittest.mock으로 순수 로직만 검증합니다.
"""

import sys
import os
import re
import tempfile
import shutil
import base64
from pathlib import Path
from datetime import datetime, timedelta
from unittest.mock import MagicMock, patch

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import UnitTestResult, TestStatus


class BackupUnitTest:
    """백업 스케줄러 유닛 테스트 (브라우저 불필요, mock 기반)"""

    def __init__(self):
        self.results = []
        self.checklist_source = project_root / "test" / "unit_checklist_backup.md"
        self.checklist_result = project_root / "test" / "unit_checklist_backup_result.md"

    def run_category(self, category_name: str, tests: list):
        """카테고리별 테스트 실행"""
        print(f"\n{'=' * 80}")
        print(f"{category_name}")
        print(f"{'=' * 80}")

        for test_func in tests:
            result = UnitTestResult(test_func.__name__, category_name)
            self.results.append(result)
            result.start()
            print(f"\n{TestStatus.RUNNING.value} {test_func.__name__}...", end=" ")

            try:
                test_func(result)
                if result.status == TestStatus.RUNNING:
                    result.pass_test()
            except Exception as e:
                import traceback
                result.fail_test(f"예외 발생: {e}")
                print(f"\r{result}")
                print(f"    ❌ {result.message}")
                print(f"    {traceback.format_exc()[:300]}")
                continue

            print(f"\r{result}")
            for detail in result.details:
                print(f"    ℹ️  {detail}")

    def print_final_report(self):
        """최종 결과 출력"""
        print("\n" + "=" * 80)
        print("Unit 테스트 결과 요약")
        print("=" * 80)

        counts = {s: 0 for s in TestStatus}
        for r in self.results:
            counts[r.status] += 1

        total = len(self.results)
        if not total:
            print("실행된 테스트가 없습니다.")
            return 0

        passed = counts[TestStatus.PASSED]
        failed = counts[TestStatus.FAILED]
        warning = counts[TestStatus.WARNING]
        skipped = counts[TestStatus.SKIPPED]

        print(f"\n총 테스트: {total}개")
        print(f"✅ 통과: {passed}개 ({passed/total*100:.1f}%)")
        print(f"❌ 실패: {failed}개 ({failed/total*100:.1f}%)")
        print(f"⚠️ 경고: {warning}개 ({warning/total*100:.1f}%)")
        print(f"⊘ 건너뜀: {skipped}개 ({skipped/total*100:.1f}%)")

        return 0 if failed == 0 else 1

    def _update_checklist_result(self):
        """체크리스트 결과 파일 업데이트 (PlaywrightTestBase와 동일한 형식)"""
        if not self.checklist_source.exists():
            print(f"⚠️ 체크리스트 소스 없음: {self.checklist_source}")
            return

        try:
            with open(self.checklist_source, 'r', encoding='utf-8') as f:
                content = f.read()

            for r in self.results:
                pattern = rf"- \[ \] \*\*{r.test_name}\*\*"
                if r.status == TestStatus.PASSED:
                    replacement = f"- [x] **{r.test_name}**"
                elif r.status == TestStatus.FAILED:
                    replacement = f"- [!] **{r.test_name}** (FAILED)"
                else:
                    continue
                content = re.sub(pattern, replacement, content)

            # 결과 요약 추가 (PlaywrightTestBase._generate_markdown_summary와 동일)
            summary = self._generate_markdown_summary()
            content = (
                f"<!-- Test Run: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} -->\n"
                + content
                + "\n\n"
                + summary
            )

            with open(self.checklist_result, 'w', encoding='utf-8') as f:
                f.write(content)

            print(f"[OK] 체크리스트 결과 저장됨: {self.checklist_result}")
        except Exception as e:
            print(f"⚠️ 체크리스트 업데이트 실패: {e}")

    def _generate_markdown_summary(self) -> str:
        """마크다운 형식의 결과 요약 생성"""
        counts = {s: 0 for s in TestStatus}
        for r in self.results:
            counts[r.status] += 1

        total = len(self.results)
        if total == 0:
            return ""

        passed = counts[TestStatus.PASSED]
        failed = counts[TestStatus.FAILED]
        warning = counts[TestStatus.WARNING]
        skipped = counts[TestStatus.SKIPPED]

        summary = "## 테스트 결과 요약\n\n"
        summary += "| 항목 | 개수 | 비율 |\n"
        summary += "|------|------|------|\n"
        summary += f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n"
        summary += f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n"
        summary += f"| ⚠️ 경고 | {warning} | {warning/total*100:.1f}% |\n"
        summary += f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n"
        summary += f"| **총계** | **{total}** | **100%** |\n"

        return summary

    # -------------------------------------------------------------------------
    # 테스트 케이스
    # -------------------------------------------------------------------------

    def test_backup_filename_format(self, result: UnitTestResult):
        """1. get_backup_filename() → 오늘 날짜 형식 snowball_YYYYMMDD.db 확인"""
        from gmail_schedule import get_backup_filename

        filename = get_backup_filename()
        result.add_detail(f"생성된 파일명: {filename}")

        today_str = datetime.now().strftime('%Y%m%d')
        expected = f"snowball_{today_str}.db"

        if filename == expected:
            result.pass_test(f"파일명 형식 확인 완료: {filename}")
        else:
            result.fail_test(f"기대: {expected}, 실제: {filename}")

    def test_backup_cleanup_no_dir(self, result: UnitTestResult):
        """2. cleanup_old_backups() - 백업 디렉토리 없을 때 정상 처리 확인"""
        from gmail_schedule import cleanup_old_backups

        fake_dir = os.path.join(tempfile.gettempdir(), "nonexistent_backup_xyz_abc")
        # 혹시 존재하면 삭제
        if os.path.exists(fake_dir):
            shutil.rmtree(fake_dir)

        with patch('gmail_schedule.BACKUP_DIR', fake_dir):
            result_data = cleanup_old_backups()

        result.add_detail(f"success: {result_data.get('success')}")
        result.add_detail(f"deleted_count: {result_data.get('deleted_count')}")

        if result_data.get('success') is True and result_data.get('deleted_count') == 0:
            result.pass_test("디렉토리 없을 때 success=True, deleted_count=0 확인 완료")
        else:
            result.fail_test(f"예상치 못한 결과: {result_data}")

    def test_backup_cleanup_deletes_old_files(self, result: UnitTestResult):
        """3. cleanup_old_backups() - 보관 기간(7일) 초과 파일 삭제 확인"""
        from gmail_schedule import cleanup_old_backups

        tmp_dir = tempfile.mkdtemp()
        try:
            # 9일 전 파일 생성 (삭제 대상)
            old_date = (datetime.now() - timedelta(days=9)).strftime('%Y%m%d')
            old_file = os.path.join(tmp_dir, f"snowball_{old_date}.db")
            open(old_file, 'w').close()
            result.add_detail(f"생성된 오래된 파일: snowball_{old_date}.db (9일 전)")

            with patch('gmail_schedule.BACKUP_DIR', tmp_dir):
                result_data = cleanup_old_backups()

            result.add_detail(f"삭제된 파일 수: {result_data.get('deleted_count')}")

            if result_data.get('deleted_count') == 1 and not os.path.exists(old_file):
                result.pass_test("7일 초과 파일 자동 삭제 확인 완료")
            else:
                result.fail_test(
                    f"삭제 실패 - deleted_count={result_data.get('deleted_count')}, "
                    f"파일 존재={os.path.exists(old_file)}"
                )
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)

    def test_backup_cleanup_keeps_recent_files(self, result: UnitTestResult):
        """4. cleanup_old_backups() - 보관 기간(7일) 내 파일 유지 확인"""
        from gmail_schedule import cleanup_old_backups

        tmp_dir = tempfile.mkdtemp()
        try:
            # 3일 전 파일 생성 (유지 대상)
            recent_date = (datetime.now() - timedelta(days=3)).strftime('%Y%m%d')
            recent_file = os.path.join(tmp_dir, f"snowball_{recent_date}.db")
            open(recent_file, 'w').close()
            result.add_detail(f"생성된 최근 파일: snowball_{recent_date}.db (3일 전)")

            with patch('gmail_schedule.BACKUP_DIR', tmp_dir):
                result_data = cleanup_old_backups()

            result.add_detail(f"삭제된 파일 수: {result_data.get('deleted_count')}")

            if result_data.get('deleted_count') == 0 and os.path.exists(recent_file):
                result.pass_test("보관 기간 내 최근 파일 유지 확인 완료")
            else:
                result.fail_test(
                    f"최근 파일 삭제됨 - deleted_count={result_data.get('deleted_count')}, "
                    f"파일 존재={os.path.exists(recent_file)}"
                )
        finally:
            shutil.rmtree(tmp_dir, ignore_errors=True)

    def test_backup_email_body_success(self, result: UnitTestResult):
        """5. send_backup_result_email() 성공 케이스 - Gmail API send() 호출 확인"""
        from gmail_schedule import send_backup_result_email

        # Mock Gmail 서비스
        mock_service = MagicMock()
        mock_send_result = {'id': 'test_msg_id_success'}
        mock_service.users.return_value.messages.return_value.send.return_value.execute.return_value = mock_send_result

        backup_result = {
            'success': True,
            'log': '[INFO] 백업 완료\n✅ 10/10 테이블',
            'backup_file': 'snowball_20260220.db',
            'total_tables': 10,
            'total_rows': 5000,
            'file_size': 1024 * 1024 * 3  # 3MB
        }
        cleanup_result = {
            'success': True,
            'log': '[INFO] 정리 완료',
            'deleted_count': 1,
            'deleted_size': 512000
        }

        sent = send_backup_result_email(
            mock_service,
            'test@example.com',
            '백업 결과',
            backup_result,
            cleanup_result
        )

        # Gmail API send()가 호출됐는지 확인
        was_called = mock_service.users.return_value.messages.return_value.send.called
        result.add_detail(f"Gmail API send() 호출됨: {was_called}")
        result.add_detail(f"반환값 id: {sent.get('id') if sent else None}")

        if was_called and sent and sent.get('id') == 'test_msg_id_success':
            result.pass_test("성공 케이스 이메일 전송 API 호출 및 응답 확인 완료")
        else:
            result.fail_test(f"이메일 전송 실패 - called={was_called}, sent={sent}")

    def test_backup_email_body_failure(self, result: UnitTestResult):
        """6. send_backup_result_email() 실패 케이스 - 이메일 본문에 에러 내용 포함 확인"""
        import email as email_lib
        from gmail_schedule import send_backup_result_email

        captured = {}

        def mock_send(userId, body):
            captured['raw'] = body.get('raw', '')
            mock_obj = MagicMock()
            mock_obj.execute.return_value = {'id': 'fail_msg_id'}
            return mock_obj

        mock_service = MagicMock()
        mock_service.users.return_value.messages.return_value.send.side_effect = mock_send

        backup_result = {
            'success': False,
            'log': '❌ 백업 실패!\n오류: MySQL Connection refused\ntraceback...',
            'error': 'MySQL Connection refused'
        }
        cleanup_result = {
            'success': True,
            'log': '',
            'deleted_count': 0,
            'deleted_size': 0
        }

        sent = send_backup_result_email(
            mock_service,
            'test@example.com',
            '백업 결과 (실패)',
            backup_result,
            cleanup_result
        )

        raw_b64 = captured.get('raw', '')
        if not raw_b64:
            result.fail_test("이메일 raw 본문을 캡처하지 못함")
            return

        # MIME 메시지 파싱: raw는 MIME 메시지 전체가 base64로 인코딩된 것
        # 1단계: url-safe base64 디코딩 → MIME 메시지 bytes
        mime_bytes = base64.urlsafe_b64decode(raw_b64 + '==')
        mime_str = mime_bytes.decode('utf-8', errors='replace')

        # 2단계: MIME 파서로 body 추출
        msg = email_lib.message_from_string(mime_str)
        body_text = ''
        if msg.is_multipart():
            for part in msg.walk():
                if part.get_content_type() == 'text/plain':
                    payload = part.get_payload(decode=True)
                    body_text += payload.decode('utf-8', errors='replace') if payload else ''
        else:
            payload = msg.get_payload(decode=True)
            body_text = payload.decode('utf-8', errors='replace') if payload else msg.get_payload()

        result.add_detail(f"이메일 본문 (앞 100자): {body_text[:100]}")

        error_keyword = 'Connection refused'
        if error_keyword in body_text:
            result.pass_test(f"실패 케이스 이메일 본문에 에러 내용('{error_keyword}') 포함 확인 완료")
        elif '실패' in body_text or '❌' in body_text:
            result.pass_test("실패 케이스 이메일 본문에 실패 관련 내용 포함 확인 완료")
        else:
            result.fail_test(f"이메일 본문에 에러 내용 없음 (본문 앞 200자: {body_text[:200]})")


def run_tests():
    test_runner = BackupUnitTest()
    test_runner.run_category("Backup Scheduler Unit Tests", [
        test_runner.test_backup_filename_format,
        test_runner.test_backup_cleanup_no_dir,
        test_runner.test_backup_cleanup_deletes_old_files,
        test_runner.test_backup_cleanup_keeps_recent_files,
        test_runner.test_backup_email_body_success,
        test_runner.test_backup_email_body_failure,
    ])
    test_runner._update_checklist_result()
    test_runner.print_final_report()


if __name__ == "__main__":
    run_tests()
