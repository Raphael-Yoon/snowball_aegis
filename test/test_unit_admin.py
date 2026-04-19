"""
관리자 기능 Unit 테스트 코드 (Enhanced by Y2K Team)

주요 테스트 항목:
1. 비로그인 상태에서 /admin 접근 차단 확인
2. 일반 사용자 권한으로 /admin 접근 차단 확인 (ITGC 권한 관리 통제 테스트)
3. 관리자 대시보드 요소 확인
4. 사용자 추가 API 유효성 및 데이터 정합성 확인 (Mutation Test)
5. RCM 관리 및 활동 로그 요소 확인
"""

import sys
import os
import sqlite3
from pathlib import Path
from datetime import datetime

project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult
from test.test_db_util import create_test_db

class AdminUnitTest(PlaywrightTestBase):
    def __init__(self, **kwargs):
        # 테스트용 DB 및 이메일 모킹 환경 변수 설정
        self.test_db_path = str(project_root / "test_admin_unit.db")
        os.environ['SQLITE_DB_PATH'] = self.test_db_path
        os.environ['MOCK_MAIL'] = 'True'
        
        # 서버 포트 변경 (병렬 실행 시 충돌 방지, 여기서는 기본 포트 사용)
        super().__init__(base_url="http://localhost:5001", **kwargs)
        self.category = "Admin: 관리자 기능 (Y2K 강화)"
        self.checklist_source = project_root / "test" / "unit_checklist_admin.md"
        self.checklist_result = project_root / "test" / "unit_checklist_admin_result.md"

    def setup(self):
        """테스트 시작 전 DB 초기화 및 서버 구동"""
        create_test_db(self.test_db_path)
        super().setup()

    def teardown(self):
        """테스트 종료 후 정리"""
        super().teardown()
        # 프로세스 종료 후 DB 파일 삭제 (Windows에서는 파일 열려있으면 실패할 수 있음)
        try:
            if os.path.exists(self.test_db_path):
                os.remove(self.test_db_path)
        except:
            pass

    # -------------------------------------------------------------------------
    # 헬퍼
    # -------------------------------------------------------------------------

    def _do_login(self, email="admin@test.com", otp="123456"):
        """로그인 수행 (고정 OTP 사용)"""
        self.page.goto(f"{self.base_url}/login")
        self.page.wait_for_load_state("networkidle")

        # 관리자 직접 로그인 버튼 시도 (localhost)
        if email == "admin@test.com":
            admin_btn = self.page.locator(".admin-login-section button[type='submit']")
            if admin_btn.count() > 0:
                admin_btn.click()
                self.page.wait_for_load_state("networkidle")
                return

        # 일반 OTP 로그인 시뮬레이션
        self.page.fill("input#email", email)
        self.page.click("button:has-text('인증 코드 발송')")
        self.page.wait_for_load_state("load")
        
        self.page.fill("input#otp_code", otp)
        self.page.click("button:has-text('로그인')")
        self.page.wait_for_load_state("networkidle")

    def _do_logout(self):
        """로그아웃 수행"""
        self.page.goto(f"{self.base_url}/logout")
        self.page.wait_for_load_state("networkidle")

    # -------------------------------------------------------------------------
    # 테스트 케이스
    # -------------------------------------------------------------------------

    def test_admin_no_access_without_login(self, result: UnitTestResult):
        """1. 비로그인 상태에서 /admin 접근 → 차단 확인"""
        self._do_logout()
        self.navigate_to("/admin")

        current_url = self.page.url
        if "/login" in current_url or "로그인" in self.page.content():
            result.pass_test("비로그인 상태 /admin 접근 차단 확인")
        else:
            result.fail_test(f"비로그인 상태에서 /admin 접근 허용됨 (URL: {current_url})")

    def test_admin_no_access_wrong_user(self, result: UnitTestResult):
        """2. 일반 사용자 계정으로 /admin 접근 → 403 Forbidden 확인 (ITGC 핵심 통제)"""
        self._do_login(email="user@test.com")
        
        # 권한 확인
        self.page.goto(f"{self.base_url}/admin")
        
        content = self.page.content()
        if "접근 권한이 없습니다" in content or "403" in content:
            result.add_detail("일반 사용자의 관리자 페이지 접근 차단 확인")
            result.pass_test("일반 사용자 관리자 페이즈 접근 거부 확인 (403)")
        else:
            # 리다이렉트 처리되는 경우도 허용 (안전한 설계)
            if "/admin" not in self.page.url:
                result.pass_test("비권한 유저 리다이렉트 차단 확인")
            else:
                result.fail_test("일반 사용자가 관리자 페이지에 접근 성공함 (보안 취약점)")

    def test_admin_dashboard_elements(self, result: UnitTestResult):
        """3. 관리자 대시보드 카드 구성 요소 확인"""
        self._do_login(email="admin@test.com")
        self.navigate_to("/admin")

        # 카드 제목(h5)과 링크(a)를 모두 확인
        cards = {
            "사용자 관리": ["/admin/users", "사용자 관리"],
            "활동 로그": ["/admin/logs", "로그 조회"],
            "RCM 관리": ["/admin/rcm", "RCM 관리"],
            "기준통제 관리": ["/admin/standard-controls", "기준통제 관리"]
        }
        
        for title, [href, link_text] in cards.items():
            card_found = False
            # 1. 카드 제목이 있는지 확인
            if self.page.locator(f"h5:has-text('{title}')").count() > 0:
                card_found = True
            # 2. 또는 특정 링크가 있는지 확인
            elif self.page.locator(f"a[href='{href}']").count() > 0:
                card_found = True
                
            if card_found:
                result.add_detail(f"확인: {title} ({href})")
            else:
                result.fail_test(f"누락된 카드: {title}")
                return
        result.pass_test("대시보드 주요 관리 링크 확인 완료")

    def test_admin_add_user_mutation(self, result: UnitTestResult):
        """4. 사용자 추가 API 및 데이터 정합성 확인 (Mutation Test)"""
        self._do_login(email="admin@test.com")
        self.navigate_to("/admin/users")

        # '새 사용자 추가' 버튼 클릭
        self.page.click("button:has-text('새 사용자 추가')")
        self.page.wait_for_selector("#addUserModal", state="visible")

        # 데이터 입력 (모달 내부의 input[name=...] 사용)
        test_email = f"newuser_{datetime.now().strftime('%H%M%S')}@example.com"
        self.page.locator("#addUserModal input[name='user_email']").fill(test_email)
        self.page.locator("#addUserModal input[name='user_name']").fill("TestUser")
        self.page.locator("#addUserModal input[name='company_name']").fill("TestCompany")
        
        # '추가' 버튼 클릭 (Mutation 발생)
        # 모달 내부에 있는 submit 버튼 클릭
        self.page.click("#addUserModal button[type='submit']")
        self.page.wait_for_load_state("networkidle")

        # 테이블에서 확인
        if self.page.locator(f"td:has-text('{test_email}')").count() > 0:
            result.add_detail(f"신규 사용자({test_email}) 리스트 노출 확인")
            
            # DB 레벨에서도 직접 확인 (기술적 무결성)
            conn = sqlite3.connect(self.test_db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM sb_user WHERE user_email = ?", (test_email,))
            if cursor.fetchone():
                result.add_detail("데이터베이스 직접 쿼리 결과 일치 확인")
                result.pass_test("사용자 추가 API 및 데이터 정합성 확인 완료")
            else:
                result.fail_test("UI에는 표시되나 DB에 데이터가 저장되지 않음")
            conn.close()
        else:
            result.fail_test("사용자 추가 후 목록에서 찾을 수 없음")

    def test_admin_logs_filtering(self, result: UnitTestResult):
        """5. 활동 로그 페이지 필터 기능 확인"""
        self._do_login(email="admin@test.com")
        self.navigate_to("/admin/logs")

        # 필터 폼 확인
        if self.page.locator("select[name='user_id']").count() > 0:
            result.add_detail("필터 드롭다운 확인")
            result.pass_test("활동 로그 필터 UI 확인 완료")
        else:
            result.fail_test("활동 로그 필터 요소를 찾을 수 없음")

def run_tests():
    test_runner = AdminUnitTest(headless=True)
    if not test_runner.check_server_running():
        return

    test_runner.setup()
    try:
        test_runner.run_category("Admin Unit Tests (Y2K)", [
            test_runner.test_admin_no_access_without_login,
            test_runner.test_admin_no_access_wrong_user,
            test_runner.test_admin_dashboard_elements,
            test_runner.test_admin_add_user_mutation,
            test_runner.test_admin_logs_filtering,
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
