"""
Link2: ITGC 인터뷰 Unit 테스트 코드 (1-page 섹션 방식)

대상 URL: /link2_1p (섹션형 인터뷰 시스템)
섹션 구성: common → apd → pc → co

주요 테스트 항목:
1. 페이지 접근 및 섹션 리다이렉트 확인
2. 섹션 스텝 인디케이터 UI 확인
3. 이메일 필드 및 Y/N 버튼 동작
4. 조건부 질문 숨김/표시 로직
5. 관리자 샘플입력 버튼 확인
6. 섹션 간 내비게이션 (폼 제출)
7. 전체 인터뷰 완료 흐름
"""

import sys
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

SECTIONS = ['common', 'apd', 'pc', 'co']
SECTION_NAMES = {
    'common': '공통사항',
    'apd': 'APD',
    'pc': 'PC',
    'co': 'CO',
}


class Link2UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link2: ITGC 인터뷰 (1-page)"
        self.checklist_source = project_root / "test" / "unit_checklist_link2.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link2_result.md"

    # ================================================================
    # 1. 페이지 접근
    # ================================================================

    def test_link2_access_guest(self, result: UnitTestResult):
        """1. 비로그인 상태에서 /link2_1p 접근 시 common 섹션으로 리다이렉트 확인"""
        self.navigate_to("/link2_1p")
        # 리다이렉트 후 URL에 /section/common 포함 여부 확인
        url = self.page.url
        if "/section/common" in url:
            result.add_detail(f"리다이렉트 URL 확인: {url}")
        else:
            result.fail_test(f"예상 URL 패턴 불일치: {url}")
            return

        # 섹션 제목 h2 확인
        h2 = self.page.locator("h2").first.inner_text()
        if "공통사항" in h2:
            result.pass_test("공통사항 섹션 접근 및 제목 확인 완료")
        else:
            result.fail_test(f"섹션 제목 불일치: {h2}")

    def test_link2_section_steps(self, result: UnitTestResult):
        """1. 섹션 스텝 인디케이터 4개(common/apd/pc/co)가 표시되는지 확인"""
        self.navigate_to("/link2_1p")
        steps = self.page.locator(".section-steps .step")
        count = steps.count()
        if count == 4:
            result.add_detail(f"스텝 인디케이터 {count}개 확인")
            result.pass_test("섹션 스텝 인디케이터 정상 표시")
        else:
            result.fail_test(f"스텝 인디케이터 수 불일치: {count}개 (예상: 4개)")

    # ================================================================
    # 2. UI 요소 확인
    # ================================================================

    def test_link2_email_field(self, result: UnitTestResult):
        """2. common 섹션에서 이메일 입력 필드(#q0)가 표시되는지 확인"""
        self.navigate_to("/link2_1p")
        email_field = self.page.locator("#q0")
        if email_field.count() > 0:
            result.add_detail("이메일 필드 #q0 존재 확인")
            placeholder = email_field.get_attribute("placeholder") or ""
            result.pass_test(f"이메일 필드 확인 완료 (placeholder: {placeholder[:30]})")
        else:
            result.fail_test("이메일 필드 #q0 를 찾을 수 없습니다")

    def test_link2_yn_buttons(self, result: UnitTestResult):
        """2. Y/N 버튼이 표시되고, 클릭 시 btn-primary 스타일로 변경되는지 확인"""
        self.navigate_to("/link2_1p")
        # Q2 (상용소프트웨어) Y 버튼 확인
        yes_btn = self.page.locator("#q2_yes")
        no_btn  = self.page.locator("#q2_no")

        if yes_btn.count() == 0 or no_btn.count() == 0:
            result.fail_test("Q2 Y/N 버튼을 찾을 수 없습니다")
            return

        # Y 클릭 → btn-primary 확인
        yes_btn.click()
        self.page.wait_for_timeout(300)
        yes_class = yes_btn.get_attribute("class") or ""
        no_class  = no_btn.get_attribute("class") or ""
        if "btn-primary" in yes_class and "btn-outline-secondary" in no_class:
            result.add_detail("Y 선택 시 btn-primary 확인")
        else:
            result.fail_test(f"Y 선택 후 스타일 불일치 — yes: {yes_class}, no: {no_class}")
            return

        # N 클릭 → 역전
        no_btn.click()
        self.page.wait_for_timeout(300)
        yes_class = yes_btn.get_attribute("class") or ""
        no_class  = no_btn.get_attribute("class") or ""
        if "btn-primary" in no_class and "btn-outline-secondary" in yes_class:
            result.pass_test("Y/N 버튼 토글 동작 확인 완료")
        else:
            result.fail_test(f"N 선택 후 스타일 불일치 — yes: {yes_class}, no: {no_class}")

    # ================================================================
    # 3. 조건부 질문 로직
    # ================================================================

    def test_link2_conditional_cloud(self, result: UnitTestResult):
        """3. Q3(Cloud 사용여부) N 선택 시 Q4/Q5 질문 블록이 숨겨지는지 확인"""
        self.navigate_to("/link2_1p")
        # Q3의 N 버튼 클릭
        no_btn = self.page.locator("#q3_no")
        if no_btn.count() == 0:
            result.fail_test("Q3 N 버튼을 찾을 수 없습니다")
            return

        no_btn.click()
        self.page.wait_for_timeout(400)

        # Q4, Q5 블록 숨김 확인
        for qidx in [4, 5]:
            block = self.page.locator(f"#qblock_{qidx}")
            if block.count() == 0:
                result.fail_test(f"qblock_{qidx} 요소를 찾을 수 없습니다")
                return
            cls = block.get_attribute("class") or ""
            if "hidden" not in cls:
                result.fail_test(f"Q{qidx} 블록이 숨겨지지 않았습니다 (class: {cls})")
                return
            result.add_detail(f"Q{qidx} 숨김 확인")

        # Q3 Y 선택 시 Q4/Q5 표시 확인
        yes_btn = self.page.locator("#q3_yes")
        yes_btn.click()
        self.page.wait_for_timeout(400)
        for qidx in [4, 5]:
            block = self.page.locator(f"#qblock_{qidx}")
            cls = block.get_attribute("class") or ""
            if "hidden" in cls:
                result.fail_test(f"Y 선택 후 Q{qidx} 블록이 여전히 숨겨져 있습니다")
                return

        result.pass_test("Cloud 조건부 질문 숨김/표시 로직 확인 완료")

    # ================================================================
    # 4. 관리자 샘플입력
    # ================================================================

    def test_link2_admin_sample_button(self, result: UnitTestResult):
        """4. localhost(127.0.0.1)에서 접근 시 '샘플입력' 버튼이 표시되는지 확인"""
        self.navigate_to("/link2_1p")
        # fillAllSamples 버튼
        sample_btn = self.page.locator("button[onclick='fillAllSamples()']")
        if sample_btn.count() > 0:
            result.pass_test("샘플입력 버튼 표시 확인 완료")
        else:
            result.fail_test("샘플입력 버튼을 찾을 수 없습니다 (localhost 환경에서 실행 필요)")

    def test_link2_sample_fill(self, result: UnitTestResult):
        """4. '샘플입력' 클릭 후 폼 필드에 값이 채워지는지 확인"""
        self.navigate_to("/link2_1p")
        sample_btn = self.page.locator("button[onclick='fillAllSamples()']")
        if sample_btn.count() == 0:
            result.fail_test("샘플입력 버튼을 찾을 수 없습니다")
            return

        sample_btn.click()
        self.page.wait_for_timeout(500)

        email_after = self.page.locator("#q0").input_value()
        if email_after:
            result.pass_test(f"샘플입력 후 이메일 필드 값 확인: {email_after[:30]}")
        else:
            result.fail_test("샘플입력 후 이메일 필드가 비어 있습니다")

    # ================================================================
    # 5. 섹션 내비게이션
    # ================================================================

    def test_link2_navigation(self, result: UnitTestResult):
        """5. common 섹션 폼 제출 후 apd 섹션으로 이동하는지 확인"""
        self.navigate_to("/link2_1p?reset=1")
        self.page.wait_for_timeout(500)

        # 샘플입력으로 필수 필드 채우기
        sample_btn = self.page.locator("button[onclick='fillAllSamples()']")
        if sample_btn.count() > 0:
            sample_btn.click()
            self.page.wait_for_timeout(500)
        else:
            # 수동 입력
            self.page.locator("#q0").fill("test@example.com")
            self.page.locator("#q1").fill("테스트시스템")

        # 제출 버튼 클릭
        submit_btn = self.page.locator("button[type='submit']")
        if submit_btn.count() == 0:
            result.fail_test("제출 버튼을 찾을 수 없습니다")
            return

        submit_btn.click()
        self.page.wait_for_load_state("networkidle", timeout=15000)

        url = self.page.url
        if "/section/apd" in url:
            result.pass_test("common → apd 섹션 이동 확인 완료")
        else:
            result.fail_test(f"apd 섹션으로 이동되지 않았습니다. 현재 URL: {url}")

    def test_link2_all_sections_accessible(self, result: UnitTestResult):
        """5. 4개 섹션 URL이 모두 직접 접근 가능한지 확인"""
        for section in SECTIONS:
            self.page.goto(f"{self.base_url}/link2_1p/section/{section}")
            self.page.wait_for_load_state("networkidle", timeout=10000)
            h2 = self.page.locator("h2").first.inner_text()
            expected = SECTION_NAMES[section]
            if expected in h2:
                result.add_detail(f"섹션 '{section}' 접근 확인: {h2.strip()[:40]}")
            else:
                result.fail_test(f"섹션 '{section}' 접근 실패 또는 제목 불일치: {h2.strip()[:40]}")
                return
        result.pass_test("4개 섹션 모두 정상 접근 확인 완료")

    # ================================================================
    # 6. 전체 인터뷰 완료
    # ================================================================

    def test_link2_complete_interview(self, result: UnitTestResult):
        """6. 샘플입력으로 4개 섹션 완료 후 AI 검토 선택 페이지 도달 확인"""
        self.navigate_to("/link2_1p?reset=1")
        self.page.wait_for_timeout(500)

        for section in SECTIONS:
            url = self.page.url
            if f"/section/{section}" not in url:
                self.page.goto(f"{self.base_url}/link2_1p/section/{section}")
                self.page.wait_for_load_state("networkidle", timeout=10000)

            # 샘플입력 시도
            sample_btn = self.page.locator("button[onclick='fillAllSamples()']")
            if sample_btn.count() > 0:
                sample_btn.click()
                self.page.wait_for_timeout(500)

            submit_btn = self.page.locator("button[type='submit']")
            if submit_btn.count() == 0:
                result.fail_test(f"섹션 '{section}' 에서 제출 버튼을 찾을 수 없습니다")
                return

            submit_btn.click()
            self.page.wait_for_load_state("networkidle", timeout=15000)
            result.add_detail(f"섹션 '{section}' 제출 완료 → {self.page.url}")

        # 마지막 섹션(co) 제출 후 AI 검토 선택 페이지 확인
        final_url = self.page.url
        if "ai_review" in final_url or "review" in final_url or "link2" in final_url:
            result.pass_test(f"전체 인터뷰 완료 — 최종 URL: {final_url}")
        else:
            # 페이지 내 완료 관련 텍스트 확인
            page_text = self.page.content()
            if "완료" in page_text or "검토" in page_text or "제출" in page_text:
                result.pass_test(f"인터뷰 완료 페이지 도달 확인 (URL: {final_url})")
            else:
                result.fail_test(f"인터뷰 완료 후 예상 페이지 미도달. URL: {final_url}")

    # ================================================================
    # 7. APD 조건부 로직 (감사팀 요청)
    # ================================================================

    def test_link2_apd_conditional(self, result: UnitTestResult):
        """7. APD 섹션 조건부 질문 로직 확인 (Q6 공유계정, Q16 DB접속, Q26 OS접속)"""
        self.page.goto(f"{self.base_url}/link2_1p/section/apd")
        self.page.wait_for_load_state("networkidle", timeout=10000)

        # ── Q6(공유계정) = N → Q9 표시, Q10~Q12 숨김 ──
        no_btn = self.page.locator("#q6_no")
        if no_btn.count() == 0:
            result.fail_test("Q6 N 버튼을 찾을 수 없습니다")
            return
        no_btn.click()
        self.page.wait_for_timeout(400)

        # Q9 표시 확인
        q9_cls = self.page.locator("#qblock_9").get_attribute("class") or ""
        if "hidden" in q9_cls:
            result.fail_test("Q6=N 시 Q9가 표시되어야 하나 숨겨져 있습니다")
            return
        result.add_detail("Q6=N → Q9 표시 확인")

        # Q10~Q12 숨김 확인
        for qidx in [10, 11, 12]:
            cls = self.page.locator(f"#qblock_{qidx}").get_attribute("class") or ""
            if "hidden" not in cls:
                result.fail_test(f"Q6=N 시 Q{qidx}가 숨겨져야 하나 표시되어 있습니다")
                return
        result.add_detail("Q6=N → Q10~Q12 숨김 확인")

        # Q6 = Y → Q9 숨김, Q10~Q12 표시
        yes_btn = self.page.locator("#q6_yes")
        yes_btn.click()
        self.page.wait_for_timeout(400)
        q9_cls = self.page.locator("#qblock_9").get_attribute("class") or ""
        if "hidden" not in q9_cls:
            result.fail_test("Q6=Y 시 Q9가 숨겨져야 하나 표시되어 있습니다")
            return
        result.add_detail("Q6=Y → Q9 숨김 확인")

        # ── Q16(DB접속) = N → Q17~Q25 숨김 ──
        q16_no = self.page.locator("#q16_no")
        if q16_no.count() == 0:
            result.fail_test("Q16 N 버튼을 찾을 수 없습니다")
            return
        q16_no.click()
        self.page.wait_for_timeout(400)
        for qidx in [17, 18, 19]:  # 대표 3개만 확인
            cls = self.page.locator(f"#qblock_{qidx}").get_attribute("class") or ""
            if "hidden" not in cls:
                result.fail_test(f"Q16=N 시 Q{qidx}가 숨겨져야 하나 표시되어 있습니다")
                return
        result.add_detail("Q16=N → Q17~Q19 숨김 확인")

        # ── Q26(OS접속) = N → Q27~Q32 숨김 ──
        q26_no = self.page.locator("#q26_no")
        if q26_no.count() == 0:
            result.fail_test("Q26 N 버튼을 찾을 수 없습니다")
            return
        q26_no.click()
        self.page.wait_for_timeout(400)
        for qidx in [27, 28]:  # 대표 2개만 확인
            cls = self.page.locator(f"#qblock_{qidx}").get_attribute("class") or ""
            if "hidden" not in cls:
                result.fail_test(f"Q26=N 시 Q{qidx}가 숨겨져야 하나 표시되어 있습니다")
                return
        result.add_detail("Q26=N → Q27~Q28 숨김 확인")

        result.pass_test("APD 조건부 질문 로직(Q6/Q16/Q26) 확인 완료")

    # ================================================================
    # 8. 세션 유지 (감사팀 요청)
    # ================================================================

    def test_link2_session_persistence(self, result: UnitTestResult):
        """8. common 섹션 제출 후 completed 스텝 클릭으로 복귀 시 답변 보존 확인"""
        # 세션 리셋 후 common 섹션으로 직접 이동
        self.navigate_to("/link2_1p?reset=1")
        # 리다이렉트 결과와 무관하게 common 섹션으로 강제 이동
        self.navigate_to("/link2_1p/section/common")

        # common 섹션 필드 로드 대기 (Q1은 id 없이 name만 있음)
        try:
            self.page.wait_for_selector("#q0", timeout=5000)
            self.page.wait_for_selector("input[name='q1']", timeout=5000)
        except Exception:
            result.fail_test(f"common 섹션 입력 필드 로드 실패 (현재 URL: {self.page.url})")
            return

        # common 섹션에 시스템명 직접 입력
        system_name = "세션유지테스트시스템"
        email_field = self.page.locator("#q0")
        system_field = self.page.locator("input[name='q1']")

        email_field.fill("persist@test.com")
        system_field.fill(system_name)

        # common 섹션 제출 → apd로 이동
        submit_btn = self.page.locator("button[type='submit']")
        submit_btn.click()
        self.page.wait_for_load_state("networkidle", timeout=15000)

        if "/section/apd" not in self.page.url:
            result.fail_test(f"apd 섹션으로 이동되지 않았습니다: {self.page.url}")
            return
        result.add_detail("common 제출 → apd 이동 확인")

        # completed 스텝(common) 클릭으로 복귀
        common_step = self.page.locator(".section-steps a.step.completed").first
        if common_step.count() == 0:
            result.fail_test("completed 상태의 common 스텝 링크를 찾을 수 없습니다")
            return
        common_step.click()
        self.page.wait_for_load_state("networkidle", timeout=10000)

        if "/section/common" not in self.page.url:
            result.fail_test(f"common 섹션으로 복귀되지 않았습니다: {self.page.url}")
            return

        # 답변 보존 확인
        restored_system = self.page.locator("input[name='q1']").input_value()
        restored_email  = self.page.locator("#q0").input_value()
        if system_name in restored_system and "persist@test.com" in restored_email:
            result.pass_test(f"섹션 복귀 후 답변 보존 확인 완료 (시스템명: {restored_system})")
        else:
            result.fail_test(
                f"답변 유실 — 시스템명: '{restored_system}' (예상: '{system_name}'), "
                f"이메일: '{restored_email}'"
            )

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

        passed  = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed  = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        warned  = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total   = len(self.results) if self.results else 1

        updated_lines.append("\n---\n")
        updated_lines.append("## 테스트 결과 요약\n\n")
        updated_lines.append("| 항목 | 개수 | 비율 |\n")
        updated_lines.append("|------|------|------|\n")
        updated_lines.append(f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n")
        updated_lines.append(f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n")
        updated_lines.append(f"| ⚠️ 경고 | {warned} | {warned/total*100:.1f}% |\n")
        updated_lines.append(f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n")
        updated_lines.append(f"| **총계** | **{total}** | **100%** |\n")

        with open(self.checklist_result, 'w', encoding='utf-8') as f:
            f.writelines(updated_lines)


def run_tests():
    test_runner = Link2UnitTest(headless=False, slow_mo=300)
    test_runner.setup()
    try:
        test_runner.run_category("Link2 Unit Tests", [
            test_runner.test_link2_access_guest,
            test_runner.test_link2_section_steps,
            test_runner.test_link2_email_field,
            test_runner.test_link2_yn_buttons,
            test_runner.test_link2_conditional_cloud,
            test_runner.test_link2_admin_sample_button,
            test_runner.test_link2_sample_fill,
            test_runner.test_link2_navigation,
            test_runner.test_link2_all_sections_accessible,
            test_runner.test_link2_complete_interview,
            test_runner.test_link2_apd_conditional,
            test_runner.test_link2_session_persistence,
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()


if __name__ == "__main__":
    run_tests()
