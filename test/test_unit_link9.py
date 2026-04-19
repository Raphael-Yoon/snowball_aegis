"""
Link9: 서비스 문의 (Contact Us) Unit 테스트 코드
"""

import sys
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

class Link9UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link9: 서비스 문의"
        self.checklist_source = project_root / "test" / "unit_checklist_link9.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link9_result.md"

    def test_link9_access(self, result: UnitTestResult):
        """1. 페이지 접근 확인"""
        self.navigate_to("/link9")
        if "서비스 문의" in self.page.title():
            result.pass_test("페이지 로드 및 타이틀 확인 완료")
        else:
            result.fail_test(f"타이틀 불일치: {self.page.title()}")

    def test_link9_ui_guest(self, result: UnitTestResult):
        """1. 게스트 UI 상태 확인"""
        self._do_logout()
        self.navigate_to("/link9")
        
        # 필드 입력 가능 여부 확인
        company_input = self.page.locator("#company_name")
        email_input = self.page.locator("#email")
        
        is_company_readonly = company_input.get_attribute("readonly") is not None
        is_email_readonly = email_input.get_attribute("readonly") is not None
        
        if not is_company_readonly and not is_email_readonly:
            result.pass_test("게스트 상태에서 필드 입력 가능 확인")
        else:
            result.fail_test("게스트 상태인데 필드가 읽기 전용임")

    def test_link9_ui_logged_in(self, result: UnitTestResult):
        """1. 로그인 상태 UI 확인"""
        self._do_admin_login()
        self.navigate_to("/link9")
        
        company_input = self.page.locator("#company_name")
        email_input = self.page.locator("#email")
        
        is_company_readonly = company_input.get_attribute("readonly") is not None
        is_email_readonly = email_input.get_attribute("readonly") is not None
        
        if is_company_readonly and is_email_readonly:
            val = email_input.get_attribute("value")
            if val and "@" in val:
                result.pass_test(f"로그인 상태에서 필드 고정 및 데이터 자동입력 확인 ({val})")
            else:
                result.fail_test("자동 입력된 이메일 값이 유효하지 않음")
        else:
            result.fail_test("로그인 상태인데 필드가 입력 가능한 상태임")

    def test_link9_form_validation(self, result: UnitTestResult):
        """2. 폼 유효성 검사 확인"""
        self._do_logout()
        self.navigate_to("/link9")
        
        # 빈 상태에서 제출 클릭
        self.page.click("button[type='submit']")
        
        # 브라우저의 전형적인 유효성 검사 확인 (필드가 비어있음)
        # HTML5 validation 메시지는 스크립트로 확인하기 까다로우므로 
        # 페이지 리로드(POST 전송)가 발생하지 않았는지 확인
        self.page.wait_for_timeout(500)
        if self.page.url.endswith("/link9") and self.page.locator(".alert-success").count() == 0:
            result.pass_test("필수값 누락 시 폼 전송 차단 확인")
        else:
            result.fail_test("필수값 누락 상태에서 폼이 전송됨")

    def test_link9_send_success(self, result: UnitTestResult):
        """2. 문의 전송 성공 확인"""
        self._do_logout()
        self.navigate_to("/link9")
        
        self.page.fill("#company_name", "Test Company")
        self.page.fill("#name", "Tester")
        self.page.fill("#email", "newsist2727@naver.com") # 테스트용 이메일
        self.page.fill("#message", "Unit Test Message: Link9 Contact Us Test")
        
        self.page.click("button[type='submit']")
        
        # 성공 메시지 대기 (메일 발송에 시간이 걸릴 수 있음)
        try:
            success_alert = self.page.locator(".alert-success")
            success_alert.wait_for(state="visible", timeout=10000)
            if "성공적으로 접수" in success_alert.inner_text():
                result.pass_test("문의 전송 및 성공 메시지 확인 완료")
            else:
                result.fail_test(f"예상치 못한 성공 메시지: {success_alert.inner_text()}")
        except Exception as e:
            # 메일 발송 설정이 안 되어 있으면 실패할 수 있음
            result.fail_test(f"성공 메시지가 나타나지 않음 (SMTP 설정 확인 필요): {str(e)}")

    def test_link9_send_failure_handling(self, result: UnitTestResult):
        """2. 문의 전송 실패 확인 (서버 오류 모의)"""
        self._do_logout()
        self.navigate_to("/link9")
        
        # POST 요청 가로채기
        def handle_route(route):
            if route.request.method == "POST":
                # 실패 메시지를 포함한 HTML 응답 반환
                html_content = """
                <!DOCTYPE html>
                <html>
                <head><meta charset="UTF-8"></head>
                <body>
                    <div class="alert alert-danger text-center">문의 접수에 실패했습니다.<br>Mocked Server Error</div>
                </body>
                </html>
                """
                route.fulfill(status=200, body=html_content, content_type="text/html")
            else:
                route.continue_()

        # 모든 /link9 요청 가로채되 POST만 처리
        self.page.route("**/link9", handle_route)
        
        self.page.fill("#company_name", "Fail Test")
        self.page.fill("#email", "fail@test.com")
        self.page.fill("#message", "Force Fail Test")
        
        # 제출 클릭 및 이동 대기
        self.page.click("button[type='submit']")
        self.page.wait_for_timeout(2000)

        error_alert = self.page.locator(".alert-danger")
        if error_alert.count() > 0:
            text = error_alert.inner_text()
            if "실패" in text:
                result.pass_test(f"실패 메시지 노출 확인: {text.strip()}")
            else:
                result.fail_test(f"경고창은 나타났으나 메시지 내용 불일치: {text}")
        else:
            result.fail_test("서버 오류 시 .alert-danger 메시지가 표시되지 않음")
        
        # 라우팅 해제
        self.page.unroute("**/link9")

    def test_link9_service_inquiry(self, result: UnitTestResult):
        """3. 로그인 페이지 서비스 문의 확인"""
        self._do_logout()
        self.page.goto(f"{self.base_url}/login")
        
        # 서비스 문의 버튼 클릭하여 폼 노출
        btn_show = self.page.locator("#showInquiryBtn")
        if btn_show.count() > 0:
            btn_show.click()
            self.page.wait_for_timeout(500)
        else:
            result.fail_test("서비스 문의 버튼(#showInquiryBtn)을 찾을 수 없음")
            return

        # 폼 필드 입력 (login.jsp의 ID 사용)
        self.page.fill("#inquiryContainer #company_name", "Service Test Inc")
        self.page.fill("#inquiryContainer #contact_name", "Inquiry Manager")
        self.page.fill("#inquiryContainer #contact_email", "newsist2727@naver.com")
        
        # '서비스 문의' 제출 버튼 클릭
        submit_btn = self.page.locator("#serviceInquiryForm button[type='submit']")
        if submit_btn.count() > 0:
            submit_btn.click()
            self.page.wait_for_timeout(1000)
            
            # 성공 메시지 확인 (login.jsp로 리다이렉트됨)
            if self.page.locator(".success-message").count() > 0:
                result.pass_test("서비스 가입 문의 성공 확인")
            else:
                result.fail_test("서비스 가입 문의 성공 메시지 누락")
        else:
            result.fail_test("로그인 페이지에서 서비스 문의 제출 버튼을 찾을 수 없음")

    def _do_admin_login(self):
        """관리자 로그인"""
        self.page.goto(f"{self.base_url}/login")
        if self.page.locator("a:has-text('로그아웃')").count() > 0:
            return
        # admin-login-section 버튼 클릭
        admin_btn = self.page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            self.page.wait_for_load_state("networkidle")

    def _do_logout(self):
        """로그아웃"""
        self.page.goto(f"{self.base_url}/logout")
        self.page.wait_for_load_state("networkidle")

    def _update_checklist_result(self):
        """체크리스트 결과 파일 생성"""
        if not self.checklist_source.exists():
            return
        with open(self.checklist_source, 'r', encoding='utf-8') as f:
            lines = f.readlines()

        updated_lines = []
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        updated_lines.append(f"<!-- Test Run: {timestamp} -->\n")

        for line in lines:
            updated_line = line
            for res in self.results:
                if res.test_name in line:
                    if res.status == TestStatus.PASSED:
                        updated_line = line.replace("- [ ]", "- [x] ✅")
                        updated_line = updated_line.rstrip() + f" → **통과** ({res.message})\n"
                    elif res.status == TestStatus.FAILED:
                        updated_line = line.replace("- [ ]", "- [ ] ❌")
                        updated_line = updated_line.rstrip() + f" → **실패** ({res.message})\n"
                    elif res.status == TestStatus.WARNING:
                        updated_line = line.replace("- [ ]", "- [~] ⚠️")
                        updated_line = updated_line.rstrip() + f" → **경고** ({res.message})\n"
                    elif res.status == TestStatus.SKIPPED:
                        updated_line = line.replace("- [ ]", "- [ ] ⊘")
                        updated_line = updated_line.rstrip() + f" → **건너뜀** ({res.message})\n"
                    break
            updated_lines.append(updated_line)

        passed = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        warned = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total = len(self.results) if self.results else 1

        updated_lines.append("\n---\n")
        updated_lines.append(f"## 테스트 결과 요약\n\n")
        updated_lines.append(f"| 항목 | 개수 | 비율 |\n")
        updated_lines.append(f"|------|------|------|\n")
        updated_lines.append(f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n")
        updated_lines.append(f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n")
        updated_lines.append(f"| ⚠️ 경고 | {warned} | {warned/total*100:.1f}% |\n")
        updated_lines.append(f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n")
        updated_lines.append(f"| **총계** | **{total}** | **100%** |\n")

        with open(self.checklist_result, 'w', encoding='utf-8') as f:
            f.writelines(updated_lines)

def run_tests():
    test_runner = Link9UnitTest(headless=False, slow_mo=500)
    test_runner.setup()
    try:
        test_runner.run_category("Link9 Unit Tests", [
            test_runner.test_link9_access,
            test_runner.test_link9_ui_guest,
            test_runner.test_link9_ui_logged_in,
            test_runner.test_link9_form_validation,
            test_runner.test_link9_send_success,
            test_runner.test_link9_send_failure_handling,
            test_runner.test_link9_service_inquiry
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
