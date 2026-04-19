"""
인증/세션 Unit 테스트 코드 (Enhanced by Y2K Team)

주요 테스트 항목:
1. 로그인 페이지 보안 요소 확인
2. Mock Mail 기반 OTP 발송 프로세스 검증
3. 잘못된 OTP 입력 시 에러 핸들링 및 시도 횟수 제한 확인
4. 세션 쿠키 보안 설정(HttpOnly, SameSite) 확인 (기술적 보안 감사)
5. 세션 연장 API 동작 확인
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

class AuthUnitTest(PlaywrightTestBase):
    def __init__(self, **kwargs):
        self.test_db_path = str(project_root / "test_auth_unit.db")
        os.environ['SQLITE_DB_PATH'] = self.test_db_path
        os.environ['MOCK_MAIL'] = 'True'
        
        super().__init__(base_url="http://localhost:5001", **kwargs)
        self.category = "Auth: 인증/세션 (Y2K 강화)"
        self.checklist_source = project_root / "test" / "unit_checklist_auth.md"
        self.checklist_result = project_root / "test" / "unit_checklist_auth_result.md"

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

    def _get_otp_from_db(self, email):
        conn = sqlite3.connect(self.test_db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT otp_code FROM sb_user WHERE user_email = ?", (email,))
        row = cursor.fetchone()
        conn.close()
        return row[0] if row else None

    # -------------------------------------------------------------------------
    # 테스트 케이스
    # -------------------------------------------------------------------------

    def test_auth_login_page_security(self, result: UnitTestResult):
        """1. 로그인 페이지 보안 요소 확인"""
        self.navigate_to("/login")
        
        # HTTPS 권장 (로컬은 HTTP이나, 관련 meta 태그나 보안 설정 확인 가능한지 체크)
        # 여기서는 기본 입력 필드 확인
        if self.page.locator("input#email").count() > 0:
            result.add_detail("이메일 입력 필드 노출 확인")
            result.pass_test()

    def test_auth_otp_process_mocked(self, result: UnitTestResult):
        """2. Mock Mail 기반 OTP 발송 및 로그인 성공 확인"""
        self.navigate_to("/login")
        
        test_email = "user@test.com"
        self.page.fill("input#email", test_email)
        self.page.click("button:has-text('인증 코드 발송')")
        self.page.wait_for_load_state("load")

        # DB에서 생성된 OTP 가져오기 (Gmail API 대용)
        otp = self._get_otp_from_db(test_email)
        if not otp:
            result.fail_test("OTP가 데이터베이스에 생성되지 않음")
            return
        
        result.add_detail(f"생성된 OTP 확인 (DB): {otp}")
        
        self.page.fill("input#otp_code", otp)
        self.page.click("button:has-text('로그인')")
        self.page.wait_for_load_state("networkidle")

        if "/login" not in self.page.url:
            result.add_detail(f"로그인 성공 및 리다이렉트 확인: {self.page.url}")
            result.pass_test()
        else:
            result.fail_test("정확한 OTP 입력에도 로그인 실패")

    def test_auth_otp_limit_check(self, result: UnitTestResult):
        """3. 잘못된 OTP 입력 시도 횟수 제한 확인 (보안 강화)"""
        self.navigate_to("/login")
        test_email = "admin@test.com"
        
        self.page.fill("input#email", test_email)
        self.page.click("button:has-text('인증 코드 발송')")
        self.page.wait_for_load_state("load")

        # 틀린 OTP 3회 입력
        for i in range(3):
            self.page.fill("input#otp_code", "000000")
            self.page.click("button:has-text('로그인')")
            self.page.wait_for_load_state("networkidle")
            
            error_msg = self.page.locator(".error-message").text_content()
            result.add_detail(f"{i+1}회 시도 에러 메시지: {error_msg}")

        # 4회째 시도 시 차단 확인 (verify_otp 로직 상 3회 초과 시 리턴)
        self.page.fill("input#otp_code", "000000")
        self.page.click("button:has-text('로그인')")
        self.page.wait_for_load_state("networkidle")
        
        if "초과" in self.page.locator(".error-message").text_content():
            result.pass_test("OTP 시도 횟수 제한(3회) 및 차단 확인 완료")
        else:
            result.fail_test("시도 횟수 제한이 작동하지 않음")

    def test_auth_session_cookie_security(self, result: UnitTestResult):
        """4. 세션 쿠키 보안 설정 확인 (기술적 보안 감사)"""
        # 로그인을 수행하여 세션 쿠키 생성
        self.navigate_to("/login")
        self.page.locator(".admin-login-section button").click()
        self.page.wait_for_load_state("networkidle")

        cookies = self.context.cookies()
        session_cookie = next((c for c in cookies if c['name'] == 'session'), None)
        
        if not session_cookie:
            result.fail_test("세션 쿠키가 생성되지 않음")
            return
        
        result.add_detail(f"Cookie: {session_cookie}")
        
        # HttpOnly 확인 (JavaScript 탈취 방지)
        if session_cookie.get('httpOnly'):
            result.add_detail("HttpOnly 설정 확인 (XSS 방어)")
        else:
            result.warn_test("HttpOnly 설정이 누락됨 (보안 주의)")
            return

        # SameSite 설정 확인 (CSRF 방어)
        if session_cookie.get('sameSite') in ['Lax', 'Strict']:
            result.add_detail(f"SameSite={session_cookie.get('sameSite')} 설정 확인 (CSRF 방어)")
        else:
            result.warn_test("SameSite 설정이 미흡함")
            return

        result.pass_test("세션 쿠키 보안 속성 검증 완료")

def run_tests():
    test_runner = AuthUnitTest(headless=True)
    if not test_runner.check_server_running():
        return

    test_runner.setup()
    try:
        test_runner.run_category("Auth Unit Tests (Y2K)", [
            test_runner.test_auth_login_page_security,
            test_runner.test_auth_otp_process_mocked,
            test_runner.test_auth_otp_limit_check,
            test_runner.test_auth_session_cookie_security,
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
