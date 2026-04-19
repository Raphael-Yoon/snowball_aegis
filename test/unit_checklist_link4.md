# Link4: 영상 가이드 E2E 테스트 시나리오

## 1. 페이지 접근 및 초기 상태 확인
- [ ] **test_link4_access**: `/link4` 페이지가 정상적으로 로드되는지 확인
- [ ] **test_link4_initial_ui**: 초기 진입 시 "항목을 선택해주세요" 메시지가 표시되는지 확인
- [ ] **test_link4_sidebar_categories**: 사이드바에 'IT Process Wide Controls', 'IT General Controls', '기타' 카테고리가 존재하는지 확인

## 2. 사이드바 인터랙션 및 컨텐츠 동적 로드
- [ ] **test_link4_sidebar_toggle**: 카테고리 클릭 시 하위 옵션 목록이 펼쳐지거나 접히는지 확인
- [ ] **test_link4_content_loading**: 활성화된 항목(예: OVERVIEW) 클릭 시 영상 컨텐츠(iframe)가 로드되는지 확인
- [ ] **test_link4_preparing_message**: 준비 중인 항목(예: IT General Controls > Data 직접변경 승인) 클릭 시 "준비 중입니다" 메시지가 표시되는지 확인

## 3. FontAwesome 아이콘

- [ ] **test_link4_sidebar_chevron_icon**: 사이드바 카테고리 제목에 FontAwesome chevron-down 아이콘(`.fa-chevron-down`)이 표시되는지 확인 (v1.35 FontAwesome CSS 추가 반영)

## 4. 로그인 및 활동 로그 (선택 사항)
- [ ] **test_link4_activity_log**: 로그인 후 페이지 접근 시 활동 로그에 기록되는지 확인
