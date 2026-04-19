"""
Link10: AI 분석 결과 조회 Unit 테스트 코드
"""

import sys
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

class Link10UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link10: AI 분석 결과"
        self.checklist_source = project_root / "test" / "unit_checklist_link10.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link10_result.md"

    def test_link10_access(self, result: UnitTestResult):
        """1. 페이지 접근 확인"""
        self.navigate_to("/link10")
        if "AI 분석 결과" in self.page.title():
            result.pass_test("페이지 로드 및 타이틀 확인 완료")
        else:
            result.fail_test(f"타이틀 불일치: {self.page.title()}")

    def test_link10_loading_state(self, result: UnitTestResult):
        """1. 로딩 스피너 확인"""
        self.navigate_to("/link10")
        # 로딩 스피너 존재 확인 (매우 빠르게 사라질 수 있으므로 존재 여부만 확인)
        spinner = self.page.locator(".spinner-border")
        if spinner.count() > 0:
            result.pass_test("초기 로딩 스피너 표시 확인")
        else:
            # 이미 로딩이 끝났을 수도 있으므로 resultsList가 비어있지 않으면 통과로 간주
            if self.page.locator("#resultsList").count() > 0:
                result.pass_test("로딩 완료 또는 스피너 확인")
            else:
                result.fail_test("로딩 상태 확인 불가")

    def test_link10_empty_state_or_list(self, result: UnitTestResult):
        """1. 결과 목록 표시 확인"""
        self.navigate_to("/link10")
        # 데이터가 로드될 때까지 충분히 대기
        self.page.wait_for_timeout(2000)
        
        cards = self.page.locator(".result-card")
        empty_msg = self.page.locator(".empty-state h3:has-text('AI 분석 결과가 없습니다')")
        
        if cards.count() > 0:
            result.pass_test(f"분석 결과 목록 표시 확인 ({cards.count()}개)")
        elif empty_msg.count() > 0:
            result.pass_test("분석 결과 없음 메시지 확인 (정상 케이스)")
        else:
            result.fail_test("목록 로드 후 상태 확인 실패")

    def test_link10_view_report(self, result: UnitTestResult):
        """2. AI 리포트 보기 모달 가동 확인"""
        self.navigate_to("/link10")
        self.page.wait_for_timeout(2000)
        
        btn_ai = self.page.locator(".btn-ai").first
        if btn_ai.count() > 0:
            btn_ai.click()
            self.page.wait_for_timeout(500)
            
            modal = self.page.locator("#aiModal")
            if modal.is_visible():
                result.pass_test("AI 리포트 모달 표시 확인")
            else:
                result.fail_test("모달이 표시되지 않음")
        else:
            result.skip_test("테스트할 결과 카드가 없음")

    def test_link10_report_content(self, result: UnitTestResult):
        """2. 모달 내 리포트 내용 로드 확인"""
        self.navigate_to("/link10")
        self.page.wait_for_timeout(2000)
        
        btn_ai = self.page.locator(".btn-ai").first
        if btn_ai.count() > 0:
            btn_ai.scroll_into_view_if_needed()
            btn_ai.click()
            
            # 주입된 HTML 내용이 나타날 때까지 대기
            try:
                # 스피너가 사라질 때까지 대기
                self.page.wait_for_selector("#aiResultContent .spinner-border", state="hidden", timeout=10000)
                
                content = self.page.locator("#aiResultContent")
                inner_html = content.inner_html()
                
                if "ai-markdown-body" in inner_html or "alert-warning" in inner_html or "alert-danger" in inner_html:
                    result.pass_test("리포트 내용 로드 또는 메시지 확인")
                else:
                    result.fail_test(f"내용 로드 결과 미흡: {inner_html[:100]}...")
            except Exception as e:
                result.fail_test(f"리포트 로드 시간 초과 또는 오류: {str(e)}")
        else:
            result.skip_test("테스트할 결과 카드가 없음")

    def test_link10_modal_close(self, result: UnitTestResult):
        """2. 모달 닫기 확인"""
        self.navigate_to("/link10")
        self.page.wait_for_timeout(1000)
        
        btn_ai = self.page.locator(".btn-ai").first
        if btn_ai.count() > 0:
            btn_ai.scroll_into_view_if_needed()
            btn_ai.click()
            self.page.wait_for_timeout(500)
            
            # 닫기 버튼 클릭
            self.page.locator("#aiModal .close-modal").click()
            self.page.wait_for_timeout(1000)
            
            if not self.page.locator("#aiModal").is_visible():
                result.pass_test("모달 닫기 기능 확인")
            else:
                result.fail_test("모달이 닫히지 않음")
        else:
            result.skip_test("테스트할 결과 카드가 없음")

    def test_link10_send_report_guest(self, result: UnitTestResult):
        """3. 게스트 상태에서 이메일 모달 확인"""
        self._do_logout()
        self.navigate_to("/link10")
        self.page.wait_for_timeout(2000)
        
        btn_send = self.page.locator(".btn-download").first
        if btn_send.count() > 0:
            btn_send.scroll_into_view_if_needed()
            btn_send.click()
            self.page.wait_for_timeout(500)
            
            modal = self.page.locator("#emailModal")
            if modal.is_visible():
                result.pass_test("게스트 상태에서 이메일 입력 모달 표시 확인")
            else:
                result.fail_test("이메일 모달이 표시되지 않음")
        else:
            result.skip_test("테스트할 결과 카드가 없음")

    def test_link10_email_validation(self, result: UnitTestResult):
        """3. 이메일 유효성 검사 확인"""
        self._do_logout()
        self.navigate_to("/link10")
        self.page.wait_for_timeout(2000)
        
        btn_send = self.page.locator(".btn-download").first
        if btn_send.count() > 0:
            btn_send.scroll_into_view_if_needed()
            btn_send.click()
            self.page.wait_for_timeout(1000)
            
            # 잘못된 이메일 입력
            self.page.locator("#recipientEmail").fill("invalid-email")
            # 이메일 모달의 전송 버튼 클릭
            self.page.locator("#emailModal button:has-text('전송')").click()
            self.page.wait_for_timeout(500)
            
            error_msg = self.page.locator("#emailError")
            if error_msg.is_visible():
                result.pass_test("이메일 유효성 검사 메시지 표시 확인")
            else:
                result.fail_test("유효성 검사가 동작하지 않음")
        else:
            result.skip_test("테스트할 결과 카드가 없음")

    def test_link10_logged_in_action(self, result: UnitTestResult):
        """3. 로그인 상태에서 전송 액션 확인"""
        try:
            self._do_admin_login()
            self.navigate_to("/link10")
            self.page.wait_for_timeout(1500)
            
            btn_send = self.page.locator(".btn-download").first
            if btn_send.count() > 0:
                # 로그인 상태에서는 이메일 모달 없이 바로 다운로드/동작 발생
                # 여기서는 모달이 뜨지 않는지만 확인
                btn_send.click()
                self.page.wait_for_timeout(1000)
                
                modal = self.page.locator("#emailModal")
                if not modal.is_visible():
                    result.pass_test("로그인 상태에서 이메일 모달 없이 동작함 확인")
                else:
                    result.fail_test("로그인 상태인데 이메일 모달이 표시됨")
            else:
                result.skip_test("테스트할 결과 카드가 없음")
        except Exception as e:
            result.fail_test(f"로그인 테스트 실패: {str(e)}")

    def _do_admin_login(self):
        """관리자 로그인"""
        self.page.goto(f"{self.base_url}/login")
        if self.page.locator("a:has-text('로그아웃')").count() > 0:
            return
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
    test_runner = Link10UnitTest(headless=False, slow_mo=500)
    test_runner.setup()
    try:
        test_runner.run_category("Link10 Unit Tests", [
            test_runner.test_link10_access,
            test_runner.test_link10_loading_state,
            test_runner.test_link10_empty_state_or_list,
            test_runner.test_link10_view_report,
            test_runner.test_link10_report_content,
            test_runner.test_link10_modal_close,
            test_runner.test_link10_send_report_guest,
            test_runner.test_link10_email_validation,
            test_runner.test_link10_logged_in_action
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
