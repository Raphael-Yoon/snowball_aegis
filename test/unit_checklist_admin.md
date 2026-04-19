# Admin: 관리자 기능 Unit 테스트 시나리오 (Y2K 강화)

## 실행 방법

```bash
python test/test_unit_admin.py
```

---

## 1. 관리자 페이지 접근 제어 (ITGC)

- [ ] **test_admin_no_access_without_login**: 비로그인 상태에서 /admin 접근 차단 확인
- [ ] **test_admin_no_access_wrong_user**: 일반 사용자 권한으로 /admin 접근 차단 확인 (403 Forbidden)

---

## 2. 관리자 대시보드

- [ ] **test_admin_dashboard_elements**: 대시보드 주요 카드 구성 요소 및 링크 확인

---

## 3. 사용자 관리 및 Mutation Test

- [ ] **test_admin_add_user_mutation**: 사용자 추가 API 유효성 및 DB 데이터 정합성 확인

---

## 4. 활동 로그 및 필터링

- [ ] **test_admin_logs_filtering**: 활동 로그 페이지 필터 요소 및 UI 확인
