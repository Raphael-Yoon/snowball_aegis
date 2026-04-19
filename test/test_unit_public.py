"""
Public 기능 통합 Unit 테스트

로그인 없이 접근 가능한 Public 기능들(Link 1, 2, 3, 4, 9, 10, 11)의
Unit 테스트를 일괄 실행합니다.

사용법:
    python test/test_unit_public.py [--headless] [--links=1,2,3]

옵션:
    --headless    : 헤드리스 모드로 실행 (브라우저 창 숨김)
    --links=N,M   : 특정 링크만 테스트 (예: --links=1,2,3)
    --skip=N,M    : 특정 링크 제외 (예: --skip=10,11)
"""

import sys
import argparse
import io
import time
import subprocess
import requests
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional
from collections import OrderedDict

# Windows 콘솔 UTF-8 출력 설정
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8', errors='replace')

# 프로젝트 루트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

# Public Link 정의 (로그인 불필요)
PUBLIC_LINKS = [1, 2, 3, 4, 9, 10, 11]

# 각 Link별 테스트 그룹 정의 (체크리스트 기준)
LINK_TEST_GROUPS = {
    1: OrderedDict([
        ("1번", ["test_link1_page_access", "test_link1_form_elements"]),
        ("2번", ["test_link1_os_version_toggle", "test_link1_cloud_env_toggle",
                 "test_link1_system_type_toggle", "test_link1_sw_version_toggle"]),
        ("3번", ["test_link1_control_table", "test_link1_toggle_detail", "test_link1_type_change_monitoring"]),
        ("4번", ["test_link1_population_templates_api", "test_link1_email_input",
                 "test_link1_export_email_validation", "test_link1_export_api"]),
        ("5번", ["test_link1_population_calculation", "test_link1_cloud_control_exclusion"]),
    ]),
    2: OrderedDict([
        ("1번", ["test_link2_access_guest", "test_link2_access_logged_in"]),
        ("2번", ["test_link2_progress_bar", "test_link2_navigation", "test_link2_input_types"]),
        ("3번", ["test_link2_conditional_skip_cloud", "test_link2_conditional_skip_db", "test_link2_conditional_skip_os"]),
        ("4번", ["test_link2_admin_sample_buttons", "test_link2_sample_fill_click"]),
        ("5번", ["test_link2_complete_interview"]),
    ]),
    3: OrderedDict([
        ("1번", ["test_link3_access", "test_link3_initial_ui"]),
        ("2번", ["test_link3_sidebar_categories", "test_link3_sidebar_toggle"]),
        ("3번", ["test_link3_content_loading", "test_link3_step_navigation"]),
        ("4번", ["test_link3_download_button_initial", "test_link3_download_button_active",
                 "test_link3_download_link_correct"]),
        ("5번", ["test_link3_activity_log"]),
    ]),
    4: OrderedDict([
        ("1번", ["test_link4_access", "test_link4_initial_ui"]),
        ("2번", ["test_link4_sidebar_categories", "test_link4_sidebar_toggle"]),
        ("3번", ["test_link4_content_loading", "test_link4_preparing_message"]),
        ("4번", ["test_link4_activity_log"]),
    ]),
    9: OrderedDict([
        ("1번", ["test_link9_access", "test_link9_ui_guest", "test_link9_ui_logged_in"]),
        ("2번", ["test_link9_form_validation"]),
        ("3번", ["test_link9_send_success", "test_link9_send_failure_handling", "test_link9_service_inquiry"]),
    ]),
    10: OrderedDict([
        ("1번", ["test_link10_access", "test_link10_loading_state"]),
        ("2번", ["test_link10_empty_state_or_list", "test_link10_view_report", "test_link10_report_content"]),
        ("3번", ["test_link10_modal_close", "test_link10_send_report_guest", "test_link10_email_validation"]),
        ("4번", ["test_link10_logged_in_action"]),
    ]),
    11: OrderedDict([
        ("1번", ["test_link11_access", "test_link11_dashboard_stats", "test_link11_progress_view"]),
        ("2번", ["test_link11_category_navigation", "test_link11_answer_yes_no", "test_link11_dependent_questions"]),
        ("3번", ["test_link11_currency_input", "test_link11_number_input", "test_link11_multi_select"]),
        ("4번", ["test_link11_evidence_modal", "test_link11_evidence_mime_validation",
                 "test_link11_evidence_physical_integrity", "test_link11_evidence_view_page",
                 "test_link11_evidence_delete", "test_link11_evidence_download",
                 "test_link11_report_preview", "test_link11_report_download"]),
        ("5번", ["test_link11_validation_b_lt_a", "test_link11_auto_calculation",
                 "test_link11_validation_personnel", "test_link11_validation_negative",
                 "test_link11_numerical_boundary", "test_link11_submit_incomplete_blocked"]),
        ("6번", ["test_link11_q7_q8", "test_link11_q13_q14", "test_link11_q27_new_question"]),
        ("7번", ["test_link11_company_data_isolation", "test_link11_reset_disclosure"]),
        ("8번", ["test_link11_copy_from_year", "test_link11_available_years", "test_link11_recursive_cleanup"]),
    ]),
}


class PublicLinkTestRunner:
    """Public 링크 통합 테스트 실행기"""

    def __init__(self, base_url: str = "http://localhost:5001",
                 headless: bool = False,
                 target_links: List[int] = None,
                 skip_links: List[int] = None):
        self.base_url = base_url
        self.headless = headless
        self.target_links = target_links or PUBLIC_LINKS
        self.skip_links = skip_links or []
        self.all_results: Dict[int, List[UnitTestResult]] = {}
        self.extra_results: Dict[str, List[UnitTestResult]] = {}
        self.start_time = None
        self.end_time = None

        # 서버 관리
        self.server_process: Optional[subprocess.Popen] = None
        self.server_was_running: bool = False

    def check_server_running(self) -> bool:
        """서버 실행 상태 확인 및 필요시 시작"""
        try:
            response = requests.get(f"{self.base_url}/health", timeout=3)
            if response.status_code == 200:
                print(f"✅ 서버 실행 중 ({self.base_url})")
                self.server_was_running = True
                return True
        except:
            pass

        print(f"⚠️ 서버가 실행 중이지 않습니다. 서버를 시작합니다...")
        self.server_was_running = False
        return self._start_server()

    def _start_server(self) -> bool:
        """서버 백그라운드 시작"""
        try:
            self.server_process = subprocess.Popen(
                [sys.executable, "snowball.py"],
                cwd=str(project_root),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == 'win32' else 0
            )
            print(f"   서버 시작 중... (PID: {self.server_process.pid})")

            for i in range(30):
                time.sleep(1)
                try:
                    response = requests.get(f"{self.base_url}/health", timeout=2)
                    if response.status_code == 200:
                        print(f"✅ 서버 시작 완료")
                        return True
                except:
                    print(f"   서버 준비 대기 중... ({i+1}/30)")

            print(f"❌ 서버 시작 시간 초과")
            return False
        except Exception as e:
            print(f"❌ 서버 시작 실패: {e}")
            return False

    def stop_server(self):
        """서버 중지 (직접 시작한 경우에만)"""
        if self.server_process and not self.server_was_running:
            print(f"\n🛑 서버 중지 중... (PID: {self.server_process.pid})")
            try:
                self.server_process.terminate()
                self.server_process.wait(timeout=5)
                print(f"✅ 서버 중지 완료")
            except Exception as e:
                print(f"⚠️ 서버 중지 중 오류: {e}")
                try:
                    self.server_process.kill()
                except:
                    pass
            self.server_process = None

    def get_test_links(self) -> List[int]:
        """테스트할 링크 목록 반환"""
        return [l for l in self.target_links if l not in self.skip_links]

    def _get_all_tests_for_link(self, link_num: int) -> List[str]:
        """링크의 모든 테스트 메서드 이름 반환"""
        if link_num not in LINK_TEST_GROUPS:
            return []
        tests = []
        for group_tests in LINK_TEST_GROUPS[link_num].values():
            tests.extend(group_tests)
        return tests

    def _get_test_group(self, link_num: int, test_name: str) -> str:
        """테스트 이름으로 그룹 찾기"""
        if link_num not in LINK_TEST_GROUPS:
            return "기타"
        for group_name, tests in LINK_TEST_GROUPS[link_num].items():
            if test_name in tests:
                return group_name
        return "기타"

    def run_link_test(self, link_num: int) -> List[UnitTestResult]:
        """개별 링크 테스트 실행"""
        results = []

        try:
            if link_num == 1:
                from test.test_unit_link1 import Link1UnitTest
                runner = Link1UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link1: RCM 생성", [
                        runner.test_link1_page_access,
                        runner.test_link1_form_elements,
                        runner.test_link1_os_version_toggle,
                        runner.test_link1_cloud_env_toggle,
                        runner.test_link1_system_type_toggle,
                        runner.test_link1_sw_version_toggle,
                        runner.test_link1_control_table,
                        runner.test_link1_toggle_detail,
                        runner.test_link1_type_change_monitoring,
                        runner.test_link1_population_templates_api,
                        runner.test_link1_email_input,
                        runner.test_link1_export_email_validation,
                        runner.test_link1_export_api,
                        runner.test_link1_population_calculation,
                        runner.test_link1_cloud_control_exclusion,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

            elif link_num == 2:
                from test.test_unit_link2 import Link2UnitTest
                runner = Link2UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link2: 인터뷰/설계평가", [
                        runner.test_link2_access_guest,
                        runner.test_link2_access_logged_in,
                        runner.test_link2_progress_bar,
                        runner.test_link2_navigation,
                        runner.test_link2_input_types,
                        runner.test_link2_conditional_skip_cloud,
                        runner.test_link2_conditional_skip_db,
                        runner.test_link2_conditional_skip_os,
                        runner.test_link2_admin_sample_buttons,
                        runner.test_link2_sample_fill_click,
                        runner.test_link2_complete_interview,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

            elif link_num == 3:
                from test.test_unit_link3 import Link3UnitTest
                runner = Link3UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link3: 조서 템플릿", [
                        runner.test_link3_access,
                        runner.test_link3_initial_ui,
                        runner.test_link3_sidebar_categories,
                        runner.test_link3_sidebar_toggle,
                        runner.test_link3_content_loading,
                        runner.test_link3_step_navigation,
                        runner.test_link3_download_button_initial,
                        runner.test_link3_download_button_active,
                        runner.test_link3_download_link_correct,
                        runner.test_link3_activity_log,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

            elif link_num == 4:
                from test.test_unit_link4 import Link4UnitTest
                runner = Link4UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link4: 컨텐츠", [
                        runner.test_link4_access,
                        runner.test_link4_initial_ui,
                        runner.test_link4_sidebar_categories,
                        runner.test_link4_sidebar_toggle,
                        runner.test_link4_content_loading,
                        runner.test_link4_preparing_message,
                        runner.test_link4_activity_log,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

            elif link_num == 9:
                from test.test_unit_link9 import Link9UnitTest
                runner = Link9UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link9: 문의/피드백", [
                        runner.test_link9_access,
                        runner.test_link9_ui_guest,
                        runner.test_link9_ui_logged_in,
                        runner.test_link9_form_validation,
                        runner.test_link9_send_success,
                        runner.test_link9_send_failure_handling,
                        runner.test_link9_service_inquiry,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

            elif link_num == 10:
                from test.test_unit_link10 import Link10UnitTest
                runner = Link10UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link10: AI 결과", [
                        runner.test_link10_access,
                        runner.test_link10_loading_state,
                        runner.test_link10_empty_state_or_list,
                        runner.test_link10_view_report,
                        runner.test_link10_report_content,
                        runner.test_link10_modal_close,
                        runner.test_link10_send_report_guest,
                        runner.test_link10_email_validation,
                        runner.test_link10_logged_in_action,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

            elif link_num == 11:
                from test.test_unit_link11 import Link11UnitTest
                runner = Link11UnitTest(base_url=self.base_url, headless=self.headless)
                runner.setup()
                try:
                    runner.run_category("Link11: 공시", [
                        runner.test_link11_access,
                        runner.test_link11_dashboard_stats,
                        runner.test_link11_progress_view,
                        runner.test_link11_category_navigation,
                        runner.test_link11_answer_yes_no,
                        runner.test_link11_dependent_questions,
                        runner.test_link11_currency_input,
                        runner.test_link11_number_input,
                        runner.test_link11_multi_select,
                        runner.test_link11_evidence_modal,
                        runner.test_link11_evidence_mime_validation,
                        runner.test_link11_evidence_physical_integrity,
                        runner.test_link11_evidence_view_page,
                        runner.test_link11_evidence_delete,
                        runner.test_link11_evidence_download,
                        runner.test_link11_report_preview,
                        runner.test_link11_report_download,
                        runner.test_link11_validation_b_lt_a,
                        runner.test_link11_auto_calculation,
                        runner.test_link11_validation_personnel,
                        runner.test_link11_validation_negative,
                        runner.test_link11_numerical_boundary,
                        runner.test_link11_submit_incomplete_blocked,
                        runner.test_link11_q7_q8,
                        runner.test_link11_q13_q14,
                        runner.test_link11_q27_new_question,
                        runner.test_link11_company_data_isolation,
                        runner.test_link11_reset_disclosure,
                        runner.test_link11_copy_from_year,
                        runner.test_link11_available_years,
                        runner.test_link11_recursive_cleanup,
                    ])
                    results = runner.results
                finally:
                    runner.teardown()

        except ImportError as e:
            print(f"  [SKIP] Link{link_num} 테스트 모듈 없음: {e}")
            skip_result = UnitTestResult(f"link{link_num}_import", f"Link{link_num}")
            skip_result.skip_test(f"테스트 모듈 없음: {e}")
            results = [skip_result]
        except AttributeError as e:
            print(f"  [WARN] Link{link_num} 일부 테스트 메서드 없음: {e}")
            warn_result = UnitTestResult(f"link{link_num}_method", f"Link{link_num}")
            warn_result.warn_test(f"일부 메서드 없음: {e}")
            results = [warn_result]
        except Exception as e:
            print(f"  [ERROR] Link{link_num} 테스트 실패: {e}")
            fail_result = UnitTestResult(f"link{link_num}_error", f"Link{link_num}")
            fail_result.fail_test(f"테스트 오류: {e}")
            results = [fail_result]

        return results

    def run_extra_tests(self):
        """Auth, Admin, Common API, Backup 추가 모듈 테스트 실행"""
        import importlib

        browser_modules = [
            ('auth',       'test.test_unit_auth',       'AuthUnitTest',      'Auth: 인증/세션',
             ['test_auth_login_page_security', 'test_auth_otp_process_mocked',
              'test_auth_otp_limit_check', 'test_auth_session_cookie_security']),
            ('admin',      'test.test_unit_admin',      'AdminUnitTest',     'Admin: 관리자 기능',
             ['test_admin_no_access_without_login', 'test_admin_no_access_wrong_user',
              'test_admin_dashboard_elements', 'test_admin_add_user_mutation', 'test_admin_logs_filtering']),
            ('common_api', 'test.test_unit_common_api', 'CommonApiUnitTest', 'Common API',
             ['test_common_health_check', 'test_common_index_guest', 'test_common_index_logged_in',
              'test_common_index_cards', 'test_common_clear_session', 'test_common_404_handling']),
        ]

        for key, module_path, class_name, category, test_names in browser_modules:
            print(f"\n{'─' * 40}")
            print(f"  {category} 테스트 시작")
            print(f"{'─' * 40}")
            try:
                mod = importlib.import_module(module_path)
                cls = getattr(mod, class_name)
                runner = cls(headless=self.headless, slow_mo=200)
                runner.setup()
                try:
                    test_methods = [getattr(runner, name) for name in test_names]
                    runner.run_category(category, test_methods)
                    self.extra_results[key] = runner.results
                finally:
                    runner._update_checklist_result()
                    runner.teardown()
            except Exception as e:
                import traceback
                print(f"  [ERROR] {category} 테스트 실패: {e}")
                traceback.print_exc()
                fail_result = UnitTestResult(f"{key}_error", category)
                fail_result.fail_test(f"모듈 실행 오류: {e}")
                self.extra_results[key] = [fail_result]

        # Backup (mock 기반, 브라우저 불필요)
        print(f"\n{'─' * 40}")
        print(f"  Backup: 백업 스케줄러 테스트 시작")
        print(f"{'─' * 40}")
        try:
            from test.test_unit_backup import BackupUnitTest
            backup_runner = BackupUnitTest()
            backup_runner.run_category("Backup: 백업 스케줄러", [
                backup_runner.test_backup_filename_format,
                backup_runner.test_backup_cleanup_no_dir,
                backup_runner.test_backup_cleanup_deletes_old_files,
                backup_runner.test_backup_cleanup_keeps_recent_files,
                backup_runner.test_backup_email_body_success,
                backup_runner.test_backup_email_body_failure,
            ])
            self.extra_results['backup'] = backup_runner.results
            backup_runner._update_checklist_result()
        except Exception as e:
            import traceback
            print(f"  [ERROR] Backup 테스트 실패: {e}")
            traceback.print_exc()
            fail_result = UnitTestResult("backup_error", "Backup")
            fail_result.fail_test(f"모듈 실행 오류: {e}")
            self.extra_results['backup'] = [fail_result]

    def run_all(self):
        """모든 Unit 테스트 실행 (Public 링크 + Auth/Admin/Common API/Backup)"""
        # 서버 확인 및 필요시 시작
        if not self.check_server_running():
            print("\n테스트를 중단합니다.")
            return

        self.start_time = datetime.now()
        test_links = self.get_test_links()

        print("\n" + "=" * 80)
        print("  전체 Unit 테스트 (Public 링크 + Auth/Admin/Common API/Backup)")
        print("=" * 80)
        print(f"  대상 링크: {', '.join([f'Link{l}' for l in test_links])}")
        print(f"  실행 시간: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"  모드: {'Headless' if self.headless else 'Browser'}")
        print("=" * 80)

        try:
            for link_num in test_links:
                print(f"\n{'─' * 40}")
                print(f"  Link{link_num} 테스트 시작")
                print(f"{'─' * 40}")

                results = self.run_link_test(link_num)
                self.all_results[link_num] = results

            # 추가 모듈 테스트 (Auth, Admin, Common API, Backup)
            self.run_extra_tests()

            self.end_time = datetime.now()
            self.print_summary()
            self.save_report()
        finally:
            # 직접 시작한 서버만 중지
            self.stop_server()

    def _get_grouped_results(self, link_num: int, results: List[UnitTestResult]) -> Dict[str, Dict]:
        """결과를 그룹별로 정리"""
        if link_num not in LINK_TEST_GROUPS:
            return {"기타": {"passed": 0, "total": len(results), "results": results}}

        grouped = OrderedDict()
        for group_name in LINK_TEST_GROUPS[link_num].keys():
            grouped[group_name] = {"passed": 0, "total": 0, "results": []}

        for result in results:
            group = self._get_test_group(link_num, result.test_name)
            if group not in grouped:
                grouped[group] = {"passed": 0, "total": 0, "results": []}
            grouped[group]["total"] += 1
            grouped[group]["results"].append(result)
            if result.status == TestStatus.PASSED:
                grouped[group]["passed"] += 1

        return grouped

    def print_summary(self):
        """테스트 결과 요약 출력 (그룹별)"""
        print("\n" + "=" * 80)
        print("  전체 Unit 테스트 결과 요약")
        print("=" * 80)

        total_passed = 0
        total_failed = 0

        for link_num, results in self.all_results.items():
            grouped = self._get_grouped_results(link_num, results)

            link_passed = sum(1 for r in results if r.status == TestStatus.PASSED)
            link_failed = sum(1 for r in results if r.status == TestStatus.FAILED)
            link_total = len(results)

            total_passed += link_passed
            total_failed += link_failed

            status_icon = "✅" if link_failed == 0 else "❌"
            print(f"\n  {status_icon} Link{link_num:2d} ({link_passed}/{link_total})")

            # 그룹별 결과 출력
            for group_name, group_data in grouped.items():
                if group_data["total"] > 0:
                    g_passed = group_data["passed"]
                    g_total = group_data["total"]
                    g_icon = "✓" if g_passed == g_total else "✗"
                    print(f"      {g_icon} {group_name}: {g_passed}/{g_total}")

        # 추가 모듈 결과 출력
        extra_names = {
            'auth':       'Auth: 인증/세션',
            'admin':      'Admin: 관리자 기능',
            'common_api': 'Common API',
            'backup':     'Backup: 백업 스케줄러',
        }
        if self.extra_results:
            print(f"\n  {'─' * 36}")
            for key, results in self.extra_results.items():
                e_passed = sum(1 for r in results if r.status == TestStatus.PASSED)
                e_failed = sum(1 for r in results if r.status == TestStatus.FAILED)
                e_warn   = sum(1 for r in results if r.status == TestStatus.WARNING)
                e_total  = len(results)
                total_passed += e_passed
                total_failed += e_failed
                status_icon = "✅" if e_failed == 0 else "❌"
                warn_str = f" (⚠️ {e_warn})" if e_warn else ""
                print(f"\n  {status_icon} {extra_names.get(key, key)} ({e_passed}/{e_total}){warn_str}")

        print("\n" + "─" * 40)
        total_all = total_passed + total_failed
        duration = (self.end_time - self.start_time).total_seconds()

        print(f"\n  총계: {total_passed}/{total_all} 통과 ({total_passed/total_all*100:.1f}%)")
        print(f"  소요 시간: {duration:.1f}초")

        if total_failed == 0:
            print("\n  🎉 모든 Unit 테스트 통과!")
        else:
            print(f"\n  ⚠️ {total_failed}개 테스트 실패")

        print("=" * 80)

    def save_report(self):
        """테스트 결과 리포트 저장"""
        report_path = project_root / "test" / "unit_public_result.md"

        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("# 전체 Unit 테스트 결과\n\n")
            f.write(f"- 실행 시간: {self.start_time.strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"- 소요 시간: {(self.end_time - self.start_time).total_seconds():.1f}초\n")
            f.write(f"- 모드: {'Headless' if self.headless else 'Browser'}\n\n")

            f.write("## 테스트 대상\n\n")
            f.write("| 모듈 | 설명 |\n")
            f.write("|------|------|\n")
            f.write("| Link1 | RCM 생성 |\n")
            f.write("| Link2 | 인터뷰/설계평가 |\n")
            f.write("| Link3 | 조서 템플릿 |\n")
            f.write("| Link4 | 컨텐츠 |\n")
            f.write("| Link9 | 문의/피드백 |\n")
            f.write("| Link10 | AI 결과 |\n")
            f.write("| Link11 | 공시 |\n")
            f.write("| Auth | 인증/세션 |\n")
            f.write("| Admin | 관리자 기능 |\n")
            f.write("| Common API | 공통 API |\n")
            f.write("| Backup | 백업 스케줄러 |\n\n")

            f.write("## 요약\n\n")

            total_passed = 0
            total_all = 0

            # Public 링크 요약
            f.write("### Public 링크\n\n")
            for link_num, results in self.all_results.items():
                grouped = self._get_grouped_results(link_num, results)

                link_passed = sum(1 for r in results if r.status == TestStatus.PASSED)
                link_failed = sum(1 for r in results if r.status == TestStatus.FAILED)
                link_total = len(results)

                total_passed += link_passed
                total_all += link_total

                status = "✅" if link_failed == 0 else "❌"
                f.write(f"#### {status} Link{link_num} ({link_passed}/{link_total})\n\n")

                f.write("| 그룹 | 결과 | 상태 |\n")
                f.write("|------|------|------|\n")

                for group_name, group_data in grouped.items():
                    if group_data["total"] > 0:
                        g_passed = group_data["passed"]
                        g_total = group_data["total"]
                        g_status = "✅" if g_passed == g_total else "❌"
                        f.write(f"| {group_name} | {g_passed}/{g_total} | {g_status} |\n")

                f.write("\n")

            # 추가 모듈 요약
            if self.extra_results:
                extra_names = {
                    'auth':       'Auth: 인증/세션',
                    'admin':      'Admin: 관리자 기능',
                    'common_api': 'Common API',
                    'backup':     'Backup: 백업 스케줄러',
                }
                f.write("### 추가 모듈\n\n")
                f.write("| 모듈 | 통과 | 전체 | 상태 |\n")
                f.write("|------|------|------|------|\n")
                for key, results in self.extra_results.items():
                    e_passed = sum(1 for r in results if r.status == TestStatus.PASSED)
                    e_total = len(results)
                    e_failed = sum(1 for r in results if r.status == TestStatus.FAILED)
                    total_passed += e_passed
                    total_all += e_total
                    e_status = "✅" if e_failed == 0 else "❌"
                    f.write(f"| {extra_names.get(key, key)} | {e_passed} | {e_total} | {e_status} |\n")
                f.write("\n")

            f.write("## 상세 결과\n\n")

            for link_num, results in self.all_results.items():
                grouped = self._get_grouped_results(link_num, results)

                f.write(f"### Link{link_num} 상세\n\n")

                for group_name, group_data in grouped.items():
                    if group_data["total"] > 0:
                        g_passed = group_data["passed"]
                        g_total = group_data["total"]
                        f.write(f"#### {group_name} ({g_passed}/{g_total})\n\n")

                        f.write("| 테스트 | 상태 | 메시지 |\n")
                        f.write("|--------|------|--------|\n")

                        for result in group_data["results"]:
                            f.write(f"| {result.test_name} | {result.status.value} | {result.message} |\n")

                        f.write("\n")

            # 추가 모듈 상세
            if self.extra_results:
                extra_names = {
                    'auth':       'Auth: 인증/세션',
                    'admin':      'Admin: 관리자 기능',
                    'common_api': 'Common API',
                    'backup':     'Backup: 백업 스케줄러',
                }
                for key, results in self.extra_results.items():
                    e_passed = sum(1 for r in results if r.status == TestStatus.PASSED)
                    e_total = len(results)
                    f.write(f"### {extra_names.get(key, key)} 상세 ({e_passed}/{e_total})\n\n")
                    f.write("| 테스트 | 상태 | 메시지 |\n")
                    f.write("|--------|------|--------|\n")
                    for result in results:
                        f.write(f"| {result.test_name} | {result.status.value} | {result.message} |\n")
                    f.write("\n")

            f.write("---\n\n")
            f.write("## 전체 요약\n\n")
            f.write(f"- 총 테스트: {total_all}\n")
            f.write(f"- 통과: {total_passed} ({total_passed/total_all*100:.1f}%)\n")
            f.write(f"- 실패: {total_all - total_passed} ({(total_all - total_passed)/total_all*100:.1f}%)\n")

        print(f"\n[OK] 리포트 저장됨: {report_path}")


def parse_args():
    """명령줄 인수 파싱"""
    parser = argparse.ArgumentParser(description="전체 Unit 테스트 (Public 링크 + Auth/Admin/Common API/Backup)")
    parser.add_argument("--headless", action="store_true", help="헤드리스 모드 실행")
    parser.add_argument("--links", type=str, help="테스트할 링크 (예: 1,2,3)")
    parser.add_argument("--skip", type=str, help="제외할 링크 (예: 10,11)")
    parser.add_argument("--url", type=str, default="http://localhost:5001", help="서버 URL")
    return parser.parse_args()


def main():
    args = parse_args()

    # 링크 파싱
    target_links = None
    skip_links = None

    if args.links:
        target_links = [int(l.strip()) for l in args.links.split(",")]
    if args.skip:
        skip_links = [int(l.strip()) for l in args.skip.split(",")]

    runner = PublicLinkTestRunner(
        base_url=args.url,
        headless=args.headless,
        target_links=target_links,
        skip_links=skip_links
    )

    runner.run_all()


if __name__ == "__main__":
    main()
