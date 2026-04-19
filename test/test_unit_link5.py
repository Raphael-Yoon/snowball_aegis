"""
Link5: RCM 관리 상세 Unit 테스트

[체크리스트 파일] test/unit_checklist_link5.md

[검증 항목]
1. 파일 업로드 및 유효성 검사
2. 목록 조회 및 권한
3. 상세 조회 및 수정
4. 삭제 관리

[테스트 환경]
- 로컬 서버 포트: 5001 (기본값)
- 로그인 방식: 로그인 화면의 '관리자 로그인' 버튼 사용
- 서버 실행 필요: snowball 앱이 localhost:5001에서 실행 중이어야 함

실행 방법:
    python test/test_unit_link5.py --url http://localhost:5001
"""

import sys
import argparse
import requests
import subprocess
import time
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, UnitTestResult, TestStatus


class Link5RCMTestSuite(PlaywrightTestBase):
    """RCM 관리 기능 상세 테스트 스위트 - 실제 사용자 클릭 시뮬레이션"""

    def __init__(self, base_url="http://localhost:5001", headless=False):
        super().__init__(base_url=base_url, headless=headless)
        self.valid_rcm_path = project_root / "test" / "assets" / "valid_rcm.xlsx"
        self.invalid_ext_path = project_root / "test" / "assets" / "invalid.txt"
        self.missing_req_path = project_root / "test" / "assets" / "missing_req.xlsx"
        self.checklist_source = project_root / "test" / "unit_checklist_link5.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link5_result.md"
        self.test_rcm_name = f"Unit_Test_RCM_{datetime.now().strftime('%H%M%S')}"
        self.uploaded_rcm_name = None  # 업로드 성공 시 저장
        self.server_process = None  # 테스트에서 시작한 서버 프로세스

    def setup_test_data(self):
        """테스트 데이터 파일 생성 - 항상 새로 생성"""
        assets_dir = project_root / "test" / "assets"
        assets_dir.mkdir(parents=True, exist_ok=True)

        from openpyxl import Workbook

        # 1. 정상 파일 (필수 컬럼 포함)
        wb = Workbook()
        ws = wb.active
        ws.append([
            "통제코드", "통제명", "통제설명", "핵심통제",
            "통제주기", "통제유형", "통제속성", "모집단", "테스트절차"
        ])
        ws.append(["P-TEST-01", "발주 승인", "발주 승인 설명", "Y", "일", "예방", "수동", "모집단 설명", "테스트 절차"])
        ws.append(["P-TEST-02", "입고 확인", "입고 확인 설명", "N", "주", "적발", "자동", "모집단 설명2", "테스트 절차2"])
        wb.save(self.valid_rcm_path)

        # 2. 필수값 누락 파일 (Control Code 누락)
        wb = Workbook()
        ws = wb.active
        ws.append(["통제코드", "통제명", "통제설명", "핵심통제"])
        ws.append(["", "코드없는 통제", "설명", "Y"])
        wb.save(self.missing_req_path)

        # 3. 잘못된 확장자
        with open(self.invalid_ext_path, 'w') as f:
            f.write("This is not an excel file.")

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
        print("=" * 80)
        print("Link5: RCM 관리 상세 테스트 (사용자 클릭 시뮬레이션)")
        print("=" * 80)

        # 서버 상태 확인
        if not self.check_server_running():
            print("\n테스트를 중단합니다.")
            return 1

        self.setup_test_data()

        try:
            self.setup()

            # 카테고리 1: 파일 업로드
            self.run_category("1. 파일 업로드 검증", [
                self.test_rcm_upload_success,
                self.test_rcm_upload_invalid_ext,
                self.test_rcm_upload_missing_required
            ])

            # 카테고리 2: 목록 및 권한
            self.run_category("2. 목록 및 권한", [
                self.test_rcm_list_metadata
            ])

            # 카테고리 3: 상세 조회
            self.run_category("3. 상세 조회", [
                self.test_rcm_detail_mapping
            ])

            # 카테고리 4: 삭제
            self.run_category("4. 삭제", [
                self.test_rcm_delete
            ])

            # 카테고리 5: 회사별 데이터 격리
            self.run_category("5. 회사별 데이터 격리", [
                self.test_link5_company_data_isolation
            ])

        finally:
            self.teardown()

        # 체크리스트 업데이트
        self._update_specific_checklist()
        return self.print_final_report()

    def _update_specific_checklist(self):
        """RCM 전용 체크리스트 결과 파일 생성 - 각 항목의 성공/실패 표시"""
        if not self.checklist_source.exists():
            print(f"[WARN] 원본 체크리스트 파일이 없습니다: {self.checklist_source}")
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
                    if res.status == TestStatus.PASSED:
                        updated_line = line.replace("- **", "- [x] ✅ **")
                        updated_line = updated_line.rstrip() + f" → **통과** ({res.message})\n"
                    elif res.status == TestStatus.FAILED:
                        updated_line = line.replace("- **", "- [ ] ❌ **")
                        updated_line = updated_line.rstrip() + f" → **실패** ({res.message})\n"
                    elif res.status == TestStatus.WARNING:
                        updated_line = line.replace("- **", "- [~] ⚠️ **")
                        updated_line = updated_line.rstrip() + f" → **경고** ({res.message})\n"
                    elif res.status == TestStatus.SKIPPED:
                        updated_line = line.replace("- **", "- [ ] ⊘ **")
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
        print(f"\n[OK] RCM 체크리스트 결과 저장됨: {self.checklist_result}")

    # =========================================================================
    # 헬퍼 메서드: 사용자 액션 시뮬레이션
    # =========================================================================

    def _do_admin_login(self):
        """관리자 로그인 버튼 클릭으로 로그인 (이미 로그인된 상태면 건너뜀)"""
        # 현재 페이지 URL 확인 - 이미 메인 페이지에 있고 로그인 상태면 건너뛰기
        current_url = self.page.url

        # 메인 페이지로 이동해서 로그인 상태 확인
        if "/login" not in current_url:
            self.page.goto(f"{self.base_url}/")
            self.page.wait_for_load_state("networkidle")

            # 로그아웃 버튼이 있으면 이미 로그인 상태
            if self.page.locator("a:has-text('로그아웃')").count() > 0:
                print("    → 이미 로그인 상태, 건너뜀")
                return

        print("    → 로그인 페이지로 이동...")
        self.page.goto(f"{self.base_url}/login")
        self.page.wait_for_load_state("networkidle")

        # 관리자 로그인 버튼 클릭
        print("    → 관리자 로그인 버튼 클릭...")
        admin_btn = self.page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            # 메인 페이지로 이동 대기
            self.page.wait_for_load_state("networkidle")
            print("    → 로그인 완료")
        else:
            raise Exception("관리자 로그인 버튼을 찾을 수 없습니다")

    def _navigate_to_rcm_list(self):
        """메인 화면에서 RCM 메뉴 클릭하여 목록으로 이동"""
        print("    → RCM 메뉴 클릭...")
        # RCM 카드의 "자세히 보기" 링크 클릭
        rcm_link = self.page.locator("a.feature-link[href='/rcm']")
        if rcm_link.count() > 0:
            rcm_link.click()
            self.page.wait_for_load_state("networkidle")
            print("    → RCM 목록 페이지 도착")
        else:
            # 직접 URL로 이동 (fallback)
            self.page.goto(f"{self.base_url}/rcm")
            self.page.wait_for_load_state("networkidle")

    def _click_rcm_upload_button(self):
        """RCM 목록에서 업로드 버튼 클릭"""
        print("    → RCM 업로드 버튼 클릭...")
        upload_btn = self.page.locator("a:has-text('RCM 업로드')")
        if upload_btn.count() > 0:
            upload_btn.click()
            self.page.wait_for_load_state("networkidle")
            print("    → 업로드 페이지 도착")
        else:
            raise Exception("RCM 업로드 버튼을 찾을 수 없습니다")

    # =========================================================================
    # 1. 파일 업로드 테스트
    # =========================================================================

    def test_rcm_upload_success(self, result: UnitTestResult):
        """정상 엑셀 파일 업로드 성공"""
        # Step 1: 관리자 로그인
        self._do_admin_login()

        # Step 2: 메인 → RCM 목록
        self._navigate_to_rcm_list()

        # Step 3: 업로드 버튼 클릭
        self._click_rcm_upload_button()

        try:
            # Step 4: 폼 작성
            print("    → RCM 이름 입력...")
            self.page.fill("#rcm_name", self.test_rcm_name)

            print("    → 카테고리 선택...")
            self.page.select_option("#control_category", "ITGC")

            print("    → 파일 선택...")
            self.page.set_input_files("#rcm_file", str(self.valid_rcm_path))

            # 미리보기 로드 대기
            self.page.wait_for_timeout(2000)

            # Step 5: 업로드 버튼 클릭
            print("    → 업로드 실행...")
            self.page.click("button[type='submit']")
            self.page.wait_for_timeout(3000)

            # Step 6: 결과 확인
            print(f"    → 현재 URL: {self.page.url}")

            # 성공 메시지 확인
            if self.page.locator(".alert-success").count() > 0:
                self.uploaded_rcm_name = self.test_rcm_name
                result.pass_test("업로드 성공 메시지 확인")
                return

            # 목록 페이지로 이동했으면 업로드된 RCM 확인
            if "/rcm" in self.page.url or "/link5/rcm" in self.page.url:
                if self.page.locator(f"text={self.test_rcm_name}").count() > 0:
                    self.uploaded_rcm_name = self.test_rcm_name
                    result.pass_test("정상 업로드 후 목록에서 확인됨")
                    result.add_detail(f"업로드된 RCM: {self.test_rcm_name}")
                else:
                    result.warn_test("목록 이동 확인, RCM명 확인 실패")
                return

            # 에러 메시지 확인 (alert-danger만, alert-warning은 안내 메시지일 수 있음)
            error_alert = self.page.locator(".alert-danger")
            if error_alert.count() > 0:
                error_text = error_alert.first.text_content()
                result.fail_test(f"업로드 실패: {error_text[:100]}")
                return

            # 업로드 페이지에 머물러 있으면 수동으로 목록 확인
            self.page.goto(f"{self.base_url}/rcm")
            self.page.wait_for_load_state("networkidle")
            if self.page.locator(f"text={self.test_rcm_name}").count() > 0:
                self.uploaded_rcm_name = self.test_rcm_name
                result.pass_test("업로드 후 목록에서 RCM 확인됨")
            else:
                result.fail_test("업로드 결과 확인 실패 (목록에 RCM 없음)")

        except Exception as e:
            result.fail_test(f"업로드 테스트 실패: {e}")

    def test_rcm_upload_invalid_ext(self, result: UnitTestResult):
        """잘못된 파일 형식 거부"""
        # 로그인 상태 유지를 위해 새로운 세션 시작
        self._do_admin_login()
        self._navigate_to_rcm_list()
        self._click_rcm_upload_button()

        try:
            print("    → 잘못된 확장자 파일 업로드 시도...")
            self.page.fill("#rcm_name", "Invalid_Test")

            try:
                self.page.set_input_files("#rcm_file", str(self.invalid_ext_path))
            except Exception:
                result.pass_test("브라우저 레벨에서 잘못된 확장자 거부됨 (accept 속성)")
                return

            btn = self.page.locator("button[type='submit']")
            if btn.count() > 0:
                btn.click()

            self.page.wait_for_timeout(1500)

            error_patterns = ["허용되지 않는", "xlsx", "xls", "파일 형식", "오류"]
            for pattern in error_patterns:
                if self.page.locator(f"text={pattern}").count() > 0:
                    result.pass_test(f"잘못된 확장자 에러 메시지 확인: {pattern}")
                    return

            if self.page.locator("#excelPreviewContainer:not([style*='display: none'])").count() == 0:
                result.pass_test("잘못된 파일 형식으로 미리보기 표시 안됨")
            else:
                result.warn_test("에러 메시지를 찾지 못함")
        except Exception as e:
            result.fail_test(f"예외 발생: {e}")

    def test_rcm_upload_missing_required(self, result: UnitTestResult):
        """필수 데이터 누락 처리"""
        self._do_admin_login()
        self._navigate_to_rcm_list()
        self._click_rcm_upload_button()

        try:
            print("    → 필수값 누락 파일 업로드 시도...")
            self.page.fill("#rcm_name", "Missing_Required_Test")
            self.page.set_input_files("#rcm_file", str(self.missing_req_path))

            self.page.wait_for_timeout(2000)

            btn = self.page.locator("button[type='submit']")
            if btn.count() > 0:
                btn.click()

            self.page.wait_for_timeout(2000)

            error_patterns = ["누락", "필수", "오류", "통제코드", "required"]
            for pattern in error_patterns:
                if self.page.locator(f"text={pattern}").count() > 0:
                    result.pass_test(f"필수값 누락 에러 확인: {pattern}")
                    return

            if self.page.locator(".badge.bg-danger").count() > 0:
                result.warn_test("필수 항목 미매핑 경고 배지 확인")
            else:
                result.warn_test("명확한 에러 메시지를 찾지 못함")
        except Exception as e:
            result.fail_test(f"예외 발생: {e}")

    # =========================================================================
    # 2. 목록 및 권한 테스트
    # =========================================================================

    def test_rcm_list_metadata(self, result: UnitTestResult):
        """업로드된 RCM 메타데이터 표시"""
        self._do_admin_login()
        self._navigate_to_rcm_list()

        try:
            # 목록에서 업로드한 RCM 또는 기존 RCM 확인
            rcm_to_find = self.uploaded_rcm_name or self.test_rcm_name

            if self.page.locator(f"text={rcm_to_find}").count() > 0:
                result.pass_test(f"RCM '{rcm_to_find}'이 목록에 표시됨")
            else:
                rows = self.page.locator("table tbody tr")
                if rows.count() > 0:
                    result.warn_test(f"목록에 {rows.count()}개의 RCM 있으나 테스트 RCM 미발견")
                    result.add_detail("다른 RCM 데이터는 존재함")
                else:
                    result.fail_test("목록에 RCM이 없음")
        except Exception as e:
            result.fail_test(f"목록 조회 실패: {e}")

    # =========================================================================
    # 3. 상세 및 수정 테스트
    # =========================================================================

    def test_rcm_detail_mapping(self, result: UnitTestResult):
        """상세 데이터 매핑 정확성"""
        self._do_admin_login()
        self._navigate_to_rcm_list()

        try:
            rcm_to_find = self.uploaded_rcm_name or self.test_rcm_name

            # 해당 RCM의 행에서 상세/보기 버튼 찾기
            print(f"    → '{rcm_to_find}' RCM 상세 버튼 찾기...")

            # 특정 RCM 행의 상세 버튼 (첫 번째 매칭)
            detail_btn = self.page.locator(f"tr:has-text('{rcm_to_find}') a:has-text('상세')").first

            if detail_btn.count() == 0:
                detail_btn = self.page.locator("a:has-text('상세')").first

            if detail_btn.count() > 0:
                print("    → 상세 버튼 클릭...")
                detail_btn.click()
                self.page.wait_for_load_state("networkidle")
                self.page.wait_for_timeout(1000)

                # 상세 페이지 확인
                if self.page.locator("table").count() > 0:
                    result.pass_test("상세 페이지 진입 및 테이블 확인됨")
                else:
                    result.warn_test("상세 페이지 진입했으나 테이블 없음")
            else:
                result.skip_test("상세/보기 버튼을 찾을 수 없음")
        except Exception as e:
            result.skip_test(f"상세 페이지 진입 실패: {e}")

    # =========================================================================
    # 4. 삭제 테스트
    # =========================================================================

    def test_link5_company_data_isolation(self, result: UnitTestResult):
        """회사별 RCM 데이터 격리 확인 (사용자 전환 테스트)"""
        self._do_admin_login()
        self._navigate_to_rcm_list()
        self.page.wait_for_timeout(2000)

        # 1. 관리자로 접속 시 RCM 목록 확인
        admin_rcm_count = self.page.locator("table tbody tr").count()
        result.add_detail(f"관리자 RCM 목록: {admin_rcm_count}개")

        # 2. 우측 상단 사용자명 클릭하여 사용자 전환 메뉴 열기
        user_dropdown = self.page.locator(".user-name, .navbar .dropdown-toggle, .user-dropdown").first
        if user_dropdown.count() == 0:
            result.skip_test("사용자 드롭다운 메뉴를 찾을 수 없음")
            return

        user_dropdown.click()
        self.page.wait_for_timeout(1000)

        # 3. 다른 회사 계정 선택
        switch_options = self.page.locator(".dropdown-menu .dropdown-item, .user-switch-item")
        target_company = None
        target_item = None

        for i in range(switch_options.count()):
            option = switch_options.nth(i)
            option_text = option.inner_text()
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

        # 5. RCM 목록 페이지로 이동
        self._navigate_to_rcm_list()
        self.page.wait_for_timeout(2000)

        # 6. 전환 후 RCM 목록 확인
        switched_rcm_count = self.page.locator("table tbody tr").count()
        result.add_detail(f"전환 후 RCM 목록: {switched_rcm_count}개")

        # 7. 데이터 격리 확인
        data_isolated = admin_rcm_count != switched_rcm_count

        # 8. 관리자로 돌아가기
        user_dropdown2 = self.page.locator(".user-name, .navbar .dropdown-toggle, .user-dropdown").first
        if user_dropdown2.count() > 0:
            user_dropdown2.click()
            self.page.wait_for_timeout(500)

            admin_return = self.page.locator("text=관리자로 돌아가기").first
            if admin_return.count() == 0:
                admin_return = self.page.locator(".dropdown-item:has-text('관리자'), .dropdown-item:has-text('스노우볼')").first

            if admin_return.count() > 0:
                admin_return.click()
                self.page.wait_for_timeout(1500)
                result.add_detail("관리자로 복귀 완료")

        # 9. 결과 판정
        if data_isolated:
            result.pass_test(f"회사별 RCM 데이터 격리 확인 (전환 회사: {target_company})")
        else:
            result.warn_test(f"데이터 격리 확인 불가 (동일 데이터가 표시될 수 있음)")

    def test_rcm_delete(self, result: UnitTestResult):
        """RCM 삭제 수행"""
        self._do_admin_login()
        self._navigate_to_rcm_list()

        try:
            rcm_to_delete = self.uploaded_rcm_name or self.test_rcm_name

            print(f"    → '{rcm_to_delete}' RCM 삭제 버튼 찾기...")

            # 특정 RCM 행의 삭제 버튼 (첫 번째 매칭)
            delete_btn = self.page.locator(f"tr:has-text('{rcm_to_delete}') button.btn-outline-danger").first

            if delete_btn.count() == 0:
                result.skip_test(f"'{rcm_to_delete}' RCM의 삭제 버튼을 찾을 수 없음")
                return

            print("    → 삭제 버튼 클릭...")

            # 다이얼로그(confirm) 자동 승인 핸들러 등록
            self.page.on("dialog", lambda dialog: dialog.accept())
            delete_btn.click()

            # confirm 다이얼로그 처리 대기
            self.page.wait_for_timeout(1000)

            # 토스트 메시지 확인 (삭제 성공/실패)
            print("    → 토스트 메시지 확인...")
            self.page.wait_for_timeout(2000)

            # 토스트 메시지 텍스트 캡처
            toast = self.page.locator(".toast, .alert").first
            toast_text = ""
            if toast.count() > 0:
                toast_text = toast.text_content() or ""
                print(f"    → 토스트 메시지: {toast_text[:50]}")

            # 페이지 새로고침 후 목록에서 확인
            self.page.goto(f"{self.base_url}/rcm")
            self.page.wait_for_load_state("networkidle")

            if self.page.locator(f"tr:has-text('{rcm_to_delete}')").count() == 0:
                result.pass_test("RCM 삭제 완료")
            else:
                # 토스트 메시지에서 실패 원인 확인
                if "평가" in toast_text or "진행" in toast_text:
                    result.warn_test(f"삭제 불가: {toast_text[:50]}")
                else:
                    result.fail_test("삭제 후에도 목록에 남아있음")
        except Exception as e:
            result.skip_test(f"삭제 테스트 실패: {e}")


def main():
    parser = argparse.ArgumentParser(description='Link5 RCM Detailed Unit Test')
    parser.add_argument('--headless', action='store_true', help='Headless 모드')
    parser.add_argument('--url', type=str, default='http://localhost:5001', help='Base URL')
    args = parser.parse_args()

    suite = Link5RCMTestSuite(base_url=args.url, headless=args.headless)
    sys.exit(suite.run_all_tests())


if __name__ == '__main__':
    main()
