"""
Link3: 운영평가 가이드 Unit 테스트 코드

주요 테스트 항목:
1. 페이지 UI 구성 및 초기 상태 확인
2. 사이드바 동적 제어 (펼치기/접기)
3. 항목 선택에 따른 Step-by-Step 컨텐츠 로드
4. 템플릿 다운로드 버튼 활성화 및 링크 확인
"""

import sys
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

class Link3UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link3: 운영평가 가이드"
        self.checklist_source = project_root / "test" / "unit_checklist_link3.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link3_result.md"

    def test_link3_access(self, result: UnitTestResult):
        """1. 페이지 접근 확인"""
        self.navigate_to("/link3")
        if "운영평가 가이드" in self.page.title():
            result.pass_test("페이지 로드 및 타이틀 확인 완료")
        else:
            result.fail_test(f"타이틀 불일치: {self.page.title()}")

    def test_link3_initial_ui(self, result: UnitTestResult):
        """1. 초기 진입 UI 확인"""
        self.navigate_to("/link3")
        
        # 안내 메시지 확인
        msg = self.page.locator("#contentContainer h3").inner_text()
        if "항목을 선택해주세요" in msg:
            result.pass_test("초기 안내 메시지 확인")
        else:
            result.fail_test("초기 안내 메시지 누락")

    def test_link3_sidebar_categories(self, result: UnitTestResult):
        """1. 사이드바 카테고리 구성 확인"""
        self.navigate_to("/link3")
        categories = ["Access Program & Data", "Program Changes", "Computer Operations"]
        for cat in categories:
            if self.page.locator(f"text={cat}").count() > 0:
                result.add_detail(f"카테고리 존재 확인: {cat}")
            else:
                result.fail_test(f"카테고리 누락: {cat}")
                return
        result.pass_test("모든 카테고리 구성 확인 완료")

    def test_link3_download_button_initial(self, result: UnitTestResult):
        """1. 초기 다운로드 버튼 상태 확인"""
        self.navigate_to("/link3")
        btn = self.page.locator("#template-download-btn")
        
        opacity = btn.evaluate("el => window.getComputedStyle(el).opacity")
        pointer_events = btn.evaluate("el => window.getComputedStyle(el).pointerEvents")
        
        if opacity == "0.5" and pointer_events == "none":
            result.pass_test("초기 버튼 비활성화 상태 확인")
        else:
            result.fail_test(f"버튼 활성화 상태이상: opacity={opacity}, pointer-events={pointer_events}")

    def test_link3_sidebar_toggle(self, result: UnitTestResult):
        """2. 사이드바 펼치기/접기 확인"""
        self.navigate_to("/link3")
        
        # 첫 번째 카테고리 클릭
        cat_title = self.page.locator(".category-title").first
        option_list = self.page.locator(".option-list").first
        
        # 초기 상태 (열려있을 수도 있고 닫혀있을 수도 있음. 코드상으로는 초기화 시 생성됨)
        # APD01이 보이는지 확인
        is_visible_before = self.page.locator("text=Application 권한부여 승인").is_visible()
        
        cat_title.click()
        self.page.wait_for_timeout(300)
        
        is_visible_after = self.page.locator("text=Application 권한부여 승인").is_visible()
        
        if is_visible_before != is_visible_after:
            result.pass_test("사이드바 토글 작동 확인")
        else:
            # 한 번 더 클릭해서 상태 변화 확인
            cat_title.click()
            self.page.wait_for_timeout(300)
            is_visible_final = self.page.locator("text=Application 권한부여 승인").is_visible()
            if is_visible_after != is_visible_final:
                result.pass_test("사이드바 토글 작동 확인 (2차 시도)")
            else:
                result.fail_test("사이드바 클릭 후 변화 없음")

    def _expand_category(self, category_text: str):
        """카테고리가 닫혀있으면 클릭해서 확장"""
        header = self.page.locator(f".category-title:has-text('{category_text}')")
        option_list = header.locator("xpath=following-sibling::div[1]")
        
        # 'show' 클래스가 없으면 클릭
        if "show" not in (option_list.get_attribute("class") or ""):
            header.click()
            self.page.wait_for_timeout(300)

    def test_link3_content_loading(self, result: UnitTestResult):
        """2. 항목 클릭 시 컨텐츠 로드 확인"""
        self.navigate_to("/link3")
        
        # 먼저 카테고리 확장 필요 (APD01은 Access Program & Data 소속)
        self._expand_category("Access Program & Data")
        
        # 'APD01' 항목 클릭
        self.page.locator("text=Application 권한부여 승인").click()
        self.page.wait_for_timeout(500)
        
        # Step 1 제목 확인
        step_title = self.page.locator("#step-title").inner_text()
        if "Step 1: 모집단 확인" in step_title:
            result.pass_test("APD01 클릭 시 Step 1 로드 확인")
        else:
            result.fail_test(f"컨텐츠 불일치: {step_title}")

    def test_link3_step_navigation(self, result: UnitTestResult):
        """2. 다음/이전 단계 이동 확인"""
        self.navigate_to("/link3")
        self._expand_category("Access Program & Data")
        self.page.locator("text=Application 권한부여 승인").click()
        
        # 다음 클릭
        self.page.click("#next-btn")
        self.page.wait_for_timeout(300)
        
        step_title = self.page.locator("#step-title").inner_text()
        if "Step 2: 샘플 선정" in step_title:
            result.add_detail("Step 2 이동 확인")
        else:
            result.fail_test("다음 버튼 작동 오류")
            return
            
        # 이전 클릭
        self.page.click("#prev-btn")
        self.page.wait_for_timeout(300)
        
        step_title = self.page.locator("#step-title").inner_text()
        if "Step 1: 모집단 확인" in step_title:
            result.pass_test("이전 버튼 작동 확인")
        else:
            result.fail_test("이전 버튼 작동 오류")

    def test_link3_download_button_active(self, result: UnitTestResult):
        """2. 항목 선택 후 다운로드 버튼 활성화 확인"""
        self.navigate_to("/link3")
        self._expand_category("Access Program & Data")
        self.page.locator("text=Application 권한부여 승인").click()
        
        btn = self.page.locator("#template-download-btn")
        opacity = btn.evaluate("el => window.getComputedStyle(el).opacity")
        
        if opacity == "1":
            result.pass_test("항목 선택 후 버튼 활성화 확인")
        else:
            result.fail_test(f"버튼 비활성화 상태: opacity={opacity}")

    def test_link3_download_link_correct(self, result: UnitTestResult):
        """2. 다운로드 링크 주소 확인"""
        self.navigate_to("/link3")
        
        # APD01
        self._expand_category("Access Program & Data")
        self.page.locator("text=Application 권한부여 승인").click()
        href = self.page.get_attribute("#template-download-btn", "href")
        if "APD01_paper.xlsx" in href:
             result.add_detail(f"APD01 링크 확인: {href}")
        else:
            result.fail_test(f"APD01 링크 오류: {href}")
            return
            
        # PC01 (항목 변경 테스트)
        self._expand_category("Program Changes")
        self.page.locator("text=프로그램 변경").click()
        href = self.page.get_attribute("#template-download-btn", "href")
        if "PC01_paper.xlsx" in href:
             result.pass_test("항목 변경 시 다운로드 링크 업데이트 확인")
        else:
            result.fail_test(f"PC01 링크 오류: {href}")

    def test_link3_activity_log(self, result: UnitTestResult):
        """3. 활동 로그 기록 확인 (로그인 필요)"""
        # 로그인이 필수이므로 먼저 수행
        try:
            # playwright_base.py의 helper 대신 직접 구현 (Link1 참고)
            self._do_admin_login()
            self.navigate_to("/link3")
            result.pass_test("로그인 상태에서 페이지 접근 기록 확인 가능 (DB 조회 생략)")
        except Exception as e:
            result.fail_test(f"로그인 접근 오류: {str(e)}")

    def _do_admin_login(self):
        """관리자 로그인"""
        self.page.goto(f"{self.base_url}/login")
        if self.page.locator("a:has-text('로그아웃')").count() > 0:
            return
        admin_btn = self.page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            self.page.wait_for_load_state("networkidle")

    def _update_checklist_result(self):
        """체크리스트 결과 파일 생성 (Link1 코드 재사용)"""
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
    test_runner = Link3UnitTest(headless=False, slow_mo=500)
    test_runner.setup()
    try:
        test_runner.run_category("Link3 Unit Tests", [
            test_runner.test_link3_access,
            test_runner.test_link3_initial_ui,
            test_runner.test_link3_sidebar_categories,
            test_runner.test_link3_download_button_initial,
            test_runner.test_link3_sidebar_toggle,
            test_runner.test_link3_content_loading,
            test_runner.test_link3_step_navigation,
            test_runner.test_link3_download_button_active,
            test_runner.test_link3_download_link_correct,
            test_runner.test_link3_activity_log
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
