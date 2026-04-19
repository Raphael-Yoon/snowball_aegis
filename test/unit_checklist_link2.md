# Link2: ITGC 인터뷰 E2E 테스트 시나리오 (1-page 섹션 방식)

대상: `/link2_1p` (섹션형 인터뷰 시스템 — common → apd → pc → co)

## 1. 페이지 접근 및 리다이렉트 확인
- [ ] **test_link2_access_guest**: 비로그인 상태에서 `/link2_1p` 접근 시 `common` 섹션으로 리다이렉트되고 "공통사항" 제목이 표시되는지 확인
- [ ] **test_link2_section_steps**: 섹션 스텝 인디케이터(`.section-steps .step`)가 4개(common/apd/pc/co) 표시되는지 확인

## 2. UI 요소 확인
- [ ] **test_link2_email_field**: `common` 섹션에서 이메일 입력 필드(`#q0`)가 표시되는지 확인
- [ ] **test_link2_yn_buttons**: Y/N 버튼(`#q2_yes`, `#q2_no`)이 표시되고, 클릭 시 `btn-primary` / `btn-outline-secondary` 스타일이 올바르게 전환되는지 확인

## 3. 조건부 질문 로직
- [ ] **test_link2_conditional_cloud**: Q3(Cloud 사용여부)에서 N 선택 시 Q4/Q5 블록에 `hidden` 클래스가 추가되고, Y 선택 시 다시 표시되는지 확인

## 4. 관리자 샘플입력
- [ ] **test_link2_admin_sample_button**: localhost(127.0.0.1) 접근 시 `fillAllSamples()` 샘플입력 버튼이 표시되는지 확인
- [ ] **test_link2_sample_fill**: '샘플입력' 클릭 후 이메일 필드(`#q0`)에 값이 자동 입력되는지 확인

## 5. 섹션 내비게이션
- [ ] **test_link2_navigation**: `common` 섹션 폼 제출 후 `apd` 섹션(`/link2_1p/section/apd`)으로 이동하는지 확인
- [ ] **test_link2_all_sections_accessible**: 4개 섹션(common/apd/pc/co) URL에 직접 접근 시 각 섹션 제목이 정상 표시되는지 확인

## 6. 전체 인터뷰 완료
- [ ] **test_link2_complete_interview**: 샘플입력으로 4개 섹션을 순서대로 제출한 후 AI 검토 선택 페이지에 도달하는지 확인

## 7. APD 조건부 질문 로직 (IT 감사팀 요청)
- [ ] **test_link2_apd_conditional**: APD 섹션 분기점 질문 로직 확인 — Q6(공유계정) N 시 Q9 표시/Q10~Q12 숨김, Y 시 역전; Q16(DB접속) N 시 Q17~Q25 숨김; Q26(OS접속) N 시 Q27~Q32 숨김

## 8. 세션 유지 (IT 감사팀 요청)
- [ ] **test_link2_session_persistence**: common 섹션 제출 후 completed 스텝 클릭으로 복귀 시 이메일·시스템명 답변이 보존되는지 확인
