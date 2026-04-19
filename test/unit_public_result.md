# Public 기능 통합 Unit 테스트 결과

- 실행 시간: 2026-02-12 13:16:51
- 소요 시간: 17.4초
- 모드: Browser

## 테스트 대상

| Link | 설명 | Public |
|------|------|--------|
| Link1 | RCM 생성 | O |
| Link2 | 인터뷰/설계평가 | O |
| Link3 | 조서 템플릿 | O |
| Link4 | 컨텐츠 | O |
| Link9 | 문의/피드백 | O |
| Link10 | AI 결과 | O |
| Link11 | 공시 | O |

## 요약 (그룹별)

### ✅ Link1 (10/10)

| 그룹 | 결과 | 상태 |
|------|------|------|
| 1번 | 2/2 | ✅ |
| 2번 | 2/2 | ✅ |
| 3번 | 3/3 | ✅ |
| 4번 | 3/3 | ✅ |

## 상세 결과

### Link1 상세

#### 1번 (2/2)

| 테스트 | 상태 | 메시지 |
|--------|------|--------|
| test_link1_page_access | ✅ | 페이지 접근 및 기본 요소 확인 완료 |
| test_link1_form_elements | ✅ | 모든 폼 요소 확인 완료 |

#### 2번 (2/2)

| 테스트 | 상태 | 메시지 |
|--------|------|--------|
| test_link1_os_version_toggle | ✅ | OS 선택에 따른 UI 변화 확인 완료 |
| test_link1_cloud_env_toggle | ✅ | Cloud 환경 선택에 따른 UI 변화 확인 완료 |

#### 3번 (3/3)

| 테스트 | 상태 | 메시지 |
|--------|------|--------|
| test_link1_control_table | ✅ | 통제 테이블 확인 완료 |
| test_link1_toggle_detail | ✅ | 상세 펼치기/접기 기능 확인 완료 |
| test_link1_type_change_monitoring | ✅ | 자동→수동 변경 시 모니터링 명칭 변경 확인 |

#### 4번 (3/3)

| 테스트 | 상태 | 메시지 |
|--------|------|--------|
| test_link1_population_templates_api | ✅ | 모집단 템플릿 API 정상 동작 |
| test_link1_email_input | ✅ | 이메일 입력 및 발송 버튼 확인 완료 |
| test_link1_export_email_validation | ✅ | 이메일 미입력 시 발송 방지 동작 확인 |

---

## 전체 요약

- 총 테스트: 10
- 통과: 10 (100.0%)
- 실패: 0 (0.0%)
