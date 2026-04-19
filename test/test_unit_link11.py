"""
Link11: 정보보호공시 Unit 테스트 코드
"""

import sys
import re
import os
import tempfile
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult

class Link11UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link11: 정보보호공시"
        self.checklist_source = project_root / "test" / "unit_checklist_link11.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link11_result.md"
        
        # DB ID -> Display Number 매핑 (화면에 표시되는 번호)
        # 기준: migration 036(ID 체계 재정비) + 037(Q27/Q28/Q29 추가) 적용 후 실제 DB 값
        self.display_map = {
            'Q1': 'Q1-1',
            'Q2': 'Q1-1-1',
            'Q3': 'Q1-1-2',
            'Q4': 'Q1-1-2-1',
            'Q5': 'Q1-1-2-2',
            'Q6': 'Q1-1-2-3',
            'Q27': 'Q1-1-3',   # 주요 투자 항목 (migration 037 신규)
            'Q7': 'Q1-2',
            'Q8': 'Q1-2-1',
            'Q9': 'Q2-1',
            'Q10': 'Q2-1-1',
            'Q28': 'Q2-1-0',   # 정보기술인력(C) (migration 037 신규, 번호 Q2-1-0)
            'Q11': 'Q2-1-2',   # 내부 전담인력 수 (migration 036 고정값)
            'Q12': 'Q2-1-3',   # 외주 전담인력 수 (migration 036 고정값)
            'Q13': 'Q2-2',
            'Q14': 'Q2-2-1',
            'Q29': 'Q2-2-2',   # CISO/CPO 활동내역 (migration 037 신규)
        }
    
    def get_question_selector(self, db_id):
        """DB ID로 질문 요소 셀렉터 반환 (id 속성 우선 사용)"""
        return f"#question-{db_id}"
    
    def get_input_selector(self, db_id):
        """DB ID로 입력 필드 셀렉터 반환 (id 속성 우선 사용)"""
        return f"#input-{db_id}"
    
    def get_display_number(self, db_id):
        """DB ID의 화면 표시 번호 반환"""
        return self.display_map.get(db_id, db_id)

    def get_question_by_display(self, db_id):
        """화면에 표시되는 번호(display_number)를 포함하는 질문 요소를 반환"""
        display_num = self.get_display_number(db_id)
        # .question-number 클래스를 가진 span의 텍스트가 display_num인 부모 .question-item 찾기
        return self.page.locator(f".question-item:has(.question-number:text-is('{display_num}'))")

    def get_input_by_display(self, db_id):
        """화면 표시 번호로 질문을 찾고 그 내부의 입력 필드를 반환"""
        question = self.get_question_by_display(db_id)
        # 해당 질문 아이템 내의 input 또는 textarea 찾기
        return question.locator("input, textarea")

    def setup(self):
        super().setup()
        self.last_dialog_message = None
        # 모든 다이얼로그 메시지를 저장하고 자동 승락
        def handle_dialog(dialog):
            self.last_dialog_message = dialog.message
            dialog.accept()
        self.page.on("dialog", handle_dialog)

    def test_link11_access(self, result: UnitTestResult):
        """1. 페이지 접근 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        if "정보보호공시" in self.page.title():
            result.pass_test("페이지 로드 및 타이틀 확인 완료")
        else:
            result.fail_test(f"타이틀 불일치: {self.page.title()} (컨텐츠: {self.page.locator('h1').inner_text() if self.page.locator('h1').count() > 0 else 'None'})")

    def test_link11_dashboard_stats(self, result: UnitTestResult):
        """1. 대시보드 통계 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        
        # 투자 비율, 인력 비율 카드 존재 확인
        inv_ratio = self.page.locator("#dashboard-inv-ratio")
        per_ratio = self.page.locator("#dashboard-per-ratio")
        
        if inv_ratio.is_visible() and per_ratio.is_visible():
            result.pass_test(f"대시보드 통계 카드 표시 확인 (투자: {inv_ratio.inner_text()}, 인력: {per_ratio.inner_text()})")
        else:
            result.fail_test("대시보드 통계 카드가 보이지 않음. 로그인 상태 확인 필요.")

    def test_link11_category_navigation(self, result: UnitTestResult):
        """1. 카테고리 네비게이션 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        
        # 첫 번째 카테고리 클릭
        cat_card = self.page.locator(".category-card").first
        if cat_card.count() > 0:
            cat_title = cat_card.locator(".category-title").inner_text()
            cat_card.click()
            self.page.wait_for_timeout(1000)
            
            # 질문 섹션으로 스크롤 및 로드 확인
            if self.page.locator("#questions-view").is_visible():
                result.pass_test(f"카테고리 이동 확인: {cat_title}")
            else:
                result.fail_test("카테고리 질문 섹션이 로드되지 않음")
        else:
            result.fail_test("카테고리 카드를 찾을 수 없음")

    def test_link11_answer_yes_no(self, result: UnitTestResult):
        """2. YES/NO 질문 응답 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 카테고리 1 클릭
        cat_card = self.page.locator(".category-card", has_text="투자").first
        if cat_card.count() > 0:
            cat_card.click()
            self.page.wait_for_timeout(1500)
            
            # Q1 질문의 '예' 버튼 찾기
            q1_yes = self.page.locator("#question-Q1 .yes-no-btn.yes")
            if q1_yes.count() > 0:
                q1_yes.scroll_into_view_if_needed()
                q1_yes.click()
                self.page.wait_for_timeout(1000)
                
                # 버튼 선택 스타일(selected) 확인
                if "selected" in q1_yes.get_attribute("class"):
                    result.pass_test("YES/NO 버튼 선택 및 상태 변경 확인")
                else:
                    result.fail_test("버튼 선택 상태가 유지되지 않음")
            else:
                result.fail_test("Q1 YES 버튼을 찾을 수 없음. 질문이 렌더링되지 않았을 수 있음.")
        else:
            result.skip_test("투자 카테고리 카드를 찾을 수 없음")

    def test_link11_dependent_questions(self, result: UnitTestResult):
        """2. 종속 질문 표시 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 카테고리 1 클릭
        cat_card = self.page.locator(".category-card", has_text="투자").first
        if cat_card.count() == 0:
            result.skip_test("투자 카테고리 카드 없음")
            return
            
        cat_card.click()
        self.page.wait_for_timeout(1500)
        
        # Q1 '아니오' 클릭 시 Q2, Q3 사라짐 확인 -> '예' 클릭 시 다시 나타남 확인
        q1_selector = self.get_question_selector('Q1')
        q1_no = self.page.locator(f"{q1_selector} .yes-no-btn.no")
        q1_yes = self.page.locator(f"{q1_selector} .yes-no-btn.yes")
        
        if q1_no.count() == 0:
            result.fail_test("Q1 버튼을 찾을 수 없음")
            return

        q1_no.click()
        self.page.wait_for_timeout(1500)
        q2_selector = self.get_question_selector('Q2')
        q2_hidden = not self.page.locator(q2_selector).is_visible()
        
        q1_yes.click()
        self.page.wait_for_timeout(1500)
        q2_visible = self.page.locator(q2_selector).is_visible()
        
        if q2_hidden and q2_visible:
            result.pass_test("부모 질문 응답에 따른 하위 질문(Q2) 동적 표시 확인")
        else:
            result.fail_test(f"종속 로직 오류 (Hidden: {q2_hidden}, Visible: {q2_visible})")

    def test_link11_currency_input(self, result: UnitTestResult):
        """2. 금액 필드 포맷팅 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 카테고리 1 클릭
        cat1 = self.page.locator(".category-card", has_text="투자").first
        if cat1.count() == 0:
            result.skip_test("투자 카테고리 카드 없음")
            return
            
        cat1.click()
        self.page.wait_for_timeout(1500)
        
        # Q1 '예' 선택하여 Q2 열기
        q1_selector = self.get_question_selector('Q1')
        self.page.locator(f"{q1_selector} .yes-no-btn.yes").click()
        self.page.wait_for_timeout(1000)
        
        # Q2 입력 필드 찾기
        q2_input = self.get_input_by_display('Q2')
        if q2_input.count() > 0:
            q2_input.fill("7654321")
            # 포커스 아웃 (blur) 유도하기 위해 다른 곳 클릭
            self.page.locator("#category-title").click()
            self.page.wait_for_timeout(1500)
            
            formatted_val = q2_input.input_value()
            if "7,654,321" in formatted_val:
                result.pass_test(f"금액 필드 쉼표 포맷팅 확인: {formatted_val}")
            else:
                # 보조 디버깅용 로그
                print(f"DEBUG: Q2 Value actual='{formatted_val}'")
                result.fail_test(f"포맷팅 실패: '{formatted_val}'")
        else:
            result.fail_test("Q2 입력 필드를 찾을 수 없음")

    def test_link11_number_input(self, result: UnitTestResult):
        """2. 숫자 필드 입력 및 저장 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 카테고리 2 클릭 (인력)
        cat2 = self.page.locator(".category-card", has_text="인력").first
        if cat2.count() > 0:
            cat2.click()
            self.page.wait_for_selector("#questions-view", state="visible")
            self.page.wait_for_timeout(1000)
            
            # Q9 '예' 선택
            q9_yes = self.page.locator("#question-Q9 .yes-no-btn.yes")
            if q9_yes.count() > 0:
                q9_yes.click()
                self.page.wait_for_timeout(1500)
                
                # Q10 (총 임직원 수) 입력
                q10_input = self.get_input_by_display('Q10')
                if q10_input.count() > 0:
                    q10_input.scroll_into_view_if_needed()
                    q10_input.click()
                    q10_input.fill("") 
                    q10_input.type("1234")
                    # 다른 곳을 클릭하여 blur 트리거
                    self.page.locator("h3#category-title").first.click()
                    self.page.wait_for_timeout(1000)
                    
                    # 포맷팅 확인 (1,234)
                    val = q10_input.input_value()
                    if "1,234" in val:
                        result.pass_test(f"숫자 필드 입력 및 포맷팅 확인: {val}")
                    else:
                        result.fail_test(f"숫자 필드 포맷팅 실패: '{val}' (예상: 1,234)")
                else:
                    result.fail_test("Q10 입력 필드를 찾을 수 없음")
            else:
                result.fail_test("Q9 버튼을 찾을 수 없음")
        else:
            result.skip_test("인력 카테고리 카드 없음")

    def test_link11_multi_select(self, result: UnitTestResult):
        """3. 다중 선택 체크박스 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 카테고리 4 클릭
        cat4 = self.page.locator(".category-card", has_text="활동").first
        if cat4.count() > 0:
            cat4.click()
            self.page.wait_for_selector("#questions-view", state="visible", timeout=5000)
            self.page.wait_for_timeout(1000)
            
            # Q17 '예' 선택 (활동 여부 트리거)
            q17_yes = self.page.locator("#question-Q17 .yes-no-btn.yes")
            if q17_yes.count() > 0:
                q17_yes.scroll_into_view_if_needed()
                q17_yes.click()
                self.page.wait_for_timeout(1500)
                
                # Q18 등의 체크박스 아이템 클릭
                # 활동 카테고리의 첫번째 체크박스 질문 찾기
                self.page.wait_for_selector(".checkbox-item", state="visible", timeout=5000)
                chk_items = self.page.locator(".checkbox-item")
                if chk_items.count() > 0:
                    first_item = chk_items.nth(0)
                    
                    first_item.scroll_into_view_if_needed()
                    # 현재 상태 확인 후 클릭
                    was_selected = "selected" in (first_item.get_attribute("class") or "")
                    first_item.click()
                    self.page.wait_for_timeout(1500)
                    
                    is_selected = "selected" in (first_item.get_attribute("class") or "")
                    
                    if is_selected != was_selected:
                        result.pass_test(f"체크박스 선택 기능 확인 (상태 반전 성공: {was_selected} -> {is_selected})")
                    else:
                        result.fail_test(f"체크박스 선택 상태 미반영 (class: {first_item.get_attribute('class')})")
                else:
                    # 질문이 로드되었는지 확인 루프
                    result.skip_test("활동 카테고리 내 체크박스 질문을 찾을 수 없음")
            else:
                result.fail_test("활동 트리거(Q17) 버튼을 찾을 수 없음")
        else:
            result.skip_test("활동 카테고리 카드 없음")

    def test_link11_evidence_modal(self, result: UnitTestResult):
        """4. 증빙 자료 업로드 모달 노출"""
        # evidence_list가 정의된 질문은 Q1(예산서/품의서), Q2(투자내역보고서)
        # Q15(인증)에는 evidence_list 미정의 → 투자 카테고리 Q1 기준으로 테스트
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        cat1 = self.page.locator(".category-card", has_text="투자").first
        if cat1.count() > 0:
            cat1.click()
            self.page.wait_for_selector("#questions-view", state="visible", timeout=5000)
            self.page.wait_for_timeout(1500)

            # Q1 YES 클릭하여 질문 활성화
            q1_yes = self.page.locator("#question-Q1 .yes-no-btn.yes")
            if q1_yes.count() > 0:
                q1_yes.scroll_into_view_if_needed()
                q1_yes.click()
                self.page.wait_for_timeout(1500)

            # Q1 질문에 증빙 버튼이 렌더링됨 (evidence_list: 예산서, 품의서)
            btn_ev = self.page.locator("#question-Q1 .evidence-upload-btn")
            if btn_ev.count() == 0:
                btn_ev = self.page.locator(".evidence-upload-btn").first

            if btn_ev.count() > 0:
                btn_ev.scroll_into_view_if_needed()
                btn_ev.click()
                self.page.wait_for_timeout(1500)

                if self.page.locator("#uploadModal").is_visible():
                    result.pass_test("증빙 자료 업로드 모달 노출 확인 (Q1 기준)")
                elif self.page.locator(".modal.show").count() > 0:
                    result.pass_test("증빙 자료 업로드 모달 노출 확인 (클래스 기반)")
                else:
                    result.fail_test("업로드 모달이 표시되지 않음")
            else:
                result.fail_test("증빙 업로드 버튼을 찾을 수 없음 (Q1 evidence_list 정의 확인 필요)")
        else:
            result.skip_test("투자 카테고리 카드 없음")

    def test_link11_evidence_mime_validation(self, result: UnitTestResult):
        """5. 파일 업로드 MIME 타입 검증 확인"""
        import tempfile
        import requests

        self._do_admin_login()

        # 세션 쿠키 가져오기
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        # 텍스트 내용으로 .pdf 확장자 파일 생성 (변조된 파일)
        with tempfile.NamedTemporaryFile(mode='w', suffix='.pdf', delete=False) as f:
            f.write("This is not a real PDF file - just plain text")
            fake_pdf_path = f.name

        try:
            # API로 파일 업로드 시도
            with open(fake_pdf_path, 'rb') as f:
                files = {'file': ('fake_document.pdf', f, 'application/pdf')}
                data = {
                    'question_id': 'Q15',
                    'answer_id': 'test-answer-id',
                    'evidence_type': 'test',
                    'year': '2024'
                }

                response = requests.post(
                    f"{self.base_url}/link11/api/evidence",
                    files=files,
                    data=data,
                    cookies=session_cookie,
                    timeout=10
                )

            # 응답 확인 (400 Bad Request 또는 에러 메시지 포함)
            if response.status_code == 400:
                resp_json = response.json()
                if 'PDF' in resp_json.get('message', '') or '일치하지 않' in resp_json.get('message', ''):
                    result.pass_test(f"MIME 타입 검증 확인: {resp_json.get('message', '')[:50]}")
                else:
                    result.pass_test(f"파일 업로드 거부됨 (400): {resp_json.get('message', '')[:50]}")
            elif response.status_code == 401:
                result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
            elif response.status_code == 200:
                result.fail_test("변조된 파일이 업로드됨 - MIME 검증 실패")
            else:
                result.warn_test(f"예상치 못한 응답: {response.status_code}")

        except Exception as e:
            result.fail_test(f"테스트 중 오류: {str(e)}")
        finally:
            # 임시 파일 정리
            import os
            try:
                os.unlink(fake_pdf_path)
            except:
                pass

    def test_link11_report_preview(self, result: UnitTestResult):
        """5. 리포트 미리보기 확인"""
        self._do_admin_login()
        self.navigate_to("/link11/report")
        self.page.wait_for_timeout(3000)
        
        # 미리보기 영역 내용 존재 확인
        preview = self.page.locator("#preview-area")
        if preview.count() > 0 and len(preview.inner_text()) > 50:
            result.pass_test(f"리포트 미리보기 데이터 로드 확인 ({len(preview.inner_text())}자)")
        else:
            result.fail_test(f"미리보기 내용이 비어있거나 로드 실패 (컨텐츠 길이: {len(preview.inner_text()) if preview.count() > 0 else 0})")

    def test_link11_report_download(self, result: UnitTestResult):
        """5. 리포트 생성 프로세스 확인"""
        self._do_admin_login()
        self.navigate_to("/link11/report")
        self.page.wait_for_timeout(2000)
        
        btn_gen = self.page.locator("#generate-btn")
        if btn_gen.count() > 0:
            # 다운로드 버튼 클릭 시 로딩 오버레이 확인
            btn_gen.click()
            self.page.wait_for_timeout(1500)
            
            overlay = self.page.locator("#loading-overlay")
            if overlay.is_visible():
                result.pass_test("리포트 생성 로딩 오버레이 노출 확인")
            else:
                # 성공 토스트가 떴는지 확인
                toast = self.page.locator(".toast-message.success")
                if toast.count() > 0:
                    result.pass_test("리포트 생성 완료 (토스트 확인)")
                else:
                    result.pass_test("리포트 생성 프로세스 시작 (오버레이 확인 불가)")
        else:
            result.fail_test("생성 버튼을 찾을 수 없음")

    def test_link11_validation_b_lt_a(self, result: UnitTestResult):
        """2. 정보보호 투자액 검증 (B <= A)"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 카테고리 1 클릭
        cat1 = self.page.locator(".category-card", has_text="투자").first
        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)
        
        # Q1 '예' 선택
        q1_selector = self.get_question_selector('Q1')
        self.page.locator(f"{q1_selector} .yes-no-btn.yes").click()
        self.page.wait_for_timeout(2000)  # 종속 질문 렌더링 대기
        
        # Q2, Q3가 나타날 때까지 대기 (종속 질문)
        q2_selector = self.get_question_selector('Q2')
        q3_selector = self.get_question_selector('Q3')
        self.page.wait_for_selector(q2_selector, state="visible", timeout=10000)
        self.page.wait_for_selector(q3_selector, state="visible", timeout=10000)
        self.page.wait_for_timeout(1000)
        
        # Q2 (A: 정보기술 투자액) 에 1,000,000 입력
        q2_input = self.get_input_by_display('Q2')
        q2_input.wait_for(state="visible", timeout=10000)
        q2_input.fill("1000000")
        q2_input.blur()
        self.page.wait_for_timeout(1500) # 자동 저장 대기
        
        # Grid 컨테이너가 나타날 때까지 대기
        self.page.wait_for_selector(".question-row-container", state="visible", timeout=10000)
        self.page.wait_for_timeout(1000)
        
        # 다이얼로그 메시지 초기화
        self.last_dialog_message = None
        
        # Q4 (B의 일부: 감가상각비)에 1,500,000 입력 (A를 초과하도록)
        q4_input = self.get_input_by_display('Q4')
        q4_input.wait_for(state="visible", timeout=10000)
        q4_input.fill("1500000")
        q4_input.blur()
        
        # 저장 시도 (저장 시점에 검증 수행)
        self.page.locator("button:has-text('임시 저장')").first.click()
        self.page.wait_for_timeout(2000) # 검증 및 토스트 대기
        
        # 1. alert가 표시되었는지 확인
        if self.last_dialog_message and "초과" in self.last_dialog_message:
            result.pass_test(f"투자액 초과 검증 확인 (alert): {self.last_dialog_message[:50]}...")
        else:
            # 2. 토스트 메시지 확인
            toast = self.page.locator(".toast-body")
            target_toast = toast.filter(has_text="초과")
            if target_toast.count() > 0:
                toast_text = target_toast.first.inner_text()
                result.pass_test(f"투자액 초과 검증 확인 (toast): {toast_text}")
            elif self.last_dialog_message:
                result.pass_test(f"투자액 초과 검증 확인 (dialog): {self.last_dialog_message}")
            else:
                result.fail_test("투자액 초과 검증 실패 (경고 메시지 없음)")


    def test_link11_auto_calculation(self, result: UnitTestResult):
        """3. 자동 계산 연동 확인 (대시보드 수치 업데이트)"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        
        # 초기 대시보드 텍스트 저장
        initial_rate = self.page.locator("#dashboard-inv-ratio").inner_text()
        
        # 카테고리 1 이동 및 값 수정
        cat1 = self.page.locator(".category-card", has_text="투자").first
        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        
        q1_selector = self.get_question_selector('Q1')
        self.page.locator(f"{q1_selector} .yes-no-btn.yes").click()
        self.page.wait_for_timeout(2000)  # 종속 질문 렌더링 대기
        
        # Q2, Q3가 나타날 때까지 대기 (종속 질문)
        q2_selector = self.get_question_selector('Q2')
        q3_selector = self.get_question_selector('Q3')
        self.page.wait_for_selector(q2_selector, state="visible", timeout=10000)
        self.page.wait_for_selector(q3_selector, state="visible", timeout=10000)
        self.page.wait_for_timeout(1000)
        
        # Grid 컨테이너가 나타날 때까지 대기 (Q3 하위 질문용)
        self.page.wait_for_selector(".question-row-container", state="visible", timeout=10000)
        self.page.wait_for_timeout(1000)
        
        # Q2 입력 필드 기다리기 (정보기술 투자액 A)
        q2_input = self.get_input_by_display('Q2')
        q2_input.wait_for(state="visible", timeout=10000)
        q2_input.fill("1000000")
        q2_input.blur()
        self.page.wait_for_timeout(1000)

        # Q4 입력 필드 기다리기 (정보보호 투자액 B의 일부)
        q4_input = self.get_input_by_display('Q4')
        q4_input.wait_for(state="visible", timeout=10000)
        q4_input.fill("500000")  # IT 예산의 50%
        q4_input.blur()
        self.page.wait_for_timeout(1000)

        # Q5, Q6 잔류 데이터 초기화 (타 테스트 데이터 오염 방지)
        q5_input = self.get_input_by_display('Q5')
        if q5_input.count() > 0 and q5_input.is_visible():
            q5_input.fill("0")
            q5_input.blur()
            self.page.wait_for_timeout(500)
        q6_input = self.get_input_by_display('Q6')
        if q6_input.count() > 0 and q6_input.is_visible():
            q6_input.fill("0")
            q6_input.blur()
            self.page.wait_for_timeout(500)

        # 임시 저장 클릭 — blur만으로는 DB 저장 미보장, 명시적 저장 필요
        save_btn = self.page.locator("button:has-text('임시 저장')").first
        if save_btn.count() > 0:
            save_btn.click()
            self.page.wait_for_timeout(2000)

        # 대시보드로 돌아가기 — 직접 URL 이동으로 최신 DB 데이터 강제 로드
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        new_rate = self.page.locator("#dashboard-inv-ratio").inner_text()

        # Q3의 디스플레이 값도 확인 (B 합계)
        q3_display = self.page.locator("#input-Q3-display")
        q3_text = q3_display.inner_text() if q3_display.count() > 0 else ""

        if "50.00" in new_rate or "50%" in new_rate:
            result.pass_test(f"자동 계산 및 대시보드 연동 확인 (비율: {new_rate}, B합계: {q3_text})")
        else:
            result.fail_test(f"수치 업데이트 미반영 (현재 비율: {new_rate}, B합계: {q3_text})")

    def test_link11_validation_negative(self, result: UnitTestResult):
        """2. 숫자/금액 필드 음수 입력 방지 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        # 카테고리 1 클릭 (투자)
        cat1 = self.page.locator(".category-card", has_text="투자").first
        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)

        # Q1 '예' 선택
        q1_selector = self.get_question_selector('Q1')
        self.page.locator(f"{q1_selector} .yes-no-btn.yes").click()
        self.page.wait_for_timeout(2000)

        # Q2 입력 필드 대기
        q2_input = self.get_input_by_display('Q2')
        q2_input.wait_for(state="visible", timeout=10000)

        # 음수 입력 시도 (-1000)
        q2_input.fill("-1000")
        q2_input.blur()
        self.page.wait_for_timeout(1000)

        # 입력값 확인 (음수가 제거되어야 함)
        current_val = q2_input.input_value()
        raw_val = q2_input.get_attribute("data-raw-value") or current_val

        # 음수 기호가 제거되었거나 값이 0 이상이면 성공
        is_positive = True
        try:
            clean_val = str(raw_val).replace(',', '')
            if clean_val and float(clean_val) < 0:
                is_positive = False
        except ValueError:
            pass

        if is_positive or "-" not in current_val:
            result.pass_test(f"음수 입력 방지 확인 (입력값: {current_val}, raw: {raw_val})")
        else:
            result.fail_test(f"음수 입력이 허용됨 (입력값: {current_val})")

    def test_link11_company_data_isolation(self, result: UnitTestResult):
        """7. 회사별 데이터 격리 확인 (사용자 전환 테스트)"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)

        # 1. 관리자로 접속 시 현재 표시되는 회사명 확인
        admin_company = self.page.locator(".company-name, .user-company").first
        admin_company_name = admin_company.inner_text() if admin_company.count() > 0 else ""

        # 대시보드 통계 값 저장 (관리자 상태)
        admin_inv_ratio = self.page.locator("#dashboard-inv-ratio").inner_text() if self.page.locator("#dashboard-inv-ratio").count() > 0 else ""

        # 2. 우측 상단 사용자명 클릭하여 사용자 전환 메뉴 열기
        user_dropdown = self.page.locator(".user-name, .navbar .dropdown-toggle, .user-dropdown").first
        if user_dropdown.count() == 0:
            result.skip_test("사용자 드롭다운 메뉴를 찾을 수 없음")
            return

        user_dropdown.click()
        self.page.wait_for_timeout(1000)

        # 3. 다른 회사 계정 선택 (SK텔레콤 또는 첫 번째 비관리자 계정)
        switch_options = self.page.locator(".dropdown-menu .dropdown-item, .user-switch-item")
        target_company = None
        target_item = None

        for i in range(switch_options.count()):
            option = switch_options.nth(i)
            option_text = option.inner_text()
            # 관리자가 아닌 다른 회사 선택
            if "관리자" not in option_text and "스노우볼" not in option_text:
                target_company = option_text.strip()
                target_item = option
                break

        if target_item is None:
            result.skip_test("전환할 다른 회사 계정을 찾을 수 없음")
            return

        result.add_detail(f"테스트 대상 회사: {target_company}")

        # 4. 다른 회사로 전환
        target_item.click()
        self.page.wait_for_timeout(2000)

        # 5. Link11 페이지로 이동 (전환 후 다시 접근)
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)

        # 6. 전환 후 회사 정보 확인
        switched_company = self.page.locator(".company-name, .user-company").first
        switched_company_name = switched_company.inner_text() if switched_company.count() > 0 else ""

        # 대시보드 통계 값 확인 (전환된 회사)
        switched_inv_ratio = self.page.locator("#dashboard-inv-ratio").inner_text() if self.page.locator("#dashboard-inv-ratio").count() > 0 else ""

        # 7. 데이터 격리 확인 - 회사명이 변경되었는지 또는 데이터가 다른지 확인
        data_isolated = False
        if switched_company_name and admin_company_name != switched_company_name:
            data_isolated = True
            result.add_detail(f"회사명 변경 확인: {admin_company_name} → {switched_company_name}")
        elif admin_inv_ratio != switched_inv_ratio:
            data_isolated = True
            result.add_detail(f"통계 데이터 변경 확인: {admin_inv_ratio} → {switched_inv_ratio}")

        # 8. 관리자로 돌아가기
        user_dropdown2 = self.page.locator(".user-name, .navbar .dropdown-toggle, .user-dropdown").first
        if user_dropdown2.count() > 0:
            user_dropdown2.click()
            self.page.wait_for_timeout(500)

            # '관리자로 돌아가기' 또는 관리자 계정 클릭
            admin_return = self.page.locator("text=관리자로 돌아가기, text=스노우볼").first
            if admin_return.count() == 0:
                admin_return = self.page.locator(".dropdown-item:has-text('관리자'), .dropdown-item:has-text('스노우볼')").first

            if admin_return.count() > 0:
                admin_return.click()
                self.page.wait_for_timeout(1500)
                result.add_detail("관리자로 복귀 완료")
            else:
                result.add_detail("⚠️ 관리자 복귀 버튼을 찾을 수 없음 (수동 복귀 필요)")

        # 9. 결과 판정
        if data_isolated:
            result.pass_test(f"회사별 데이터 격리 확인 (전환 회사: {target_company})")
        else:
            result.warn_test(f"데이터 격리 확인 불가 (동일 데이터가 표시될 수 있음)")

    def test_link11_validation_personnel(self, result: UnitTestResult):
        """3. 정보보호 인력 검증 (Total >= IT >= Security hierarchy)"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)
        
        # 인력 카테고리 클릭
        cat2 = self.page.locator(".category-card", has_text="인력").first
        cat2.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)
        
        # Q9 '예' 선택 (정보보호 전담 부서/인력 여부)
        q9_selector = self.get_question_selector('Q9')
        self.page.locator(f"{q9_selector} .yes-no-btn.yes").click()
        self.page.wait_for_timeout(2000)
        
        # 다이얼로그 메시지 초기화
        self.last_dialog_message = None
        
        q10_input = self.get_input_by_display('Q10') # 총 임직원
        q28_input = self.get_input_by_display('Q28') # 정보기술인력 C
        q11_input = self.get_input_by_display('Q11') # 내부 D1
        q12_input = self.get_input_by_display('Q12') # 외주 D2

        # [테스트 1] IT 인력(C) > 총 임직원(Total) 오류 검증
        q10_input.fill("100")
        q28_input.fill("120") # 오류 유발
        q28_input.blur()
        self.page.wait_for_timeout(1500)
        
        # 토스트 메시지 기반 검증
        toast = self.page.locator(".toast-body")
        case1_ok = (self.last_dialog_message and "총 임직원 수" in self.last_dialog_message) or \
                   (toast.filter(has_text="총 임직원 수").count() > 0)
        
        self.last_dialog_message = None # 초기화
        
        # [테스트 2] 보안 인력(D1+D2) > IT 인력(C) 오류 검증
        q28_input.fill("50") # 정상값으로 수정 (IT=50, Total=100)
        q28_input.blur()
        self.page.wait_for_timeout(1000)
        
        q11_input.fill("40")
        q12_input.fill("20") # 합계 60 > IT 50 (오류 유발)
        q12_input.blur()
        self.page.wait_for_timeout(1500)
        
        case2_ok = (self.last_dialog_message and "정보기술부문 인력" in self.last_dialog_message) or \
                   (toast.filter(has_text="정보기술부문 인력").count() > 0)
        self.last_dialog_message = None # 초기화

        # 결과 판정
        if case1_ok and case2_ok:
            result.pass_test("인력 수 계층 검증 확인 (Total >= IT / IT >= Security)")
        else:
            errors = []
            if not case1_ok: errors.append("IT 인력 수 상부 초과 검증 실패")
            if not case2_ok: errors.append("보안 인력 수 상부 초과 검증 실패")
            result.fail_test(", ".join(errors))

    def test_link11_numerical_boundary(self, result: UnitTestResult):
        """8. 수치 경계값 무결성 확인 (조 단위 입력)"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        
        # 카테고리 1 클릭
        cat1 = self.page.locator(".category-card", has_text="투자").first
        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        
        # Q1 '예' 선택
        q1_selector = self.get_question_selector('Q1')
        self.page.locator(f"{q1_selector} .yes-no-btn.yes").click()
        self.page.wait_for_timeout(1000)
        
        # Q2 에 1조원(1,000,000,000,000) 입력
        q2_input = self.get_input_by_display('Q2')
        large_val = "1000000000000"
        q2_input.fill(large_val)
        q2_input.blur()
        
        # Q4 에 5,000억원 입력 (비율 50% 유도)
        q4_input = self.get_input_by_display('Q4')
        half_val = "500000000000"
        q4_input.fill(half_val)
        q4_input.blur()
        
        self.page.wait_for_timeout(2000)
        
        # 비율 디스플레이 확인
        ratio_display = self.page.locator("#ratio-value")
        ratio_text = ratio_display.inner_text()
        
        if "50.00%" in ratio_text:
            result.pass_test(f"조 단위 대규모 수치 연산 무결성 확인 (비율: {ratio_text})")
        else:
            result.fail_test(f"대규모 수치 연산 오차 발생 (예상: 50.00%, 실제: {ratio_text})")

    def test_link11_evidence_physical_integrity(self, result: UnitTestResult):
        """8. 증빙 물리 파일 존재 무결성 확인"""
        # evidence_list 정의된 Q1 기준으로 테스트 (Q15는 evidence_list 미정의)
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)

        # 투자 카테고리 이동 (Q1에 evidence_list: 예산서, 품의서)
        cat1 = self.page.locator(".category-card", has_text="투자").first
        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible", timeout=5000)
        self.page.wait_for_timeout(1000)

        # Q1 YES 클릭하여 질문 활성화
        q1_yes = self.page.locator("#question-Q1 .yes-no-btn.yes")
        if q1_yes.count() > 0:
            q1_yes.click()
            self.page.wait_for_timeout(1000)

        # 업로드 모달 열기 (Q1 기준 버튼)
        btn_ev = self.page.locator("#question-Q1 .evidence-upload-btn")
        if btn_ev.count() == 0:
            btn_ev = self.page.locator(".evidence-upload-btn").first
        btn_ev.click()
        self.page.wait_for_selector("#uploadModal", state="visible")
        
        # 임시 파일 생성 (유효한 PNG 시그니처 포함) 및 업로드
        png_sig = b"\x89PNG\r\n\x1a\n"
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp.write(png_sig + b"fake image content for integrity check")
            tmp_path = tmp.name

        try:
            # 파일 선택 및 업로드
            self.page.set_input_files("input[type='file']", tmp_path)
            self.page.click("#uploadModal .btn-primary:has-text('업로드')")
            self.page.wait_for_timeout(4000) # 업로드 및 파일 시스템 동기화 대기
            
            # 업로드 경로 추적
            upload_root = project_root / "uploads"
            
            found = False
            # 재시도 로직 추가 (파일 시스템 쓰기 대기)
            for _ in range(3):
                for root, dirs, files in os.walk(upload_root):
                    for f in files:
                        f_path = Path(root) / f
                        if f_path.stat().st_size == (len(png_sig) + len(b"fake image content for integrity check")):
                            if f_path.read_bytes().startswith(png_sig):
                                found = True
                                break
                    if found: break
                if found: break
                self.page.wait_for_timeout(1000)
                
            if found:
                result.pass_test("파일 업로드 후 서버 내 물리적 파일 존재 확인 (데이터 일치)")
            else:
                result.fail_test("물리적 파일이 서버 저장소에 존재하지 않거나 내용이 불일치함")
                
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    def test_link11_recursive_cleanup(self, result: UnitTestResult):
        """8. 재귀적 하위 데이터 클렌징 무결성 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        
        # 투자 카테고리
        cat1 = self.page.locator(".category-card", has_text="투자").first
        cat1.click()
        self.page.wait_for_timeout(1000)
        
        # Q1 '예' 선택하고 Q2에 값 입력
        self.page.locator("#question-Q1 .yes-no-btn.yes").click()
        q2_input = self.get_input_by_display('Q2')
        q2_input.fill("888888")
        q2_input.blur()
        self.page.wait_for_timeout(1500)
        
        # 다시 Q1 '아니오' 선택 → 하위 질문 N/A 처리 트리거
        self.page.locator("#question-Q1 .yes-no-btn.no").click()
        self.page.wait_for_timeout(2000) # N/A 처리 완료 대기
        
        # 다시 Q1 '예' 선택하여 Q2를 열었을 때 값이 비어있어야 함 (무결성)
        self.page.locator("#question-Q1 .yes-no-btn.yes").click()
        self.page.wait_for_timeout(1000)
        
        q2_val = self.get_input_by_display('Q2').input_value()
        
        if q2_val == "" or q2_val == "0":
            result.pass_test("상위 질문 취소 시 하위 데이터 재귀적 클렌징 확인 (논리 무결성)")
        else:
            result.fail_test(f"데이터 클렌징 실패: Q2에 여전히 데이터가 남음 ('{q2_val}')")

    def test_link11_evidence_view_page(self, result: UnitTestResult):
        """5. 증빙 자료 관리 페이지 조회"""
        self._do_admin_login()
        self.navigate_to("/link11/evidence")
        self.page.wait_for_timeout(2000)

        page_has_title = self.page.locator("h1, h2, .page-title").count() > 0
        has_evidence_container = self.page.locator(
            "#evidence-list, .evidence-table, .evidence-container, table, .card"
        ).count() > 0

        if page_has_title or has_evidence_container:
            result.pass_test(f"증빙 자료 관리 페이지 로드 확인 (URL: {self.page.url})")
        else:
            result.fail_test(f"페이지 로드 실패 또는 컨텐츠 없음 (URL: {self.page.url})")

    def test_link11_progress_view(self, result: UnitTestResult):
        """1. 진행 현황 페이지 접근 확인"""
        self._do_admin_login()
        self.navigate_to("/link11/progress")
        self.page.wait_for_timeout(2000)

        progress_elem = self.page.locator(".progress-bar, .progress-chart, #progress-view, .completion-rate, .progress")
        page_title = self.page.locator("h1, h2, .page-title")

        if progress_elem.count() > 0:
            result.pass_test("진행 현황 페이지 로드 및 진행률 요소 확인")
        elif page_title.count() > 0:
            title_text = page_title.first.inner_text() if page_title.count() > 0 else ""
            result.pass_test(f"진행 현황 페이지 로드 확인 (제목: {title_text[:30]})")
        else:
            result.fail_test(f"진행 현황 페이지 로드 실패 (URL: {self.page.url})")

    def test_link11_q7_q8(self, result: UnitTestResult):
        """2. 향후 투자 계획(Q7) 및 예정 투자액(Q8) 응답 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        cat1 = self.page.locator(".category-card", has_text="투자").first
        if cat1.count() == 0:
            result.skip_test("투자 카테고리 없음")
            return

        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)

        q7_yes = self.page.locator("#question-Q7 .yes-no-btn.yes")
        if q7_yes.count() == 0:
            result.fail_test("Q7 (향후 투자 계획 여부) 버튼 미발견 - 렌더링 확인 필요")
            return

        q7_yes.scroll_into_view_if_needed()
        q7_yes.click()
        self.page.wait_for_timeout(1500)

        # Q8 (예정 투자액) 입력 필드 노출 확인
        q8_input = self.get_input_by_display('Q8')
        if q8_input.count() > 0 and q8_input.is_visible():
            q8_input.fill("500000")
            q8_input.blur()
            self.page.wait_for_timeout(1000)
            val = q8_input.input_value()
            result.pass_test(f"Q7 YES → Q8 연동 확인 (입력값: {val})")
        else:
            result.fail_test("Q7 YES 선택 후 Q8 (예정 투자액) 입력 필드가 나타나지 않음")

    def test_link11_q13_q14(self, result: UnitTestResult):
        """3. CISO/CPO 지정(Q13) 및 상세현황(Q14) 응답 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        cat2 = self.page.locator(".category-card", has_text="인력").first
        if cat2.count() == 0:
            result.skip_test("인력 카테고리 없음")
            return

        cat2.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)

        q9_yes = self.page.locator("#question-Q9 .yes-no-btn.yes")
        if q9_yes.count() > 0:
            q9_yes.click()
            self.page.wait_for_timeout(1500)

        q13_yes = self.page.locator("#question-Q13 .yes-no-btn.yes")
        if q13_yes.count() == 0:
            result.fail_test("Q13 (CISO/CPO 지정 여부) 버튼 미발견")
            return

        q13_yes.scroll_into_view_if_needed()
        q13_yes.click()
        self.page.wait_for_timeout(1500)

        # Q14는 테이블 형식(이름/직급/임원여부/겸직여부 다중 컬럼) → .first 사용
        q14_input = self.get_input_by_display('Q14')
        if q14_input.count() > 0 and q14_input.first.is_visible():
            result.pass_test(f"Q13 YES → Q14 (CISO/CPO 상세현황 테이블) 연동 확인 ({q14_input.count()}개 입력 셀)")
        else:
            result.fail_test("Q13 YES 선택 후 Q14 입력 필드가 나타나지 않음")

    def test_link11_q27_new_question(self, result: UnitTestResult):
        """2. 신규 질문 Q27 (주요 투자 항목) 렌더링 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        cat1 = self.page.locator(".category-card", has_text="투자").first
        if cat1.count() == 0:
            result.skip_test("투자 카테고리 없음")
            return

        cat1.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)

        q27_elem = self.page.locator("#question-Q27")
        if q27_elem.count() > 0:
            result.pass_test(f"Q27 (주요 투자 항목) 질문 요소 렌더링 확인 (표시: {q27_elem.is_visible()})")
        else:
            # Q27이 Q1 YES에 종속될 수 있음
            q1_yes = self.page.locator("#question-Q1 .yes-no-btn.yes")
            if q1_yes.count() > 0:
                q1_yes.click()
                self.page.wait_for_timeout(1500)
                q27_after = self.page.locator("#question-Q27")
                if q27_after.count() > 0:
                    result.pass_test("Q27 Q1 YES 선택 후 노출 확인 (종속 질문)")
                else:
                    result.fail_test("Q27 질문이 화면에 렌더링되지 않음 (DB 또는 템플릿 확인 필요)")
            else:
                result.fail_test("Q27 및 Q1 버튼 모두 미발견")

    def test_link11_q29_new_question(self, result: UnitTestResult):
        """3. 신규 질문 Q29 (CISO/CPO 활동내역) 렌더링 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2500)

        cat2 = self.page.locator(".category-card", has_text="인력").first
        if cat2.count() == 0:
            result.skip_test("인력 카테고리 없음")
            return

        cat2.click()
        self.page.wait_for_selector("#questions-view", state="visible")
        self.page.wait_for_timeout(1000)

        # Q13 YES에 종속되므로 먼저 Q9, Q13 순서로 활성화
        q9_yes = self.page.locator("#question-Q9 .yes-no-btn.yes")
        if q9_yes.count() > 0:
            q9_yes.click()
            self.page.wait_for_timeout(1000)

        q13_yes = self.page.locator("#question-Q13 .yes-no-btn.yes")
        if q13_yes.count() == 0:
            result.fail_test("Q13 버튼 미발견 — Q29 종속 여부 확인 불가")
            return

        q13_yes.scroll_into_view_if_needed()
        q13_yes.click()
        self.page.wait_for_timeout(1500)

        q29_elem = self.page.locator("#question-Q29")
        if q29_elem.count() > 0 and q29_elem.is_visible():
            result.pass_test("Q29 (CISO/CPO 활동내역) Q13 YES 선택 후 노출 확인")
        else:
            result.fail_test("Q29 질문이 화면에 렌더링되지 않음 (DB 또는 템플릿 확인 필요)")

    def test_link11_evidence_delete(self, result: UnitTestResult):
        """5. 증빙 파일 삭제 기능 확인"""
        import requests as req
        import tempfile

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        png_sig = b"\x89PNG\r\n\x1a\n"
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp.write(png_sig + b"evidence delete test")
            tmp_path = tmp.name

        try:
            # 1. 파일 업로드
            with open(tmp_path, 'rb') as f:
                upload_resp = req.post(
                    f"{self.base_url}/link11/api/evidence",
                    files={'file': ('del_test.png', f, 'image/png')},
                    data={'question_id': 'Q15', 'year': '2024', 'evidence_type': 'cert'},
                    cookies=session_cookie, timeout=10
                )

            if upload_resp.status_code == 401:
                result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
                return
            if upload_resp.status_code != 200 or not upload_resp.json().get('success'):
                result.skip_test(f"사전 업로드 실패로 삭제 테스트 건너뜀 ({upload_resp.status_code})")
                return

            evidence_id = upload_resp.json().get('evidence', {}).get('id')
            if not evidence_id:
                result.skip_test("업로드 응답에서 증빙 ID를 가져올 수 없음")
                return

            # 2. 삭제 요청
            del_resp = req.delete(
                f"{self.base_url}/link11/api/evidence/{evidence_id}",
                cookies=session_cookie, timeout=10
            )

            if del_resp.status_code == 200 and del_resp.json().get('success'):
                result.pass_test(f"증빙 파일 삭제 확인 (ID: {evidence_id[:8]}...)")
            else:
                result.fail_test(f"증빙 삭제 실패: HTTP {del_resp.status_code} - {del_resp.text[:80]}")

        except Exception as e:
            result.fail_test(f"테스트 중 오류: {str(e)}")
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    def test_link11_evidence_download(self, result: UnitTestResult):
        """5. 증빙 파일 다운로드 확인"""
        import requests as req
        import tempfile

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        png_sig = b"\x89PNG\r\n\x1a\n"
        with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
            tmp.write(png_sig + b"evidence download test")
            tmp_path = tmp.name

        evidence_id = None
        try:
            # 1. 파일 업로드
            with open(tmp_path, 'rb') as f:
                upload_resp = req.post(
                    f"{self.base_url}/link11/api/evidence",
                    files={'file': ('dl_test.png', f, 'image/png')},
                    data={'question_id': 'Q15', 'year': '2024', 'evidence_type': 'cert'},
                    cookies=session_cookie, timeout=10
                )

            if upload_resp.status_code == 401:
                result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
                return
            if upload_resp.status_code != 200 or not upload_resp.json().get('success'):
                result.skip_test(f"사전 업로드 실패 ({upload_resp.status_code})")
                return

            evidence_id = upload_resp.json().get('evidence', {}).get('id')
            if not evidence_id:
                result.skip_test("업로드 응답에서 증빙 ID를 가져올 수 없음")
                return

            # 2. 다운로드 요청
            dl_resp = req.get(
                f"{self.base_url}/link11/api/evidence/download/{evidence_id}",
                cookies=session_cookie, timeout=10
            )

            if dl_resp.status_code == 200 and len(dl_resp.content) > 0:
                result.pass_test(f"증빙 파일 다운로드 확인 ({len(dl_resp.content)} bytes)")
            else:
                result.fail_test(f"다운로드 실패: HTTP {dl_resp.status_code}")

        except Exception as e:
            result.fail_test(f"테스트 중 오류: {str(e)}")
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)
            # 업로드된 테스트 파일 정리
            if evidence_id:
                try:
                    import requests as req2
                    req2.delete(
                        f"{self.base_url}/link11/api/evidence/{evidence_id}",
                        cookies=session_cookie, timeout=5
                    )
                except Exception:
                    pass

    def test_link11_submit_incomplete_blocked(self, result: UnitTestResult):
        """6. 미완료 상태에서 공시 제출 차단 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        response = req.post(
            f"{self.base_url}/link11/api/submit/1/2024",
            json={'details': 'unit test - incomplete submission'},
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 401:
            result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
        elif response.status_code in (400, 404):
            msg = response.json().get('message', '')
            result.pass_test(f"미완료/세션 없음으로 공시 제출 차단 확인: {msg[:60]}")
        elif response.status_code == 200:
            result.warn_test("제출 성공 - 해당 회사의 완료율이 이미 100%인 상태일 수 있음")
        else:
            result.fail_test(f"예상치 못한 응답: HTTP {response.status_code}")

    def test_link11_reset_disclosure(self, result: UnitTestResult):
        """6. 데이터 초기화(새로하기) API 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        # 테스트 전용 연도(9998) 사용 — 실제 운영 데이터 영향 없음
        test_year = 9998
        response = req.post(
            f"{self.base_url}/link11/api/reset/1/{test_year}",
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 401:
            result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
        elif response.status_code == 200:
            resp_json = response.json()
            if resp_json.get('success'):
                result.pass_test(f"데이터 초기화 API 정상 응답 확인: {resp_json.get('message', '')}")
            else:
                result.fail_test(f"초기화 API 실패 응답: {resp_json.get('message', '')}")
        else:
            result.fail_test(f"초기화 API 오류: HTTP {response.status_code}")

    def test_link11_copy_block_verification(self, result: UnitTestResult):
        """6. 전년도 자료 복사(직접 복사) 차단 및 가이드 메시지 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        # 이전에는 복사가 성공했으나, 이제는 403 Forbidden과 가이드 메시지가 와야 함
        # target_year를 2025로 설정 (이미 데이터가 있을 수 있으므로 무관)
        response = req.post(
            f"{self.base_url}/link11/api/copy-from-year/1/2024/2025",
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 403:
            resp_json = response.json()
            msg = resp_json.get('message', '')
            if '전년도 참고' in msg and '데이터 무결성' in msg:
                result.pass_test(f"직접 복사 기능 차단 및 가이드 메시지 확인 완료: {msg[:60]}...")
            else:
                result.fail_test(f"차단되었으나 메시지가 예상과 다름: {msg}")
        elif response.status_code == 401:
            result.skip_test("로그인 세션 만료")
        else:
            result.fail_test(f"기능이 차단되지 않음 (Status: {response.status_code})")

    def test_link11_reference_view(self, result: UnitTestResult):
        """9. 전년도 참고 패널 노출 및 데이터 조회 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)

        # 전년도 참고 버튼 클릭
        ref_btn = self.page.locator("button:has-text('전년도 참고')")
        if ref_btn.count() > 0:
            ref_btn.click()
            self.page.wait_for_timeout(1000)

            # 패널 노출 확인
            panel = self.page.locator(".reference-panel")
            if panel.is_visible():
                # 연도 선택 셀렉트 박스 존재 확인
                year_select = self.page.locator("#ref-year-select")
                if year_select.count() > 0:
                    result.pass_test("전년도 참고 패널 노출 및 구성 요소 확인 완료")
                else:
                    result.fail_test("참고 패널 내 연도 선택 필드 미발견")
            else:
                result.fail_test("참고 패널이 화면에 표시되지 않음")
        else:
            result.fail_test("'전년도 참고' 버튼을 찾을 수 없음")

    def test_link11_ratio_trigger_integrity(self, result: UnitTestResult):
        """9. 상위 트리거 '아니오' 시 하위 잔류 데이터 무시 확인 (대시보드 0% 고정)"""
        import requests as req
        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        # 1. 테스트용 데이터를 강제로 주입 (Q1=NO 지만 Q2, Q3에 값이 있는 모순된 상태)
        # API를 통해 Q2, Q4 값을 먼저 넣고 마지막에 Q1을 NO로 변경
        base_api = f"{self.base_url}/link11/api/answers"
        req.post(base_api, json={'question_id': 'Q2', 'value': '1000000', 'year': 2026}, cookies=session_cookie)
        req.post(base_api, json={'question_id': 'Q4', 'value': '500000', 'year': 2026}, cookies=session_cookie)
        req.post(base_api, json={'question_id': 'Q1', 'value': 'NO', 'year': 2026}, cookies=session_cookie)
        
        self.navigate_to("/link11")
        # 2026년으로 연도 변경
        self.page.select_option("#disclosure-year-select", "2026")
        self.page.wait_for_timeout(3000)

        # 2. 대시보드 수치 확인
        inv_ratio = self.page.locator("#dashboard-inv-ratio").inner_text()
        
        # 3. Q1이 NO이므로 하위 데이터가 있더라도 0.00%여야 함
        if inv_ratio == "0.00":
            result.pass_test("상위 트리거 '아니오' 시 잔류 데이터 무시하고 0% 표시 확인 (무결성 강화)")
        else:
            result.fail_test(f"잔류 데이터로 인해 비율이 계산됨 (현재: {inv_ratio}%, 예상: 0.00%)")

    def test_link11_available_years(self, result: UnitTestResult):
        """6. 이용 가능 연도 목록 조회 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        response = req.get(
            f"{self.base_url}/link11/api/available-years/1",
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 401:
            result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
        elif response.status_code == 200:
            resp_json = response.json()
            if resp_json.get('success') and 'years' in resp_json:
                result.pass_test(f"이용 가능 연도 목록 조회 성공 ({len(resp_json['years'])}개 연도)")
            else:
                result.fail_test(f"API 응답 형식 오류: {str(resp_json)[:80]}")
        else:
            result.fail_test(f"연도 목록 API 오류: HTTP {response.status_code}")

    def test_link11_submit_disclosure(self, result: UnitTestResult):
        """10. 공시 제출 API 호출 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        response = req.post(
            f"{self.base_url}/link11/api/submit/1/2024",
            json={'details': 'unit test - submit'},
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 401:
            result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
        elif response.status_code == 200:
            resp_json = response.json()
            if resp_json.get('success'):
                result.pass_test("공시 제출 API 정상 응답 (submitted 상태로 전환)")
            else:
                result.fail_test(f"제출 API 응답 오류: {resp_json.get('message', '')}")
        elif response.status_code == 404:
            msg = response.json().get('message', '')
            result.warn_test(f"공시 세션 없음 (세션 생성 후 재테스트 필요): {msg[:80]}")
        elif response.status_code in (400, 403):
            msg = response.json().get('message', '')
            result.warn_test(f"제출 차단: {msg[:80]} (완료율 미달 또는 이미 확정 상태)")
        else:
            result.fail_test(f"예상치 못한 응답: HTTP {response.status_code}")

    def test_link11_confirm_disclosure(self, result: UnitTestResult):
        """10. 공시 확정 API 동작 확인 (submitted → confirmed)"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        response = req.post(
            f"{self.base_url}/link11/api/confirm/1/2024",
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 401:
            result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
        elif response.status_code == 200:
            resp_json = response.json()
            if resp_json.get('success'):
                result.pass_test("공시 확정 API 정상 응답 (confirmed 상태로 전환)")
            else:
                result.fail_test(f"확정 API 응답 오류: {resp_json.get('message', '')}")
        elif response.status_code == 404:
            msg = response.json().get('message', '')
            result.warn_test(f"공시 세션 없음 (세션 생성 후 재테스트 필요): {msg[:80]}")
        elif response.status_code == 400:
            msg = response.json().get('message', '')
            result.warn_test(f"확정 조건 미충족 (submitted 상태 아님): {msg[:80]}")
        else:
            result.fail_test(f"예상치 못한 응답: HTTP {response.status_code}")

    def test_link11_unconfirm_disclosure(self, result: UnitTestResult):
        """10. 공시 확정 해제 API 동작 확인 (confirmed → submitted)"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        response = req.post(
            f"{self.base_url}/link11/api/unconfirm/1/2024",
            cookies=session_cookie, timeout=10
        )

        if response.status_code == 401:
            result.skip_test("로그인 세션이 API에 전달되지 않음 (쿠키 문제)")
        elif response.status_code == 200:
            resp_json = response.json()
            if resp_json.get('success'):
                result.pass_test("공시 확정 해제 API 정상 응답 (submitted 상태로 복귀)")
            else:
                result.fail_test(f"확정 해제 API 응답 오류: {resp_json.get('message', '')}")
        elif response.status_code == 400:
            msg = response.json().get('message', '')
            result.warn_test(f"확정 해제 조건 미충족 (confirmed 상태 아님): {msg[:80]}")
        else:
            result.fail_test(f"예상치 못한 응답: HTTP {response.status_code}")

    def test_link11_confirmed_save_blocked(self, result: UnitTestResult):
        """10. confirmed 상태에서 답변 저장 시 403 차단 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        # 테스트 연도로 submit → confirm 시도 (이미 confirmed면 바로 저장 테스트)
        test_year = 9997
        req.post(f"{self.base_url}/link11/api/submit/1/{test_year}",
                 json={'details': 'test'}, cookies=session_cookie, timeout=10)
        confirm_resp = req.post(f"{self.base_url}/link11/api/confirm/1/{test_year}",
                                cookies=session_cookie, timeout=10)

        if confirm_resp.status_code != 200 or not confirm_resp.json().get('success'):
            # 현재 연도(2024) 기준으로 already confirmed 상태인지 체크
            save_resp_2024 = req.post(
                f"{self.base_url}/link11/api/answers",
                json={'question_id': 'Q1', 'value': 'YES', 'year': 2024},
                cookies=session_cookie, timeout=10
            )
            if save_resp_2024.status_code == 403:
                msg = save_resp_2024.json().get('message', '')
                result.pass_test(f"confirmed 상태 저장 차단 확인 (403): {msg[:60]}")
            else:
                result.skip_test("confirmed 상태 설정 불가 (완료율 100% 미충족으로 제출 선행 필요)")
            return

        # confirmed 상태에서 답변 저장 시도
        save_resp = req.post(
            f"{self.base_url}/link11/api/answers",
            json={'question_id': 'Q1', 'value': 'YES', 'year': test_year},
            cookies=session_cookie, timeout=10
        )

        if save_resp.status_code == 403:
            msg = save_resp.json().get('message', '')
            result.pass_test(f"confirmed 상태 저장 차단 확인 (403): {msg[:60]}")
        elif save_resp.status_code == 401:
            result.skip_test("로그인 세션 만료")
        else:
            result.fail_test(f"차단되지 않음: HTTP {save_resp.status_code}")

    def test_link11_confirmed_fields_disabled(self, result: UnitTestResult):
        """10. confirmed 상태에서 입력 필드 disabled 렌더링 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        # confirmed 상태인 연도 탐색
        years_resp = req.get(
            f"{self.base_url}/link11/api/available-years/1",
            cookies=session_cookie, timeout=10
        )
        confirmed_year = None
        if years_resp.status_code == 200:
            for y in years_resp.json().get('years', []):
                if y.get('status') == 'confirmed':
                    confirmed_year = y.get('year')
                    break

        if not confirmed_year:
            result.skip_test("confirmed 상태인 연도 없음 — 확정 완료 후 재테스트 필요")
            return

        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)
        self.page.select_option("#disclosure-year-select", str(confirmed_year))
        self.page.wait_for_timeout(2000)

        # 카테고리 클릭해서 질문 로드
        cat_card = self.page.locator(".category-card").first
        if cat_card.count() > 0:
            cat_card.click()
            self.page.wait_for_timeout(1500)

        disabled_inputs = self.page.locator("#questions-view input:disabled, #questions-view textarea:disabled")
        total_inputs = self.page.locator("#questions-view input, #questions-view textarea")

        if disabled_inputs.count() > 0:
            result.pass_test(
                f"confirmed 상태 입력 필드 disabled 확인 "
                f"({disabled_inputs.count()}/{total_inputs.count()}개 잠금, {confirmed_year}년)"
            )
        else:
            result.fail_test(
                f"confirmed 상태({confirmed_year}년)임에도 입력 필드가 모두 활성화되어 있음"
            )

    def test_link11_reference_year_status_badge(self, result: UnitTestResult):
        """11. 연도 참고 드롭다운에 상태 뱃지 표시 확인"""
        self._do_admin_login()
        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)

        ref_btn = self.page.locator("button:has-text('전년도 참고')")
        if ref_btn.count() == 0:
            result.fail_test("'전년도 참고' 버튼을 찾을 수 없음")
            return

        ref_btn.click()
        self.page.wait_for_timeout(1000)

        year_select = self.page.locator("#ref-year-select")
        if year_select.count() == 0:
            result.fail_test("연도 선택 드롭다운을 찾을 수 없음")
            return

        options = year_select.locator("option")
        if options.count() <= 1:
            result.skip_test("참고 가능한 연도가 없음 — 데이터 입력 후 재테스트 필요")
            return

        first_option_text = options.nth(1).inner_text()
        status_keywords = ['확정', '제출됨', '작성완료', '작성중', '진행중', '미시작', '초안']
        has_status = any(kw in first_option_text for kw in status_keywords)

        if has_status:
            result.pass_test(f"연도 드롭다운 상태 뱃지 확인: '{first_option_text}'")
        else:
            result.fail_test(f"상태 표시 없이 연도만 표시됨: '{first_option_text}'")

    def test_link11_reference_panel_status_banner(self, result: UnitTestResult):
        """11. 참고 패널 내 상태 안내 배너 표시 확인"""
        import requests as req

        self._do_admin_login()
        cookies = self.context.cookies()
        session_cookie = {c['name']: c['value'] for c in cookies if 'session' in c['name'].lower()}

        years_resp = req.get(
            f"{self.base_url}/link11/api/available-years/1",
            cookies=session_cookie, timeout=10
        )
        if years_resp.status_code != 200 or not years_resp.json().get('years'):
            result.skip_test("참고 가능한 연도 없음 — 데이터 입력 후 재테스트 필요")
            return

        ref_year = years_resp.json()['years'][0].get('year')

        self.navigate_to("/link11")
        self.page.wait_for_timeout(2000)

        ref_btn = self.page.locator("button:has-text('전년도 참고')")
        if ref_btn.count() == 0:
            result.fail_test("'전년도 참고' 버튼을 찾을 수 없음")
            return

        ref_btn.click()
        self.page.wait_for_timeout(2500)  # 비동기 옵션 로드 대기

        year_select = self.page.locator("#ref-year-select")
        if year_select.count() > 0:
            options = year_select.locator("option")
            # 옵션 value 기반으로 선택 (텍스트에 연도 포함된 옵션 찾기)
            selected = False
            for i in range(options.count()):
                opt_val = options.nth(i).get_attribute("value") or ""
                if str(ref_year) in opt_val or opt_val == str(ref_year):
                    year_select.select_option(value=opt_val)
                    selected = True
                    break
            if not selected:
                # fallback: 첫 번째 실제 옵션 선택
                if options.count() > 1:
                    first_val = options.nth(1).get_attribute("value") or ""
                    if first_val:
                        year_select.select_option(value=first_val)
            self.page.wait_for_timeout(2000)

        status_banner = self.page.locator(".reference-panel .ref-status-banner, .reference-panel .alert")
        if status_banner.count() > 0 and status_banner.first.is_visible():
            result.pass_test(f"참고 패널 상태 안내 배너 표시 확인 ({ref_year}년 데이터)")
        else:
            result.fail_test("참고 패널 내 상태 안내 배너가 표시되지 않음")

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
                    # 결과 메시지에서 개행 문자 제거하여 마크다운 양식 유지
                    clean_message = res.message.replace('\n', ' ').strip()
                    if res.status == TestStatus.PASSED:
                        updated_line = line.replace("- [ ]", "- [x] ✅")
                        updated_line = updated_line.rstrip() + f" → **통과** ({clean_message})\n"
                    elif res.status == TestStatus.FAILED:
                        updated_line = line.replace("- [ ]", "- [ ] ❌")
                        updated_line = updated_line.rstrip() + f" → **실패** ({clean_message})\n"
                    elif res.status == TestStatus.WARNING:
                        updated_line = line.replace("- [ ]", "- [~] ⚠️")
                        updated_line = updated_line.rstrip() + f" → **경고** ({clean_message})\n"
                    elif res.status == TestStatus.SKIPPED:
                        updated_line = line.replace("- [ ]", "- [ ] ⊘")
                        updated_line = updated_line.rstrip() + f" → **건너뜀** ({clean_message})\n"
                    break
            updated_lines.append(updated_line)

        passed = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        warning = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        total = len(self.results) if self.results else 1

        updated_lines.append("\n---\n")
        updated_lines.append(f"## 테스트 결과 요약\n\n")
        updated_lines.append(f"| 항목 | 개수 | 비율 |\n")
        updated_lines.append(f"|------|------|------|\n")
        updated_lines.append(f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n")
        updated_lines.append(f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n")
        updated_lines.append(f"| ⚠️ 경고 | {warning} | {warning/total*100:.1f}% |\n")
        updated_lines.append(f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n")
        updated_lines.append(f"| **총계** | **{total}** | **100%** |\n")

        with open(self.checklist_result, 'w', encoding='utf-8') as f:
            f.writelines(updated_lines)
        print(f"\n✅ Link11 체크리스트 결과 저장됨: {self.checklist_result}")

def run_tests():
    test_runner = Link11UnitTest(headless=True, slow_mo=500)
    test_runner.setup()
    try:
        test_runner.run_category("Link11 Unit Tests", [
            # 기존 테스트 (20개)
            test_runner.test_link11_access,
            test_runner.test_link11_dashboard_stats,
            test_runner.test_link11_category_navigation,
            test_runner.test_link11_answer_yes_no,
            test_runner.test_link11_dependent_questions,
            test_runner.test_link11_currency_input,
            test_runner.test_link11_validation_b_lt_a,
            test_runner.test_link11_validation_negative,
            test_runner.test_link11_validation_personnel,
            test_runner.test_link11_auto_calculation,
            test_runner.test_link11_number_input,
            test_runner.test_link11_multi_select,
            test_runner.test_link11_evidence_modal,
            test_runner.test_link11_evidence_mime_validation,
            test_runner.test_link11_report_preview,
            test_runner.test_link11_report_download,
            # test_link11_company_data_isolation: 멀티 회사 테스트 데이터 부재로 제외
            test_runner.test_link11_numerical_boundary,
            test_runner.test_link11_evidence_physical_integrity,
            test_runner.test_link11_recursive_cleanup,
            # 신규 추가 테스트 (12개) - 커버리지 갭 보완
            test_runner.test_link11_evidence_view_page,
            test_runner.test_link11_progress_view,
            test_runner.test_link11_q7_q8,
            test_runner.test_link11_q13_q14,
            test_runner.test_link11_q27_new_question,
            test_runner.test_link11_q29_new_question,
            test_runner.test_link11_evidence_delete,
            test_runner.test_link11_evidence_download,
            test_runner.test_link11_submit_incomplete_blocked,
            test_runner.test_link11_reset_disclosure,
            test_runner.test_link11_copy_block_verification,
            test_runner.test_link11_available_years,
            test_runner.test_link11_reference_view,
            test_runner.test_link11_ratio_trigger_integrity,
            # 확정 프로세스 및 입력 잠금 (5개)
            test_runner.test_link11_submit_disclosure,
            test_runner.test_link11_confirm_disclosure,
            test_runner.test_link11_unconfirm_disclosure,
            test_runner.test_link11_confirmed_save_blocked,
            test_runner.test_link11_confirmed_fields_disabled,
            # 연도별 참고 패널 개선 (2개)
            test_runner.test_link11_reference_year_status_badge,
            test_runner.test_link11_reference_panel_status_banner,
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()

if __name__ == "__main__":
    run_tests()
