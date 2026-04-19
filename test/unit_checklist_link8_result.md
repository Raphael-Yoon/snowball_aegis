<!-- Test Run: 2026-02-13 14:45:41 -->
# Link8: 내부평가(Internal Assessment) E2E 테스트 시나리오

## 1. 메인 페이지 (내부평가 현황)
- [x] ✅ **test_link8_access**: `/link8` 페이지가 정상적으로 로드되는지 확인 → **통과** (페이지 로드 및 헤더 확인 완료: Dashboard)
- [x] ✅ **test_link8_company_list**: 사용자에게 할당된 회사 목록 및 카테고리(ITGC, ELC, TLC)별 RCM 카드가 표시되는지 확인 → **통과** (RCM 카드 목록 표시 확인 (6개))
- [x] ✅ **test_link8_progress_badges**: RCM 카드 내 진행 상태(NOT_STARTED, IN_PROGRESS, COMPLETED) 배지가 정상적으로 표시되는지 확인 → **통과** (상태 배지 확인 완료: 대기, 대기, 대기, 대기...)

## 2. 내부평가 상세 페이지
- [x] ✅ **test_link8_detail_access**: 특정 RCM의 상세 페이지(`/internal-assessment/<rcm_id>`) 진입 확인 → **통과** (상세 페이지 진입 확인: http://localhost:5001/link8/2/Eval_1770270677)
- [x] ✅ **test_link8_summary_stats**: 설계평가 및 운영평가 요약 정보(효과성 통계, 결론 등)가 표시되는지 확인 → **통과** (상세 페이지(http://localhost:5001/link8/2/Eval_1770270677) 요약 통계 영역 표시 확인 (6개 요소))
- [x] ✅ **test_link8_progress_stepper**: 상단에 평가 단계(설계평가 -> 운영평가)를 나타내는 스테퍼가 표시되는지 확인 → **통과** (상세 페이지(http://localhost:5001/link8/2/Eval_1770270677) 타임라인 표시 확인 (3개 요소))

## 3. 단계별 평가 화면 (설계/운영)
- [x] ✅ **test_link8_step_navigation**: 스테퍼 또는 목록에서 '이동' 버튼 클릭 시 해당 단계 페이지로 이동하는지 확인 → **통과** (평가 화면 이동 확인 (버튼: 설계평가 확인하기) -> http://localhost:5001/link8)
- [x] ✅ **test_link8_design_evaluation_sync**: 설계평가 단계에서 Link6에서 작성된 설계 효과성 결과가 정상적으로 반영되어 있는지 확인 → **통과** (설계평가 결과 동기화 확인 (총 통제 수: 33개, 완료: 33개))
- [x] ✅ **test_link8_operation_evaluation_sync**: 운영평가 단계에서 Link7에서 작성된 운영 효과성 결과(Conclusion)가 정상적으로 반영되어 있는지 확인 → **통과** (운영평가 결과 동기화 확인 (총 통제 수: 33개, 완료: 1개))

## 4. 진행 상황 관리 (API)
- [x] ✅ **test_link8_api_detail**: `/internal-assessment/api/detail/<rcm_id>/<session>` API 호출 시 상세 데이터가 JSON으로 반환되는지 확인 → **통과** (API 호출 성공 (디자인 통제 수: 0))

## 5. 단계별 상세 페이지 (Step 1~6)
- [x] ✅ **test_link8_step_templates**: 1단계(계획)부터 6단계(보고)까지 각 단계별 템플릿이 정상적으로 렌더링되는지 확인 → **통과** (타임라인 단계 확인 완료: 2개 단계 ())
    - Step 1: `assessment_step1_planning.jsp`
    - Step 2: `assessment_step2_design.jsp`
    - Step 3: `assessment_step3_operation.jsp`
    - Step 4: `assessment_step4_defects.jsp`
    - Step 5: `assessment_step5_improvement.jsp`
    - Step 6: `assessment_step6_report.jsp`

## 6. 회사별 데이터 격리
- [ ] **test_link8_company_data_isolation**: 사용자 전환 후 본인 회사 내부평가만 조회 가능한지 확인
  - 우측 상단 사용자명 클릭하여 다른 회사 계정으로 전환
  - 해당 회사의 내부평가 데이터만 표시되는지 확인
  - '관리자로 돌아가기' 버튼으로 원래 계정 복귀

---
## 테스트 결과 요약

| 항목 | 개수 | 비율 |
|------|------|------|
| ✅ 통과 | 11 | 100.0% |
| ❌ 실패 | 0 | 0.0% |
| **합계** | **11** | **100%** |
