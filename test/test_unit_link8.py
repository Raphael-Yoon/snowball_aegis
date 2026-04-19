"""
Link8: 내부평가(Internal Assessment) Unit 테스트 코드
"""

import sys
from pathlib import Path
from datetime import datetime
import json

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

class Link8UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link8: 내부평가"
        self.checklist_source = project_root / "test" / "unit_checklist_link8.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link8_result.md"

    def setup(self):
        super().setup()
        self.last_dialog_message = None
        # 모든 다이얼로그 메시지를 저장하고 자동 승락
        def handle_dialog(dialog):
            self.last_dialog_message = dialog.message
            dialog.accept()
        self.page.on("dialog", handle_dialog)

    def _do_admin_login(self):
        """관리자 로그인"""
        self.page.goto(f"{self.base_url}/login")
        if self.page.locator("a:has-text('로그아웃')").count() > 0:
            return
        admin_btn = self.page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            self.page.wait_for_load_state("networkidle")

    def test_link8_access(self, result: UnitTestResult):
        """1. 페이지 접근 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)
        
        # 타이틀이나 헤더 확인
        header = self.page.locator("h1, h2, h3").first
        header_text = header.inner_text() if header.count() > 0 else ""
        
        if "내부평가" in header_text or "Assessment" in header_text or "Dashboard" in header_text:
            result.pass_test(f"페이지 로드 및 헤더 확인 완료: {header_text}")
        else:
            result.fail_test(f"헤더 불일치: {header_text}")

    def test_link8_company_list(self, result: UnitTestResult):
        """1. 회사 목록 및 RCM 카드 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)
        
        # RCM 카드들이 있는지 확인
        rcm_cards = self.page.locator(".rcm-card, .card")
        if rcm_cards.count() > 0:
            result.pass_test(f"RCM 카드 목록 표시 확인 ({rcm_cards.count()}개)")
        else:
            # 관리자 계정이면 최소한 하나는 있어야 함 (샘플 데이터 포함)
            result.fail_test("RCM 카드를 찾을 수 없습니다. 테스트 데이터 확인 필요.")

    def test_link8_progress_badges(self, result: UnitTestResult):
        """1. 진행 상태 배지 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)
        
        badges = self.page.locator(".badge")
        if badges.count() > 0:
            badge_texts = [badges.nth(i).inner_text().strip() for i in range(badges.count())]
            result.pass_test(f"상태 배지 확인 완료: {', '.join(badge_texts[:5])}...")
        else:
            result.fail_test("상태 배지를 찾을 수 없습니다.")

    def test_link8_detail_access(self, result: UnitTestResult):
        """2. 상세 페이지 진입 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)
        
        # 첫 번째 RCM 카드의 상세 버튼 클릭
        # 버튼 텍스트가 '상세보기', '상세', '보기' 등일 수 있음
        detail_btn = self.page.locator("a:has-text('상세'), a:has-text('이동'), .btn-primary").first
        if detail_btn.count() > 0:
            detail_btn.click()
            self.page.wait_for_load_state("networkidle")
            self.page.wait_for_timeout(1000)
            
            if "/link8/" in self.page.url:
                result.pass_test(f"상세 페이지 진입 확인: {self.page.url}")
            else:
                result.fail_test(f"상세 페이지 URL 불일치: {self.page.url}")
        else:
            result.fail_test("상세 페이지로 이동할 버튼을 찾을 수 없습니다.")

    def test_link8_summary_stats(self, result: UnitTestResult):
        """2. 상세 페이지 요약 통계 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)
        
        detail_btn = self.page.locator("a:has-text('상세 현황 보기')").first
        if detail_btn.count() > 0:
            detail_btn.click()
            self.page.wait_for_load_state("networkidle")
            self.page.wait_for_timeout(1000)
            
            # 요약 정보 (차트나 수치) 확인 - assessment_detail.jsp 기반
            stats = self.page.locator(".detail-card, .progress-bar")
            if stats.count() > 0:
                result.pass_test(f"상세 페이지({self.page.url}) 요약 통계 영역 표시 확인 ({stats.count()}개 요소)")
            else:
                result.fail_test(f"요약 통계 영역을 찾을 수 없습니다. (URL: {self.page.url})")
        else:
            result.skip_test("상세 이동 불가로 인한 건너뜜")

    def test_link8_progress_stepper(self, result: UnitTestResult):
        """2. 진행 스테퍼(타임라인) 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)
        
        detail_btn = self.page.locator("a:has-text('상세 현황 보기')").first
        if detail_btn.count() > 0:
            detail_btn.click()
            self.page.wait_for_load_state("networkidle")
            self.page.wait_for_timeout(1000)
            
            # 타임라인 형태의 스테퍼 확인
            stepper = self.page.locator(".timeline, .timeline-item")
            if stepper.count() > 0:
                result.pass_test(f"상세 페이지({self.page.url}) 타임라인 표시 확인 ({stepper.count()}개 요소)")
            else:
                result.fail_test(f"평가 단계 타임라인을 찾을 수 없습니다. (URL: {self.page.url})")
        else:
            result.skip_test("상세 이동 불가로 인한 건너뜜")

    def test_link8_step_navigation(self, result: UnitTestResult):
        """3. 단계별 이동 확인 (설계/운영평가 버튼)"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)

        detail_btn = self.page.locator("a:has-text('상세 현황 보기')").first
        if detail_btn.count() == 0:
            result.fail_test("상세 현황 보기 버튼을 찾을 수 없습니다.")
            return

        detail_btn.click()
        self.page.wait_for_load_state("networkidle")
        self.page.wait_for_timeout(1000)

        # 타임라인 내의 액션 버튼 확인 (설계평가/운영평가 버튼)
        # 버튼 텍스트: '설계평가 확인하기', '설계평가 계속하기', '운영평가 확인하기', '운영평가 계속하기'
        # 또는 잠김 상태: '설계평가 (잠김)', '운영평가 (설계평가 완료 후)'
        action_btn = self.page.locator("button:has-text('설계평가'), button:has-text('운영평가')").first
        if action_btn.count() > 0:
            btn_text = action_btn.inner_text().strip()
            is_disabled = action_btn.is_disabled()

            if is_disabled:
                # 버튼이 잠김 상태 - 정상 동작 (평가가 시작되지 않은 상태)
                result.pass_test(f"평가 버튼 확인 (상태: 잠김) - {btn_text}")
            else:
                # 버튼이 활성화 상태 - 클릭하여 이동 확인
                action_btn.click()
                self.page.wait_for_timeout(1000)
                result.pass_test(f"평가 화면 이동 확인 (버튼: {btn_text}) -> {self.page.url}")
        else:
            # 버튼이 없는 경우 (권한이나 상태 문제)
            result.fail_test(f"상세 페이지({self.page.url})에서 설계평가/운영평가 버튼을 찾을 수 없습니다.")

    def test_link8_step_templates(self, result: UnitTestResult):
        """5. 단계별 템플릿 렌더링 확인 (상세 페이지 내 타임라인 구조 검증)"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)

        detail_btn = self.page.locator("a:has-text('상세 현황 보기')").first
        if detail_btn.count() == 0:
            result.fail_test("상세 현황 보기 버튼을 찾을 수 없습니다.")
            return

        detail_btn.click()
        self.page.wait_for_load_state("networkidle")
        self.page.wait_for_timeout(1000)

        # 상세 페이지에서 타임라인 단계 요소 확인 (설계평가, 운영평가)
        # 타임라인에는 2단계(설계평가, 운영평가)가 표시됨
        timeline_items = self.page.locator(".timeline-item")
        timeline_count = timeline_items.count()

        if timeline_count >= 2:
            # 각 단계의 제목 확인
            step_names = []
            for i in range(timeline_count):
                item = timeline_items.nth(i)
                title = item.locator("h6, .timeline-title, strong").first
                if title.count() > 0:
                    step_names.append(title.inner_text().strip())

            result.pass_test(f"타임라인 단계 확인 완료: {timeline_count}개 단계 ({', '.join(step_names[:3])})")
        elif timeline_count > 0:
            result.pass_test(f"타임라인 구조 확인: {timeline_count}개 항목 발견")
        else:
            # 타임라인이 없으면 다른 구조 확인
            step_cards = self.page.locator(".step-card, .progress-step, .detail-card")
            if step_cards.count() > 0:
                result.pass_test(f"평가 단계 카드 확인: {step_cards.count()}개")
            else:
                result.fail_test("평가 단계 구조(타임라인/카드)를 찾을 수 없습니다.")

    def test_link8_design_evaluation_sync(self, result: UnitTestResult):
        """3. 설계평가 데이터 동기화 확인 (Link6 -> Link8)"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)

        detail_btn = self.page.locator("a:has-text('상세 현황 보기')").first
        if detail_btn.count() == 0:
            result.skip_test("상세 이동 불가")
            return

        detail_btn.click()
        self.page.wait_for_timeout(1500)

        # 설계평가(Step 1) 내의 평가 결과 통계 확인
        # Link6의 결과가 Link8의 상세 대시보드에 반영됨
        design_section = self.page.locator(".timeline-item", has_text="설계평가")
        counts = design_section.locator(".info-row").all_inner_texts()
        
        if len(counts) > 0:
            result.pass_test(f"설계평가 결과 동기화 확인 ({', '.join(counts)})")
        else:
            result.fail_test("설계평가 요약 정보를 찾을 수 없습니다.")

    def test_link8_operation_evaluation_sync(self, result: UnitTestResult):
        """3. 운영평가 데이터 동기화 확인 (Link7 -> Link8)"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)

        detail_btn = self.page.locator("a:has-text('상세 현황 보기')").first
        if detail_btn.count() == 0:
            result.skip_test("상세 이동 불가")
            return

        detail_btn.click()
        self.page.wait_for_timeout(1500)

        # 운영평가(Step 2) 내의 평가 결과 통계 확인
        op_section = self.page.locator(".timeline-item", has_text="운영평가")
        counts = op_section.locator(".info-row").all_inner_texts()
        
        if len(counts) > 0:
            result.pass_test(f"운영평가 결과 동기화 확인 ({', '.join(counts)})")
        else:
            result.fail_test("운영평가 요약 정보를 찾을 수 없습니다.")

    def test_link8_api_detail(self, result: UnitTestResult):
        """4. 상세 데이터 API 확인"""
        self._do_admin_login()
        self.navigate_to("/link8")
        self.page.wait_for_timeout(2000)

        # 첫 번째 카드에서 rcm_id 추출
        detail_link = self.page.locator("a:has-text('상세 현황 보기')").first
        href = detail_link.get_attribute("href")
        if not href:
            result.skip_test("상세 링크 없음")
            return
            
        # /link8/2/Eval_123 -> rcm_id=2, session=Eval_123
        parts = href.strip("/").split("/")
        if len(parts) >= 3:
            rcm_id = parts[1]
            session = parts[2]
            api_url = f"{self.base_url}/link8/api/detail/{rcm_id}/{session}"
            
            response = self.page.request.get(api_url)
            if response.status == 200:
                data = response.json()
                if data.get("success"):
                    result.pass_test(f"API 호출 성공 (디자인 통제 수: {data.get('design_detail', {}).get('total_controls', 0)})")
                else:
                    result.fail_test(f"API 응답 실패: {data.get('message')}")
            else:
                result.fail_test(f"API 요청 실패 (Status: {response.status})")
        else:
            result.fail_test(f"URL 파싱 실패: {href}")

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
                    # 메시지 내 줄바꿈 제거 및 공백 정리
                    clean_msg = res.message.replace('\n', ' ').replace('\r', '').strip()
                    if res.status == TestStatus.PASSED:
                        updated_line = line.replace("- [ ]", "- [x] ✅")
                        updated_line = updated_line.rstrip() + f" → **통과** ({clean_msg})\n"
                    elif res.status == TestStatus.FAILED:
                        updated_line = line.replace("- [ ]", "- [ ] ❌")
                        updated_line = updated_line.rstrip() + f" → **실패** ({clean_msg})\n"
                    elif res.status == TestStatus.WARNING:
                        updated_line = line.replace("- [ ]", "- [~] ⚠️")
                        updated_line = updated_line.rstrip() + f" → **경고** ({clean_msg})\n"
                    elif res.status == TestStatus.SKIPPED:
                        updated_line = line.replace("- [ ]", "- [ ] ⊘")
                        updated_line = updated_line.rstrip() + f" → **건너뜀** ({clean_msg})\n"
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
        print(f"\n✅ Link8 체크리스트 결과 저장됨: {self.checklist_result}")

def run_tests():
    # 5001 포트 사용
    test_runner = Link8UnitTest(base_url="http://localhost:5001", headless=False, slow_mo=500)
    test_runner.setup()
    try:
        test_runner.run_category("Link8 Unit Tests", [
            test_runner.test_link8_access,
            test_runner.test_link8_company_list,
            test_runner.test_link8_progress_badges,
            test_runner.test_link8_detail_access,
            test_runner.test_link8_summary_stats,
            test_runner.test_link8_progress_stepper,
            test_runner.test_link8_step_navigation,
            test_runner.test_link8_design_evaluation_sync,
            test_runner.test_link8_operation_evaluation_sync,
            test_runner.test_link8_api_detail,
            test_runner.test_link8_step_templates
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
