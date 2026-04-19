# Link10: AI 분석 결과 조회 E2E 테스트 시나리오

## 1. 페이지 접근 및 초기 상태 확인
- [ ] **test_link10_access**: `/link10` 페이지가 정상적으로 로드되는지 확인
- [ ] **test_link10_loading_state**: 초기 진입 시 로딩 스피너(".spinner-border")가 표시되는지 확인
- [ ] **test_link10_empty_state_or_list**: 데이터 로드 후 "결과가 없습니다" 메시지 또는 결과 카드(".result-card")가 표시되는지 확인

## 2. AI 리포트 조회 (모달)
- [ ] **test_link10_view_report**: 결과 카드에서 "AI 리포트 보기" 버튼 클릭 시 모달("#aiModal")이 가동되는지 확인
- [ ] **test_link10_report_content**: 모달 내부에 리포트 내용(또는 오류 메시지)이 로드되는지 확인
- [ ] **test_link10_modal_close**: 모달의 '닫기' 버튼 또는 외부 클릭 시 모달이 닫히는지 확인

## 3. 기능성 인터랙션 (다운로드 및 전송)
- [ ] **test_link10_send_report_guest**: 비로그인 상태에서 "AI 리포트 전송" 클릭 시 이메일 입력 모달("#emailModal")이 표시되는지 확인
- [ ] **test_link10_email_validation**: 이메일 모달에서 잘못된 이메일 형식 입력 시 유효성 검사 메시지가 표시되는지 확인
- [ ] **test_link10_logged_in_action**: 로그인 상태에서 "AI 리포트 전송" 클릭 시 이메일 모달 없이 즉시 동작(다운로드)하는지 확인
