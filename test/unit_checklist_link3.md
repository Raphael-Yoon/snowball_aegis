# Link3: 운영평가 가이드 E2E 테스트 시나리오

## 1. 페이지 접근 및 초기 상태 확인
- [ ] **test_link3_access**: `/link3` 페이지가 정상적으로 로드되는지 확인
- [ ] **test_link3_initial_ui**: 초기 진입 시 "항목을 선택해주세요" 메시지가 표시되는지 확인
- [ ] **test_link3_sidebar_categories**: 사이드바에 'Access Program & Data', 'Program Changes', 'Computer Operations' 카테고리가 존재하는지 확인
- [ ] **test_link3_download_button_initial**: 초기 상태에서 '템플릿 다운로드' 버튼이 비활성화(opacity 0.5, pointer-events none) 되어 있는지 확인

## 2. 사이드바 인터랙션 및 컨텐츠 동적 로드
- [ ] **test_link3_sidebar_toggle**: 카테고리 클릭 시 하위 옵션 목록이 펼쳐지거나 접히는지 확인
- [ ] **test_link3_content_loading**: 사이드바 항목(예: APD01) 클릭 시 "Step 1" 컨텐츠가 로드되는지 확인
- [ ] **test_link3_step_navigation**: '다음', '이전' 버튼 클릭 시 컨텐츠가 순차적으로 변하는지 확인
- [ ] **test_link3_download_button_active**: 항목 선택 후 '템플릿 다운로드' 버튼이 활성화되는지 확인
- [ ] **test_link3_download_link_correct**: 항목별로 다운로드 링크가 올바르게 업데이트되는지 확인 (예: `/static/paper/APD01_paper.xlsx`)

## 3. 로그인 및 활동 로그 (선택 사항)
- [ ] **test_link3_activity_log**: 로그인 후 페이지 접근 시 활동 로그에 기록되는지 확인
