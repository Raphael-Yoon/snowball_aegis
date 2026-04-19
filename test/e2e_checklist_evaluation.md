# E2E 통합 테스트 시나리오

## 개요

ITGC/ELC/TLC 평가 업무의 전체 흐름을 검증하는 E2E(End-to-End) 테스트입니다.
RCM 업로드부터 설계평가, 운영평가까지의 전체 사이클을 테스트합니다.

## 실행 방법

```bash
# 타입별 실행
python test/test_e2e_evaluation.py --type=itgc
python test/test_e2e_evaluation.py --type=elc
python test/test_e2e_evaluation.py --type=tlc
python test/test_e2e_evaluation.py --type=all

# 배치 파일
test\run_e2e_itgc.bat
test\run_e2e_elc.bat
test\run_e2e_tlc.bat
test\run_e2e_all.bat
```

---

## Phase 1: RCM 관리 (공통)

RCM 업로드 및 기본 CRUD 기능을 검증합니다.

- [ ] **test_rcm_upload**: 테스트용 RCM 파일 업로드 및 성공 확인
- [ ] **test_rcm_list_display**: 업로드된 RCM이 목록에 정상 표시되는지 확인

### 검증 포인트
- RCM 파일(Excel) 업로드 성공
- 카테고리(ITGC/ELC/TLC) 올바르게 설정
- 목록 페이지에서 RCM 확인 가능

---

## Phase 2: 설계평가

설계평가 세션 생성부터 평가 완료(확정)까지의 흐름을 검증합니다.

- [ ] **test_design_create_session**: 설계평가 세션 생성 및 상세 페이지 진입
- [ ] **test_design_evaluate_control**: 개별 통제 항목 평가 수행 및 저장
- [ ] **test_design_complete**: 모든 항목 평가 후 완료(확정) 처리

### 검증 포인트
- 내부평가 시작 모달에서 RCM 선택 가능
- 평가명 입력 및 세션 생성
- 평가 모달에서 적절성/효과성 선택 및 저장
- 적정저장(일괄) 기능 동작
- 진행률 100% 시 완료 버튼 활성화
- 완료 처리 후 status=1 (확정) 상태 변경

---

## Phase 3: 운영평가

설계평가 완료 후 운영평가 수행을 검증합니다.

- [ ] **test_operation_create_session**: 운영평가 세션 시작 및 상세 페이지 진입
- [ ] **test_operation_evaluate_control**: 개별 통제 항목 운영평가 수행 및 저장
- [ ] **test_operation_dashboard**: 대시보드에서 평가 현황 반영 확인

### 검증 포인트
- 설계평가 완료(status=1)된 세션만 운영평가 진입 가능
- 운영평가 모달에서 효과성 선택 및 의견 입력
- 저장 후 평가 결과 반영
- 메인 대시보드에서 진행 현황 확인

---

## Phase 4: Cleanup (자동)

테스트 후 생성된 데이터를 역순으로 정리합니다.

1. 운영평가 세션 삭제
2. 설계평가 확정 취소 (status → 0)
3. 설계평가 세션 삭제
4. RCM 삭제

---

## 타입별 차이점

| 항목 | ITGC | ELC | TLC |
|------|------|-----|-----|
| 평가 페이지 | /itgc-evaluation | /elc-evaluation | /tlc-evaluation |
| 설계평가 URL | /design-evaluation/rcm | /elc-design-evaluation | /tlc-design-evaluation |
| 운영평가 URL | /operation-evaluation/rcm | /elc-operation-evaluation | /tlc-operation-evaluation |
| 통제 항목 | 접근권한, 변경관리, 운영보안 | 윤리강령, 이사회 독립성 | 거래 승인, 거래 검증 |

---

## 사전 조건

1. **서버 실행**: snowball 앱이 localhost:5001에서 실행 중
2. **로그인**: 관리자 계정으로 로그인 가능
3. **테스트 데이터**: 테스트 시작 시 자동 생성 (assets 폴더)

---

## 결과 파일

테스트 완료 후 결과 파일이 생성됩니다:
- `e2e_checklist_itgc_result.md`
- `e2e_checklist_elc_result.md`
- `e2e_checklist_tlc_result.md`
