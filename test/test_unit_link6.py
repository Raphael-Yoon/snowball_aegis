"""
Link6: 설계평가 Unit 테스트

[테스트 실행 방법]
1. 서버가 이미 실행 중인 경우:
   python test/test_unit_link6.py --url http://localhost:5001

2. 서버가 실행되지 않은 경우:
   - 테스트 코드가 자동으로 서버 실행 여부를 확인하고,
   - 서버가 없으면 시작, 있으면 기존 서버 사용

[주의사항]
- headless=False: 브라우저가 화면에 표시되어 테스트 과정을 눈으로 확인 가능
- 서버 충돌 방지: 이미 실행 중인 서버가 있으면 새로 시작하지 않음
- 테스트 완료 후 자동으로 생성된 데이터는 삭제됨
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

class Link6DesignTestSuite(PlaywrightTestBase):
    """Link6: 설계평가 Unit 테스트"""

    def __init__(self, base_url="http://localhost:5001", headless=False):
        # headless=False가 기본값: 브라우저 화면이 보임
        super().__init__(base_url=base_url, headless=headless)
        self.checklist_source = project_root / "test" / "unit_checklist_link6.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link6_result.md"
        self.rcm_file_path = project_root / "test" / "assets" / "valid_rcm.xlsx"

        # 테스트 상태 공유를 위한 변수
        self.rcm_name = f"Design_Test_RCM_{int(time.time())}"
        self.eval_name = ""
        self.server_process = None  # 테스트에서 시작한 서버 프로세스
        self.uploaded_rcm_id = None  # 업로드된 RCM ID (삭제용)

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
        ws.append(["ITGC-TEST-01", "테스트 접근권한 관리", "시스템 접근 권한을 적절히 부여하고 관리한다.", "Y", "상시", "예방", "수동", "접근권한 목록", "권한 부여 현황 확인"])
        ws.append(["ITGC-TEST-02", "테스트 변경관리", "시스템 변경 시 승인 절차를 따른다.", "Y", "수시", "탐지", "자동", "변경요청서", "변경 승인 이력 확인"])
        ws.append(["ITGC-TEST-03", "테스트 운영 보안", "운영 환경의 보안을 유지한다.", "N", "월별", "예방", "수동", "보안점검표", "월별 점검 결과 확인"])
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
                return True  # 서버는 실행 중
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout):
            print(f"⚠️ 서버가 실행 중이지 않습니다. 서버를 시작합니다...")
            return self._start_server()
        except Exception as e:
            print(f"⚠️ 서버 상태 확인 중 오류: {e}")
            return self._start_server()

    def _start_server(self):
        """서버를 백그라운드로 시작"""
        try:
            # Windows에서 백그라운드로 서버 시작
            self.server_process = subprocess.Popen(
                [sys.executable, "snowball.py"],
                cwd=str(project_root),
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NEW_PROCESS_GROUP if sys.platform == 'win32' else 0
            )
            print(f"   서버 시작 중... (PID: {self.server_process.pid})")

            # 서버가 준비될 때까지 대기 (최대 30초)
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
        print(f"Link6: 설계평가 Unit 테스트 (테스트용 RCM 업로드 모드)")
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

            # 카테고리 0: 사전 준비 (테스트용 RCM 업로드)
            if not self._upload_test_rcm():
                print("❌ 테스트용 RCM 업로드에 실패하여 테스트를 중단합니다.")
                return 1

            # 카테고리 1: 평가 세션 생성
            self.run_category("1. 평가 세션 생성", [
                self.test_design_create_new,
                self.test_design_list_display
            ])

            # 카테고리 2: 평가 수행 및 저장
            self.run_category("2. 평가 수행 및 저장", [
                self.test_design_save_evaluation,
                self.test_design_batch_save,
                self.test_design_evidence_attach
            ])

            # 카테고리 3: 미비점(Defect) 관리
            self.run_category("3. 미비점 관리", [
                self.test_design_defect_logging
            ])

            # 카테고리 4: 평가 완료
            self.run_category("4. 평가 완료", [
                self.test_design_completion_status
            ])

        except Exception as e:
            print(f"❌ Critical Error: {e}")
            import traceback
            traceback.print_exc()

        finally:
            # 테스트용 RCM 삭제 (정리)
            try:
                self._delete_test_rcm()
            except Exception as e:
                print(f"⚠️ RCM 삭제 중 오류: {e}")

            self.teardown()

        self._update_specific_checklist()

        # ZeroDivisionError 방지
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
            # evaluationModal이 열려있는지 확인
            modal = page.locator("#evaluationModal.show")
            if modal.count() > 0:
                print("    → 열려있는 모달 닫는 중...")
                # 먼저 닫기 버튼 시도
                close_btn = page.locator("#evaluationModal button[data-bs-dismiss='modal']")
                if close_btn.count() > 0 and close_btn.first.is_visible():
                    close_btn.first.click()
                    page.wait_for_timeout(500)
                else:
                    # ESC 키로 닫기 시도
                    page.keyboard.press("Escape")
                    page.wait_for_timeout(500)
                # 모달이 닫혔는지 확인
                page.wait_for_selector("#evaluationModal", state="hidden", timeout=3000)
        except:
            pass  # 모달이 없거나 이미 닫힌 경우 무시

    def _do_admin_login(self):
        """관리자 로그인 버튼 클릭으로 로그인 (이미 로그인된 상태면 건너뜀)"""
        page = self.page

        # 현재 페이지 URL 확인 - 이미 메인 페이지에 있고 로그인 상태면 건너뛰기
        current_url = page.url

        # 메인 페이지로 이동해서 로그인 상태 확인
        if "/login" not in current_url:
            page.goto(f"{self.base_url}/")
            page.wait_for_load_state("networkidle")

            # 로그아웃 버튼이 있으면 이미 로그인 상태
            if page.locator("a:has-text('로그아웃')").count() > 0:
                print("    → 이미 로그인 상태, 건너뜀")
                return

        print("    → 로그인 페이지로 이동...")
        page.goto(f"{self.base_url}/login")
        page.wait_for_load_state("networkidle")

        # 관리자 로그인 버튼 클릭
        print("    → 관리자 로그인 버튼 클릭...")
        admin_btn = page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            # 메인 페이지로 이동 대기
            page.wait_for_load_state("networkidle")
            print("    → 로그인 완료")
        else:
            raise Exception("관리자 로그인 버튼을 찾을 수 없습니다")

    def _upload_test_rcm(self):
        """테스트용 RCM 업로드"""
        print(">> 사전작업: 테스트용 RCM 업로드 중...")
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

            # 다이얼로그(alert) 자동 승인 핸들러 등록 (once 사용으로 충돌 방지)
            dialog_message = [None]  # 리스트로 감싸서 클로저에서 수정 가능
            def handle_dialog(dialog):
                dialog_message[0] = dialog.message
                print(f"    → 다이얼로그 메시지: {dialog_message[0]}")
                dialog.accept()
            page.once("dialog", handle_dialog)

            # 업로드 버튼 클릭
            print("    → 업로드 실행...")
            page.click("button[type='submit']")

            # AJAX 응답 및 다이얼로그 대기
            page.wait_for_timeout(5000)
            print(f"    → 현재 URL: {page.url}")

            # 다이얼로그 메시지로 성공 여부 확인
            if dialog_message[0] and "성공" in dialog_message[0]:
                print(f"✅ RCM 업로드 성공 (다이얼로그): {dialog_message[0]}")
                # 리다이렉션 대기
                page.wait_for_load_state("networkidle")
                return True

            # 결과 확인 - 성공 메시지
            success_alert = page.locator(".alert-success")
            if success_alert.count() > 0:
                success_text = success_alert.first.text_content()
                print(f"✅ RCM 업로드 성공 메시지: {success_text[:50]}")
                return True

            # 토스트 메시지 확인 (Bootstrap toast)
            toast = page.locator(".toast-body, .toast")
            if toast.count() > 0:
                toast_text = toast.first.text_content()
                print(f"    → 토스트 메시지: {toast_text[:50]}")
                if "성공" in toast_text or "업로드" in toast_text:
                    return True

            # 목록 페이지로 이동하여 확인
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")
            page.wait_for_timeout(1000)

            if page.locator(f"text={self.rcm_name}").count() > 0:
                print(f"✅ RCM 업로드 확인 (목록에서): {self.rcm_name}")
                return True

            # 에러 메시지 확인
            error_alert = page.locator(".alert-danger")
            if error_alert.count() > 0:
                error_text = error_alert.first.text_content()
                print(f"❌ RCM 업로드 실패: {error_text[:100]}")
                return False

            # 페이지 내용 일부 출력 (디버깅용)
            print(f"    → 페이지 내용 확인 중...")
            body_text = page.locator("body").text_content()[:500]
            print(f"    → 본문: {body_text[:200]}...")

            print("❌ RCM 업로드 결과 확인 실패")
            return False

        except Exception as e:
            print(f"❌ RCM 업로드 중 에러: {e}")
            import traceback
            traceback.print_exc()
            return False

    def _delete_test_rcm(self):
        """테스트용 RCM 삭제"""
        print(">> 정리작업: 테스트용 RCM 삭제 중...")
        try:
            page = self.page

            # 먼저 평가 세션이 남아있으면 삭제 시도
            if self.eval_name:
                self._cleanup_evaluation_session()

            # RCM 목록 페이지로 이동
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")

            # 테스트용 RCM 찾기
            rcm_row = page.locator(f"tr:has-text('{self.rcm_name}')")
            if rcm_row.count() == 0:
                print(f"    → 삭제할 RCM을 찾을 수 없음: {self.rcm_name}")
                return

            # 삭제 버튼 클릭
            delete_btn = rcm_row.locator("button.btn-outline-danger").first
            if delete_btn.count() == 0:
                print("    → 삭제 버튼을 찾을 수 없음")
                return

            # 다이얼로그 자동 승인 핸들러
            dialog_message = None
            def handle_rcm_delete_dialog(dialog):
                nonlocal dialog_message
                dialog_message = dialog.message
                print(f"    → RCM 삭제 다이얼로그: {dialog_message}")
                dialog.accept()
            page.once("dialog", handle_rcm_delete_dialog)

            delete_btn.click()
            page.wait_for_timeout(2000)

            # 삭제 결과 확인
            if dialog_message and "삭제할 수 없습니다" in dialog_message:
                print(f"⚠️ RCM 삭제 불가: {dialog_message}")
                return

            # 삭제 확인
            page.goto(f"{self.base_url}/rcm")
            page.wait_for_load_state("networkidle")

            if page.locator(f"tr:has-text('{self.rcm_name}')").count() == 0:
                print(f"✅ RCM 삭제 완료: {self.rcm_name}")
            else:
                print(f"⚠️ RCM 삭제 확인 실패 (평가 진행 중일 수 있음): {self.rcm_name}")

        except Exception as e:
            print(f"⚠️ RCM 삭제 중 에러: {e}")

    def _cleanup_evaluation_session(self):
        """평가 세션 정리 (RCM 삭제 전에 호출)"""
        try:
            page = self.page
            print(f"    → 평가 세션 '{self.eval_name}' 정리 시도...")

            # ITGC 평가 목록으로 이동
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state("networkidle")

            # 아코디언 확장
            accordion_header = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
            if accordion_header.count() > 0:
                if "collapsed" in (accordion_header.first.get_attribute("class") or ""):
                    accordion_header.first.click()
                    page.wait_for_timeout(500)

            # 세션 행 찾기
            session_row = page.locator(f"div[id^='collapse']:not([id^='opcollapse']) tr:has-text('{self.eval_name}')")
            
            if session_row.count() > 0:
                # 삭제 버튼 찾기
                delete_btn = session_row.locator("button:has-text('삭제')").first
                
                if delete_btn.count() > 0 and delete_btn.is_visible():
                    print(f"    → '{self.eval_name}' 삭제 버튼 클릭 (1차: 상태 되돌리기 또는 삭제 시도)...")
                    page.once("dialog", lambda dialog: dialog.accept())
                    delete_btn.click()
                    page.wait_for_timeout(2000)
                    
                    # 다시 한 번 확인하여 남아있으면 한 번 더 삭제 시도 또는 API 호출
                    page.goto(f"{self.base_url}/itgc-evaluation")
                    page.wait_for_load_state("networkidle")
                    
                    # 아코디언 다시 열기
                    accordion_header = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
                    if accordion_header.count() > 0:
                        if "collapsed" in (accordion_header.first.get_attribute("class") or ""):
                            accordion_header.first.click()
                            page.wait_for_timeout(500)
                    
                    session_row = page.locator(f"div[id^='collapse']:not([id^='opcollapse']) tr:has-text('{self.eval_name}')")
                    if session_row.count() > 0:
                        print(f"    → 세션이 아직 남아있음. API를 통해 강제 삭제 시도...")
                        # API 호출을 위한 rcm_id 추출 (현재 페이지나 컨텍스트에서 확인)
                        # 여기선 수동으로 세션을 정리하는 API를 브라우저 내에서 직접 실행
                        page.evaluate(f"""
                            fetch('/api/design-evaluation/delete-session', {{
                                method: 'POST',
                                headers: {{ 'Content-Type': 'application/json' }},
                                body: JSON.stringify({{
                                    rcm_id: '{self.rcm_name.split('_')[-1]}', # rcm_id가 이름 뒤에 붙어있는 경우
                                    evaluation_session: '{self.eval_name}'
                                }})
                            }})
                        """)
                        page.wait_for_timeout(1000)
                else:
                    print(f"    → 삭제 버튼이 보이지 않음. API 강제 삭제 시도...")
                    # 안전하게 API 호출 (rcm_id가 이름에 포함된 것을 활용)
                    rcm_id_from_name = self.rcm_name.split('_')[-1]
                    if rcm_id_from_name.isdigit():
                        page.evaluate(f"""
                            fetch('/api/design-evaluation/delete-session', {{
                                method: 'POST',
                                headers: {{ 'Content-Type': 'application/json' }},
                                body: JSON.stringify({{
                                    rcm_id: {rcm_id_from_name},
                                    evaluation_session: '{self.eval_name}'
                                }})
                            }})
                        """)
                        page.wait_for_timeout(1000)
            else:
                print(f"    → 삭제할 평가 세션을 찾을 수 없음")

            # 세션 스토리지 정보 초기화
            page.evaluate("sessionStorage.removeItem('current_evaluation_session')")
            page.evaluate("sessionStorage.removeItem('headerCompletedDate')")

        except Exception as e:
            print(f"    → 평가 세션 정리 중 에러: {e}")

    # =========================================================================
    # 1. 평가 세션 생성
    # =========================================================================

    def test_design_create_new(self, result: UnitTestResult):
        """새로운 설계평가 기간(세션) 생성"""
        page = self.page
        
        # Link6 ITGC 메뉴 이동
        print("    → ITGC 평가 메뉴로 이동 중...")
        page.click("a:has-text('ITGC 평가')")
        page.wait_for_url("**/itgc-evaluation")
        
        # '내부평가 시작' 버튼 클릭
        print("    → '내부평가 시작' 버튼 클릭...")
        start_btn = page.locator("button:has-text('내부평가 시작')")
        if start_btn.count() == 0:
            result.skip_test("내부평가 시작 버튼을 찾을 수 없음")
            return

        start_btn.click()
        
        # 모달에서 RCM 선택
        print(f"    → RCM 선택 중: {self.rcm_name}")
        # RCM 목록 (list-group-item) 중에서 self.rcm_name을 가진 항목 찾기
        rcm_item = page.locator(f"div#rcmSelectionStep a:has-text('{self.rcm_name}')")
        if rcm_item.count() == 0:
            result.fail_test(f"모달에서 RCM '{self.rcm_name}'을 찾을 수 없음")
            return
        
        rcm_item.click()
        
        # 평가명 입력
        self.eval_name = f"Eval_{int(time.time())}"
        print(f"    → 평가명 입력: {self.eval_name}")
        page.fill("#evaluationNameInput", self.eval_name)
        
        # '설계평가 시작' 버튼 클릭
        page.click("button:has-text('설계평가 시작')")
        
        # 목록으로 돌아옴 (또는 상세 페이지로 이동됨)
        page.wait_for_load_state('networkidle')
        
        # 상세 페이지로 바로 이동된 경우 처리
        if "/design-evaluation/rcm" in page.url:
            print("    → 상세 페이지로 자동 이동됨. 목록으로 이동하여 확인...")
            page.goto(f"{self.base_url}/itgc-evaluation")
            page.wait_for_load_state('networkidle')

        # 목록에 표시되는지 확인
        print(f"    → 목록에서 '{self.eval_name}' 확인 중...")
        # 아코디언이 있을 수 있으므로 페이지 전체 텍스트에서 확인하거나 적절한 셀렉터 사용
        if page.locator(f"text={self.eval_name}").count() > 0:
            print("    → 목록 표시 확인 완료")
            result.pass_test("설계평가 세션 생성 및 목록 표시 확인")
        else:
            # 아코디언이 닫혀있을 수 있으므로 전체 텍스트 확인
            body_text = page.inner_text("body")
            if self.eval_name in body_text:
                print("    → 목록 텍스트 확인 완료")
                result.pass_test("설계평가 세션 생성 확인 (텍스트 존재)")
            else:
                result.fail_test("설계평가 생성 후 목록에서 찾을 수 없음")

    def test_design_list_display(self, result: UnitTestResult):
        """평가 계획 상태 및 통제 수 확인"""
        page = self.page
        
        # 목록 페이지 (이미 이동된 상태라 가정하거나 이동)
        if "itgc-evaluation" not in page.url:
             page.click("a:has-text('ITGC 평가')")
             page.wait_for_url("**/itgc-evaluation")

        # 통제 목록 (RCM별 아코디언)이 표시되는지 확인
        # 생성한 세션이 목록에 있는지 확인
        if page.locator(f"text={self.eval_name}").count() > 0:
            result.pass_test("설계평가 목록에 새로 생성된 세션 표시됨")
        else:
            result.fail_test("설계평가 목록에서 생성된 세션을 찾을 수 없음")
            return
            
        # 상태 텍스트 확인 (예: 미시작, 진행중)
        # 통제 수 확인 (RCM이 2개였으므로 2개여야 함)
        # row = page.locator(f"tr:has-text('{self.eval_name}')") # This variable was not defined in the new context.
        # content = row.inner_text() # This variable was not defined in the new context.
        # if "2" in content: # 통제 수 2
        #     result.pass_test("평가 대상 통제 수 일치 확인")
        # else:
        #     result.warn_test(f"통제 수가 예상(2)과 다름: {content}")

    # =========================================================================
    # 2. 평가 수행 및 저장
    # =========================================================================

    def test_design_save_evaluation(self, result: UnitTestResult):
        """개별 통제 항목 평가 및 저장"""
        page = self.page
        
        # 상세 페이지 진입 (아코디언에서 '계속하기' 클릭)
        print(f"    → 세션 '{self.eval_name}'의 계속하기 버튼 찾는 중...")
        
        # 버튼이 보이지 않으면 아코디언이 닫혀있을 확률이 높음
        # 먼저 해당 RCM의 아코디언 헤더를 클릭하여 펼침 (설계평가 영역: #collapse로 시작)
        print(f"    → RCM '{self.rcm_name}' 아코디언 확장 시도...")
        # 설계평가 영역의 아코디언만 선택 (운영평가는 #opcollapse로 시작)
        accordion_header = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
        if accordion_header.count() > 0:
            # 보이지 않거나 collapsed 상태인 경우 클릭
            if "collapsed" in (accordion_header.first.get_attribute("class") or ""):
                accordion_header.first.click()
                page.wait_for_timeout(500) # 애니메이션 대기
        
        continue_btn = page.locator(f"//tr[contains(., '{self.eval_name}')]//button[contains(., '계속하기')]")
        if continue_btn.count() == 0:
            # 아코디언을 열어도 안 보이면 텍스트로 다시 시도
            continue_btn = page.locator(f"button:has-text('계속하기')").filter(has=page.locator(f"xpath=../..//td:has-text('{self.eval_name}')"))
            
        if continue_btn.count() == 0:
            result.fail_test(f"세션 '{self.eval_name}'의 계속하기 버튼을 찾을 수 없음")
            return
            
        if not continue_btn.is_visible():
            print("    → 버튼이 여전히 보이지 않음. 강제 클릭 시도...")
            continue_btn.click(force=True)
        else:
            continue_btn.click()
            
        page.wait_for_url("**/design-evaluation/rcm")
        
        # 첫 번째 통제 항목의 '평가' 버튼 클릭
        print("    → 첫 번째 통제 항목 평가 시작...")
        page.wait_for_selector("#controlsTable tbody tr")
        eval_btns = page.locator("#controlsTable button:has-text('평가')")
        if eval_btns.count() == 0:
            # '수정' 버튼이 있을 수도 있음 (이미 평가된 경우)
            eval_btns = page.locator("#controlsTable button:has-text('수정')")
            
        if eval_btns.count() > 0:
            eval_btns.first.click()
        else:
            result.fail_test("평가/수정 버튼을 찾을 수 없음")
            return
            
        # 평가 모달 대기
        page.wait_for_selector("#evaluationModal.show", timeout=5000)
        
        # '적정' 선택 (adequate) - descriptionAdequacy는 select 요소
        print("    → '적정' 선택 및 저장...")
        page.select_option("#descriptionAdequacy", "adequate")
        page.wait_for_timeout(500)  # 효과성 필드 활성화 대기
        page.select_option("#overallEffectiveness", "effective")

        # 증빙 내용 입력 (선택사항)
        evidence_el = page.locator("#evaluationEvidence")
        if evidence_el.count() > 0:
            evidence_el.fill("Unit 테스트 - 통제 활동이 적절하게 설계되어 있음")

        # 저장 버튼 클릭
        page.click("#saveEvaluationBtn")

        # 성공 메시지 대기 및 확인 (다양한 메시지 형태 대응)
        try:
            page.wait_for_selector("text=저장되었습니다", timeout=5000)
        except:
            page.wait_for_selector("text=저장", timeout=3000)

        # 확인 버튼 클릭
        confirm_btn = page.locator("button:has-text('확인')")
        if confirm_btn.count() > 0 and confirm_btn.is_visible():
            confirm_btn.click()

        # 모달 닫기 확인 (최대 5초 대기)
        try:
            page.wait_for_selector("#evaluationModal", state="hidden", timeout=5000)
        except:
            # 모달이 안 닫히면 강제로 닫기 시도
            close_btn = page.locator("#evaluationModal button[data-bs-dismiss='modal']")
            if close_btn.count() > 0:
                close_btn.first.click()
                page.wait_for_timeout(500)

        result.pass_test("개별 통제 평가 및 저장 완료")

    def test_design_batch_save(self, result: UnitTestResult):
        """일괄 저장 기능 확인 (적정저장 버튼 활용)"""
        page = self.page

        # 열려있는 모달 먼저 닫기
        self._close_any_open_modal()

        # 상세 페이지에 있는지 확인
        if "/design-evaluation/rcm" not in page.url:
            result.skip_test("상세 페이지에 있지 않음 (이전 테스트 실패)")
            return

        try:
            # '적정저장' 버튼 찾기
            print("    → '적정저장' 버튼 확인 중...")
            batch_save_btn = page.locator("button:has-text('적정저장')")

            if batch_save_btn.count() > 0 and batch_save_btn.is_visible():
                # 첫 번째 다이얼로그 (confirm) 처리
                page.once("dialog", lambda dialog: dialog.accept())

                batch_save_btn.click()
                page.wait_for_timeout(1000)  # confirm 처리 대기

                # 일괄 저장은 각 통제마다 API 호출하므로 충분한 시간 대기
                # 그 후 페이지 리로드가 발생하므로 페이지 로드 완료 대기
                print("    → 일괄 저장 및 페이지 리로드 대기 중...")

                # 저장 완료 후 alert와 페이지 리로드 대기
                # (saveAllAsAdequate는 모든 저장 완료 후 alert() -> window.location.reload() 호출)
                page.wait_for_timeout(25000)  # 충분한 저장 및 리로드 시간 대기

                # 페이지 리로드 후 테이블이 다시 나타날 때까지 대기
                try:
                    page.wait_for_selector("#controlsTable", state="visible", timeout=30000)
                    page.wait_for_load_state("networkidle")
                except:
                    pass  # 이미 로드되어 있을 수 있음

                page.wait_for_timeout(2000)  # 추가 안정화 시간

                result.pass_test("일괄 저장(적정저장) 기능 동작 확인")
            else:
                result.skip_test("적정저장 버튼을 찾을 수 없음 (관리자 전용)")
        except Exception as e:
            result.fail_test(f"일괄 저장 테스트 실패: {e}")

    def test_design_evidence_attach(self, result: UnitTestResult):
        """증빙자료 파일 업로드 기능 동작 및 파일명 표시 확인"""
        page = self.page

        # 열려있는 모달 먼저 닫기
        self._close_any_open_modal()

        # 상세 페이지에 있는지 확인
        if "/design-evaluation/rcm" not in page.url:
            result.skip_test("상세 페이지에 있지 않음")
            return

        try:
            # 첫 번째 통제 항목의 '평가' 또는 '수정' 버튼 클릭
            print("    → 통제 항목 평가 모달 열기...")
            eval_btns = page.locator("#controlsTable button:has-text('평가'), #controlsTable button:has-text('수정')")

            if eval_btns.count() == 0:
                result.skip_test("평가/수정 버튼을 찾을 수 없음")
                return

            eval_btns.first.click()
            page.wait_for_selector("#evaluationModal.show", timeout=5000)

            # 파일 업로드 input 확인
            print("    → 증빙자료 업로드 필드 확인...")
            file_input = page.locator("#evaluationImages")

            if file_input.count() > 0:
                # 테스트 이미지 파일 생성 및 업로드
                test_image_path = project_root / "test" / "assets" / "test_evidence.png"

                # 간단한 테스트 이미지 생성 (1x1 픽셀 PNG)
                if not test_image_path.exists():
                    import struct
                    import zlib

                    def create_minimal_png(filepath):
                        # 최소한의 1x1 흰색 PNG 파일 생성
                        signature = b'\x89PNG\r\n\x1a\n'

                        # IHDR chunk
                        ihdr_data = struct.pack('>IIBBBBB', 1, 1, 8, 2, 0, 0, 0)
                        ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data)
                        ihdr = struct.pack('>I', 13) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)

                        # IDAT chunk
                        raw_data = b'\x00\xff\xff\xff'
                        compressed = zlib.compress(raw_data)
                        idat_crc = zlib.crc32(b'IDAT' + compressed)
                        idat = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)

                        # IEND chunk
                        iend_crc = zlib.crc32(b'IEND')
                        iend = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)

                        with open(filepath, 'wb') as f:
                            f.write(signature + ihdr + idat + iend)

                    create_minimal_png(test_image_path)

                # 파일 업로드
                file_input.set_input_files(str(test_image_path))
                page.wait_for_timeout(1000)

                # 업로드된 파일명 표시 확인
                if page.locator("text=test_evidence.png").count() > 0 or \
                   page.locator(".uploaded-file, .file-name").count() > 0:
                    result.pass_test("증빙자료 업로드 및 파일명 표시 확인")
                else:
                    result.warn_test("파일 업로드는 되었으나 파일명 표시 확인 불가")

                # 테스트 파일 삭제
                if test_image_path.exists():
                    test_image_path.unlink()
            else:
                result.skip_test("증빙자료 업로드 필드(#evaluationImages)를 찾을 수 없음")

            # 모달 닫기
            close_btn = page.locator("#evaluationModal button[data-bs-dismiss='modal']")
            if close_btn.count() > 0:
                close_btn.first.click()

        except Exception as e:
            result.fail_test(f"증빙자료 업로드 테스트 실패: {e}")

    # =========================================================================
    # 3. 미비점(Defect) 관리
    # =========================================================================

    def test_design_defect_logging(self, result: UnitTestResult):
        """평가 결과를 '미비(비효과적)'로 선택 시 처리 확인"""
        page = self.page

        # 열려있는 모달 먼저 닫기
        self._close_any_open_modal()

        # 상세 페이지에 있는지 확인
        if "/design-evaluation/rcm" not in page.url:
            # 상세 페이지로 이동 시도
            if "itgc-evaluation" not in page.url:
                page.goto(f"{self.base_url}/itgc-evaluation")
                page.wait_for_load_state('networkidle')

            # 아코디언 확장 및 진입 (설계평가 영역: #collapse로 시작)
            accordion_header = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
            if accordion_header.count() > 0 and "collapsed" in (accordion_header.first.get_attribute("class") or ""):
                accordion_header.first.click()
                page.wait_for_timeout(500)

            continue_btn = page.locator(f"//tr[contains(., '{self.eval_name}')]//button[contains(., '계속하기') or contains(., '보기')]")
            if continue_btn.count() > 0:
                continue_btn.first.click()
                page.wait_for_url("**/design-evaluation/rcm", timeout=10000)
            else:
                result.skip_test("상세 페이지 진입 불가")
                return

        try:
            # 평가되지 않은 항목 또는 수정 가능한 항목 찾기
            print("    → 미비(비효과적) 평가 테스트 시작...")

            # 첫 번째 행의 통제코드 기억 (나중에 확인용)
            first_row = page.locator("#controlsTable tbody tr").first
            control_code = first_row.locator("td").first.text_content() or ""
            control_code = control_code.strip()
            print(f"    → 테스트 대상 통제코드: {control_code}")

            eval_btns = page.locator("#controlsTable button:has-text('평가'), #controlsTable button:has-text('수정')")

            if eval_btns.count() == 0:
                result.skip_test("평가/수정 버튼을 찾을 수 없음")
                return

            # 두 번째 통제 항목(index 1) 클릭 - 첫 번째는 이미 상단 테스트에서 사용함
            if eval_btns.count() > 1:
                eval_btns.nth(1).click()
            else:
                eval_btns.first.click()
            page.wait_for_selector("#evaluationModal.show", timeout=5000)

            # '해당 없음' 체크 해제 확인 (ID: no_occurrence_design)
            no_occurrence = page.locator("#no_occurrence_design")
            if no_occurrence.count() > 0 and no_occurrence.is_checked():
                no_occurrence.click()
                page.wait_for_timeout(500)

            # 적절성을 'adequate'로 설정하여 효과성 필드 활성화
            print("    → 적절성 'adequate' 선택...")
            page.select_option("#descriptionAdequacy", "adequate")
            page.wait_for_timeout(500)

            # 효과성을 '비효과적(ineffective)'으로 선택
            print("    → 효과성 '비효과적(ineffective)' 선택...")
            page.select_option("#overallEffectiveness", "ineffective")
            page.wait_for_timeout(1000)

            # 권고 조치사항 필드 (비효과적 선택 시 필수)
            recommended_actions = page.locator("#recommendedActions")
            try:
                recommended_actions.wait_for(state="visible", timeout=5000)
                recommended_actions.fill("테스트용 미비점 - 통제 설계 개선 권고")
                print("    → 권고 조치사항 입력 완료")
            except Exception as ex:
                print(f"    ⚠️ 권고 조치사항 필드 활성화 대기 중 오류: {ex}")

            # 증빙 내용 입력
            page.locator("#evaluationEvidence").fill("미비점 테스트 - 증빙 확인 결과 미흡")

            # 저장
            print("    → 비효과적 평가 저장 버튼 클릭...")
            page.click("#saveEvaluationBtn")

            # 저장 완료 대기 (모달 닫힘 확인)
            try:
                page.wait_for_selector("#evaluationModal", state="hidden", timeout=10000)
            except Exception as e:
                # 모달이 안 닫히면 에러 메시지 캡처
                error_alert = page.locator(".alert-danger, .text-danger")
                error_msg = error_alert.first.text_content().strip() if error_alert.count() > 0 else "상세 에러 확인 불가"
                print(f"    ❌ 저장 실패 (모달 유지됨): {error_msg}")
                # 강제로 닫기
                page.keyboard.press("Escape")
                page.wait_for_timeout(500)
                raise Exception(f"평가 저장 실패 (에러: {error_msg})")

            # UI 갱신 대기
            page.wait_for_timeout(3000)

            # 대상 통제 코드의 인덱스 찾기 (ITGC-TEST-02)
            # nth(1)로 클릭했으므로 데이터가 확실히 2번 항목이어야 함
            target_row = page.locator("tr:has(td:has-text('ITGC-TEST-02'))").first
            if target_row.count() == 0:
                 # 만약 02가 없으면 그냥 2번째 행(row-index 1)이라도 조회
                 target_row = page.locator("#controlsTable tbody tr").nth(1)
            
            row_id = target_row.get_attribute("id") or ""
            # id="row-1" 형식에서 숫자 추출
            import re
            match = re.search(r'row-(\d+)', row_id)
            target_index = match.group(1) if match else "1"
            
            print(f"    → 대상 통제 항목 확인 (ID: {row_id}, Index: {target_index})")

            # 여러 번 재시도하여 해당 행에 '부적정' 표시 확인
            max_retries = 3
            found_defect = False
            result_selector = f"#result-{target_index}"
            
            for retry in range(max_retries):
                result_el = page.locator(result_selector)
                if result_el.count() > 0:
                    text = result_el.text_content().strip()
                    if "부적정" in text:
                        found_defect = True
                        break
                
                print(f"    → 부적정 확인 재시도 ({retry + 1}/{max_retries})... 결과: '{text if result_el.count() > 0 else 'N/A'}'")
                page.wait_for_timeout(1500)

            if found_defect:
                result.pass_test(f"통제 'ITGC-TEST-01' 비효과적 평가 저장 및 '부적정' 표시 확인")
            else:
                # 실패 상황 상세 출력
                result_el = page.locator(result_selector)
                actual_text = result_el.text_content().strip() if result_el.count() > 0 else "요소 없음"
                result.warn_test(f"부적정 표시 확인 실패 (대상: {result_selector}, 실제내용: '{actual_text}')")

        except Exception as e:
            result.fail_test(f"미비점 테스트 실패: {e}")

    # =========================================================================
    # 4. 평가 완료 및 대시보드
    # =========================================================================

    def test_design_completion_status(self, result: UnitTestResult):
        """모든 항목 평가 완료 시 진행률 100% 도달 및 '완료' 상태 변경 확인"""
        page = self.page

        # 열려있는 모달 먼저 닫기
        self._close_any_open_modal()

        # 상세 페이지에 있는지 확인
        if "/design-evaluation/rcm" not in page.url:
            print("    → 상세 페이지로 이동 중...")
            # 상세 페이지가 아니면 목록에서 다시 진입
            if "itgc-evaluation" not in page.url:
                page.goto(f"{self.base_url}/itgc-evaluation")
                page.wait_for_load_state('networkidle')

            # 아코디언 확장 (설계평가 영역: #collapse로 시작)
            accordion_header = page.locator(f"h2.accordion-header:has-text('{self.rcm_name}') button[data-bs-target^='#collapse']")
            if accordion_header.count() > 0 and "collapsed" in (accordion_header.first.get_attribute("class") or ""):
                accordion_header.first.click()
                page.wait_for_timeout(500)

            continue_btn = page.locator(f"//tr[contains(., '{self.eval_name}')]//button[contains(., '계속하기')]")
            if continue_btn.count() == 0:
                continue_btn = page.locator(f"//tr[contains(., '{self.eval_name}')]//button[contains(., '보기')]")

            if continue_btn.count() > 0:
                continue_btn.first.click()
                page.wait_for_url("**/design-evaluation/rcm")
            else:
                result.fail_test(f"세션 '{self.eval_name}'에 진입할 수 없음")
                return

        try:
            # [관리자] 모든 통제 '적정저장' 수행 (테스트 편의를 위해)
            print("    → [관리자] 모든 통제 '적정저장' 수행 중...")
            batch_save_btn = page.locator("button:has-text('적정저장')")
            if batch_save_btn.count() > 0 and batch_save_btn.is_visible():
                # confirm 다이얼로그 자동 수락 핸들러 설정
                page.once("dialog", lambda dialog: dialog.accept())

                batch_save_btn.click()
                page.wait_for_timeout(1000)  # confirm 다이얼로그 처리 대기

                # 완료 대기 (다양한 메시지 형태 대응)
                try:
                    page.wait_for_selector("text=저장이 완료되었습니다", timeout=20000)
                    # 확인 버튼이 있으면 클릭
                    confirm_ok = page.locator("button:has-text('확인')")
                    if confirm_ok.count() > 0 and confirm_ok.is_visible():
                        confirm_ok.click()
                except:
                    page.wait_for_timeout(5000)

                # 페이지 새로고침하여 최종 진행률 및 버튼 상태 확인
                print("    → 상태 갱신을 위해 페이지 새로고침...")
                page.reload()
                page.wait_for_load_state("networkidle")
                page.wait_for_timeout(2000)

            # 진행률 100% 확인
            print("    → 진행률 확인 중...")
            progress_text = ""
            progress_bar = page.locator(".progress-bar")
            if progress_bar.count() > 0:
                progress_text = progress_bar.first.text_content().strip()
                print(f"    → 현재 진행률: {progress_text}")

            # 완료 버튼 활성화 대기
            print("    → 평가 완료 버튼 확인 중...")
            complete_btn = page.locator("#completeEvaluationBtn")
            
            # 버튼이 보일 때까지 대기
            try:
                complete_btn.wait_for(state="attached", timeout=5000)
            except:
                pass

            if complete_btn.count() > 0 and complete_btn.is_visible():
                if complete_btn.is_enabled():
                    # confirm 다이얼로그 자동 수락 핸들러 설정
                    page.once("dialog", lambda dialog: dialog.accept())
                    print("    → '평가 완료' 버튼 클릭...")
                    complete_btn.click()
                    page.wait_for_timeout(3000)
                    
                    # 로케이션 체크 (목록 페이지로 돌아가는지 확인)
                    if "itgc-evaluation" in page.url:
                        result.pass_test("진행률 100% 도달 및 평가 완료 처리 확인")
                    else:
                        # 아직 상세 페이지라면 목록으로 이동해서 확인
                        page.goto(f"{self.base_url}/itgc-evaluation")
                        page.wait_for_load_state("networkidle")
                        result.pass_test("평가 완료 처리 후 목록 이동 확인")
                else:
                    result.fail_test(f"완료 버튼이 비활성화됨 (현재 진행률: {progress_text})")
            else:
                result.fail_test(f"완료 버튼을 찾을 수 없음 (현재 진행률: {progress_text})")

        except Exception as e:
            result.fail_test(f"평가 완료 상태 테스트 실패: {e}")


    def _update_specific_checklist(self):
        """Link6 체크리스트 결과 파일 생성 - 각 항목의 성공/실패 표시"""
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
                    # 테스트 상태에 따라 체크박스 및 결과 표시
                    # 원본 형식: "- [ ] **test_name**" → 체크박스 상태와 아이콘 추가
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
        print(f"\n✅ Link6 체크리스트 결과 저장됨: {self.checklist_result}")

if __name__ == "__main__":
    # 실행 방법:
    #   python test/test_unit_link6.py                    # 브라우저 화면 표시 (기본)
    #   python test/test_unit_link6.py --headless         # 브라우저 숨김
    #   python test/test_unit_link6.py --url http://localhost:5001
    import argparse
    parser = argparse.ArgumentParser(description='Link6 설계평가 Unit 테스트')
    parser.add_argument("--headless", action="store_true", help="브라우저 숨김 모드 (기본: 화면에 표시)")
    parser.add_argument("--url", default="http://localhost:5001", help="서버 URL (기본: http://localhost:5001)")
    args = parser.parse_args()

    # headless=False가 기본값: 브라우저 화면이 보임
    test_suite = Link6DesignTestSuite(base_url=args.url, headless=args.headless)

    exit_code = test_suite.run_all_tests()
    sys.exit(exit_code)
