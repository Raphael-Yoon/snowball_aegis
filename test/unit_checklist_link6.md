# Link6: 설계평가 E2E 테스트 시나리오

## 1. 평가 세션 생성
- [ ] **test_design_create_new**: RCM을 선택하여 새로운 설계평가 기간(세션)을 생성하고 목록에 표시되는지 확인
- [ ] **test_design_list_display**: 생성된 평가 계획의 상태(미시작/진행중)와 평가 대상 통제 수 일치 확인

## 2. 평가 수행 및 저장
- [ ] **test_design_save_evaluation**: 개별 통제 항목에 대해 평가 결과(적정/부적정) 및 의견 입력 후 저장 확인
- [ ] **test_design_batch_save**: '일괄 저장' 기능을 통해 여러 항목의 상태가 동시에 업데이트되는지 확인
- [ ] **test_design_evidence_attach**: 증빙자료 파일 업로드 기능 동작 및 파일명 표시 확인

## 3. 미비점(Defect) 관리
- [ ] **test_design_defect_logging**: 평가 결과를 '미비(Exception)'로 선택 시 미비점 등록 팝업 동작 및 저장 확인

## 4. 평가 완료
- [ ] **test_design_completion_status**: 모든 항목 평가 완료 시 진행률 100% 도달 및 '완료' 상태 변경 확인

## 5. 회사별 데이터 격리
- [ ] **test_link6_company_data_isolation**: 사용자 전환 후 본인 회사 설계평가만 조회 가능한지 확인
  - 우측 상단 사용자명 클릭하여 다른 회사 계정으로 전환
  - 해당 회사의 설계평가 데이터만 표시되는지 확인
  - '관리자로 돌아가기' 버튼으로 원래 계정 복귀
