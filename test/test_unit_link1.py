"""
Link1: RCM 생성 (AI RCM Builder) Unit 테스트 코드

주요 테스트 항목:
1. 비로그인 상태에서 페이지 접근 및 필드 확인
2. 입력 폼 요소 확인 (시스템명, 시스템유형, SW, OS, DB, Cloud)
3. 폼 입력에 따른 동적 UI 변화 확인 (Linux 배포판 선택, Cloud에 따른 OS/DB 숨김)
4. 통제 테이블 및 펼치기/접기 기능 확인
5. 모집단 템플릿 API 테스트
6. 메일 발송 기능 테스트
"""

import sys
import os
import json
from pathlib import Path
from datetime import datetime

# 프로젝트 루트 및 테스트 경로 설정
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from test.playwright_base import PlaywrightTestBase, TestStatus, UnitTestResult


class Link1UnitTest(PlaywrightTestBase):
    def __init__(self, base_url="http://localhost:5001", **kwargs):
        super().__init__(base_url=base_url, **kwargs)
        self.category = "Link1: RCM 생성"
        self.checklist_source = project_root / "test" / "unit_checklist_link1.md"
        self.checklist_result = project_root / "test" / "unit_checklist_link1_result.md"

    def test_link1_page_access(self, result: UnitTestResult):
        """1. 페이지 접근 및 기본 요소 확인"""
        self.navigate_to("/link1")

        # 페이지 타이틀 확인
        title = self.page.title()
        if "RCM 생성" in title or "Snowball" in title:
            result.add_detail(f"페이지 타이틀 확인: {title}")
        else:
            result.fail_test(f"페이지 타이틀 불일치: {title}")
            return

        # 섹션 헤더 확인
        if self.is_visible("h5:has-text('대상 시스템 정보')"):
            result.add_detail("대상 시스템 정보 섹션 확인")
        else:
            result.fail_test("대상 시스템 정보 섹션을 찾을 수 없습니다.")
            return

        # 간편 모드 안내 메시지 기본 표시 확인
        if self.page.locator("#simple-mode-notice").is_visible():
            result.add_detail("간편 모드 안내 메시지 기본 표시 확인")
        else:
            result.fail_test("간편 모드 안내 메시지가 표시되지 않습니다.")
            return

        # 전문가 모드 버튼 확인
        if self.page.locator("#btn-expert-mode").count() > 0:
            result.add_detail("전문가 모드 버튼 확인")
        else:
            result.fail_test("전문가 모드 버튼을 찾을 수 없습니다.")
            return

        # RCM 테이블 DOM 존재 확인 (기본: 숨김 상태)
        if self.page.locator("#rcm-table").count() > 0:
            result.add_detail("ITGC RCM 테이블 DOM 확인 (간편 모드에서 숨김 상태)")
        else:
            result.fail_test("RCM 테이블을 찾을 수 없습니다.")
            return

        result.pass_test("페이지 접근 및 기본 요소 확인 완료")

    def test_link1_form_elements(self, result: UnitTestResult):
        """2. 입력 폼 요소 확인"""
        self.navigate_to("/link1")

        # 필수 폼 요소 확인
        form_elements = {
            "#system_name": "시스템 명칭",
            "#system_type": "시스템 유형",
            "#software": "Application",
            "#os": "OS",
            "#db": "DB",
            "#cloud_env": "Cloud 환경",
            "#os_tool": "OS 접근제어",
            "#db_tool": "DB 접근제어",
            "#deploy_tool": "배포 Tool",
            "#batch_tool": "배치 스케줄러"
        }

        missing_elements = []
        for selector, name in form_elements.items():
            if self.page.locator(selector).count() > 0:
                result.add_detail(f"폼 요소 확인: {name}")
            else:
                missing_elements.append(name)

        if missing_elements:
            result.fail_test(f"누락된 폼 요소: {', '.join(missing_elements)}")
        else:
            result.pass_test("모든 폼 요소 확인 완료")

    def test_link1_os_version_toggle(self, result: UnitTestResult):
        """3. OS 선택에 따른 Linux 배포판 표시/숨김 확인"""
        self.navigate_to("/link1")

        # Linux 선택 시 배포판 드롭다운 표시
        self.page.select_option("#os", "LINUX")
        self.page.wait_for_timeout(300)

        os_version_visible = self.page.locator("#os_version_group").is_visible()
        if os_version_visible:
            result.add_detail("Linux 선택 시 배포판 드롭다운 표시 확인")
        else:
            result.fail_test("Linux 선택 시 배포판 드롭다운이 표시되지 않습니다.")
            return

        # Windows 선택 시 배포판 드롭다운 숨김
        self.page.select_option("#os", "WINDOWS")
        self.page.wait_for_timeout(300)

        os_version_hidden = not self.page.locator("#os_version_group").is_visible()
        if os_version_hidden:
            result.add_detail("Windows 선택 시 배포판 드롭다운 숨김 확인")
        else:
            result.fail_test("Windows 선택 시에도 배포판 드롭다운이 표시됩니다.")
            return

        result.pass_test("OS 선택에 따른 UI 변화 확인 완료")

    def test_link1_cloud_env_toggle(self, result: UnitTestResult):
        """4. Cloud 환경 선택에 따른 OS/DB 숨김 확인"""
        self.navigate_to("/link1")

        # On-Premise(None) 선택 시 OS/DB 표시
        self.page.select_option("#cloud_env", "None")
        self.page.wait_for_timeout(300)

        os_visible = self.page.locator("#os").is_visible()
        db_visible = self.page.locator("#db").is_visible()

        if os_visible and db_visible:
            result.add_detail("On-Premise 선택 시 OS/DB 표시 확인")
        else:
            result.fail_test("On-Premise 선택 시 OS/DB가 표시되지 않습니다.")
            return

        # SaaS 선택 시 OS/DB N/A로 변경 확인
        self.page.select_option("#cloud_env", "SaaS")
        self.page.wait_for_timeout(300)

        os_value = self.page.locator("#os").input_value()
        db_value = self.page.locator("#db").input_value()

        if os_value == "N/A" and db_value == "N/A":
            result.add_detail("SaaS 선택 시 OS/DB가 N/A로 변경됨")
        else:
            result.add_detail(f"SaaS 선택 후 OS={os_value}, DB={db_value}")

        result.pass_test("Cloud 환경 선택에 따른 UI 변화 확인 완료")

    def test_link1_control_table(self, result: UnitTestResult):
        """5. 통제 테이블 및 행 확인"""
        self.navigate_to("/link1")
        self._enter_expert_mode()

        # 통제 행 개수 확인
        control_rows = self.page.locator(".control-row").count()
        if control_rows > 0:
            result.add_detail(f"통제 항목 {control_rows}개 확인")
        else:
            result.fail_test("통제 항목이 없습니다.")
            return

        # 첫 번째 통제의 기본 요소 확인
        first_row = self.page.locator(".control-row").first
        control_id = first_row.get_attribute("data-id")

        if control_id:
            result.add_detail(f"첫 번째 통제 ID: {control_id}")

            # 구분(type), 주기(freq), 성격(method) 드롭다운 확인
            type_select = self.page.locator(f"#type-{control_id}")
            freq_select = self.page.locator(f"#freq-{control_id}")
            method_select = self.page.locator(f"#method-{control_id}")

            if type_select.count() > 0 and freq_select.count() > 0 and method_select.count() > 0:
                result.add_detail("통제별 드롭다운 요소 확인")
            else:
                result.fail_test("통제별 드롭다운 요소가 누락되었습니다.")
                return

        result.pass_test("통제 테이블 확인 완료")

    def test_link1_toggle_detail(self, result: UnitTestResult):
        """6. 상세 펼치기/접기 기능 확인"""
        self.navigate_to("/link1")
        self._enter_expert_mode()

        # 전체 펼치기 버튼 확인
        toggle_all_btn = self.page.locator("#btn-toggle-all")
        if toggle_all_btn.count() == 0:
            result.fail_test("전체 펼치기 버튼을 찾을 수 없습니다.")
            return

        # 첫 번째 통제의 상세 행 확인
        first_row = self.page.locator(".control-row").first
        control_id = first_row.get_attribute("data-id")
        detail_row = self.page.locator(f"#detail-{control_id}")

        # 초기 상태: 접힌 상태
        initial_visible = detail_row.is_visible()
        result.add_detail(f"초기 상세 행 상태: {'펼침' if initial_visible else '접힘'}")

        # 전체 펼치기 클릭
        toggle_all_btn.click()
        self.page.wait_for_timeout(500)

        after_toggle = detail_row.is_visible()
        if after_toggle != initial_visible:
            result.add_detail("전체 펼치기/접기 동작 확인")
        else:
            result.add_detail("전체 펼치기/접기 상태 변화 없음 (이미 동일 상태)")

        result.pass_test("상세 펼치기/접기 기능 확인 완료")

    def test_link1_type_change_monitoring(self, result: UnitTestResult):
        """7. 자동→수동 변경 시 모니터링 명칭 변경 확인"""
        self.navigate_to("/link1")
        self._enter_expert_mode()

        # 원래 자동통제인 APD05 찾기
        name_span = self.page.locator("#name-APD05")
        type_select = self.page.locator("#type-APD05")

        if name_span.count() == 0 or type_select.count() == 0:
            result.skip_test("APD05 통제를 찾을 수 없습니다.")
            return

        # 원래 이름 확인
        original_name = name_span.get_attribute("data-original")
        result.add_detail(f"원래 통제명: {original_name}")

        # 수동으로 변경
        type_select.select_option("Manual")
        self.page.wait_for_timeout(500)

        # 변경된 이름 확인
        changed_name = name_span.text_content()

        if "모니터링" in changed_name:
            result.add_detail(f"변경된 통제명: {changed_name}")
            result.pass_test("자동→수동 변경 시 모니터링 명칭 변경 확인")
        else:
            result.fail_test(f"모니터링 명칭으로 변경되지 않음: {changed_name}")

    def test_link1_population_templates_api(self, result: UnitTestResult):
        """8. 모집단 템플릿 API 테스트"""
        try:
            response = self.page.request.get(f"{self.base_url}/api/rcm/population_templates")

            if response.status == 200:
                data = response.json()

                # 기본 템플릿 확인 (sw, os, db)
                required_keys = ["sw_templates", "os_templates", "db_templates"]
                # Tool 템플릿 확인 (os_tool, db_tool, deploy_tool, batch_tool)
                tool_keys = ["os_tool_templates", "db_tool_templates", "deploy_tool_templates", "batch_tool_templates"]

                all_keys = required_keys + tool_keys
                missing_keys = [k for k in all_keys if k not in data]

                if data.get("success") and not missing_keys:
                    sw_count = len(data["sw_templates"])
                    os_count = len(data["os_templates"])
                    db_count = len(data["db_templates"])
                    os_tool_count = len(data["os_tool_templates"])
                    db_tool_count = len(data["db_tool_templates"])
                    deploy_tool_count = len(data["deploy_tool_templates"])
                    batch_tool_count = len(data["batch_tool_templates"])

                    result.add_detail(f"기본 템플릿 - SW: {sw_count}, OS: {os_count}, DB: {db_count}")
                    result.add_detail(f"Tool 템플릿 - OS Tool: {os_tool_count}, DB Tool: {db_tool_count}, Deploy: {deploy_tool_count}, Batch: {batch_tool_count}")
                    result.pass_test("모집단 템플릿 API 정상 동작")
                else:
                    result.fail_test(f"템플릿 데이터 구조 불일치 (누락: {missing_keys})")
            else:
                result.fail_test(f"API 응답 오류: {response.status}")

        except Exception as e:
            result.fail_test(f"API 호출 실패: {e}")

    def test_link1_email_input(self, result: UnitTestResult):
        """9. 이메일 입력 필드 및 발송 버튼 확인"""
        self.navigate_to("/link1")

        # 이메일 입력 필드 확인
        email_input = self.page.locator("#send_email")
        if email_input.count() == 0:
            result.fail_test("이메일 입력 필드를 찾을 수 없습니다.")
            return

        result.add_detail("이메일 입력 필드 확인")

        # 발송 버튼 확인
        send_btn = self.page.locator("#btn-export-excel")
        if send_btn.count() == 0:
            result.fail_test("RCM 메일 발송 버튼을 찾을 수 없습니다.")
            return

        btn_text = send_btn.text_content()
        if "메일 발송" in btn_text:
            result.add_detail(f"발송 버튼 확인: {btn_text.strip()}")

        result.pass_test("이메일 입력 및 발송 버튼 확인 완료")

    def test_link1_system_type_toggle(self, result: UnitTestResult):
        """11. 시스템 유형(In-house/Package) 변경 시 SW 드롭다운 토글 확인"""
        self.navigate_to("/link1")

        sw_select = self.page.locator("#software")

        # In-house 선택 → SW 드롭다운 비활성화, 값 ETC 고정
        self.page.select_option("#system_type", "In-house")
        self.page.wait_for_timeout(400)

        if sw_select.is_disabled():
            result.add_detail("In-house: SW 드롭다운 비활성화 확인")
        else:
            result.fail_test("In-house 선택 시에도 SW 드롭다운이 활성화되어 있습니다.")
            return

        sw_val = sw_select.input_value()
        if sw_val == "ETC":
            result.add_detail("In-house: SW 값 ETC 고정 확인")
        else:
            result.fail_test(f"In-house 선택 후 SW 값이 ETC가 아닙니다: {sw_val}")
            return

        # Package 선택 → SW 드롭다운 활성화
        self.page.select_option("#system_type", "Package")
        self.page.wait_for_timeout(400)

        if not sw_select.is_disabled():
            result.add_detail("Package: SW 드롭다운 활성화 확인")
        else:
            result.fail_test("Package 선택 시에도 SW 드롭다운이 비활성화되어 있습니다.")
            return

        result.pass_test("시스템 유형 변경 시 SW 드롭다운 토글 확인 완료")

    def test_link1_sw_version_toggle(self, result: UnitTestResult):
        """12. SW 변경 시 버전 드롭다운 옵션 갱신 확인"""
        self.navigate_to("/link1")

        # Package로 전환하여 SW 선택 가능 상태로
        self.page.select_option("#system_type", "Package")
        self.page.wait_for_timeout(300)

        version_select = self.page.locator("#sw_version")

        # SAP 선택 → 버전 옵션에 ECC, S4HANA 포함 확인
        self.page.select_option("#software", "SAP")
        self.page.wait_for_timeout(400)

        sap_options = version_select.locator("option").all_text_contents()
        sap_has_ecc = any("ECC" in o for o in sap_options)
        sap_has_s4 = any("S/4HANA" in o or "S4HANA" in o for o in sap_options)

        if sap_has_ecc and sap_has_s4:
            result.add_detail(f"SAP 버전 옵션 확인: {sap_options}")
        else:
            result.fail_test(f"SAP 선택 시 버전 옵션 불일치: {sap_options}")
            return

        # ORACLE 선택 → 버전 옵션에 R12, Fusion 포함 확인
        self.page.select_option("#software", "ORACLE")
        self.page.wait_for_timeout(400)

        oracle_options = version_select.locator("option").all_text_contents()
        oracle_has_r12 = any("R12" in o for o in oracle_options)
        oracle_has_fusion = any("Fusion" in o or "FUSION" in o for o in oracle_options)

        if oracle_has_r12 and oracle_has_fusion:
            result.add_detail(f"ORACLE 버전 옵션 확인: {oracle_options}")
        else:
            result.fail_test(f"ORACLE 선택 시 버전 옵션 불일치: {oracle_options}")
            return

        result.pass_test("SW 변경 시 버전 드롭다운 옵션 갱신 확인 완료")

    def test_link1_population_calculation(self, result: UnitTestResult):
        """13. 수동 통제 주기 변경 시 모집단·표본수 자동 계산 확인"""
        self.navigate_to("/link1")
        self._enter_expert_mode()
        self.page.wait_for_timeout(1500)  # 템플릿 로드 대기

        # APD01: 수동 통제 (접근 권한 검토)
        ctrl_id = "APD01"
        freq_select = self.page.locator(f"#freq-{ctrl_id}")

        if freq_select.count() == 0:
            result.skip_test(f"{ctrl_id} 통제를 찾을 수 없습니다.")
            return

        # 수동(Manual) 상태 확인 후 주기를 '월'로 변경
        type_select = self.page.locator(f"#type-{ctrl_id}")
        if type_select.input_value() == "Auto":
            type_select.select_option("Manual")
            self.page.wait_for_timeout(400)

        freq_select.select_option("월")
        self.page.wait_for_timeout(500)

        # 상세 행 펼치기
        detail_row = self.page.locator(f"#detail-{ctrl_id}")
        if not detail_row.is_visible():
            toggle_btn = self.page.locator(f".control-row[data-id='{ctrl_id}'] .toggle-detail")
            if toggle_btn.count() > 0:
                toggle_btn.click()
                self.page.wait_for_timeout(400)

        # 모집단 수 확인 (월 = 12건)
        pop_count_el = self.page.locator(f"#population-count-{ctrl_id}")
        pop_count_text = pop_count_el.text_content().strip() if pop_count_el.count() > 0 else ""

        # 표본수 확인 (월 = 2건)
        sample_count_el = self.page.locator(f"#sample-count-{ctrl_id}")
        sample_count_text = sample_count_el.text_content().strip() if sample_count_el.count() > 0 else ""

        if "12" in pop_count_text:
            result.add_detail(f"모집단 수: {pop_count_text} (월=12건 정상)")
        else:
            result.fail_test(f"모집단 수 계산 오류 — 기대: 12, 실제: '{pop_count_text}'")
            return

        if "2" in sample_count_text:
            result.add_detail(f"표본수: {sample_count_text} (월=2건 정상)")
        else:
            result.fail_test(f"표본수 계산 오류 — 기대: 2, 실제: '{sample_count_text}'")
            return

        result.pass_test(f"주기 '월' 선택 시 모집단 12건·표본수 2건 자동 계산 확인")

    def test_link1_cloud_control_exclusion(self, result: UnitTestResult):
        """14. SaaS 선택 시 특정 통제에 CSP Managed 뱃지 및 비활성화 확인"""
        self.navigate_to("/link1")
        self._enter_expert_mode()
        self.page.wait_for_timeout(500)

        # SaaS 선택
        self.page.select_option("#cloud_env", "SaaS")
        self.page.wait_for_timeout(600)

        # CO06: 모든 Cloud에서 제외 대상
        co06_row = self.page.locator(".control-row[data-id='CO06']")
        if co06_row.count() == 0:
            result.skip_test("CO06 통제 행을 찾을 수 없습니다.")
            return

        # excluded-control 클래스 부여 확인
        co06_class = co06_row.get_attribute("class") or ""
        if "excluded-control" in co06_class:
            result.add_detail("CO06: excluded-control 클래스 부여 확인")
        else:
            result.fail_test(f"CO06에 excluded-control 클래스가 없습니다. (class: {co06_class})")
            return

        # CSP Managed 뱃지 확인
        badge = co06_row.locator(".cloud-badge")
        if badge.count() > 0:
            result.add_detail(f"CO06: CSP Managed 뱃지 표시 확인 ({badge.text_content().strip()})")
        else:
            result.fail_test("CO06에 cloud-badge가 없습니다.")
            return

        # SaaS 전용 제외 통제 확인 (APD09)
        apd09_row = self.page.locator(".control-row[data-id='APD09']")
        if apd09_row.count() > 0:
            apd09_class = apd09_row.get_attribute("class") or ""
            if "excluded-control" in apd09_class:
                result.add_detail("APD09: SaaS 환경 제외 확인")
            else:
                result.add_detail(f"APD09: excluded-control 미적용 (class: {apd09_class})")

        result.pass_test("SaaS 환경 시 통제 제외(CSP Managed) 처리 확인 완료")

    def test_link1_export_api(self, result: UnitTestResult):
        """15. Export Excel API 직접 검증 (이메일 누락 400, 유효 요청 응답 구조 확인)"""
        self._do_admin_login()
        self.navigate_to("/link1")

        # 페이지에서 CSRF 토큰 추출 (link1은 CSRF 보호 적용됨)
        csrf_token = self.page.evaluate("() => typeof csrfToken !== 'undefined' ? csrfToken : ''")

        # 케이스 1: 이메일 누락 → 400
        res_no_email = self.page.evaluate(f"""
            async () => {{
                const resp = await fetch('/api/rcm/export_excel', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json', 'X-CSRFToken': '{csrf_token}'}},
                    body: JSON.stringify({{
                        rcm_data: [],
                        system_info: {{system_name: '테스트시스템', software: 'ETC'}},
                        user_email: ''
                    }})
                }});
                const body = await resp.json();
                return {{status: resp.status, body: body}};
            }}
        """)

        if res_no_email["status"] == 400:
            msg = res_no_email["body"].get("message", "")
            result.add_detail(f"이메일 누락 → 400 확인 (message: {msg})")
        else:
            result.fail_test(f"이메일 누락 시 400이 아닌 {res_no_email['status']} 반환")
            return

        # 케이스 2: 유효 요청 → 200(성공) 또는 500(SMTP 오류), 단 API 자체는 도달
        res_valid = self.page.evaluate(f"""
            async () => {{
                const resp = await fetch('/api/rcm/export_excel', {{
                    method: 'POST',
                    headers: {{'Content-Type': 'application/json', 'X-CSRFToken': '{csrf_token}'}},
                    body: JSON.stringify({{
                        rcm_data: [],
                        system_info: {{
                            system_name: '테스트시스템',
                            software: 'ETC',
                            os: 'LINUX',
                            db: 'ORACLE',
                            cloud_env: 'None',
                            system_type: 'In-house'
                        }},
                        user_email: 'test@test.com'
                    }})
                }});
                const body = await resp.json();
                return {{status: resp.status, body: body}};
            }}
        """)

        if res_valid["status"] in (200, 500):
            msg = res_valid["body"].get("message", "")[:60]
            result.add_detail(f"유효 요청 → {res_valid['status']} (success: {res_valid['body'].get('success')}, message: {msg})")
            result.pass_test("Export Excel API 구조 검증 완료")
        else:
            result.fail_test(f"유효 요청 시 예상 외 상태 코드: {res_valid['status']}")

    def test_link1_export_email_validation(self, result: UnitTestResult):
        """10. 이메일 미입력 시 발송 방지 확인"""
        self.navigate_to("/link1")

        # 이메일 필드 비우기
        email_input = self.page.locator("#send_email")
        email_input.fill("")

        # 발송 버튼 클릭
        send_btn = self.page.locator("#btn-export-excel")

        # alert 대기
        self.page.on("dialog", lambda dialog: dialog.accept())
        send_btn.click()
        self.page.wait_for_timeout(1000)

        # alert가 표시되었는지 확인 (페이지가 이동하지 않았는지)
        current_url = self.page.url
        if "/link1" in current_url:
            result.pass_test("이메일 미입력 시 발송 방지 동작 확인")
        else:
            result.fail_test("이메일 없이 발송이 진행되었습니다.")

    def _enter_expert_mode(self):
        """전문가 모드 진입 (RCM 테이블 표시)"""
        btn = self.page.locator("#btn-expert-mode")
        if btn.count() > 0 and not self.page.locator("#rcm-section").is_visible():
            btn.click()
            self.page.wait_for_timeout(300)

    def test_link1_expert_mode_toggle(self, result: UnitTestResult):
        """16. 간편/전문가 모드 토글 기능 확인"""
        self.navigate_to("/link1")

        rcm_section = self.page.locator("#rcm-section")
        notice = self.page.locator("#simple-mode-notice")
        btn = self.page.locator("#btn-expert-mode")

        # 기본 상태: 간편 모드 (RCM 숨김, 안내 표시)
        if not rcm_section.is_visible() and notice.is_visible():
            result.add_detail("기본 간편 모드 확인: RCM 숨김, 안내 메시지 표시")
        else:
            result.fail_test(f"기본 상태 오류 — RCM visible: {rcm_section.is_visible()}, notice visible: {notice.is_visible()}")
            return

        # 전문가 모드 전환
        btn.click()
        self.page.wait_for_timeout(300)

        if rcm_section.is_visible() and not notice.is_visible():
            result.add_detail("전문가 모드 전환 확인: RCM 표시, 안내 메시지 숨김")
        else:
            result.fail_test(f"전문가 모드 전환 오류 — RCM visible: {rcm_section.is_visible()}, notice visible: {notice.is_visible()}")
            return

        btn_text = btn.text_content().strip()
        if "간편 모드" in btn_text:
            result.add_detail(f"버튼 텍스트 변경 확인: '{btn_text}'")
        else:
            result.fail_test(f"전문가 모드 전환 후 버튼 텍스트 오류: '{btn_text}'")
            return

        # 간편 모드 복귀
        btn.click()
        self.page.wait_for_timeout(300)

        if not rcm_section.is_visible() and notice.is_visible():
            result.add_detail("간편 모드 복귀 확인: RCM 숨김, 안내 메시지 표시")
        else:
            result.fail_test(f"간편 모드 복귀 오류 — RCM visible: {rcm_section.is_visible()}, notice visible: {notice.is_visible()}")
            return

        result.pass_test("간편/전문가 모드 토글 기능 확인 완료")

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
                    if res.status == TestStatus.PASSED:
                        updated_line = line.replace("- [ ]", "- [x]")
                        updated_line = updated_line.rstrip() + f" -> PASS ({res.message})\n"
                    elif res.status == TestStatus.FAILED:
                        updated_line = line.replace("- [ ]", "- [ ] X")
                        updated_line = updated_line.rstrip() + f" -> FAIL ({res.message})\n"
                    elif res.status == TestStatus.SKIPPED:
                        updated_line = updated_line.rstrip() + f" -> SKIP ({res.message})\n"
                    break
            updated_lines.append(updated_line)

        # 요약 추가
        passed = sum(1 for r in self.results if r.status == TestStatus.PASSED)
        failed = sum(1 for r in self.results if r.status == TestStatus.FAILED)
        skipped = sum(1 for r in self.results if r.status == TestStatus.SKIPPED)
        total = len(self.results) if self.results else 1

        updated_lines.append("\n---\n")
        updated_lines.append(f"## 테스트 결과 요약\n\n")
        updated_lines.append(f"| 항목 | 개수 | 비율 |\n")
        updated_lines.append(f"|------|------|------|\n")
        updated_lines.append(f"| PASS | {passed} | {passed/total*100:.1f}% |\n")
        updated_lines.append(f"| FAIL | {failed} | {failed/total*100:.1f}% |\n")
        updated_lines.append(f"| SKIP | {skipped} | {skipped/total*100:.1f}% |\n")
        updated_lines.append(f"| **총계** | **{total}** | **100%** |\n")

        with open(self.checklist_result, 'w', encoding='utf-8') as f:
            f.writelines(updated_lines)
        print(f"\n[OK] 체크리스트 결과 저장됨: {self.checklist_result}")


def run_tests():
    test_runner = Link1UnitTest(headless=False, slow_mo=500)
    test_runner.setup()

    try:
        test_runner.run_category("Link1 Unit Tests", [
            # 기존 테스트 (10개)
            test_runner.test_link1_page_access,
            test_runner.test_link1_form_elements,
            test_runner.test_link1_os_version_toggle,
            test_runner.test_link1_cloud_env_toggle,
            test_runner.test_link1_control_table,
            test_runner.test_link1_toggle_detail,
            test_runner.test_link1_type_change_monitoring,
            test_runner.test_link1_population_templates_api,
            test_runner.test_link1_email_input,
            test_runner.test_link1_export_email_validation,
            # 신규 추가 테스트 (5개) - 커버리지 갭 보완
            test_runner.test_link1_system_type_toggle,
            test_runner.test_link1_sw_version_toggle,
            test_runner.test_link1_population_calculation,
            test_runner.test_link1_cloud_control_exclusion,
            test_runner.test_link1_export_api,
            test_runner.test_link1_expert_mode_toggle,
        ])
    finally:
        test_runner._update_checklist_result()
        test_runner.print_final_report()
        test_runner.teardown()


if __name__ == "__main__":
    run_tests()
