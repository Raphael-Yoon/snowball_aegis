# Link1: RCM 자동생성 Unit 테스트 시나리오

## 1. 페이지 접근 및 기본 요소 확인

- [ ] **test_link1_page_access**: 페이지 타이틀, '대상 시스템 정보' 섹션, 간편 모드 안내 메시지(`#simple-mode-notice`) 기본 표시, 전문가 모드 버튼(`#btn-expert-mode`) 존재, RCM 테이블(`#rcm-table`) DOM 존재 확인 (간편 모드에서 숨김 상태)

## 2. 입력 폼 요소 확인

- [ ] **test_link1_form_elements**: 시스템명, 시스템유형, SW, OS, DB, Cloud, OS접근제어, DB접근제어, 배포Tool, 배치스케줄러 등 모든 입력 요소 화면 표시 확인

## 3. OS / Cloud 환경 토글

- [ ] **test_link1_os_version_toggle**: Linux 선택 시 배포판 드롭다운 표시, Windows 선택 시 숨김 확인
- [ ] **test_link1_cloud_env_toggle**: SaaS 선택 시 OS/DB N/A 처리, On-Premise 복원 확인

## 4. 시스템 유형 토글

- [ ] **test_link1_system_type_toggle**: In-house 선택 시 SW 드롭다운 비활성화 및 ETC 고정, Package 선택 시 전체 옵션 활성화 확인

## 5. SW 버전 그룹 토글

- [ ] **test_link1_sw_version_toggle**: SW 선택 변경 시 버전 드롭다운 옵션이 해당 SW에 맞게 갱신되는지 확인 (SAP → ECC/S4HANA, ORACLE → R12/Fusion)

## 6. 통제 테이블

- [ ] **test_link1_control_table**: 통제 항목 행 수, data-id, 구분/주기/성격 드롭다운 요소 확인
- [ ] **test_link1_toggle_detail**: 전체 펼치기/접기 버튼 동작 확인

## 7. 통제 속성 변경

- [ ] **test_link1_type_change_monitoring**: Auto→Manual 전환 시 통제명이 '모니터링'으로 변경되는지 확인
- [ ] **test_link1_population_calculation**: 수동 통제(APD01)의 주기를 '월'로 변경 시 모집단 수 12건, 표본수 2건으로 자동 계산되는지 확인

## 8. Cloud 환경에 따른 통제 제외

- [ ] **test_link1_cloud_control_exclusion**: SaaS 선택 시 해당 통제(CO06, APD09~APD11 등)에 'CSP Managed' 뱃지 표시 및 드롭다운 비활성화 확인

## 9. API 테스트

- [ ] **test_link1_population_templates_api**: 모집단 템플릿 API 호출 시 기본 템플릿(sw, os, db)과 Tool 템플릿(os_tool, db_tool, deploy_tool, batch_tool)이 모두 반환되는지 확인
- [ ] **test_link1_export_api**: Export Excel API (POST `/api/rcm/export_excel`) — 이메일 누락 시 400 반환, 유효 요청 시 200 또는 메일 오류 응답 확인

## 10. 간편/전문가 모드 토글

- [ ] **test_link1_expert_mode_toggle**: 기본 간편 모드 상태(RCM 숨김·안내 메시지 표시) 확인 → 전문가 모드 전환 시 RCM 표시·안내 메시지 숨김·버튼 텍스트 변경 확인 → 간편 모드 복귀 확인

## 11. 이메일 입력 및 발송 UI

- [ ] **test_link1_email_input**: 이메일 입력 필드(`#send_email`) 및 발송 버튼(`#btn-export-excel`) 존재 확인
- [ ] **test_link1_export_email_validation**: 이메일 미입력 상태로 발송 버튼 클릭 시 페이지 이동 없이 차단되는지 확인
