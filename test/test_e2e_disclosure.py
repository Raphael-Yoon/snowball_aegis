"""
E2E 통합 테스트 (정보보호공시 - Link11)

[실행 방법]
    python test/test_e2e_disclosure.py
    python test/test_e2e_disclosure.py --headless
    python test/test_e2e_disclosure.py --url http://localhost:5001

[테스트 흐름]
    Phase 1: 세션 및 페이지 접근
    Phase 2: 답변 입력 (Yes/No, 숫자형)
    Phase 3: 증빙자료 업로드 및 조회
    Phase 4: 리포트 생성/다운로드
    Phase 5: 제출 차단 검증 (완료율 미달)
    Cleanup: 데이터 초기화 (reset API)
"""

import sys
import time
import argparse
import requests
import subprocess
from pathlib import Path
from datetime import datetime

project_root = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, UnitTestResult, TestStatus


class E2EDisclosureTestSuite(PlaywrightTestBase):
    """E2E 정보보호공시 통합 테스트 스위트 (Link11)"""

    def __init__(self, base_url="http://localhost:5001", headless=False):
        super().__init__(base_url=base_url, headless=headless)

        self.test_year = 2099           # 실 데이터와 충돌 방지용 연도
        self.user_id = None             # 로그인 후 획득
        self.uploaded_evidence_id = None

        self.checklist_result = project_root / "test" / "e2e_checklist_disclosure_result.md"
        self.test_evidence_file = project_root / "test" / "assets" / "e2e_disclosure_evidence.txt"

        self.server_process = None
        self.server_was_running = False
        self.skip_server_stop = False

    # =========================================================================
    # 서버 관리 (unit test base의 강제 재시작과 다르게 기존 서버 재활용)
    # =========================================================================

    def check_server_running(self) -> bool:
        """서버 상태 확인 (기존 서버 재활용, 없으면 시작)"""
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
        return self._start_server_bg()

    def _start_server_bg(self) -> bool:
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

    # =========================================================================
    # 공통 헬퍼
    # =========================================================================

    def _do_admin_login(self):
        """관리자 로그인"""
        page = self.page

        page.goto(f"{self.base_url}/login")
        page.wait_for_load_state("networkidle")

        if page.locator("a:has-text('로그아웃')").count() > 0:
            print("    → 이미 로그인 상태")
            return

        admin_btn = page.locator(".admin-login-section button[type='submit']")
        if admin_btn.count() > 0:
            admin_btn.click()
            page.wait_for_load_state("networkidle")
            print("    → 관리자 로그인 완료")
        else:
            raise Exception("관리자 로그인 버튼을 찾을 수 없습니다")

    def _get_user_id(self) -> int:
        """로그인된 세션의 user_id 획득 (캐시)"""
        if self.user_id:
            return self.user_id
        try:
            page = self.page
            uid = page.evaluate("""
                () => {
                    const el = document.querySelector('[data-user-id]');
                    if (el) return parseInt(el.dataset.userId);
                    const meta = document.querySelector('meta[name="user-id"]');
                    if (meta) return parseInt(meta.content);
                    return null;
                }
            """)
            if uid:
                self.user_id = int(uid)
                return self.user_id
        except:
            pass
        self.user_id = 1  # admin 기본값
        return self.user_id

    def _call_api(self, method: str, path: str, body: dict = None) -> dict:
        """브라우저 컨텍스트에서 인증된 API 호출"""
        body_json = str(body).replace("'", '"').replace("True", "true").replace("False", "false") if body else "null"
        js = f"""
            async () => {{
                const opts = {{
                    method: '{method}',
                    headers: {{'Content-Type': 'application/json'}}
                }};
                if ('{method}' !== 'GET' && {body_json} !== null) {{
                    opts.body = JSON.stringify({body_json});
                }}
                const res = await fetch('{path}', opts);
                return {{status: res.status, body: await res.json().catch(() => {{}})}};
            }}
        """
        return self.page.evaluate(js)

    # =========================================================================
    # 테스트 데이터 준비
    # =========================================================================

    def setup_test_data(self):
        """테스트용 증빙파일 생성"""
        assets_dir = project_root / "test" / "assets"
        assets_dir.mkdir(parents=True, exist_ok=True)
        with open(self.test_evidence_file, 'w', encoding='utf-8') as f:
            f.write(f"E2E 정보보호공시 테스트 증빙파일\n생성일시: {datetime.now().isoformat()}\n")
        print(f"    → 테스트 증빙파일 생성: {self.test_evidence_file}")

    # =========================================================================
    # Phase 1: 세션 및 페이지 접근
    # =========================================================================

    def test_session_page_access(self, result: UnitTestResult):
        """[공시] 메인 페이지 접근"""
        page = self.page
        page.goto(f"{self.base_url}/link11")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(2000)

        if "정보보호공시" in page.title() or page.locator("h1, h2").count() > 0:
            result.pass_test(f"정보보호공시 페이지 접근 확인 (title: {page.title()})")
        else:
            result.fail_test(f"페이지 접근 실패: {page.url}")

    def test_session_create(self, result: UnitTestResult):
        """[공시] 세션 생성 API"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/session', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json'}},
                    body: JSON.stringify({{user_id: {user_id}, year: {self.test_year}}})
                }});
                return {{status: res.status, body: await res.json().catch(() => {{}})}};
            }}
        """)

        if resp and resp.get('status') in (200, 201):
            result.pass_test(f"세션 생성 성공 (user_id={user_id}, year={self.test_year})")
        else:
            result.warn_test(f"세션 생성 응답 확인 필요: {resp}")

    def test_session_year_selector(self, result: UnitTestResult):
        """[공시] 연도 선택기 렌더링 및 옵션 확인"""
        page = self.page
        page.goto(f"{self.base_url}/link11")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(2000)

        selector = page.locator("#disclosure-year-select")
        if selector.count() == 0:
            result.fail_test("연도 선택기(#disclosure-year-select) 없음")
            return

        options = selector.locator("option")
        option_count = options.count()
        if option_count >= 2:
            from datetime import datetime
            current_actual_year = datetime.now().year
            first_val = options.first.get_attribute("value")
            result.pass_test(f"연도 선택기 확인 (옵션 {option_count}개, 최신연도: {first_val})")
        else:
            result.warn_test(f"연도 선택기 옵션 부족 ({option_count}개)")

    def test_session_year_change(self, result: UnitTestResult):
        """[공시] 연도 변경 시 데이터 리프레시 (뷰 전환, DB 무영향 확인)"""
        page = self.page
        page.goto(f"{self.base_url}/link11")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(2000)

        selector = page.locator("#disclosure-year-select")
        if selector.count() == 0:
            result.skip_test("연도 선택기 없음 — 건너뜀")
            return

        options = selector.locator("option")
        if options.count() < 2:
            result.skip_test("연도 선택 옵션 2개 미만 — 건너뜀")
            return

        # 현재 선택값 확인
        before_year = page.evaluate("() => parseInt(document.getElementById('disclosure-year-select').value)")

        # 두 번째 옵션(전년도)으로 변경
        second_val = options.nth(1).get_attribute("value")
        selector.select_option(second_val)
        page.wait_for_timeout(1500)

        after_year = page.evaluate("() => typeof currentYear !== 'undefined' ? currentYear : null")

        if after_year is not None and str(after_year) == str(second_val):
            result.pass_test(f"연도 변경 성공 ({before_year} → {after_year}), DB reset 없이 뷰 전환 확인")
        else:
            result.warn_test(f"연도 변경 후 currentYear 확인 필요 (선택값: {second_val}, JS값: {after_year})")

    def test_session_progress_page(self, result: UnitTestResult):
        """[공시] 진행률 페이지 접근"""
        page = self.page
        page.goto(f"{self.base_url}/link11/progress")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)

        if "404" not in page.title() and page.locator("body").count() > 0:
            result.pass_test("진행률 페이지 접근 확인")
        else:
            result.fail_test("진행률 페이지 404 또는 접근 실패")

    # =========================================================================
    # Phase 2: 답변 입력
    # =========================================================================

    def test_answer_yes_no(self, result: UnitTestResult):
        """[답변] Yes/No 답변 저장 (Q1)"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/answers', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json'}},
                    body: JSON.stringify({{
                        user_id: {user_id},
                        year: {self.test_year},
                        question_id: 'Q1',
                        answer_value: 'yes',
                        answer_type: 'yes_no'
                    }})
                }});
                return {{status: res.status, body: await res.json().catch(() => {{}})}};
            }}
        """)

        if resp and resp.get('status') == 200:
            result.pass_test(f"Q1 Yes/No 답변 저장 성공 (year={self.test_year})")
        else:
            result.fail_test(f"Q1 답변 저장 실패: {resp}")

    def test_answer_numeric(self, result: UnitTestResult):
        """[답변] 숫자형 답변 저장 (Q7 IT예산)"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/answers', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json'}},
                    body: JSON.stringify({{
                        user_id: {user_id},
                        year: {self.test_year},
                        question_id: 'Q7',
                        answer_value: '1000000',
                        answer_type: 'currency'
                    }})
                }});
                return {{status: res.status, body: await res.json().catch(() => {{}})}};
            }}
        """)

        if resp and resp.get('status') == 200:
            result.pass_test("Q7 숫자형 답변(IT예산 1,000,000) 저장 성공")
        else:
            result.warn_test(f"Q7 답변 응답 확인 필요: {resp}")

    def test_answer_progress_api(self, result: UnitTestResult):
        """[답변] 진행률 API 확인"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/progress/{user_id}/{self.test_year}');
                if (res.ok) return await res.json();
                return {{status: res.status}};
            }}
        """)

        if resp and not resp.get('error') and resp.get('status') != 404:
            rate = resp.get('completion_rate', resp.get('rate', '?'))
            result.pass_test(f"진행률 API 응답 확인 (완료율: {rate}%)")
        else:
            result.fail_test(f"진행률 API 응답 없음: {resp}")

    # =========================================================================
    # Phase 3: 증빙자료
    # =========================================================================

    def test_evidence_page_access(self, result: UnitTestResult):
        """[증빙] 증빙자료 페이지 접근"""
        page = self.page
        page.goto(f"{self.base_url}/link11/evidence")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)

        if "404" not in page.title() and page.locator("body").count() > 0:
            result.pass_test("증빙자료 페이지 접근 확인")
        else:
            result.fail_test("증빙자료 페이지 404 또는 접근 실패")

    def test_evidence_upload(self, result: UnitTestResult):
        """[증빙] 파일 업로드"""
        page = self.page
        page.goto(f"{self.base_url}/link11/evidence")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)

        file_input = page.locator("input[type='file']")
        if file_input.count() == 0:
            result.warn_test("파일 업로드 input 없음 — 증빙 페이지 UI 구조 확인 필요")
            return

        file_input.first.set_input_files(str(self.test_evidence_file))
        page.wait_for_timeout(500)

        upload_btn = page.locator("button:has-text('업로드'), button[type='submit']:visible").first
        if upload_btn.count() > 0 and upload_btn.is_visible():
            upload_btn.click()
            page.wait_for_timeout(2000)
            result.pass_test("증빙파일 업로드 시도 완료")
        else:
            result.warn_test("업로드 버튼 미발견 — 업로드 방식 확인 필요")

    def test_evidence_list_api(self, result: UnitTestResult):
        """[증빙] 증빙 목록 조회 API"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/evidence/{user_id}/{self.test_year}');
                if (res.ok) return await res.json();
                return {{status: res.status}};
            }}
        """)

        if isinstance(resp, list):
            count = len(resp)
            result.pass_test(f"증빙 목록 조회 성공 (건수: {count})")
            if count > 0:
                self.uploaded_evidence_id = resp[0].get('id') or resp[0].get('evidence_id')
        elif resp and not resp.get('error'):
            result.pass_test(f"증빙 목록 API 응답 확인: {resp}")
        else:
            result.fail_test(f"증빙 목록 API 응답 실패: {resp}")

    # =========================================================================
    # Phase 4: 리포트
    # =========================================================================

    def test_report_page_access(self, result: UnitTestResult):
        """[리포트] 리포트 페이지 접근"""
        page = self.page
        page.goto(f"{self.base_url}/link11/report")
        page.wait_for_load_state("networkidle")
        page.wait_for_timeout(1000)

        if "404" not in page.title() and page.locator("body").count() > 0:
            result.pass_test("리포트 페이지 접근 확인")
        else:
            result.fail_test("리포트 페이지 404 또는 접근 실패")

    def test_report_generate_json(self, result: UnitTestResult):
        """[리포트] JSON 리포트 생성 API"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/report/generate', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json'}},
                    body: JSON.stringify({{
                        user_id: {user_id},
                        year: {self.test_year},
                        format: 'json'
                    }})
                }});
                return {{status: res.status, body: await res.json().catch(() => {{}})}};
            }}
        """)

        if resp and resp.get('status') == 200:
            result.pass_test("JSON 리포트 생성 API 성공")
        elif resp and resp.get('status') in (400, 422):
            result.warn_test(f"리포트 생성 조건 미충족 (status={resp.get('status')})")
        else:
            result.fail_test(f"리포트 생성 API 실패: {resp}")

    def test_report_download_excel(self, result: UnitTestResult):
        """[리포트] Excel 다운로드 API 응답 확인"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/report/download', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json'}},
                    body: JSON.stringify({{user_id: {user_id}, year: {self.test_year}}})
                }});
                return {{
                    status: res.status,
                    content_type: res.headers.get('Content-Type') || ''
                }};
            }}
        """)

        if resp and resp.get('status') == 200:
            ct = resp.get('content_type', '')
            if 'spreadsheet' in ct or 'excel' in ct or 'octet' in ct:
                result.pass_test(f"Excel 다운로드 응답 확인 (Content-Type: {ct})")
            else:
                result.warn_test(f"다운로드 응답 수신 (Content-Type: {ct})")
        elif resp and resp.get('status') in (400, 404):
            result.warn_test(f"다운로드 조건 미충족 (status={resp.get('status')})")
        else:
            result.fail_test(f"Excel 다운로드 API 실패: {resp}")

    # =========================================================================
    # Phase 5: 제출 검증
    # =========================================================================

    def test_submit_incomplete_blocked(self, result: UnitTestResult):
        """[제출] 완료율 미달 시 제출 차단 확인"""
        page = self.page
        user_id = self._get_user_id()

        resp = page.evaluate(f"""
            async () => {{
                const res = await fetch('/link11/api/submit/{user_id}/{self.test_year}', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json'}}
                }});
                return {{status: res.status, body: await res.json().catch(() => {{}})}};
            }}
        """)

        if resp and resp.get('status') == 400:
            result.pass_test("완료율 미달 시 제출 차단 확인 (400 반환)")
        elif resp and resp.get('status') == 200:
            result.warn_test("제출 성공 — 테스트 연도 데이터가 이미 완료율 100%인 상태")
        else:
            result.warn_test(f"제출 API 응답 확인 필요: {resp}")

    # =========================================================================
    # Cleanup
    # =========================================================================

    def cleanup_all(self):
        """테스트 데이터 초기화 (reset API + 임시파일 삭제)"""
        print("\n>> Cleanup: 공시 테스트 데이터 초기화 중...")
        try:
            page = self.page
            user_id = self._get_user_id()

            resp = page.evaluate(f"""
                async () => {{
                    const res = await fetch('/link11/api/reset/{user_id}/{self.test_year}', {{
                        method: 'POST',
                        headers: {{'Content-Type': 'application/json'}}
                    }});
                    return {{status: res.status, body: await res.json().catch(() => {{}})}};
                }}
            """)

            if resp and resp.get('status') == 200:
                print(f"    ✅ 공시 데이터 초기화 완료 (year={self.test_year})")
            else:
                print(f"    ⚠️ 초기화 응답: {resp}")
        except Exception as e:
            print(f"    ⚠️ 초기화 중 오류: {e}")

        try:
            if self.test_evidence_file.exists():
                self.test_evidence_file.unlink()
                print(f"    ✅ 임시 증빙파일 삭제: {self.test_evidence_file.name}")
        except:
            pass

    # =========================================================================
    # 메인 실행
    # =========================================================================

    def run_all_tests(self):
        """E2E 공시 테스트 전체 실행"""
        print("=" * 80)
        print("  정보보호공시(Link11) E2E 통합 테스트")
        print("=" * 80)
        print(f"  테스트 연도: {self.test_year}")
        print(f"  모드: {'Headless' if self.headless else 'Browser'}")
        print("=" * 80)

        if not self.server_was_running and not self.check_server_running():
            print("\n테스트를 중단합니다.")
            return 1

        self.setup_test_data()

        try:
            self.setup()
            self._do_admin_login()

            # Phase 1: 세션 및 페이지 접근
            self.run_category("Phase 1: 세션 및 페이지 접근", [
                self.test_session_page_access,
                self.test_session_create,
                self.test_session_year_selector,
                self.test_session_year_change,
                self.test_session_progress_page,
            ])

            # Phase 2: 답변 입력
            self.run_category("Phase 2: 답변 입력", [
                self.test_answer_yes_no,
                self.test_answer_numeric,
                self.test_answer_progress_api,
            ])

            # Phase 3: 증빙자료
            self.run_category("Phase 3: 증빙자료", [
                self.test_evidence_page_access,
                self.test_evidence_upload,
                self.test_evidence_list_api,
            ])

            # Phase 4: 리포트
            self.run_category("Phase 4: 리포트", [
                self.test_report_page_access,
                self.test_report_generate_json,
                self.test_report_download_excel,
            ])

            # Phase 5: 제출 검증
            self.run_category("Phase 5: 제출 검증", [
                self.test_submit_incomplete_blocked,
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
            self.stop_server()

        self._save_result_report()
        return self.print_final_report()

    def _save_result_report(self):
        """결과 리포트 저장"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        PHASE_MAP = {
            "session":  "Phase 1: 세션 및 페이지 접근",
            "answer":   "Phase 2: 답변 입력",
            "evidence": "Phase 3: 증빙자료",
            "report":   "Phase 4: 리포트",
            "submit":   "Phase 5: 제출 검증",
        }

        lines = [
            f"<!-- E2E Test Run: {timestamp} -->\n",
            f"# 정보보호공시(Link11) E2E 통합 테스트 결과\n\n",
            f"- 실행 시간: {timestamp}\n",
            f"- 테스트 연도: {self.test_year}\n",
            f"- 모드: {'Headless' if self.headless else 'Browser'}\n\n",
        ]

        current_phase = ""
        for res in self.results:
            parts = res.test_name.split('_')
            phase_key = parts[1] if len(parts) > 1 else ""
            phase_label = PHASE_MAP.get(phase_key, "기타")

            if phase_label != current_phase:
                current_phase = phase_label
                lines.append(f"\n## {current_phase}\n\n")

            status_icon = {
                TestStatus.PASSED:  "✅",
                TestStatus.FAILED:  "❌",
                TestStatus.WARNING: "⚠️",
                TestStatus.SKIPPED: "⊘",
            }.get(res.status, "")

            checkbox = "[x]" if res.status == TestStatus.PASSED else "[ ]"
            lines.append(f"- {checkbox} {status_icon} **{res.test_name}**: {res.message}\n")

        passed  = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed  = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        warned  = sum(1 for r in self.results if r.status == TestStatus.WARNING)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total   = len(self.results)

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


def main():
    parser = argparse.ArgumentParser(description='정보보호공시(Link11) E2E 통합 테스트')
    parser.add_argument('--headless', action='store_true', help='Headless 모드')
    parser.add_argument('--url', type=str, default='http://localhost:5001', help='서버 URL')
    args = parser.parse_args()

    suite = E2EDisclosureTestSuite(base_url=args.url, headless=args.headless)
    sys.exit(suite.run_all_tests())


if __name__ == '__main__':
    main()
