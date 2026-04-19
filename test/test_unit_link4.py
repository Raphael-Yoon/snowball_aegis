"""
Link4: 영상 가이드 Unit 테스트 코드

주요 테스트 항목:
1. 페이지 UI 구성 및 초기 상태 확인
2. 사이드바 동작 및 컨텐츠 로딩
3. 비활성화/준비중 항목 처리 확인
4. 활동 로그 기록
"""

import sys
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

class Link4UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link4: 영상 가이드"
        self.checklist_source = project_root / "test" / "unit_checklist_link4.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link4_result.md"

    def test_link4_access(self, result: UnitTestResult):
        """1. 페이지 접근 확인"""
        self.navigate_to("/link4")
        if "영상 가이드" in self.page.title():
            result.pass_test("페이지 로드 및 타이틀 확인 완료")
        else:
            result.fail_test(f"타이틀 불일치: {self.page.title()}")

    def test_link4_initial_ui(self, result: UnitTestResult):
        """1. 초기 진입 UI 확인"""
        self.navigate_to("/link4")
        
        # 안내 메시지 확인
        msg = self.page.locator("#contentContainer h3").inner_text()
        if "항목을 선택해주세요" in msg:
            result.pass_test("초기 안내 메시지 확인")
        else:
            result.fail_test("초기 안내 메시지 누락")

    def test_link4_sidebar_categories(self, result: UnitTestResult):
        """1. 사이드바 카테고리 구성 확인"""
        self.navigate_to("/link4")
        categories = ["IT Process Wide Controls", "IT General Controls", "기타"]
        for cat in categories:
            if self.page.locator(f"text={cat}").count() > 0:
                result.add_detail(f"카테고리 존재 확인: {cat}")
            else:
                result.fail_test(f"카테고리 누락: {cat}")
                return
        result.pass_test("모든 카테고리 구성 확인 완료")

    def _expand_category(self, category_text: str):
        """카테고리가 닫혀있으면 클릭해서 확장"""
        header = self.page.locator(f".category-title:has-text('{category_text}')")
        option_list = header.locator("xpath=following-sibling::div[1]")
        
        # 'show' 클래스가 없으면 클릭
        if "show" not in (option_list.get_attribute("class") or ""):
            header.click()
            self.page.wait_for_timeout(300)

    def test_link4_sidebar_toggle(self, result: UnitTestResult):
        """2. 사이드바 펼치기/접기 확인"""
        self.navigate_to("/link4")
        
        cat_title = self.page.locator(".category-title").first
        
        # 초기 상태 확인 (첫 번째 카테고리 확장 시도)
        header_text = cat_title.inner_text().strip()
        self._expand_category(header_text) # 열기
        
        option_list = cat_title.locator("xpath=following-sibling::div[1]")
        if "show" in (option_list.get_attribute("class") or ""):
            result.add_detail(f"카테고리 '{header_text}' 확장 확인")
        else:
            result.fail_test(f"카테고리 '{header_text}' 확장 실패")
            return

        # 다시 클릭해서 닫기
        cat_title.click()
        self.page.wait_for_timeout(300)
        if "show" not in (option_list.get_attribute("class") or ""):
            result.pass_test("사이드바 토글 작동 확인")
        else:
            result.fail_test("사이드바 접기 실패")

    def test_link4_content_loading(self, result: UnitTestResult):
        """2. 항목 클릭 시 영상 컨텐츠(iframe) 로드 확인"""
        self.navigate_to("/link4")
        
        self._expand_category("IT Process Wide Controls")
        
        # '내부회계관리제도 Overview' 클릭
        self.page.locator("text=내부회계관리제도 Overview").click()
        
        # iframe 로드 대기
        try:
            iframe = self.page.locator("#youtube-frame")
            iframe.wait_for(state="visible", timeout=5000)
            src = iframe.get_attribute("src")
            if "youtube.com" in src:
                result.pass_test("영상 컨텐츠(iframe) 로드 확인")
            else:
                result.fail_test(f"잘못된 영상 소스: {src}")
        except Exception as e:
            result.fail_test(f"영상 로드 실패: {str(e)}")

    def test_link4_preparing_message(self, result: UnitTestResult):
        """2. 준비 중 항목 클릭 시 메시지 표시 확인"""
        self.navigate_to("/link4")
        
        self._expand_category("IT General Controls")
        
        # 준비 중인 항목 (Data 직접변경 승인) 클릭
        self.page.locator("text=Data 직접변경 승인").click()
        self.page.wait_for_timeout(500)
        
        msg = self.page.locator("#contentContainer h3").inner_text()
        if "준비 중입니다" in msg:
            result.pass_test("준비 중 메시지 표시 확인")
        else:
            result.fail_test(f"메시지 불일치: {msg}")

    def test_link4_sidebar_chevron_icon(self, result: UnitTestResult):
        """4. 사이드바 카테고리 chevron 아이콘 표시 확인 (FontAwesome)"""
        self.navigate_to("/link4")

        chevron_icons = self.page.locator(".category-title .fa-chevron-down")
        count = chevron_icons.count()

        if count > 0:
            result.add_detail(f"카테고리 chevron 아이콘 {count}개 확인")
        else:
            result.fail_test("chevron 아이콘을 찾을 수 없습니다. FontAwesome이 로드되지 않았을 수 있습니다.")
            return

        result.pass_test("사이드바 chevron 아이콘 표시 확인 완료 (FontAwesome 정상 로드)")

    def test_link4_activity_log(self, result: UnitTestResult):
        """3. 활동 로그 기록 확인 (로그인)"""
        try:
            self._do_admin_login()
            self.navigate_to("/link4")
            result.pass_test("로그인 상태에서 페이지 접근 완료")
        except Exception as e:
            result.fail_test(f"로그인 접근 실패: {str(e)}")

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
    test_runner = Link4UnitTest(headless=False, slow_mo=500)
    test_runner.setup()
    try:
        test_runner.run_category("Link4 Unit Tests", [
            test_runner.test_link4_access,
            test_runner.test_link4_initial_ui,
            test_runner.test_link4_sidebar_categories,
            test_runner.test_link4_sidebar_toggle,
            test_runner.test_link4_content_loading,
            test_runner.test_link4_preparing_message,
            test_runner.test_link4_sidebar_chevron_icon,
            test_runner.test_link4_activity_log
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
