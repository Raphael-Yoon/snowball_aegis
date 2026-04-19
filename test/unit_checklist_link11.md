# Link11: 정보보호공시 E2E 테스트 시나리오

## 1. 대시보드 및 네비게이션

- **test_link11_access**: `/link11` 페이지가 정상적으로 로드되는지 확인
- **test_link11_dashboard_stats**: 대시보드 카드(투자 비율, 인력 비율 등)가 표시되는지 확인
- **test_link11_category_navigation**: 카테고리 카드 클릭 시 해당 카테고리 질문 페이지로 이동하는지 확인

## 2. 질문 응답 기능 (카테고리 1: 정보보호 투자)

- **test_link11_answer_yes_no**: YES/NO 질문 클릭 시 색상 변경 및 활성화 상태 확인
- **test_link11_dependent_questions**: Q1에서 '예' 선택 시 하위 질문(Q2, Q3...)이 나타나는지 확인
- **test_link11_currency_input**: 금액 입력 시 쉼표(,) 자동 포맷팅 확인
- **test_link11_validation_b_lt_a**: '정보보호 투자액(B)'이 '정보기술 투자액(A)'보다 클 때 저장 시도 시 경고 메시지 확인
- **test_link11_validation_negative**: 숫자/금액 필드에 음수 입력 시 방지되는지 확인 (min="0", 서버 검증)

## 3. 질문 응답 기능 (카테고리 2: 정보보호 인력)

- **test_link11_validation_personnel**: 인력 수 계층 검증 (총 임직원 >= IT 인력 >= 보안 인력)

## 4. 질문 응답 기능 (기타 유형)

- **test_link11_multi_select**: 체크박스형 질문(카테고리 4 등)에서 다중 선택 및 저장 확인
- **test_link11_number_input**: 숫자 필드(인력 수 등) 입력 및 저장 확인
- **test_link11_auto_calculation**: 답변 입력 후 상단 진행률 또는 대시보드 수치가 업데이트되는지 확인

## 5. 증빙 자료 관리

- **test_link11_evidence_modal**: 질문 하단의 '증빙 자료 업로드' 버튼 클릭 시 파일 선택창/모달 노출 확인
- **test_link11_evidence_view_page**: `/link11/evidence` 페이지에서 전체 증빙 자료 목록 확인
- **test_link11_evidence_mime_validation**: 확장자가 변조된 파일 업로드 시 MIME 타입 검증으로 거부되는지 확인
- **test_link11_evidence_delete**: 증빙 파일 업로드 후 삭제 API 정상 동작 확인 (CRUD 완결성)
- **test_link11_evidence_download**: 증빙 파일 업로드 후 다운로드 API 정상 동작 확인 (CRUD 완결성)

## 6. 공시 자료 생성 및 제출 관리

- **test_link11_report_preview**: `/link11/report` 페이지에서 지금까지 입력한 내용의 미리보기가 표시되는지 확인
- **test_link11_report_download**: '공시자료 생성 및 다운로드' 버튼 클릭 시 파일 생성 프로세스(로딩 오버레이) 시작 확인
- **test_link11_submit_incomplete_blocked**: 완료율 미달(< 100%) 상태에서 공시 제출 시도 시 차단되는지 확인
- **test_link11_reset_disclosure**: 새로하기(데이터 초기화) API 정상 동작 확인
- **test_link11_copy_block_verification**: 이전 자료 불러오기(직접 복사) API 호출 시 403 차단 및 가이드 메시지 반환 확인
- **test_link11_available_years**: 이용 가능 연도 목록 조회 API 정상 응답 확인

## 7. 회사별 데이터 격리

- ~~**test_link11_company_data_isolation**: 사용자 전환 후 본인 회사 데이터만 조회 가능한지 확인~~ *(멀티 회사 테스트 데이터 부재로 자동화 테스트에서 제외)*

## 8. 데이터 무결성 검증 (Data Integrity)

- **test_link11_numerical_boundary**: 극단적인 수치(조 단위) 입력 시 비율 계산 정밀도 및 DB 저장 무결성 확인
- **test_link11_evidence_physical_integrity**: 증빙 업로드 후 서버 내 물리적 파일 존재 여부 및 DB 메타데이터(크기, 타입) 일치 확인
- **test_link11_recursive_cleanup**: 상위 질문 '아니오' 변경 시 하위 데이터의 논리적 무결성(N/A 처리 후 YES 복귀 시 재입력 상태) 확인

## 9. 진행 현황 및 추가 질문 검증 (신규)

- **test_link11_progress_view**: `/link11/progress` 진행 현황 페이지 접근 및 진행률 요소 표시 확인
- **test_link11_q7_q8**: 향후 투자 계획(Q7) YES 선택 후 예정 투자액(Q8) 입력 필드 연동 확인
- **test_link11_q13_q14**: CISO/CPO 지정 여부(Q13) YES 선택 후 상세현황(Q14) 입력 연동 확인
- **test_link11_q27_new_question**: 신규 추가 질문 Q27(주요 투자 항목) 렌더링 및 표시 확인
- **test_link11_q29_new_question**: 신규 추가 질문 Q29(CISO/CPO 활동내역) Q13 YES 선택 후 노출 확인
- **test_link11_reference_view**: "전년도 참고" 패널 노출 및 연도 선택에 따른 데이터 조회 확인
- **test_link11_ratio_trigger_integrity**: 상위 트리거(Q1, Q9) '아니오' 시 하위 잔류 데이터 무시 및 대시보드 0% 고정 확인

## 10. 확정 프로세스 및 입력 잠금 (신규)

- **test_link11_submit_disclosure**: 공시 제출 API 호출 확인 (완료율 100% 시 제출, 미달 시 차단 메시지)
- **test_link11_confirm_disclosure**: 공시 확정 API 동작 확인 (submitted → confirmed 상태 전환)
- **test_link11_unconfirm_disclosure**: 공시 확정 해제 API 동작 확인 (confirmed → submitted 상태 복귀)
- **test_link11_confirmed_save_blocked**: confirmed 상태에서 답변 저장 시도 시 403 Forbidden 차단 확인
- **test_link11_confirmed_fields_disabled**: confirmed 상태에서 질문 입력 필드 disabled 렌더링 확인 (UI 잠금)

## 11. 연도별 참고 패널 개선 (신규)

- **test_link11_reference_year_status_badge**: 연도 선택 드롭다운 옵션에 상태 뱃지(확정/제출됨/작성완료 등) 표시 확인
- **test_link11_reference_panel_status_banner**: 연도 선택 후 참고 패널 내 상태 안내 배너 표시 확인

