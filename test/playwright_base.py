"""
Playwright Unit 테스트를 위한 베이스 클래스 및 유틸리티

Playwright를 활용한 엔드투엔드 테스트의 기본 기능을 제공합니다.
- 브라우저 설정
- 공통 페이지 액션
- 스크린샷 캡처
- 테스트 결과 리포팅
"""

import os
import sys
import re
import time
import subprocess
import requests
from pathlib import Path
from datetime import datetime
from typing import Optional, Dict, Any, List
from enum import Enum
import json

from playwright.sync_api import Page, Browser, BrowserContext, Playwright, sync_playwright, expect

# 프로젝트 루트 경로
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))


class TestStatus(Enum):
    """테스트 상태"""
    RUNNING = "🔄"
    PASSED = "✅"
    FAILED = "❌"
    WARNING = "⚠️"
    SKIPPED = "⊘"


class UnitTestResult:
    """Unit 테스트 결과 클래스"""

    def __init__(self, test_name: str, category: str):
        self.test_name = test_name
        self.category = category
        self.status = TestStatus.RUNNING
        self.message = ""
        self.details: List[str] = []
        self.screenshots: List[str] = []
        self.start_time: Optional[datetime] = None
        self.end_time: Optional[datetime] = None

    def start(self):
        """테스트 시작"""
        self.start_time = datetime.now()
        self.status = TestStatus.RUNNING

    def pass_test(self, message: str = "테스트 통과"):
        """테스트 성공"""
        self.status = TestStatus.PASSED
        self.message = message
        self.end_time = datetime.now()

    def fail_test(self, message: str):
        """테스트 실패"""
        self.status = TestStatus.FAILED
        self.message = message
        self.end_time = datetime.now()

    def warn_test(self, message: str):
        """테스트 경고"""
        self.status = TestStatus.WARNING
        self.message = message
        self.end_time = datetime.now()

    def skip_test(self, message: str = "건너뜀"):
        """테스트 건너뛰기"""
        self.status = TestStatus.SKIPPED
        self.message = message
        self.end_time = datetime.now()

    def add_detail(self, detail: str):
        """상세 정보 추가"""
        self.details.append(detail)

    def add_screenshot(self, screenshot_path: str):
        """스크린샷 경로 추가"""
        self.screenshots.append(screenshot_path)

    def get_duration(self) -> float:
        """테스트 소요 시간 (초)"""
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        return 0.0

    def __str__(self):
        duration_str = f"({self.get_duration():.2f}s)" if self.end_time else ""
        return f"{self.status.value} {self.test_name} {duration_str} - {self.message}"


class PlaywrightTestBase:
    """Playwright Unit 테스트 베이스 클래스"""

    def __init__(self, base_url: str = "http://localhost:5000", headless: bool = True, slow_mo: int = 0):
        """
        Args:
            base_url: 테스트할 애플리케이션의 기본 URL
            headless: 헤드리스 모드 실행 여부
            slow_mo: 동작 사이의 지연 시간 (밀리초)
        """
        self.base_url = base_url
        self.headless = headless
        self.slow_mo = slow_mo
        self.playwright: Optional[Playwright] = None
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None
        self.results: List[UnitTestResult] = []

        # 서버 관리
        self.server_process: Optional[subprocess.Popen] = None
        self.server_was_running: bool = False  # 기존 서버가 실행 중이었는지

        # 스크린샷 저장 디렉토리
        self.screenshot_dir = project_root / "test" / "screenshots"
        self.screenshot_dir.mkdir(exist_ok=True)

    def check_server_running(self) -> bool:
        """서버 실행 상태 확인 및 강제 재시작 (환경변수 반영을 위함)"""
        port = int(self.base_url.split(':')[-1])
        
        # 해당 포트를 사용하는 프로세스 강제 종료 (Windows)
        print(f"🧹 기존 포트({port}) 정리 중...")
        try:
            # netstat로 PID 찾기
            find_pid_cmd = f"netstat -ano | findstr LISTENING | findstr :{port}"
            output = subprocess.check_output(find_pid_cmd, shell=True).decode()
            for line in output.splitlines():
                parts = line.strip().split()
                if len(parts) > 4 and parts[1].endswith(f":{port}"):
                    pid = parts[-1]
                    if pid != "0" and int(pid) != os.getpid():
                        subprocess.run(["taskkill", "/F", "/PID", pid], capture_output=True)
                        print(f"   종료된 PID: {pid}")
        except:
            pass

        print(f"🚀 서버를 새로 시작합니다... (Base URL: {self.base_url})")
        self.server_was_running = False
        return self._start_server()

    def _start_server(self) -> bool:
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

    def stop_server(self):
        """서버 중지 (직접 시작한 경우에만)"""
        if self.server_process and not self.server_was_running:
            print(f"\n🛑 서버 중지 중... (PID: {self.server_process.pid})")
            try:
                if sys.platform == 'win32':
                    self.server_process.terminate()
                else:
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

    def setup(self):
        """테스트 환경 설정"""
        self.playwright = sync_playwright().start()

        # Chromium 브라우저 실행 (Firefox, WebKit도 가능)
        self.browser = self.playwright.chromium.launch(
            headless=self.headless,
            slow_mo=self.slow_mo
        )

        # 브라우저 컨텍스트 생성 (쿠키, 세션 격리)
        self.context = self.browser.new_context(
            viewport={"width": 1920, "height": 1080},
            locale="ko-KR",
            timezone_id="Asia/Seoul",
        )

        # 새 페이지 생성
        self.page = self.context.new_page()

    def teardown(self):
        """테스트 환경 정리"""
        if self.page:
            self.page.close()
        if self.context:
            self.context.close()
        if self.browser:
            self.browser.close()
        if self.playwright:
            self.playwright.stop()

    def navigate_to(self, path: str = ""):
        """페이지 이동"""
        url = f"{self.base_url}{path}"
        self.page.goto(url, wait_until="networkidle")
        return self.page

    def take_screenshot(self, name: str) -> str:
        """스크린샷 캡처"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{name}_{timestamp}.png"
        filepath = self.screenshot_dir / filename
        self.page.screenshot(path=str(filepath), full_page=True)
        return str(filepath)

    def wait_for_selector(self, selector: str, timeout: int = 5000):
        """선택자가 나타날 때까지 대기"""
        return self.page.wait_for_selector(selector, timeout=timeout)

    def click_button(self, selector: str):
        """버튼 클릭"""
        self.page.click(selector)

    def fill_input(self, selector: str, value: str):
        """입력 필드 채우기"""
        self.page.fill(selector, value)

    def select_option(self, selector: str, value: str):
        """드롭다운에서 옵션 선택"""
        self.page.select_option(selector, value)

    def get_text(self, selector: str) -> str:
        """텍스트 가져오기 (공백 정규화)"""
        text = self.page.text_content(selector) or ""
        # HTML 공백/줄바꿈을 단일 공백으로 정규화
        return re.sub(r'\s+', ' ', text).strip()

    def is_visible(self, selector: str) -> bool:
        """요소가 보이는지 확인"""
        return self.page.is_visible(selector)

    def wait_for_navigation(self, action_fn):
        """네비게이션 대기"""
        with self.page.expect_navigation():
            action_fn()

    def check_element_exists(self, selector: str) -> bool:
        """요소 존재 확인"""
        try:
            self.page.wait_for_selector(selector, timeout=2000)
            return True
        except:
            return False

    def run_category(self, category_name: str, tests: List):
        """카테고리별 테스트 실행"""
        print(f"\n{'=' * 80}")
        print(f"{category_name}")
        print(f"{'=' * 80}")

        for test_func in tests:
            result = UnitTestResult(test_func.__name__, category_name)
            self.results.append(result)

            try:
                result.start()
                print(f"\n{TestStatus.RUNNING.value} {test_func.__name__}...", end=" ")

                # 각 테스트마다 새로운 페이지 컨텍스트 사용 (격리)
                test_func(result)

                if result.status == TestStatus.RUNNING:
                    result.pass_test()

                print(f"\r{result}")

                # 상세 정보 출력
                if result.details:
                    for detail in result.details:
                        print(f"    ℹ️  {detail}")

                # 스크린샷 정보 출력
                if result.screenshots:
                    for screenshot in result.screenshots:
                        print(f"    📷 Screenshot: {screenshot}")

            except Exception as e:
                result.fail_test(f"예외 발생: {str(e)}")
                print(f"\r{result}")
                print(f"    ❌ {result.message}")

                # 실패 시 스크린샷 캡처
                try:
                    screenshot = self.take_screenshot(f"error_{test_func.__name__}")
                    result.add_screenshot(screenshot)
                    print(f"    📷 Error Screenshot: {screenshot}")
                except:
                    pass

    def print_final_report(self):
        """최종 리포트 출력 (콘솔 전용)"""
        print("\n" + "=" * 80)
        print("Unit 테스트 결과 요약")
        print("=" * 80)

        status_counts = {status: 0 for status in TestStatus}
        for result in self.results:
            status_counts[result.status] += 1

        total = len(self.results)
        if total == 0:
            print("실행된 테스트가 없습니다.")
            return

        passed = status_counts[TestStatus.PASSED]
        failed = status_counts[TestStatus.FAILED]
        warning = status_counts[TestStatus.WARNING]
        skipped = status_counts[TestStatus.SKIPPED]

        print(f"\n총 테스트: {total}개")
        print(f"{TestStatus.PASSED.value} 통과: {passed}개 ({passed/total*100:.1f}%)")
        print(f"{TestStatus.FAILED.value} 실패: {failed}개 ({failed/total*100:.1f}%)")
        print(f"{TestStatus.WARNING.value} 경고: {warning}개 ({warning/total*100:.1f}%)")
        print(f"{TestStatus.SKIPPED.value} 건너뜀: {skipped}개 ({skipped/total*100:.1f}%)")

        return 0 if failed == 0 else 1

    def _update_checklist_result(self):
        """테스트 결과를 체크리스트 마크다운 파일에 업데이트"""
        if not hasattr(self, 'checklist_source') or not hasattr(self, 'checklist_result'):
            return

        print(f"📄 결과 리포트 업데이트 중: {self.checklist_result}")
        
        try:
            # 원본 체크리스트 읽기
            with open(self.checklist_source, 'r', encoding='utf-8') as f:
                content = f.read()

            # 테스트 결과 매핑
            for result in self.results:
                # 체크리스트 항목 패턴 찾기 (예: - [ ] **test_xxx**)
                pattern = rf"- \[ \] \*\*{result.test_name}\*\*"
                if result.status == TestStatus.PASSED:
                    content = re.sub(pattern, f"- [x] **{result.test_name}**", content)
                elif result.status == TestStatus.FAILED:
                    content = re.sub(pattern, f"- [!] **{result.test_name}** (FAILED)", content)

            # 결과 요약 추가
            summary = self._generate_markdown_summary()
            content = f"<!-- Test Run: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')} -->\n" + content + "\n\n" + summary

            # 결과 파일 저장 (UTF-8)
            with open(self.checklist_result, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print(f"✅ 결과 리포트 저장 완료")
        except Exception as e:
            print(f"⚠️ 리포트 업데이트 중 오류: {e}")

    def _generate_markdown_summary(self) -> str:
        """마크다운 형식의 결과 요약 생성"""
        status_counts = {status: 0 for status in TestStatus}
        for result in self.results:
            status_counts[result.status] += 1

        total = len(self.results)
        if total == 0: return ""

        passed = status_counts[TestStatus.PASSED]
        failed = status_counts[TestStatus.FAILED]
        warning = status_counts[TestStatus.WARNING]
        skipped = status_counts[TestStatus.SKIPPED]

        summary = f"## 테스트 결과 요약\n\n"
        summary += f"| 항목 | 개수 | 비율 |\n"
        summary += f"|------|------|------|\n"
        summary += f"| ✅ 통과 | {passed} | {passed/total*100:.1f}% |\n"
        summary += f"| ❌ 실패 | {failed} | {failed/total*100:.1f}% |\n"
        summary += f"| ⚠️ 경고 | {warning} | {warning/total*100:.1f}% |\n"
        summary += f"| ⊘ 건너뜀 | {skipped} | {skipped/total*100:.1f}% |\n"
        summary += f"| **총계** | **{total}** | **100%** |\n"
        
        return summary

    def save_json_report(self, report_name: str):
        """JSON 리포트 저장 (테스트 완료 후 자동 삭제)"""
        # JSON 리포트는 더 이상 생성하지 않음 (텍스트 파일로 대체)
        # 기존 JSON 파일들 정리
        test_dir = project_root / 'test'
        for json_file in test_dir.glob('*_unit_report_*.json'):
            try:
                os.remove(json_file)
            except:
                pass

        return None

    def cleanup_generated_files(self):
        """테스트 과정에서 생성된 파일 정리"""
        test_dir = project_root / 'test'

        # 스크린샷 정리
        screenshot_dir = test_dir / 'screenshots'
        if screenshot_dir.exists():
            for screenshot in screenshot_dir.glob('*.png'):
                try:
                    os.remove(screenshot)
                except:
                    pass

        # JSON 리포트 정리
        for json_file in test_dir.glob('*_unit_report_*.json'):
            try:
                os.remove(json_file)
            except:
                pass

        print(f"\n🧹 생성된 파일 정리 완료")


class PageHelper:
    """페이지별 공통 액션 헬퍼"""

    @staticmethod
    def login_with_otp(page: Page, email: str, otp_code: str):
        """OTP를 사용한 로그인"""
        # 로그인 페이지로 이동
        page.goto("http://localhost:5000/login")

        # 이메일 입력
        page.fill("input[name='email']", email)
        page.click("button[type='submit']")

        # OTP 입력 (OTP 페이지로 전환 대기)
        page.wait_for_selector("input[name='otp']", timeout=5000)
        page.fill("input[name='otp']", otp_code)
        page.click("button[type='submit']")

        # 로그인 완료 대기 (메인 페이지로 리다이렉트)
        page.wait_for_url("**/main", timeout=5000)

    @staticmethod
    def logout(page: Page):
        """로그아웃"""
        page.goto("http://localhost:5000/logout")

    @staticmethod
    def check_alert_message(page: Page, expected_text: str) -> bool:
        """알림 메시지 확인"""
        try:
            alert = page.locator(".alert, .flash-message, .message")
            return expected_text in alert.text_content()
        except:
            return False
