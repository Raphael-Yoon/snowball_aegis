# Link7: 운영평가 E2E 테스트 시나리오

## 1. 평가 세션 관리
- [ ] **test_operation_create_new**: RCM을 선택하여 새로운 운영평가 기간(세션)을 생성하고 목록에 표시되는지 확인
- [ ] **test_operation_list_display**: 생성된 평가 계획의 상태(미시작/진행중)와 평가 대상 통제 수 일치 확인
- [ ] **test_operation_continue_session**: 기존 세션 '계속' 버튼 클릭 시 상세 페이지로 이동 확인

## 2. 수동통제 모집단 및 샘플 관리
- [ ] **test_operation_sample_attribute_input**: 샘플 라인의 Attribute 값 입력 및 저장 확인 (RCM에서 정의된 Attribute 기반)
- [ ] **test_operation_population_upload**: 모집단 파일(Excel) 업로드 및 건수 표시 확인
- [ ] **test_operation_sample_extract**: 샘플 추출 기능 동작 및 추출된 샘플 목록 표시 확인
- [ ] **test_operation_sample_count_validation**: 모집단 대비 샘플 수 적정성 확인 (25건 기준 등)

## 3. 평가 수행 및 저장
- [ ] **test_operation_save_evaluation**: 개별 통제 항목에 대해 평가 결과(적정/부적정) 및 의견 입력 후 저장 확인
- [ ] **test_operation_batch_save**: '일괄 저장' 기능을 통해 여러 항목의 상태가 동시에 업데이트되는지 확인
- [ ] **test_operation_manual_control_test**: 수동통제(APD, PC, CO 등) 테스트 페이지 진입 및 테스트 수행 확인

## 4. 증빙자료 관리
- [ ] **test_operation_evidence_attach**: 증빙자료 파일 업로드 기능 동작 및 파일명 표시 확인
- [ ] **test_operation_image_upload**: 이미지 증빙 업로드 기능 동작 확인
- [ ] **test_operation_image_display**: 업로드된 이미지가 평가 화면에 정상 표시되는지 확인

## 5. 미비점(Defect) 관리
- [ ] **test_operation_defect_logging**: 평가 결과를 '미비(Exception)'로 선택 시 미비점 등록 팝업 동작 및 저장 확인
- [ ] **test_operation_defect_badge**: 미비점 등록 후 해당 항목에 '부적정' 배지 표시 확인

## 6. 평가 완료 및 대시보드
- [ ] **test_operation_completion_status**: 모든 항목 평가 완료 시 진행률 100% 도달 및 '완료' 상태 변경 확인
- [ ] **test_operation_dashboard_reflection**: 메인 대시보드 등에서 운영평가 진행 현황이 올바르게 반영되는지 확인

## 7. ELC/TLC 운영평가
- [ ] **test_elc_operation_evaluation**: ELC 운영평가 페이지 진입 및 평가 수행 확인
- [ ] **test_tlc_operation_evaluation**: TLC 운영평가 페이지 진입 및 평가 수행 확인

## 8. 데이터 정리
- [ ] **test_operation_delete_session**: 테스트를 위해 생성했던 평가 세션 삭제 및 목록 사라짐 확인
- [ ] **test_operation_cleanup_files**: 테스트 중 업로드한 파일(모집단, 증빙) 정리 확인

## 9. 회사별 데이터 격리
- [ ] **test_link7_company_data_isolation**: 사용자 전환 후 본인 회사 운영평가만 조회 가능한지 확인
  - 우측 상단 사용자명 클릭하여 다른 회사 계정으로 전환
  - 해당 회사의 운영평가 데이터만 표시되는지 확인
  - '관리자로 돌아가기' 버튼으로 원래 계정 복귀
