"""
공통 API Unit 테스트 (snowball.py 핵심 엔드포인트)

주요 테스트 항목:
1. GET /health - 서버 상태 확인 API 응답 형식
2. GET / - 비로그인 상태 메인 페이지
3. GET / - 로그인 상태 메인 페이지 (사용자명, 로그아웃 링크)
4. GET / - 카드 목록 구성 확인 (Dashboard, RCM, ELC, TLC, ITGC 등)
5. POST /clear_session - 세션 초기화 API (204 응답)
6. 존재하지 않는 경로 - 404 처리
"""

import sys
import os
import requests
from pathlib import Path

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult
from test.test_db_util import create_test_db


class CommonApiUnitTest(PlaywrightTestBase):
    def __init__(self, **kwargs):
        self.test_db_path = str(project_root / "test_common_api_unit.db")
        os.environ['SQLITE_DB_PATH'] = self.test_db_path
        os.environ['MOCK_MAIL'] = 'True'

        super().__init__(base_url="http://localhost:5001", **kwargs)
        self.checklist_source = project_root / "test" / "unit_checklist_common_api.md"
        self.checklist_result = project_root / "test" / "unit_checklist_common_api_result.md"

    def setup(self):
        create_test_db(self.test_db_path)
        super().setup()

    def teardown(self):
        super().teardown()
        try:
            if os.path.exists(self.test_db_path):
                os.remove(self.test_db_path)
        except:
            pass

    # -------------------------------------------------------------------------
    # 헬퍼
    # -------------------------------------------------------------------------

    def _do_admin_login(self):
        """관리자 직접 로그인 (localhost 전용 버튼)"""
        self.page.goto(f"{self.base_url}/login", wait_until="domcontentloaded", timeout=10000)
        btn = self.page.locator(".admin-login-section button[type='submit']")
        if btn.count() > 0:
            btn.click()
            self.page.wait_for_load_state("domcontentloaded", timeout=10000)

    def _do_logout(self):
        """로그아웃"""
        self.page.goto(f"{self.base_url}/logout", wait_until="domcontentloaded", timeout=10000)

    # -------------------------------------------------------------------------
    # 테스트 케이스
    # -------------------------------------------------------------------------

    def test_common_health_check(self, result: UnitTestResult):
        """1. GET /health → {status: ok, host, timestamp} 응답 형식 확인"""
        resp = requests.get(f"{self.base_url}/health", timeout=5)

        if resp.status_code != 200:
            result.fail_test(f"HTTP {resp.status_code} 응답")
            return

        try:
            data = resp.json()
        except Exception:
            result.fail_test("JSON 파싱 실패")
            return

        required_fields = ['status', 'host', 'timestamp']
        for field in required_fields:
            if field not in data:
                result.fail_test(f"응답에 '{field}' 필드 없음: {data}")
                return
            result.add_detail(f"{field}: {data[field]}")

        if data.get('status') != 'ok':
            result.fail_test(f"status가 'ok'가 아님: {data['status']}")
            return

        result.pass_test("/health 응답 구조 및 status='ok' 확인 완료")

    def test_common_index_guest(self, result: UnitTestResult):
        """2. GET / 비로그인 상태 → 로그인 유도 UI 표시 확인"""
        self._do_logout()
        self.navigate_to("/")

        page_text = self.page.content()

        # 비로그인 시 '환영합니다' 문구 없어야 함
        welcome = self.page.locator(".user-welcome")
        if welcome.count() > 0:
            result.fail_test("비로그인 상태에서 환영 메시지가 표시됨")
            return
        result.add_detail("비로그인 상태: 환영 메시지 미표시 확인")

        # 로그인 링크 표시 확인
        login_link = self.page.locator("a[href='/login']")
        if login_link.count() > 0:
            result.add_detail("로그인 링크 표시 확인")
        else:
            result.fail_test("비로그인 상태에서 로그인 링크가 없음")
            return

        result.pass_test("비로그인 메인 페이지 UI 확인 완료")

    def test_common_index_logged_in(self, result: UnitTestResult):
        """3. 로그인 후 GET / → 사용자명 환영 메시지, 로그아웃 링크 표시 확인"""
        self._do_admin_login()
        self.navigate_to("/")

        # 환영 메시지 확인
        welcome = self.page.locator(".user-welcome")
        if welcome.count() == 0:
            result.fail_test("로그인 후 환영 메시지(.user-welcome)를 찾을 수 없음")
            return
        welcome_text = welcome.first.text_content()
        result.add_detail(f"환영 메시지: {welcome_text.strip()}")

        # 로그아웃 링크 확인
        logout_link = self.page.locator("a[href='/logout']")
        if logout_link.count() == 0:
            result.fail_test("로그인 후 로그아웃 링크가 없음")
            return
        result.add_detail("로그아웃 링크 표시 확인")

        result.pass_test("로그인 후 메인 페이지 사용자 정보 표시 확인 완료")

    def test_common_index_cards(self, result: UnitTestResult):
        """4. 메인 페이지 서비스 카드 구성 확인 (Dashboard, RCM, ELC, TLC, ITGC)"""
        self._do_admin_login()
        self.navigate_to("/")

        # feature-card 수 확인
        cards = self.page.locator(".feature-card")
        card_count = cards.count()
        result.add_detail(f"feature-card 총 개수: {card_count}개")

        if card_count == 0:
            result.fail_test("메인 페이지에 카드가 없음")
            return

        # 각 카드 제목 확인
        expected_titles = ["Dashboard", "RCM", "ELC", "TLC", "ITGC"]
        found_titles = []
        for title in expected_titles:
            if self.page.locator(f"h5.feature-title:has-text('{title}')").count() > 0:
                found_titles.append(title)
                result.add_detail(f"카드 확인: {title}")

        if len(found_titles) >= 4:
            result.pass_test(f"서비스 카드 {len(found_titles)}/{len(expected_titles)}개 확인 완료")
        else:
            result.fail_test(f"확인된 카드 부족: {found_titles} (기대: {expected_titles})")

    def test_common_clear_session(self, result: UnitTestResult):
        """5. POST /clear_session → 204 No Content 응답 확인"""
        self._do_admin_login()
        self.navigate_to("/")

        # 브라우저 컨텍스트에서 fetch 호출 (session-manager.js와 동일한 방식)
        status = self.page.evaluate("""
            async () => {
                const resp = await fetch('/clear_session', {
                    method: 'POST',
                    credentials: 'include'
                });
                return resp.status;
            }
        """)

        result.add_detail(f"POST /clear_session 응답 코드: {status}")

        if status == 204:
            result.pass_test("POST /clear_session → 204 No Content 응답 확인")
        elif status == 200:
            result.warn_test("POST /clear_session → 200 응답 (204 기대)")
        else:
            result.fail_test(f"POST /clear_session 예상치 못한 응답: {status}")

    def test_common_404_handling(self, result: UnitTestResult):
        """6. 존재하지 않는 경로 접근 → 404 응답 확인"""
        resp = requests.get(
            f"{self.base_url}/nonexistent_path_xyz_test",
            timeout=5,
            allow_redirects=False
        )

        result.add_detail(f"GET /nonexistent_path_xyz_test 응답: {resp.status_code}")

        if resp.status_code == 404:
            result.pass_test("존재하지 않는 경로 → 404 응답 확인 완료")
        elif resp.status_code in (301, 302):
            location = resp.headers.get('Location', '')
            result.add_detail(f"리다이렉트: {location}")
            result.pass_test("존재하지 않는 경로 → 리다이렉트 처리 확인")
        else:
            result.warn_test(f"예상치 못한 응답 코드: {resp.status_code}")


def run_tests():
    test_runner = CommonApiUnitTest(headless=True, slow_mo=200)
    if not test_runner.check_server_running():
        print("서버가 실행되지 않아 테스트를 중단합니다.")
        return

    test_runner.setup()
    try:
        test_runner.run_category("Common API Unit Tests", [
            test_runner.test_common_health_check,
            test_runner.test_common_index_guest,
            test_runner.test_common_index_logged_in,
            test_runner.test_common_index_cards,
            test_runner.test_common_clear_session,
            test_runner.test_common_404_handling,
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()


if __name__ == "__main__":
    run_tests()
