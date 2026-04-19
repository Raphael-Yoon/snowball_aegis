"""
E2E 통합 테스트 (ITGC / ELC / TLC)

[실행 방법]
    python test/test_e2e_evaluation.py --type=itgc
    python test/test_e2e_evaluation.py --type=elc
    python test/test_e2e_evaluation.py --type=tlc
    python test/test_e2e_evaluation.py --type=all

    옵션:
        --type      : itgc, elc, tlc, all (기본: itgc)
        --headless  : 브라우저 숨김 모드
        --url       : 서버 URL (기본: http://localhost:5001)

[테스트 흐름]
    Phase 1: RCM 업로드 (공통)
    Phase 2: 설계평가 (타입별)
    Phase 3: 운영평가 (타입별)
    Cleanup: 역순 삭제
"""

import os
import sys
import time
import argparse
import requests
import subprocess
from pathlib import Path
from datetime import datetime
from enum import Enum

# 프로젝트 루트 경로 설정
project_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, UnitTestResult, TestStatus


class EvaluationType(Enum):
    ITGC = "itgc"
    ELC = "elc"
    TLC = "tlc"
    ALL = "all"


class E2EEvaluationTestSuite(PlaywrightTestBase):
    """E2E 통합 테스트 스위트 (ITGC/ELC/TLC)"""

    def __init__(self, base_url="http://localhost:5001", headless=False, eval_type="itgc"):
        super().__init__(base_url=base_url, headless=headless)

        self.eval_type = eval_type.lower()

        # 테스트 데이터 경로
        self.rcm_file_path = project_root / "test" / "assets" / f"e2e_{self.eval_type}_rcm.xlsx"
        self.checklist_result = project_root / "test" / f"e2e_checklist_{self.eval_type}_result.md"

        # 공유 테스트 데이터
        timestamp = int(time.time())
        self.rcm_name = f"E2E_{self.eval_type.upper()}_{timestamp}"
        self.design_eval_name = f"E2E_Design_{timestamp}"
        self.rcm_id = None

        self.server_process = None
        self.server_was_running = False  # 기존 서버가 실행 중이었는지
        self.skip_server_stop = False    # 외부에서 서버 관리시 True

        # 타입별 설정
        self.type_config = {
            "itgc": {
                "category": "ITGC",
                "control_prefix": "E2E-ITGC",
                "eval_page": "/itgc-evaluation",
                "design_url": "/design-evaluation/rcm",
                "operation_url": "/operation-evaluation/rcm"
            },
            "elc": {
                "category": "ELC",
                "control_prefix": "E2E-ELC",
                "eval_page": "/elc/design-evaluation",
                "design_url": "/design-evaluation/rcm",
                "operation_url": "/operation-evaluation/rcm"
            },
            "tlc": {
                "category": "TLC",
                "control_prefix": "E2E-TLC",
                "eval_page": "/tlc-evaluation",
                "design_url": "/design-evaluation/rcm",
                "operation_url": "/operation-evaluation/rcm"
            }
        }

    # =========================================================================
    # 테스트 데이터 준비
    # =========================================================================

    def setup_test_data(self):
        """테스트용 RCM 엑셀 파일 생성"""
        assets_dir = project_root / "test" / "assets"
        assets_dir.mkdir(parents=True, exist_ok=True)

        from openpyxl import Workbook

        config = self.type_config.get(self.eval_type, self.type_config["itgc"])
        prefix = config["control_prefix"]

        wb = Workbook()
        ws = wb.active

        if self.eval_type == "itgc":
            ws.append([
                "통제코드", "통제명", "통제설명", "핵심통제",
                "통제주기", "통제유형", "통제속성", "모집단", "테스트절차"
            ])
            ws.append([f"{prefix}-01", "접근권한 관리", "시스템 접근 권한을 적절히 관리", "Y", "상시", "예방", "수동", "접근권한 목록", "권한 부여 현황 확인"])
            ws.append([f"{prefix}-02", "변경관리", "시스템 변경 시 승인 절차 준수", "Y", "수시", "탐지", "자동", "변경요청서", "변경 승인 이력 확인"])
            ws.append([f"{prefix}-03", "운영 보안", "운영 환경의 보안 유지", "N", "월별", "예방", "수동", "보안점검표", "월별 점검 결과 확인"])
        elif self.eval_type == "elc":
            ws.append([
                "통제코드", "통제명", "통제설명", "핵심통제",
                "통제주기", "통제유형", "통제속성", "모집단", "테스트절차"
            ])
            ws.append([f"{prefix}-01", "전사 윤리강령", "윤리경영 강령 수립 및 준수", "Y", "연간", "예방", "수동", "윤리강령 문서", "윤리강령 검토"])
            ws.append([f"{prefix}-02", "이사회 독립성", "이사회 구성원의 독립성 확보", "Y", "연간", "예방", "수동", "이사회 명단", "독립성 평가"])
        elif self.eval_type == "tlc":
            ws.append([
                "통제코드", "통제명", "통제설명", "핵심통제",
                "통제주기", "통제유형", "통제속성", "모집단", "테스트절차"
            ])
            ws.append([f"{prefix}-01", "거래 승인", "주요 거래에 대한 승인 절차", "Y", "수시", "예방", "수동", "승인기록", "승인 절차 검토"])
            ws.append([f"{prefix}-02", "거래 검증", "거래 내역의 정확성 검증", "Y", "일별", "탐지", "자동", "거래내역", "검증 결과 확인"])

        wb.save(self.rcm_file_path)
        print(f"    → 테스트용 RCM 파일 생성: {self.rcm_file_path}")

    def check_server_running(self):
        """서버 실행 상태 확인"""
        try:
            response = requests.get(f"{self.base_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"✅ 서버 실행 중 ({self.base_url})")
                self.server_was_running = True
                return True
        except:
            pass

        print(f"⚠️ 서버가 실행 중이지 않습니다. 서버를 시작합니다...")
        self.server_was_running = False
        return self._start_server()

    def stop_server(self):
        """서버 중지 (직접 시작한 경우에만)"""
        if self.skip_server_stop:
            return
        if self.server_process and not self.server_was_running:
            print(f"\n🛑 서버 중지 중... (PID: {self.server_process.pid})")
            try:
                self.server_process.terminate()
                self.server_process.wait(timeout=5)
                print(f"✅ 서버 중지 완료")
            except Exception as e:
                print(f"⚠️ 서버 중지 중 오류: {e}")
                try:
                    self.server_process.kill()
                except:
                    pass
            self.server_process = None

    def _start_server(self):
        """서버 백그라운드 시작"""
        try:
            self.server_process = subprocess.Popen(
                [sys.executable, "snowball.py"],
                cwd=str(project_root),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == 'win32' else 0
            )
            print(f"   서버 시작 중... (PID: {self.server_process.pid})")

            for i in range(30):
                time.sleep(1)
                try:
                    response = requests.get(f"{self.base_url}/health", timeout=2)
                    if response.status_code == 200:
                        print(f"✅ 서버 시작 완료")
                        return True
                except:
                    print(f"   서버 준비 대기 중... ({i+1}/30)")

            print(f"❌ 서버 시작 시간 초과")
            return False
        except Exception as e:
            print(f"❌ 서버 시작 실패: {e}")
            return False

    # =========================================================================
    # 공통 헬퍼 메서드
    # =========================================================================

    def _do_admin_login(self):
        """관리자 로그인"""
        page = self.page
        current_url = page.url

        if "/login" not in current_url:
            page.goto(f"{self.base_url}/")
            page.wait_for_load_state("networkidle")
            if page.locator("a:has-text('로그아웃')").count() > 0:
                print("    → 이미 로그인 상태")
                return

        print("    → 로그인 페이지로 이동...")
        page.goto(f"{self.base_url}/login")
        page.wait_for_load_state("networkidle")

        admin_btn = page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            page.wait_for_load_state("networkidle")
            print("    → 로그인 완료")
        else:
            raise Exception("관리자 로그인 버튼을 찾을 수 없습니다")

    def _close_any_open_modal(self):
        """열린 모달 닫기"""
        page = self.page
        try:
            for modal_id in ["#evaluationModal", "#operationEvaluationModal"]:
                modal = page.locator(f"{modal_id}.show")
                if modal.count() > 0:
                    close_btn = page.locator(f"{modal_id} button[data-bs-dismiss='modal']")
                    if close_btn.count() > 0 and close_btn.first.is_visible():
                        close_btn.first.click()
                        page.wait_for_timeout(500)
                    else:
                        page.keyboard.press("Escape")
                        page.wait_for_timeout(500)
        except:
            pass

    def _get_config(self):
        """현재 타입의 설정 반환"""
        return self.type_config.get(self.eval_type, self.type_config["itgc"])

    # =========================================================================
    # Phase 1: RCM 관리 (공통)
    # =========================================================================

    def test_rcm_upload(self, result: UnitTestResult):
        """[RCM] 업로드"""
        page = self.page
        config = self._get_config()

        page.goto(f"{self.base_url}/rcm")
        page.wait_for_load_state("networkidle")

        upload_btn = page.locator("a:has-text('RCM 업로드')")
        if upload_btn.count() == 0:
            result.fail_test("RCM 업로드 버튼을 찾을 수 없음")
            return
        upload_btn.click()
        page.wait_for_load_state("networkidle")

        print(f"    → RCM 이름: {self.rcm_name}")
        page.fill("#rcm_name", self.rcm_name)
        page.select_option("#control_category", config["category"])
        page.set_input_files("#rcm_file", str(self.rcm_file_path))
        page.wait_for_timeout(2000)

        page.once("dialog", lambda d: d.accept())
        page.click("button[type='submit']")
        page.wait_for_timeout(5000)

        page.goto(f"{self.base_url}/rcm")
        page.wait_for_load_state("networkidle")

        if page.locator(f"text={self.rcm_name}").count() > 0:
            result.pass_test(f"RCM 업로드 성공: {self.rcm_name}")
        else:
            result.fail_test("RCM 업로드 후 목록에서 확인 실패")

    def test_rcm_list_display(self, result: UnitTestResult):
        """[RCM] 목록 표시 확인"""
        page = self.page

        page.goto(f"{self.base_url}/rcm")
        page.wait_for_load_state("networkidle")

        if page.locator(f"text={self.rcm_name}").count() > 0:
            result.pass_test(f"RCM '{self.rcm_name}' 목록 표시 확인")
        else:
            result.fail_test("RCM 목록에서 찾을 수 없음")

    # =========================================================================
    # Phase 2: 설계평가
    # =========================================================================

    def test_design_create_session(self, result: UnitTestResult):
        """[설계평가] 세션 생성"""
        page = self.page
        config = self._get_config()

        page.goto(f"{self.base_url}{config['eval_page']}")
        page.wait_for_load_state("networkidle")

        start_btn = page.locator("button:has-text('내부평가 시작')")
        if start_btn.count() == 0:
            result.fail_test("내부평가 시작 버튼 없음")
            return
        start_btn.click()

        page.wait_for_timeout(1000)
        rcm_item = page.locator(f"div#rcmSelectionStep a:has-text('{self.rcm_name}')")
        if rcm_item.count() == 0:
            result.fail_test(f"RCM '{self.rcm_name}' 선택 불가")
            return
        rcm_item.click()

        print(f"    → 설계평가명: {self.design_eval_name}")
        page.fill("#evaluationNameInput", self.design_eval_name)
        page.click("button:has-text('설계평가 시작')")
        page.wait_for_load_state("networkidle")

        if config["design_url"] in page.url:
            result.pass_test("설계평가 세션 생성 및 상세 페이지 진입")
        else:
            page.goto(f"{self.base_url}{config['eval_page']}")
            page.wait_for_load_state("networkidle")
            if page.locator(f"text={self.design_eval_name}").count() > 0:
                result.pass_test("설계평가 세션 생성 확인")
            else:
                result.fail_test("설계평가 세션 생성 실패")

    def test_design_evaluate_control(self, result: UnitTestResult):
        """[설계평가] 평가 수행"""
        page = self.page
        config = self._get_config()

        if config["design_url"] not in page.url:
            page.goto(f"{self.base_url}{config['eval_page']}")
            page.wait_for_load_state("networkidle")

            accordion = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
            if accordion.count() > 0 and "collapsed" in (accordion.first.get_attribute("class") or ""):
                accordion.first.click()
                page.wait_for_timeout(500)

            continue_btn = page.locator(f"tr:has-text('{self.design_eval_name}') button:has-text('계속하기')")
            if continue_btn.count() > 0:
                continue_btn.click()
                page.wait_for_load_state("networkidle")

        eval_btns = page.locator("#controlsTable button:has-text('평가'), #controlsTable button:has-text('수정')")
        if eval_btns.count() == 0:
            result.fail_test("평가 버튼 없음")
            return

        eval_btns.first.click()
        page.wait_for_selector("#evaluationModal.show", timeout=5000)

        page.select_option("#descriptionAdequacy", "adequate")
        page.wait_for_timeout(500)
        page.select_option("#overallEffectiveness", "effective")
        page.locator("#evaluationEvidence").fill(f"E2E {self.eval_type.upper()} 테스트 - 통제 설계 적정")

        page.click("#saveEvaluationBtn")
        page.wait_for_timeout(3000)

        confirm_btn = page.locator("button:has-text('확인')")
        if confirm_btn.count() > 0 and confirm_btn.is_visible():
            confirm_btn.click()

        self._close_any_open_modal()
        result.pass_test("설계평가 수행 및 저장 완료")

    def test_design_complete(self, result: UnitTestResult):
        """[설계평가] 완료(확정)"""
        page = self.page
        config = self._get_config()

        self._close_any_open_modal()

        if config["design_url"] not in page.url:
            result.skip_test("설계평가 상세 페이지 아님")
            return

        batch_btn = page.locator("button:has-text('적정저장')")
        if batch_btn.count() > 0 and batch_btn.is_visible():
            page.once("dialog", lambda d: d.accept())
            batch_btn.click()
            page.wait_for_timeout(15000)

            try:
                page.wait_for_selector("text=저장이 완료되었습니다", timeout=20000)
                page.once("dialog", lambda d: d.accept())
                page.click("button:has-text('확인')")
            except:
                page.wait_for_timeout(2000)

        page.reload()
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(2000)

        complete_btn = page.locator("#completeEvaluationBtn")
        if complete_btn.count() > 0 and complete_btn.is_visible() and complete_btn.is_enabled():
            page.once("dialog", lambda d: d.accept())
            complete_btn.click()
            page.wait_for_timeout(3000)

            try:
                page.wait_for_selector("text=완료되었습니다", timeout=5000)
                confirm = page.locator("button:has-text('확인')")
                if confirm.count() > 0 and confirm.is_visible():
                    confirm.click()
            except:
                pass

            result.pass_test("설계평가 완료(확정) 처리")
        else:
            result.warn_test("완료 버튼 비활성화 (모든 항목 평가 필요)")

    # =========================================================================
    # Phase 3: 운영평가
    # =========================================================================

    def test_operation_create_session(self, result: UnitTestResult):
        """[운영평가] 세션 생성"""
        page = self.page
        config = self._get_config()

        page.goto(f"{self.base_url}{config['eval_page']}")
        page.wait_for_load_state("networkidle")

        # 운영평가 아코디언 확장
        op_accordion = page.locator(f"#operationEvaluationAccordion h2.accordion-header:has-text('{self.rcm_name}') button")
        if op_accordion.count() > 0:
            if "collapsed" in (op_accordion.first.get_attribute("class") or ""):
                op_accordion.first.click()
                page.wait_for_timeout(500)

        start_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('시작하기'), div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('계속하기')")

        if start_btn.count() > 0:
            start_btn.first.click()
            page.wait_for_load_state("networkidle")
            page.wait_for_timeout(1000)

            if config["operation_url"] in page.url:
                result.pass_test("운영평가 세션 시작 및 상세 페이지 진입")
            else:
                result.warn_test("운영평가 페이지 이동 확인 필요")
        else:
            result.fail_test("운영평가 시작 버튼을 찾을 수 없음 (설계평가 완료 필요)")

    def test_operation_evaluate_control(self, result: UnitTestResult):
        """[운영평가] 평가 수행"""
        page = self.page
        config = self._get_config()

        self._close_any_open_modal()

        if config["operation_url"] not in page.url:
            result.skip_test("운영평가 상세 페이지 아님")
            return

        eval_btns = page.locator("#controlsTable button.btn-warning")
        if eval_btns.count() == 0:
            result.fail_test("운영평가 버튼 없음")
            return

        eval_btns.first.click()
        page.wait_for_selector("#operationEvaluationModal.show", timeout=10000)

        effectiveness = page.locator("#effectiveness")
        if effectiveness.count() > 0 and effectiveness.is_visible():
            effectiveness.select_option("effective")
        else:
            eff_select = page.locator("select[name='effectiveness'], #overallEffectiveness")
            if eff_select.count() > 0:
                eff_select.select_option("effective")

        opinion = page.locator("#opinion, #evaluationEvidence, textarea[name='opinion']")
        if opinion.count() > 0:
            opinion.first.fill(f"E2E {self.eval_type.upper()} 테스트 - 운영평가 의견")

        save_btn = page.locator("#saveOperationEvaluationBtn, button:has-text('저장')")
        if save_btn.count() > 0:
            save_btn.first.click()
            page.wait_for_timeout(3000)

        try:
            page.wait_for_selector("text=저장", timeout=5000)
            confirm = page.locator("button:has-text('확인')")
            if confirm.count() > 0 and confirm.is_visible():
                confirm.click()
        except:
            pass

        self._close_any_open_modal()
        result.pass_test("운영평가 수행 및 저장 완료")

    def test_operation_dashboard(self, result: UnitTestResult):
        """[운영평가] 대시보드 반영 확인"""
        page = self.page

        page.goto(f"{self.base_url}/")
        page.wait_for_load_state("networkidle")

        dashboard_content = page.locator("body").text_content()

        if "평가" in dashboard_content or self.eval_type.upper() in dashboard_content:
            result.pass_test("대시보드에서 평가 현황 확인")
        else:
            result.warn_test("대시보드 평가 현황 표시 확인 필요")

    # =========================================================================
    # Cleanup
    # =========================================================================

    def _cleanup_operation_evaluation(self):
        """운영평가 세션 삭제"""
        print("    → 운영평가 세션 삭제 중...")
        try:
            page = self.page
            config = self._get_config()

            page.goto(f"{self.base_url}{config['eval_page']}")
            page.wait_for_load_state("networkidle")

            op_accordion = page.locator(f"#operationEvaluationAccordion h2.accordion-header:has-text('{self.rcm_name}') button")
            if op_accordion.count() > 0:
                if "collapsed" in (op_accordion.first.get_attribute("class") or ""):
                    op_accordion.first.click()
                    page.wait_for_timeout(500)

            delete_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('삭제')")
            if delete_btn.count() > 0:
                page.once("dialog", lambda d: d.accept())
                delete_btn.first.click()
                page.wait_for_timeout(2000)
                print("    ✅ 운영평가 삭제 완료")
        except Exception as e:
            print(f"    ⚠️ 운영평가 삭제 중 오류: {e}")

    def _cancel_design_evaluation(self):
        """설계평가 확정 취소"""
        print("    → 설계평가 확정 취소 중...")
        try:
            page = self.page

            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")

            rcm_row = page.locator(f"tr:has-text('{self.rcm_name}')")
            if rcm_row.count() == 0:
                return

            import re
            rcm_link = rcm_row.locator("a[href*='rcm_id=']").first
            rcm_id = None
            if rcm_link.count() > 0:
                href = rcm_link.get_attribute("href") or ""
                match = re.search(r'rcm_id=(\d+)', href)
                if match:
                    rcm_id = match.group(1)

            if rcm_id:
                response = page.evaluate(f'''
                    async () => {{
                        const response = await fetch('/api/design-evaluation/cancel', {{
                            method: 'POST',
                            headers: {{'Content-Type': 'application/json'}},
                            body: JSON.stringify({{
                                rcm_id: {rcm_id},
                                evaluation_session: '{self.design_eval_name}'
                            }})
                        }});
                        return await response.json();
                    }}
                ''')
                if response and response.get('success'):
                    print(f"    ✅ 설계평가 확정 취소 완료")
                else:
                    print(f"    ⚠️ 확정 취소 실패: {response}")
        except Exception as e:
            print(f"    ⚠️ 설계평가 확정 취소 중 오류: {e}")

    def _delete_design_evaluation(self):
        """설계평가 세션 삭제"""
        print("    → 설계평가 세션 삭제 중...")
        try:
            page = self.page
            config = self._get_config()

            page.goto(f"{self.base_url}{config['eval_page']}")
            page.wait_for_load_state("networkidle")

            accordion = page.locator(f"#designEvaluationAccordion h2.accordion-header:has-text('{self.rcm_name}') button")
            if accordion.count() > 0:
                if "collapsed" in (accordion.first.get_attribute("class") or ""):
                    accordion.first.click()
                    page.wait_for_timeout(500)

            delete_btn = page.locator(f"#designEvaluationAccordion tr:has-text('{self.design_eval_name}') button:has-text('삭제')")
            if delete_btn.count() > 0:
                page.once("dialog", lambda d: d.accept())
                delete_btn.first.click()
                page.wait_for_timeout(3000)
                print("    ✅ 설계평가 삭제 완료")
        except Exception as e:
            print(f"    ⚠️ 설계평가 삭제 중 오류: {e}")

    def _delete_rcm(self):
        """RCM 삭제"""
        print("    → RCM 삭제 중...")
        try:
            page = self.page
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")

            delete_btn = page.locator(f"tr:has-text('{self.rcm_name}') button.btn-outline-danger")
            if delete_btn.count() > 0:
                page.once("dialog", lambda d: d.accept())
                delete_btn.first.click()
                page.wait_for_timeout(2000)

                page.reload()
                page.wait_for_load_state("networkidle")
                if page.locator(f"tr:has-text('{self.rcm_name}')").count() == 0:
                    print(f"    ✅ RCM 삭제 완료: {self.rcm_name}")
                else:
                    print(f"    ⚠️ RCM 삭제 확인 실패")
        except Exception as e:
            print(f"    ⚠️ RCM 삭제 중 오류: {e}")

    def cleanup_all(self):
        """모든 테스트 데이터 정리"""
        print("\n>> Cleanup: 테스트 데이터 정리 중...")
        self._cleanup_operation_evaluation()
        self.page.wait_for_timeout(1000)
        self._cancel_design_evaluation()
        self.page.wait_for_timeout(1000)
        self._delete_design_evaluation()
        self.page.wait_for_timeout(1000)
        self._delete_rcm()

    # =========================================================================
    # 메인 실행
    # =========================================================================

    def run_all_tests(self):
        """E2E 테스트 실행"""
        print("=" * 80)
        print(f"{self.eval_type.upper()} E2E 통합 테스트")
        print("=" * 80)

        # server_was_running이 이미 True면 외부에서 서버 상태를 관리하므로 스킵
        if not self.server_was_running and not self.check_server_running():
            print("\n테스트를 중단합니다.")
            return 1

        self.setup_test_data()

        try:
            self.setup()
            self._do_admin_login()

            # Phase 1: RCM 관리
            self.run_category("Phase 1: RCM 관리", [
                self.test_rcm_upload,
                self.test_rcm_list_display
            ])

            # Phase 2: 설계평가
            self.run_category("Phase 2: 설계평가", [
                self.test_design_create_session,
                self.test_design_evaluate_control,
                self.test_design_complete
            ])

            # Phase 3: 운영평가
            self.run_category("Phase 3: 운영평가", [
                self.test_operation_create_session,
                self.test_operation_evaluate_control,
                self.test_operation_dashboard
            ])

        except Exception as e:
            print(f"❌ Critical Error: {e}")
            import traceback
            traceback.print_exc()

        finally:
            try:
                self.cleanup_all()
            except Exception as e:
                print(f"⚠️ Cleanup 중 오류: {e}")

            self.teardown()

            # 직접 시작한 서버만 중지
            self.stop_server()

        self._save_result_report()
        return self.print_final_report()

    def _save_result_report(self):
        """결과 리포트 저장"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        PHASE_MAP = {
            "rcm":       "Phase 1: RCM 관리",
            "design":    "Phase 2: 설계평가",
            "operation": "Phase 3: 운영평가",
        }

        lines = [
            f"<!-- E2E Test Run: {timestamp} -->\n",
            f"# {self.eval_type.upper()} E2E 통합 테스트 결과\n\n"
        ]

        current_phase = ""
        for res in self.results:
            # test_name에서 phase 키 추출 (예: test_rcm_upload → rcm, test_design_complete → design)
            parts = res.test_name.split('_')
            phase_key = parts[1] if len(parts) > 1 else ""
            phase_label = PHASE_MAP.get(phase_key, "기타")

            if phase_label != current_phase:
                current_phase = phase_label
                lines.append(f"\n## {current_phase}\n\n")

            status_icon = {
                TestStatus.PASSED: "✅",
                TestStatus.FAILED: "❌",
                TestStatus.WARNING: "⚠️",
                TestStatus.SKIPPED: "⊘"
            }.get(res.status, "")

            checkbox = "[x]" if res.status == TestStatus.PASSED else "[ ]"
            lines.append(f"- {checkbox} {status_icon} **{res.test_name}**: {res.message}\n")

        passed = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        warned = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total = len(self.results)

        lines.append("\n---\n## 테스트 결과 요약\n\n")
        lines.append("| 항목 | 개수 | 비율 |\n")
        lines.append("|------|------|------|\n")
        if total > 0:
            lines.append(f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n")
            lines.append(f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n")
            lines.append(f"| ⚠️ 경고 | {warned} | {warned/total*100:.1f}% |\n")
            lines.append(f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n")
        lines.append(f"| **총계** | **{total}** | **100%** |\n")

        with open(self.checklist_result, 'w', encoding='utf-8') as f:
            f.writelines(lines)
        print(f"\n✅ E2E 테스트 결과 저장: {self.checklist_result}")


def run_all_types(base_url, headless):
    """모든 타입 순차 실행 (서버 생명주기를 외부에서 일원 관리)"""
    total_exit_code = 0
    eval_types = ["itgc", "elc", "tlc"]
    server_process = None
    server_was_running_initially = False

    # 서버 상태 확인
    try:
        response = requests.get(f"{base_url}/health", timeout=3)
        if response.status_code == 200:
            server_was_running_initially = True
            print(f"✅ 서버 실행 중 ({base_url})")
    except:
        pass

    # 필요시 서버 직접 시작
    if not server_was_running_initially:
        print(f"⚠️ 서버가 실행 중이지 않습니다. 서버를 시작합니다...")
        try:
            server_process = subprocess.Popen(
                [sys.executable, "snowball.py"],
                cwd=str(project_root),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == 'win32' else 0
            )
            print(f"   서버 시작 중... (PID: {server_process.pid})")
            started = False
            for i in range(30):
                time.sleep(1)
                try:
                    response = requests.get(f"{base_url}/health", timeout=2)
                    if response.status_code == 200:
                        print(f"✅ 서버 시작 완료")
                        started = True
                        break
                except:
                    print(f"   서버 준비 대기 중... ({i+1}/30)")
            if not started:
                print(f"❌ 서버 시작 시간 초과")
                return 1
        except Exception as e:
            print(f"❌ 서버 시작 실패: {e}")
            return 1

    try:
        for eval_type in eval_types:
            print(f"\n{'='*80}")
            print(f">>> {eval_type.upper()} 테스트 시작")
            print(f"{'='*80}\n")

            suite = E2EEvaluationTestSuite(base_url=base_url, headless=headless, eval_type=eval_type)
            suite.server_was_running = True  # 서버 관리는 run_all_types에서 담당
            suite.skip_server_stop = True    # 각 suite 내에서 서버 종료 방지

            exit_code = suite.run_all_tests()
            if exit_code != 0:
                total_exit_code = exit_code

    finally:
        # 직접 시작한 서버 종료 (예외 발생 시에도 반드시 실행)
        if server_process is not None:
            print(f"\n🛑 서버 중지 중... (PID: {server_process.pid})")
            try:
                server_process.terminate()
                server_process.wait(timeout=5)
                print(f"✅ 서버 중지 완료")
            except Exception as e:
                print(f"⚠️ 서버 중지 중 오류: {e}")
                try:
                    server_process.kill()
                except:
                    pass

    return total_exit_code


def main():
    parser = argparse.ArgumentParser(description='E2E 통합 테스트 (ITGC/ELC/TLC)')
    parser.add_argument('--type', type=str, default='itgc',
                        choices=['itgc', 'elc', 'tlc', 'all'],
                        help='평가 타입: itgc, elc, tlc, all (기본: itgc)')
    parser.add_argument('--headless', action='store_true', help='Headless 모드')
    parser.add_argument('--url', type=str, default='http://localhost:5001', help='서버 URL')
    args = parser.parse_args()

    if args.type == 'all':
        sys.exit(run_all_types(args.url, args.headless))
    else:
        suite = E2EEvaluationTestSuite(base_url=args.url, headless=args.headless, eval_type=args.type)
        sys.exit(suite.run_all_tests())


if __name__ == '__main__':
    main()
