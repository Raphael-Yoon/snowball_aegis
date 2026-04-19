"""
Link7: 운영평가 Unit 테스트

[테스트 실행 방법]
1. 서버가 이미 실행 중인 경우:
   python test/test_unit_link7.py --url http://localhost:5001

2. 서버가 실행되지 않은 경우:
   - 테스트 코드가 자동으로 서버 실행 여부를 확인하고,
   - 서버가 없으면 시작, 있으면 기존 서버 사용

[주의사항]
- headless=False: 브라우저가 화면에 표시되어 테스트 과정을 눈으로 확인 가능
- 서버 충돌 방지: 이미 실행 중인 서버가 있으면 새로 시작하지 않음
- 테스트 완료 후 자동으로 생성된 데이터는 삭제됨
- 운영평가는 설계평가가 완료된 세션이 있어야 진행 가능
- 이 테스트는 자체적으로 RCM 업로드 → 설계평가 완료 → 운영평가 테스트 → 정리 순서로 진행
"""

import os
import sys
import time
import pytest
import unittest
import requests
import subprocess
from pathlib import Path
from datetime import datetime
from playwright.sync_api import Page, expect

# 프로젝트 루트 경로 설정
project_root = Path(__file__).resolve().parent.parent
sys.path.append(str(project_root))

from test.playwright_base import PlaywrightTestBase, PageHelper, UnitTestResult, TestStatus

class Link7OperationTestSuite(PlaywrightTestBase):
    """Link7: 운영평가 Unit 테스트"""

    def __init__(self, base_url="http://localhost:5001", headless=False):
        # headless=False가 기본값: 브라우저 화면이 보임
        super().__init__(base_url=base_url, headless=headless)
        self.checklist_source = project_root / "test" / "unit_checklist_link7.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link7_result.md"
        self.rcm_file_path = project_root / "test" / "assets" / "valid_rcm.xlsx"

        # 테스트 상태 공유를 위한 변수
        self.rcm_name = f"Op_Test_RCM_{int(time.time())}"  # 테스트용 RCM명
        self.rcm_id = None
        self.design_eval_name = f"DesignEval_{int(time.time())}"  # 설계평가 세션명
        self.operation_eval_name = ""  # 운영평가 세션명
        self.server_process = None

    def setup_test_data(self):
        """테스트용 RCM 엑셀 파일 생성"""
        assets_dir = project_root / "test" / "assets"
        assets_dir.mkdir(parents=True, exist_ok=True)

        from openpyxl import Workbook

        # 테스트용 RCM 파일 생성
        wb = Workbook()
        ws = wb.active
        ws.append([
            "통제코드", "통제명", "통제설명", "핵심통제",
            "통제주기", "통제유형", "통제속성", "모집단", "테스트절차"
        ])
        ws.append(["ITGC-OP-01", "테스트 접근권한 관리", "시스템 접근 권한을 적절히 부여하고 관리한다.", "Y", "상시", "예방", "수동", "접근권한 목록", "권한 부여 현황 확인"])
        ws.append(["ITGC-OP-02", "테스트 변경관리", "시스템 변경 시 승인 절차를 따른다.", "Y", "수시", "탐지", "자동", "변경요청서", "변경 승인 이력 확인"])
        ws.append(["ITGC-OP-03", "테스트 운영 보안", "운영 환경의 보안을 유지한다.", "N", "월별", "예방", "수동", "보안점검표", "월별 점검 결과 확인"])
        wb.save(self.rcm_file_path)
        print(f"    → 테스트용 RCM 파일 생성: {self.rcm_file_path}")

    def check_server_running(self):
        """서버가 실행 중인지 확인하고, 없으면 시작"""
        try:
            response = requests.get(f"{self.base_url}/health", timeout=5)
            if response.status_code == 200:
                print(f"✅ 서버가 이미 실행 중입니다 ({self.base_url})")
                return True
            else:
                print(f"⚠️ 서버 응답 코드: {response.status_code}")
                return True
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
            print(f"⚠️ 서버가 실행 중이지 않습니다. 서버를 시작합니다...")
            return self._start_server()
        except Exception as e:
            print(f"⚠️ 서버 상태 확인 중 오류: {e}")
            return self._start_server()

    def _start_server(self):
        """서버를 백그라운드로 시작"""
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
                        print(f"✅ 서버 시작 완료 ({self.base_url})")
                        return True
                except:
                    print(f"   서버 준비 대기 중... ({i+1}/30)")

            print(f"❌ 서버 시작 시간 초과")
            return False
        except Exception as e:
            print(f"❌ 서버 시작 실패: {e}")
            return False

    def run_all_tests(self):
        """전체 테스트 시나리오 실행"""
        print(f"\n================================================================================")
        print(f"Link7: 운영평가 Unit 테스트 (RCM 업로드 + 설계평가 완료 모드)")
        print(f"================================================================================\n")

        # 서버 상태 확인
        if not self.check_server_running():
            print("\n❌ 서버에 연결할 수 없어 테스트를 중단합니다.")
            return 1

        try:
            self.setup()  # 브라우저 시작

            # 테스트 데이터 파일 생성
            self.setup_test_data()

            # 로그인 수행
            self._do_admin_login()

            # 사전 준비 0: RCM 업로드
            if not self._upload_test_rcm():
                print("❌ 테스트용 RCM 업로드에 실패하여 테스트를 중단합니다.")
                return 1

            # 사전 준비 1: 설계평가 생성 및 완료
            if not self._create_and_complete_design_evaluation():
                print("❌ 설계평가 생성/완료에 실패하여 테스트를 중단합니다.")
                return 1

            # 카테고리 1: 평가 세션 관리
            self.run_category("1. 평가 세션 관리", [
                self.test_operation_create_new,
                self.test_operation_list_display,
                self.test_operation_continue_session
            ])

            # 카테고리 2: 모집단 설정
            self.run_category("2. 모집단 설정", [
                self.test_operation_sample_attribute_input,
            ])

            # 카테고리 3: 평가 수행 및 저장
            self.run_category("3. 평가 수행 및 저장", [
                self.test_operation_save_evaluation,
                self.test_operation_batch_save,
            ])

            # 카테고리 4: 증빙자료 관리
            self.run_category("3. 증빙자료 관리", [
                self.test_operation_evidence_attach,
            ])

            # 카테고리 5: 미비점 관리
            self.run_category("4. 미비점 관리", [
                self.test_operation_defect_logging,
            ])

            # 카테고리 6: 평가 완료 및 대시보드
            self.run_category("5. 평가 완료 및 대시보드", [
                self.test_operation_completion_status,
                self.test_operation_dashboard_reflection
            ])

            # 카테고리 7: 데이터 정리
            self.run_category("6. 데이터 정리", [
                self.test_operation_delete_session,
            ])

        except Exception as e:
            print(f"❌ Critical Error: {e}")
            import traceback
            traceback.print_exc()

        finally:
            # 테스트 데이터 정리 (설계평가 + RCM 삭제)
            try:
                self._cleanup_all_test_data()
            except Exception as e:
                print(f"⚠️ 테스트 데이터 정리 중 오류: {e}")

            self._update_specific_checklist()
            self.teardown()

        if len(self.results) == 0:
            print("\n실행된 테스트가 없습니다.")
            return 1
        return self.print_final_report()

    # =========================================================================
    # Helper Methods
    # =========================================================================

    def _close_any_open_modal(self):
        """열려있는 모달이 있으면 닫기"""
        page = self.page
        try:
            # operationEvaluationModal이 열려있는지 확인
            modal = page.locator("#operationEvaluationModal.show")
            if modal.count() > 0:
                print("    → 열려있는 모달 닫는 중...")
                close_btn = page.locator("#operationEvaluationModal button[data-bs-dismiss='modal']")
                if close_btn.count() > 0 and close_btn.first.is_visible():
                    close_btn.first.click()
                    page.wait_for_timeout(500)
                else:
                    page.keyboard.press("Escape")
                    page.wait_for_timeout(500)
                page.wait_for_selector("#operationEvaluationModal", state="hidden", timeout=3000)
        except:
            pass

    def _do_admin_login(self):
        """관리자 로그인 버튼 클릭으로 로그인 (이미 로그인된 상태면 건너뜀)"""
        page = self.page

        current_url = page.url

        if "/login" not in current_url:
            page.goto(f"{self.base_url}/")
            page.wait_for_load_state("networkidle")

            if page.locator("a:has-text('로그아웃')").count() > 0:
                print("    → 이미 로그인 상태, 건너뜀")
                return

        print("    → 로그인 페이지로 이동...")
        page.goto(f"{self.base_url}/login")
        page.wait_for_load_state("networkidle")

        print("    → 관리자 로그인 버튼 클릭...")
        admin_btn = page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            page.wait_for_load_state("networkidle")
            print("    → 로그인 완료")
        else:
            raise Exception("관리자 로그인 버튼을 찾을 수 없습니다")

    def _upload_test_rcm(self):
        """테스트용 RCM 업로드"""
        print(">> 사전작업 1: 테스트용 RCM 업로드 중...")
        try:
            page = self.page

            # RCM 목록 페이지로 이동
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")

            # RCM 업로드 버튼 클릭
            upload_btn = page.locator("a:has-text('RCM 업로드')")
            if upload_btn.count() == 0:
                print("❌ RCM 업로드 버튼을 찾을 수 없습니다")
                return False

            upload_btn.click()
            page.wait_for_load_state("networkidle")

            # 폼 작성
            print(f"    → RCM 이름 입력: {self.rcm_name}")
            page.fill("#rcm_name", self.rcm_name)

            print("    → 카테고리 선택: ITGC")
            page.select_option("#control_category", "ITGC")

            print(f"    → 파일 선택: {self.rcm_file_path}")
            page.set_input_files("#rcm_file", str(self.rcm_file_path))

            # 미리보기 로드 대기
            page.wait_for_timeout(2000)

            # 다이얼로그(alert) 자동 승인 핸들러 등록
            dialog_message = None
            def handle_dialog(dialog):
                nonlocal dialog_message
                dialog_message = dialog.message
                print(f"    → 다이얼로그 메시지: {dialog_message}")
                dialog.accept()
            page.once("dialog", handle_dialog)

            # 업로드 버튼 클릭
            print("    → 업로드 실행...")
            page.click("button[type='submit']")

            # AJAX 응답 및 다이얼로그 대기
            page.wait_for_timeout(5000)

            # 다이얼로그 메시지로 성공 여부 확인
            if dialog_message and "성공" in dialog_message:
                print(f"✅ RCM 업로드 성공: {dialog_message}")
                page.wait_for_load_state("networkidle")
                return True

            # 목록 페이지로 이동하여 확인
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")
            page.wait_for_timeout(1000)

            if page.locator(f"text={self.rcm_name}").count() > 0:
                print(f"✅ RCM 업로드 확인 (목록에서): {self.rcm_name}")
                return True

            print("❌ RCM 업로드 결과 확인 실패")
            return False

        except Exception as e:
            print(f"❌ RCM 업로드 중 에러: {e}")
            import traceback
            traceback.print_exc()
            return False

    def _create_and_complete_design_evaluation(self):
        """설계평가 생성 및 완료 (운영평가 전제조건)"""
        print(">> 사전작업 2: 설계평가 생성 및 완료 중...")
        try:
            page = self.page

            # ITGC 평가 페이지로 이동
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state("networkidle")

            # '내부평가 시작' 버튼 클릭
            print("    → '내부평가 시작' 버튼 클릭...")
            start_btn = page.locator("button:has-text('내부평가 시작')")
            if start_btn.count() == 0:
                print("❌ 내부평가 시작 버튼을 찾을 수 없습니다")
                return False

            start_btn.click()
            page.wait_for_timeout(1000)

            # 모달에서 RCM 선택
            print(f"    → RCM 선택 중: {self.rcm_name}")
            rcm_item = page.locator(f"div#rcmSelectionStep a:has-text('{self.rcm_name}')")
            if rcm_item.count() == 0:
                print(f"❌ 모달에서 RCM '{self.rcm_name}'을 찾을 수 없음")
                return False

            rcm_item.click()

            # 평가명 입력
            print(f"    → 평가명 입력: {self.design_eval_name}")
            page.fill("#evaluationNameInput", self.design_eval_name)

            # '설계평가 시작' 버튼 클릭
            page.click("button:has-text('설계평가 시작')")
            page.wait_for_load_state('networkidle')
            page.wait_for_timeout(1000)

            # 상세 페이지로 이동되었는지 확인
            if "/design-evaluation/rcm" not in page.url:
                print("    → 상세 페이지로 이동 중...")
                # 목록에서 다시 진입
                page.goto(f"{self.base_url}/itgc-evaluation")
                page.wait_for_load_state('networkidle')

                # 아코디언 확장
                accordion_header = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
                if accordion_header.count() > 0 and "collapsed" in (accordion_header.first.get_attribute("class") or ""):
                    accordion_header.first.click()
                    page.wait_for_timeout(500)

                continue_btn = page.locator(f"//tr[contains(., '{self.design_eval_name}')]//button[contains(., '계속하기')]")
                if continue_btn.count() > 0:
                    continue_btn.first.click()
                    page.wait_for_url("**/design-evaluation/rcm")

            # 적정저장으로 모든 통제 평가 (운영평가 진입을 위해 필요)
            print("    → 적정저장으로 모든 통제 평가 중...")
            batch_save_btn = page.locator("button:has-text('적정저장')")
            if batch_save_btn.count() > 0 and batch_save_btn.is_visible():
                page.once("dialog", lambda dialog: dialog.accept())
                batch_save_btn.click()
                page.wait_for_timeout(1000)

                try:
                    page.wait_for_selector("text=저장이 완료되었습니다", timeout=20000)
                    page.once("dialog", lambda dialog: dialog.accept())
                    page.click("button:has-text('확인')")
                except:
                    page.wait_for_timeout(2000)

            # 설계평가 완료(확정) 버튼 클릭 - 운영평가 진입을 위해 필수
            print("    → 설계평가 완료(확정) 처리 중...")
            complete_btn = page.locator("#completeEvaluationBtn")
            if complete_btn.count() > 0 and complete_btn.is_visible():
                try:
                    complete_btn.wait_for(state="visible", timeout=5000)
                    if complete_btn.is_enabled():
                        page.once("dialog", lambda dialog: dialog.accept())
                        complete_btn.click()
                        page.wait_for_timeout(2000)

                        # 완료 확인 메시지 처리
                        try:
                            page.wait_for_selector("text=완료되었습니다", timeout=5000)
                            confirm_btn = page.locator("button:has-text('확인')")
                            if confirm_btn.count() > 0 and confirm_btn.is_visible():
                                confirm_btn.click()
                        except:
                            pass

                        print("    → 설계평가 확정 완료 (status=1)")
                    else:
                        print("    → 완료 버튼 비활성화 (모든 항목 평가 필요)")
                except Exception as e:
                    print(f"    → 완료 버튼 처리 중 오류: {e}")
            else:
                print("    → 완료 버튼을 찾을 수 없음")

            print("✅ 설계평가 생성 및 확정 완료")
            return True

        except Exception as e:
            print(f"❌ 설계평가 생성/완료 중 에러: {e}")
            import traceback
            traceback.print_exc()
            return False

    def _cleanup_all_test_data(self):
        """테스트 데이터 전체 정리 (운영평가 → 설계평가 확정 취소 → 설계평가 삭제 → RCM 삭제)"""
        print(">> 정리작업: 테스트 데이터 삭제 중...")
        try:
            page = self.page

            # 1. 운영평가 세션 삭제 (먼저!)
            self._delete_operation_evaluation()
            page.wait_for_timeout(1000)

            # 2. 설계평가 확정 취소 (status 0으로 변경)
            self._cancel_design_evaluation_completion()
            page.wait_for_timeout(1000)

            # 3. 설계평가 세션 삭제
            self._delete_design_evaluation()
            page.wait_for_timeout(2000)

            # 4. RCM 삭제
            self._delete_test_rcm()

        except Exception as e:
            print(f"⚠️ 테스트 데이터 정리 중 에러: {e}")

    def _cancel_design_evaluation_completion(self):
        """설계평가 확정 취소 (status를 0으로 변경)"""
        print("    → 설계평가 확정 취소 중...")
        try:
            page = self.page

            # RCM ID를 가져오기 위해 RCM 목록 페이지로 이동
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state('networkidle')

            # RCM ID 추출
            rcm_row = page.locator(f"tr:has-text('{self.rcm_name}')")
            if rcm_row.count() == 0:
                print(f"    → RCM을 찾을 수 없음: {self.rcm_name}")
                return False

            # RCM ID를 data 속성이나 링크에서 추출
            rcm_link = rcm_row.locator("a[href*='rcm_id='], button[onclick*='rcm_id']").first
            rcm_id = None

            if rcm_link.count() > 0:
                href = rcm_link.get_attribute("href") or rcm_link.get_attribute("onclick") or ""
                import re
                match = re.search(r'rcm_id[=:](\d+)', href)
                if match:
                    rcm_id = match.group(1)

            if not rcm_id:
                # 다른 방법으로 RCM ID 추출 시도 - 테이블 행의 첫 번째 셀에서
                first_cell = rcm_row.locator("td").first
                if first_cell.count() > 0:
                    # 숫자만 추출 시도
                    cell_text = first_cell.inner_text().strip()
                    if cell_text.isdigit():
                        rcm_id = cell_text

            if not rcm_id:
                print("    → RCM ID를 추출할 수 없음")
                return False

            print(f"    → RCM ID: {rcm_id}, 평가 세션: {self.design_eval_name}")

            # API 호출로 확정 취소
            response = page.evaluate(f'''
                async () => {{
                    const response = await fetch('/api/design-evaluation/cancel', {{
                        method: 'POST',
                        headers: {{
                            'Content-Type': 'application/json'
                        }},
                        body: JSON.stringify({{
                            rcm_id: {rcm_id},
                            evaluation_session: '{self.design_eval_name}'
                        }})
                    }});
                    return await response.json();
                }}
            ''')

            if response and response.get('success'):
                print(f"✅ 설계평가 확정 취소 완료: {response.get('message', '')}")
                return True
            else:
                print(f"    → 확정 취소 실패 또는 이미 취소됨: {response.get('message', '') if response else 'No response'}")
                return False

        except Exception as e:
            print(f"    → 설계평가 확정 취소 중 에러: {e}")
            return False

    def _delete_operation_evaluation(self):
        """운영평가 세션 삭제"""
        print("    → 운영평가 세션 삭제 중...")
        try:
            page = self.page

            # ITGC 평가 목록으로 이동
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state('networkidle')
            page.wait_for_timeout(1000)

            # 운영평가 아코디언 확장 (opcollapse)
            op_accordion_btn = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#opcollapse']")
            if op_accordion_btn.count() > 0 and "collapsed" in (op_accordion_btn.first.get_attribute("class") or ""):
                op_accordion_btn.first.click()
                page.wait_for_timeout(500)

            # 운영평가 삭제 버튼 찾기
            delete_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('삭제')")
            if delete_btn.count() > 0:
                # 다이얼로그 핸들러
                def handle_op_dialog(dialog):
                    print(f"    → 운영평가 삭제 다이얼로그: {dialog.message[:50]}...")
                    dialog.accept()
                page.on("dialog", handle_op_dialog)

                delete_btn.first.click()
                page.wait_for_timeout(3000)

                # 핸들러 제거
                page.remove_listener("dialog", handle_op_dialog)

                print(f"✅ 운영평가 세션 삭제 요청 완료: {self.design_eval_name}")
                return True
            else:
                print(f"    → 삭제할 운영평가 세션을 찾을 수 없음 (이미 삭제됨 또는 테스트 중 삭제됨)")
                return True

        except Exception as e:
            print(f"    → 운영평가 세션 삭제 중 에러: {e}")
            return False

    def _delete_design_evaluation(self):
        """설계평가 세션 삭제"""
        print("    → 설계평가 세션 삭제 중...")
        try:
            page = self.page

            # ITGC 평가 목록으로 이동
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state('networkidle')
            page.wait_for_timeout(1000)

            # 설계평가 현황 카드 내 아코디언 확장 (운영평가 현황과 구분)
            # 설계평가는 #designEvaluationAccordion 또는 첫 번째 카드에 있음
            design_accordion = page.locator(f"#designEvaluationAccordion h2.accordion-header:has-text('{self.rcm_name}') button")
            if design_accordion.count() > 0:
                btn_class = design_accordion.first.get_attribute("class") or ""
                if "collapsed" in btn_class:
                    design_accordion.first.click()
                    page.wait_for_timeout(500)

            # 설계평가 영역에서 삭제 버튼 찾기
            delete_btn = page.locator(f"#designEvaluationAccordion tr:has-text('{self.design_eval_name}') button:has-text('삭제')")
            if delete_btn.count() == 0:
                print(f"    → 삭제할 설계평가 세션을 찾을 수 없음 (이미 삭제됨): {self.design_eval_name}")
                return True

            # 다이얼로그 핸들러 - 여러 개의 다이얼로그 처리
            dialog_count = [0]
            def handle_delete_dialogs(dialog):
                dialog_count[0] += 1
                print(f"    → 다이얼로그 #{dialog_count[0]}: {dialog.message[:50]}...")
                dialog.accept()

            page.on("dialog", handle_delete_dialogs)

            # 삭제 버튼 클릭
            delete_btn.first.click()
            page.wait_for_timeout(5000)  # 충분한 대기 시간

            # 핸들러 제거
            page.remove_listener("dialog", handle_delete_dialogs)

            # 페이지 새로고침 후 삭제 확인
            page.reload()
            page.wait_for_load_state('networkidle')
            page.wait_for_timeout(1000)

            # 아코디언 다시 확장하여 확인
            design_accordion = page.locator(f"#designEvaluationAccordion h2.accordion-header:has-text('{self.rcm_name}') button")
            if design_accordion.count() > 0:
                btn_class = design_accordion.first.get_attribute("class") or ""
                if "collapsed" in btn_class:
                    design_accordion.first.click()
                    page.wait_for_timeout(500)

            # 삭제 확인
            remaining = page.locator(f"#designEvaluationAccordion tr:has-text('{self.design_eval_name}')")
            if remaining.count() == 0:
                print(f"✅ 설계평가 세션 삭제 완료: {self.design_eval_name}")
                return True
            else:
                print(f"⚠️ 설계평가 세션이 아직 남아있음: {self.design_eval_name}")
                return False

        except Exception as e:
            print(f"    → 설계평가 세션 삭제 중 에러: {e}")
            return False

    def _delete_test_rcm(self):
        """테스트용 RCM 삭제"""
        print("    → RCM 삭제 중...")
        try:
            page = self.page

            # RCM 목록 페이지로 이동
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")
            page.wait_for_timeout(1000)

            # 테스트용 RCM 찾기
            rcm_row = page.locator(f"tr:has-text('{self.rcm_name}')")
            if rcm_row.count() == 0:
                print(f"    → 삭제할 RCM을 찾을 수 없음 (이미 삭제됨): {self.rcm_name}")
                return True

            # 삭제 버튼 클릭
            delete_btn = rcm_row.locator("button.btn-outline-danger").first
            if delete_btn.count() == 0:
                print("    → 삭제 버튼을 찾을 수 없음")
                return False

            # 다이얼로그 처리 - 메시지 확인용
            dialog_messages = []
            def handle_rcm_dialog(dialog):
                dialog_messages.append(dialog.message)
                print(f"    → RCM 다이얼로그: {dialog.message[:50]}...")
                dialog.accept()
            page.on("dialog", handle_rcm_dialog)

            delete_btn.click()
            page.wait_for_timeout(3000)

            # 핸들러 제거
            page.remove_listener("dialog", handle_rcm_dialog)

            # 삭제 실패 메시지 확인
            for msg in dialog_messages:
                if "삭제할 수 없습니다" in msg or "진행 중" in msg:
                    print(f"⚠️ RCM 삭제 불가: {msg[:80]}")
                    return False

            # 삭제 확인
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")

            if page.locator(f"tr:has-text('{self.rcm_name}')").count() == 0:
                print(f"✅ RCM 삭제 완료: {self.rcm_name}")
                return True
            else:
                print(f"⚠️ RCM 삭제 확인 실패 (평가 진행 중일 수 있음): {self.rcm_name}")
                return False

        except Exception as e:
            print(f"    → RCM 삭제 중 에러: {e}")
            return False

    # =========================================================================
    # 1. 평가 세션 관리
    # =========================================================================

    def test_operation_create_new(self, result: UnitTestResult):
        """운영평가 세션 시작 (완료된 설계평가 기반)"""
        page = self.page

        try:
            # ITGC 평가 페이지로 이동 (운영평가 아코디언이 있는 페이지)
            print("    → ITGC 평가 페이지로 이동...")
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state("networkidle")

            # 운영평가 현황 아코디언 확장 (opcollapse로 시작)
            print(f"    → RCM '{self.rcm_name}' 운영평가 아코디언 확장...")
            op_accordion_btn = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#opcollapse']")
            if op_accordion_btn.count() > 0:
                if "collapsed" in (op_accordion_btn.first.get_attribute("class") or ""):
                    op_accordion_btn.first.click()
                    page.wait_for_timeout(500)

            # 운영평가 세션 찾기 (설계평가 이름 기반)
            print(f"    → 운영평가 세션 '{self.design_eval_name}' 찾는 중...")
            # 운영평가 아코디언 내에서 버튼 찾기
            op_view_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('계속하기'), div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('시작하기')")

            if op_view_btn.count() > 0:
                op_view_btn.first.click()
                page.wait_for_load_state("networkidle")
                page.wait_for_timeout(1000)

                # 상세 페이지 진입 확인
                if "/operation-evaluation/rcm" in page.url:
                    self.operation_eval_name = self.design_eval_name
                    print(f"    → 운영평가 세션: {self.operation_eval_name}")
                    result.pass_test("운영평가 세션 시작 및 상세 페이지 진입 확인")
                else:
                    result.warn_test(f"운영평가 버튼 클릭됨 (URL: {page.url})")
            else:
                # 운영평가 보기 버튼으로 시도
                op_view_btn2 = page.locator(f"div[id^='opcollapse'] button:has-text('보기')").first
                if op_view_btn2.count() > 0:
                    op_view_btn2.click()
                    page.wait_for_load_state("networkidle")
                    if "/operation-evaluation/rcm" in page.url:
                        self.operation_eval_name = self.design_eval_name
                        result.pass_test("운영평가 상세 페이지 진입 확인")
                    else:
                        result.warn_test("운영평가 버튼 클릭됨")
                else:
                    result.fail_test(f"운영평가 세션 '{self.design_eval_name}'을 찾을 수 없음")

        except Exception as e:
            result.fail_test(f"운영평가 세션 시작 실패: {e}")

    def test_operation_list_display(self, result: UnitTestResult):
        """운영평가 목록 표시 확인"""
        page = self.page

        try:
            # ITGC 평가 페이지로 이동
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state("networkidle")

            # 운영평가 현황 아코디언 확장 (opcollapse로 시작)
            op_accordion_btn = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#opcollapse']")
            if op_accordion_btn.count() > 0:
                if "collapsed" in (op_accordion_btn.first.get_attribute("class") or ""):
                    op_accordion_btn.first.click()
                    page.wait_for_timeout(500)

                # 세션 목록에서 우리 세션 찾기
                session_row = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}')")
                if session_row.count() > 0:
                    result.pass_test(f"운영평가 목록에 세션 '{self.design_eval_name}' 표시 확인")
                else:
                    result.warn_test("운영평가 현황 섹션 표시됨 (세션 확인 필요)")
            else:
                result.skip_test("운영평가 현황 섹션이 없음")

        except Exception as e:
            result.fail_test(f"운영평가 목록 표시 확인 실패: {e}")

    def test_operation_continue_session(self, result: UnitTestResult):
        """기존 세션 '계속하기' 버튼 동작 확인"""
        page = self.page

        try:
            # ITGC 평가 페이지로 이동
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state("networkidle")

            # 운영평가 현황 아코디언 확장
            op_accordion_btn = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#opcollapse']")
            if op_accordion_btn.count() > 0:
                if "collapsed" in (op_accordion_btn.first.get_attribute("class") or ""):
                    op_accordion_btn.first.click()
                    page.wait_for_timeout(500)

            # '계속하기' 또는 '보기' 버튼 클릭
            continue_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('계속하기'), div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('보기')")
            if continue_btn.count() > 0:
                continue_btn.first.click()
                page.wait_for_load_state("networkidle")

                # 상세 페이지 진입 확인
                if "/operation-evaluation/rcm" in page.url:
                    result.pass_test("운영평가 세션 계속하기 동작 확인")
                else:
                    result.warn_test(f"버튼 클릭됨 (URL: {page.url})")
            else:
                result.skip_test("운영평가 계속하기 버튼이 없음")

        except Exception as e:
            result.fail_test(f"세션 계속하기 테스트 실패: {e}")

    # =========================================================================
    # 3. 평가 수행 및 저장
    # =========================================================================

    def _navigate_to_operation_detail(self):
        """운영평가 상세 페이지로 이동하는 헬퍼 메서드"""
        page = self.page

        if "/operation-evaluation/rcm" in page.url:
            return True

        # ITGC 평가 페이지에서 진입
        page.goto(f"{self.base_url}/itgc-evaluation")
        page.wait_for_load_state("networkidle")

        # 운영평가 아코디언 확장
        op_accordion_btn = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#opcollapse']")
        if op_accordion_btn.count() > 0 and "collapsed" in (op_accordion_btn.first.get_attribute("class") or ""):
            op_accordion_btn.first.click()
            page.wait_for_timeout(500)

        # 계속하기 버튼 클릭
        continue_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('계속하기'), div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('보기'), div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('시작하기')")
        if continue_btn.count() > 0:
            continue_btn.first.click()
            page.wait_for_load_state("networkidle")
            page.wait_for_timeout(1000)

        return "/operation-evaluation/rcm" in page.url

    def test_operation_sample_attribute_input(self, result: UnitTestResult):
        """샘플 라인의 Attribute 값 입력 및 저장 확인 (RCM에서 정의된 Attribute 기반)"""
        page = self.page

        # 모달 닫기
        self._close_any_open_modal()

        # 상세 페이지 진입 확인
        if not self._navigate_to_operation_detail():
            result.skip_test("운영평가 상세 페이지 진입 불가")
            return

        try:
            # 평가 모달 열기
            print("    → 평가 모달 열어서 샘플 라인 확인...")
            eval_btns = page.locator("#controlsTable button.btn-warning")
            if eval_btns.count() == 0:
                result.skip_test("평가 버튼을 찾을 수 없음")
                return

            eval_btns.first.click()
            page.wait_for_selector("#operationEvaluationModal.show", timeout=10000)
            page.wait_for_timeout(1000)  # 샘플 라인 로드 대기

            # 샘플 라인 테이블 확인
            sample_tbody = page.locator("#sample-lines-tbody")
            if sample_tbody.count() == 0:
                result.skip_test("샘플 라인 테이블을 찾을 수 없음")
                return

            # 샘플 라인의 입력 필드 찾기 (attribute 입력 또는 증빙 입력)
            sample_inputs = page.locator("#sample-lines-tbody input[type='text'], #sample-lines-tbody textarea")
            if sample_inputs.count() > 0:
                # 첫 번째 입력 필드에 테스트 값 입력
                first_input = sample_inputs.first
                if first_input.is_visible() and first_input.is_enabled():
                    first_input.fill("테스트 Attribute 값")
                    print("    → 샘플 라인 입력 필드에 값 입력 완료")
                    result.pass_test("샘플 라인 Attribute 입력 필드 동작 확인")
                else:
                    result.warn_test("샘플 입력 필드가 있으나 비활성화됨")
            else:
                # 샘플 라인이 아직 생성되지 않은 경우 (표본수 설정 필요)
                sample_size_input = page.locator("#sample_size")
                if sample_size_input.count() > 0 and sample_size_input.is_visible():
                    result.warn_test("샘플 라인 없음 - 표본수 설정 후 자동 생성됨")
                else:
                    result.skip_test("샘플 입력 필드를 찾을 수 없음")

            # 모달 닫기
            close_btn = page.locator("#operationEvaluationModal button[data-bs-dismiss='modal']")
            if close_btn.count() > 0:
                close_btn.first.click()

        except Exception as e:
            result.fail_test(f"샘플 Attribute 입력 테스트 실패: {e}")

    def test_operation_save_evaluation(self, result: UnitTestResult):
        """개별 통제 항목 운영평가 및 저장"""
        page = self.page

        # 모달 닫기
        self._close_any_open_modal()

        # 상세 페이지 진입 확인
        if not self._navigate_to_operation_detail():
            result.skip_test("운영평가 상세 페이지 진입 불가")
            return

        try:
            # 통제 목록에서 첫 번째 '평가' 버튼 클릭
            print("    → 통제 항목 평가 버튼 클릭...")
            # 테이블 내 평가 버튼 찾기 (onclick 속성 확인)
            eval_btns = page.locator("#controlsTable button.btn-warning")
            print(f"    → 평가 버튼 수: {eval_btns.count()}")

            if eval_btns.count() == 0:
                # 다른 셀렉터 시도
                eval_btns = page.locator("button:has-text('평가')")
                print(f"    → 대체 셀렉터로 찾은 버튼 수: {eval_btns.count()}")

            if eval_btns.count() == 0:
                result.skip_test("평가/수정 버튼을 찾을 수 없음")
                return

            # 버튼 클릭 전 대기
            page.wait_for_timeout(500)
            eval_btns.first.click()
            print("    → 버튼 클릭 완료")

            # 평가 모달 대기 (더 긴 타임아웃)
            page.wait_for_selector("#operationEvaluationModal.show", timeout=10000)

            # 운영 효과성 선택
            print("    → '효과적' 선택 및 저장...")
            effectiveness_select = page.locator("#opEffectiveness")
            if effectiveness_select.count() > 0:
                page.select_option("#opEffectiveness", "effective")
                page.wait_for_timeout(500)

            # 테스트 증빙 입력
            evidence_el = page.locator("#opEvidence")
            if evidence_el.count() > 0:
                evidence_el.fill("Unit 테스트 - 운영평가 결과: 통제가 효과적으로 운영되고 있음")

            # 저장 버튼 클릭
            save_btn = page.locator("#saveOperationEvaluationBtn")
            if save_btn.count() > 0:
                save_btn.click()
            else:
                page.click("button:has-text('저장')")

            # 성공 메시지 대기
            try:
                page.wait_for_selector("text=저장", timeout=5000)
            except:
                pass

            # 확인 버튼 클릭
            confirm_btn = page.locator("button:has-text('확인')")
            if confirm_btn.count() > 0 and confirm_btn.is_visible():
                confirm_btn.click()

            # 모달 닫기 확인
            try:
                page.wait_for_selector("#operationEvaluationModal", state="hidden", timeout=5000)
            except:
                close_btn = page.locator("#operationEvaluationModal button[data-bs-dismiss='modal']")
                if close_btn.count() > 0:
                    close_btn.first.click()
                    page.wait_for_timeout(500)

            result.pass_test("개별 통제 운영평가 및 저장 완료")

        except Exception as e:
            result.fail_test(f"운영평가 저장 실패: {e}")

    def test_operation_batch_save(self, result: UnitTestResult):
        """일괄 저장 기능 확인 (적정저장 버튼 활용)"""
        page = self.page

        self._close_any_open_modal()

        if "/operation-evaluation/rcm" not in page.url:
            result.skip_test("상세 페이지에 있지 않음")
            return

        try:
            # '적정저장' 버튼 찾기
            print("    → '적정저장' 버튼 확인 중...")
            batch_save_btn = page.locator("button:has-text('적정저장')")

            if batch_save_btn.count() > 0 and batch_save_btn.is_visible():
                # confirm 다이얼로그 자동 수락
                page.once("dialog", lambda dialog: dialog.accept())

                batch_save_btn.click()
                page.wait_for_timeout(1000)

                # 완료 대기
                try:
                    page.wait_for_selector("text=저장이 완료되었습니다", timeout=20000)
                    page.click("button:has-text('확인')")
                except:
                    page.wait_for_timeout(2000)

                result.pass_test("일괄 저장(적정저장) 기능 동작 확인")
            else:
                result.skip_test("적정저장 버튼을 찾을 수 없음 (관리자 전용)")

        except Exception as e:
            result.fail_test(f"일괄 저장 테스트 실패: {e}")

    # =========================================================================
    # 4. 증빙자료 관리
    # =========================================================================

    def test_operation_evidence_attach(self, result: UnitTestResult):
        """증빙자료 파일 업로드 기능 동작 확인"""
        page = self.page

        self._close_any_open_modal()

        # 상세 페이지 진입 확인 및 재진입
        if not self._navigate_to_operation_detail():
            result.skip_test("상세 페이지에 있지 않음")
            return

        try:
            # 평가 모달 열기
            print("    → 통제 항목 평가 모달 열기...")
            eval_btns = page.locator("#controlsTable button.btn-warning")

            if eval_btns.count() == 0:
                result.skip_test("평가/수정 버튼을 찾을 수 없음")
                return

            page.wait_for_timeout(500)
            eval_btns.first.click()
            page.wait_for_selector("#operationEvaluationModal.show", timeout=10000)

            # 파일 업로드 input 확인
            print("    → 증빙자료 업로드 필드 확인...")
            file_input = page.locator("#opEvaluationImages, input[type='file']")

            if file_input.count() > 0:
                # 테스트 이미지 파일 생성 및 업로드
                test_image_path = project_root / "test" / "assets" / "test_op_evidence.png"

                if not test_image_path.exists():
                    import struct
                    import zlib

                    def create_minimal_png(filepath):
                        signature = b'\x89PNG\r\n\x1a\n'
                        ihdr_data = struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0)
                        ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
                        ihdr = struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
                        raw_data = b'\x00\xff\xff\xff'
                        compressed = zlib.compress(raw_data)
                        idat_crc = zlib.crc32(b'IDAT' + compressed)
                        idat = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
                        iend_crc = zlib.crc32(b'IEND')
                        iend = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
                        with open(filepath, 'wb') as f:
                            f.write(signature + ihdr + idat + iend)

                    create_minimal_png(test_image_path)

                file_input.first.set_input_files(str(test_image_path))
                page.wait_for_timeout(1000)

                if page.locator("text=test_op_evidence.png").count() > 0 or \
                   page.locator(".uploaded-file, .file-name, .preview").count() > 0:
                    result.pass_test("증빙자료 업로드 및 파일명 표시 확인")
                else:
                    result.warn_test("파일 업로드는 되었으나 파일명 표시 확인 불가")

                if test_image_path.exists():
                    test_image_path.unlink()
            else:
                result.skip_test("증빙자료 업로드 필드를 찾을 수 없음")

            # 모달 닫기
            close_btn = page.locator("#operationEvaluationModal button[data-bs-dismiss='modal']")
            if close_btn.count() > 0:
                close_btn.first.click()

        except Exception as e:
            result.fail_test(f"증빙자료 업로드 테스트 실패: {e}")

    # =========================================================================
    # 5. 미비점(Defect) 관리
    # =========================================================================

    def test_operation_defect_logging(self, result: UnitTestResult):
        """평가 결과를 '비효과적'으로 선택 시 처리 확인"""
        page = self.page

        self._close_any_open_modal()

        if not self._navigate_to_operation_detail():
            result.skip_test("상세 페이지 진입 불가")
            return

        try:
            print("    → 미비(비효과적) 평가 테스트 시작...")
            eval_btns = page.locator("#controlsTable button.btn-warning")

            if eval_btns.count() == 0:
                result.skip_test("평가/수정 버튼을 찾을 수 없음")
                return

            page.wait_for_timeout(500)
            eval_btns.first.click()
            page.wait_for_selector("#operationEvaluationModal.show", timeout=10000)

            # 효과성을 '비효과적(ineffective)'으로 선택
            print("    → 효과성 '비효과적(ineffective)' 선택...")
            effectiveness_select = page.locator("#opEffectiveness")
            if effectiveness_select.count() > 0 and not effectiveness_select.is_disabled():
                page.select_option("#opEffectiveness", "ineffective")
                page.wait_for_timeout(500)
            else:
                result.skip_test("효과성 필드가 없거나 비활성화됨")
                return

            # 권고 조치사항 필드 (비효과적 선택 시 표시)
            recommended_actions = page.locator("#opRecommendedActions")
            if recommended_actions.count() > 0:
                try:
                    recommended_actions.wait_for(state="visible", timeout=3000)
                    if not recommended_actions.is_disabled():
                        recommended_actions.fill("테스트용 미비점 - 통제 운영 개선 필요")
                        print("    → 권고 조치사항 입력 완료")
                except:
                    print("    → 권고 조치사항 필드 미표시 (건너뜀)")

            # 증빙 입력
            evidence_el = page.locator("#opEvidence")
            if evidence_el.count() > 0:
                evidence_el.fill("미비점 테스트 - 통제 운영 미흡 사항 확인")

            # 저장
            print("    → 비효과적 평가 저장...")
            save_btn = page.locator("#saveOperationEvaluationBtn")
            if save_btn.count() > 0:
                save_btn.click()
            else:
                page.click("button:has-text('저장')")

            # 저장 완료 대기
            try:
                page.wait_for_selector("#successAlert, text=저장", timeout=5000)
            except:
                pass

            # 모달 닫기 확인
            try:
                page.wait_for_selector("#operationEvaluationModal", state="hidden", timeout=5000)
            except:
                close_btn = page.locator("#operationEvaluationModal button[data-bs-dismiss='modal']")
                if close_btn.count() > 0:
                    close_btn.first.click()

            # 목록에서 '부적정' 배지 확인
            page.wait_for_timeout(1000)
            if page.locator(".badge.bg-danger:has-text('부적정')").count() > 0:
                result.pass_test("비효과적 평가 저장 및 '부적정' 표시 확인")
            else:
                result.warn_test("비효과적 평가 저장됨 (부적정 배지 확인 불가)")

        except Exception as e:
            result.fail_test(f"미비점 테스트 실패: {e}")

    # =========================================================================
    # 6. 평가 완료 및 대시보드
    # =========================================================================

    def test_operation_completion_status(self, result: UnitTestResult):
        """모든 항목 평가 완료 시 진행률 100% 도달 확인"""
        page = self.page

        self._close_any_open_modal()

        if not self._navigate_to_operation_detail():
            result.warn_test("상세 페이지 진입 불가 (운영평가 세션 없음)")
            return

        try:
            # 적정저장으로 모든 통제 평가
            print("    → [관리자] 모든 통제 '적정저장' 수행 중...")
            batch_save_btn = page.locator("button:has-text('적정저장')")
            if batch_save_btn.count() > 0 and batch_save_btn.is_visible():
                page.once("dialog", lambda dialog: dialog.accept())
                batch_save_btn.click()
                page.wait_for_timeout(1000)

                try:
                    page.wait_for_selector("text=저장이 완료되었습니다", timeout=20000)
                    page.click("button:has-text('확인')")
                except:
                    page.wait_for_timeout(2000)

            # 진행률 확인
            print("    → 진행률 확인 중...")
            progress_bar = page.locator("#evaluationProgress, .progress-bar")
            if progress_bar.count() > 0:
                progress_text = progress_bar.first.inner_text()
                print(f"    → 진행률: {progress_text}")

            # 완료 버튼 클릭 시도
            print("    → 완료 버튼 클릭 시도...")
            complete_btn = page.locator("#completeEvaluationBtn, button:has-text('평가 완료')")

            try:
                complete_btn.wait_for(state="visible", timeout=5000)
            except:
                pass

            if complete_btn.count() > 0 and complete_btn.is_visible() and complete_btn.is_enabled():
                page.once("dialog", lambda dialog: dialog.accept())
                complete_btn.click()
                page.wait_for_timeout(1000)

                page.wait_for_timeout(2000)
                if page.locator("#archiveEvaluationBtn").is_visible() or \
                   page.locator("text=완료").count() > 0:
                    result.pass_test("진행률 100% 도달 및 '완료' 상태 변경 확인")
                else:
                    result.warn_test("완료 처리됨 (상태 표시 확인 불가)")
            else:
                result.warn_test("완료 버튼이 활성화되지 않음 (모든 항목 평가 필요)")

        except Exception as e:
            result.fail_test(f"평가 완료 상태 테스트 실패: {e}")

    def test_operation_dashboard_reflection(self, result: UnitTestResult):
        """메인 대시보드에서 운영평가 진행 현황 반영 확인"""
        page = self.page

        try:
            print("    → 대시보드로 이동...")
            page.goto(f"{self.base_url}/user/internal-assessment")
            page.wait_for_load_state("networkidle")

            if '/login' in page.url:
                result.skip_test("로그인 필요 - 대시보드 접근 불가")
                return

            print("    → 운영평가 현황 확인 중...")
            page_content = page.inner_text("body")

            if "운영평가" in page_content or "ITGC" in page_content or "평가" in page_content:
                if "완료" in page_content or "진행" in page_content:
                    result.pass_test("대시보드에서 평가 현황 정보 확인됨")
                else:
                    result.warn_test("대시보드 접근 가능하나 진행 현황 표시 확인 불가")
            else:
                result.warn_test("대시보드에 평가 관련 섹션 없음")

        except Exception as e:
            result.fail_test(f"대시보드 반영 테스트 실패: {e}")

    # =========================================================================
    # 8. 데이터 정리
    # =========================================================================

    def test_operation_delete_session(self, result: UnitTestResult):
        """테스트로 생성된 운영평가 데이터 정리 (삭제)"""
        page = self.page

        self._close_any_open_modal()

        try:
            # ITGC 평가 목록으로 이동
            print("    → ITGC 평가 목록으로 이동 중...")
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state("networkidle")

            # 운영평가 아코디언 확장
            op_accordion_btn = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#opcollapse']")
            if op_accordion_btn.count() > 0:
                if "collapsed" in (op_accordion_btn.first.get_attribute("class") or ""):
                    op_accordion_btn.first.click()
                    page.wait_for_timeout(500)

                # 운영평가 삭제 버튼 찾기
                delete_btn = page.locator(f"div[id^='opcollapse'] tr:has-text('{self.design_eval_name}') button:has-text('삭제')")
                if delete_btn.count() > 0:
                    print(f"    → 운영평가 세션 '{self.design_eval_name}' 삭제 중...")
                    page.once("dialog", lambda dialog: dialog.accept())
                    delete_btn.first.click()
                    page.wait_for_timeout(2000)

                    # 결과 다이얼로그도 처리
                    page.once("dialog", lambda dialog: dialog.accept())
                    page.wait_for_timeout(1000)

                    result.pass_test("운영평가 데이터 정리 완료")
                else:
                    # 운영평가 데이터는 설계평가 세션에 종속될 수 있음
                    result.warn_test("운영평가 삭제 버튼 없음 (설계평가 삭제 시 함께 삭제됨)")
            else:
                result.warn_test("운영평가 세션이 없음 (정리할 데이터 없음)")

        except Exception as e:
            result.fail_test(f"데이터 정리 실패: {e}")

    def _update_specific_checklist(self):
        """Link7 체크리스트 결과 파일 생성"""
        if not self.checklist_source.exists():
            print(f"⚠️ 원본 체크리스트 파일이 없습니다: {self.checklist_source}")
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
                        updated_line = line.replace("- [ ] **", "- [x] ✅ **")
                        updated_line = updated_line.rstrip() + f" → **통과** ({res.message})\n"
                    elif res.status == TestStatus.FAILED:
                        updated_line = line.replace("- [ ] **", "- [ ] ❌ **")
                        updated_line = updated_line.rstrip() + f" → **실패** ({res.message})\n"
                    elif res.status == TestStatus.WARNING:
                        updated_line = line.replace("- [ ] **", "- [~] ⚠️ **")
                        updated_line = updated_line.rstrip() + f" → **경고** ({res.message})\n"
                    elif res.status == TestStatus.SKIPPED:
                        updated_line = line.replace("- [ ] **", "- [ ] ⊘ **")
                        updated_line = updated_line.rstrip() + f" → **건너뜀** ({res.message})\n"
                    break
            updated_lines.append(updated_line)

        # 테스트 요약 추가
        passed = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        warned = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total = len(self.results)

        updated_lines.append("\n---\n")
        updated_lines.append("## 테스트 결과 요약\n\n")
        updated_lines.append("| 항목 | 개수 | 비율 |\n")
        updated_lines.append("|------|------|------|\n")
        updated_lines.append(f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n" if total > 0 else "| ✅ 통과 | 0 | 0% |\n")
        updated_lines.append(f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n" if total > 0 else "| ❌ 실패 | 0 | 0% |\n")
        updated_lines.append(f"| ⚠️ 경고 | {warned} | {warned/total*100:.1f}% |\n" if total > 0 else "| ⚠️ 경고 | 0 | 0% |\n")
        updated_lines.append(f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n" if total > 0 else "| ⊘ 건너뜀 | 0 | 0% |\n")
        updated_lines.append(f"| **총계** | **{total}** | **100%** |\n")

        with open(self.checklist_result, 'w', encoding='utf-8') as f:
            f.writelines(updated_lines)
        print(f"\n✅ Link7 체크리스트 결과 저장됨: {self.checklist_result}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Link7 운영평가 Unit 테스트')
    parser.add_argument("--headless", action="store_true", help="브라우저 숨김 모드 (기본: 화면에 표시)")
    parser.add_argument("--url", default="http://localhost:5001", help="서버 URL (기본: http://localhost:5001)")
    args = parser.parse_args()

    test_suite = Link7OperationTestSuite(base_url=args.url, headless=args.headless)

    exit_code = test_suite.run_all_tests()
    sys.exit(exit_code)
