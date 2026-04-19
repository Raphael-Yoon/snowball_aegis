# Common API: 공통 API Unit 테스트 시나리오

## 실행 방법

```bash
python test/test_unit_common_api.py
```

---

## 1. 서버 상태 확인 API

- [ ] **test_common_health_check**: `GET /health` 호출 시 `{"status": "ok", "host": ..., "timestamp": ...}` 형태의 응답을 반환하는지 확인

---

## 2. 메인 페이지 - 비로그인

- [ ] **test_common_index_guest**: 비로그인 상태에서 `GET /` 접근 시 환영 메시지(`.user-welcome`)가 없고 로그인 링크(`a[href='/login']`)가 표시되는지 확인

---

## 3. 메인 페이지 - 로그인

- [ ] **test_common_index_logged_in**: 로그인 후 `GET /` 접근 시 환영 메시지(`.user-welcome`)와 로그아웃 링크(`a[href='/logout']`)가 표시되는지 확인

---

## 4. 메인 페이지 카드 구성

- [ ] **test_common_index_cards**: 메인 페이지에 서비스 카드(`.feature-card`)가 존재하고 Dashboard, RCM, ELC, TLC, ITGC 카드 제목이 4개 이상 확인되는지 확인

---

## 5. 세션 초기화 API

- [ ] **test_common_clear_session**: 로그인 상태에서 `POST /clear_session` 호출 시 204 No Content 응답을 반환하는지 확인

---

## 6. 404 처리

- [ ] **test_common_404_handling**: 존재하지 않는 경로(`/nonexistent_path_xyz_test`) 접근 시 404 응답을 반환하는지 확인
