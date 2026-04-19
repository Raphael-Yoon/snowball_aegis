<!-- Test Run: 2026-03-12 09:00:30 -->
# Link4: 영상 가이드 E2E 테스트 시나리오

## 1. 페이지 접근 및 초기 상태 확인
- [x] ✅ **test_link4_access**: `/link4` 페이지가 정상적으로 로드되는지 확인 → **통과** (페이지 로드 및 타이틀 확인 완료)
- [x] ✅ **test_link4_initial_ui**: 초기 진입 시 "항목을 선택해주세요" 메시지가 표시되는지 확인 → **통과** (초기 안내 메시지 확인)
- [x] ✅ **test_link4_sidebar_categories**: 사이드바에 'IT Process Wide Controls', 'IT General Controls', '기타' 카테고리가 존재하는지 확인 → **통과** (모든 카테고리 구성 확인 완료)

## 2. 사이드바 인터랙션 및 컨텐츠 동적 로드
- [x] ✅ **test_link4_sidebar_toggle**: 카테고리 클릭 시 하위 옵션 목록이 펼쳐지거나 접히는지 확인 → **통과** (사이드바 토글 작동 확인)
- [x] ✅ **test_link4_content_loading**: 활성화된 항목(예: OVERVIEW) 클릭 시 영상 컨텐츠(iframe)가 로드되는지 확인 → **통과** (영상 컨텐츠(iframe) 로드 확인)
- [x] ✅ **test_link4_preparing_message**: 준비 중인 항목(예: IT General Controls > Data 직접변경 승인) 클릭 시 "준비 중입니다" 메시지가 표시되는지 확인 → **통과** (준비 중 메시지 표시 확인)

## 3. FontAwesome 아이콘

- [x] ✅ **test_link4_sidebar_chevron_icon**: 사이드바 카테고리 제목에 FontAwesome chevron-down 아이콘(`.fa-chevron-down`)이 표시되는지 확인 (v1.35 FontAwesome CSS 추가 반영) → **통과** (사이드바 chevron 아이콘 표시 확인 완료 (FontAwesome 정상 로드))

## 4. 로그인 및 활동 로그 (선택 사항)
- [x] ✅ **test_link4_activity_log**: 로그인 후 페이지 접근 시 활동 로그에 기록되는지 확인 → **통과** (로그인 상태에서 페이지 접근 완료)

---
## 테스트 결과 요약

| 항목 | 개수 | 비율 |
|------|------|------|
| ✅ 통과 | 8 | 100.0% |
| ❌ 실패 | 0 | 0.0% |
| ⚠️ 경고 | 0 | 0.0% |
| ⊘ 건너뜀 | 0 | 0.0% |
| **총계** | **8** | **100%** |
