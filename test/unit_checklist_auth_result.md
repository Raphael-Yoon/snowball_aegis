<!-- Test Run: 2026-02-20 22:12:40 -->
# Auth: 인증/세션 Unit 테스트 시나리오 (Y2K 강화)

## 실행 방법

```bash
python test/test_unit_auth.py
```

---

## 1. 로그인 보안 구성

- [x] **test_auth_login_page_security**: 로그인 페이지 필수 입력 요소 및 보안 구성 확인

---

## 2. OTP 프로세스 검증

- [x] **test_auth_otp_process_mocked**: Mock Mail 기반 OTP 발송 및 로그인 성공 확인
- [x] **test_auth_otp_limit_check**: 잘못된 OTP 입력 시도 횟수 제한(3회) 작동 여부 확인

---

## 3. 세션 및 쿠키 보안

- [x] **test_auth_session_cookie_security**: 세션 쿠키의 HttpOnly, SameSite 속성 준수 여부 확인


## 테스트 결과 요약

| 항목 | 개수 | 비율 |
|------|------|------|
| ✅ 통과 | 4 | 100.0% |
| ❌ 실패 | 0 | 0.0% |
| ⚠️ 경고 | 0 | 0.0% |
| ⊘ 건너뜀 | 0 | 0.0% |
| **총계** | **4** | **100%** |
