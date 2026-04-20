# AEGIS - ITGC 실시간 모니터링 시스템 컨셉

## 0. 미션 (Mission)
**"상시 감사(Continuous Auditing) 체계로의 전환"**
- 연 1회/분기 1회 수행하는 사후적 ITGC 샘플링 테스트에서 벗어나, 365일 실시간으로 모집단(Population)의 무결성을 감시한다.

---

## 1. 핵심 가치 (Core Values)
1. **Real-time**: 배치(Batch) 엔진을 통한 주기적 모집단 추출 및 시그니처 대조
2. **Lean**: 불필요한 수동 평가 로직(RCM, 설계/운영테스트)을 제거한 경량화된 엔진
3. **Automated**: Jira/GitHub/DB Log 등 이기종 시스템과의 커넥터 기반 자동 분석

---

## 2. 주요 기능 및 범위 (Final Scope)

### 2.1 현재 구현 범위 (Done)
- **4대 통제 영역 모니터링**: APD(권한), PC(변경), PD(개발), CO(운영)
- **커넥터 아키텍처**: 각 타겟 시스템(infosd, trade 등)별 독립 커넥터
- **통제-시스템 매핑**: 기준통제와 시스템별 쿼리/임계치 커스터마이징
- **대시보드**: 통제 유효성 실시간 상태 및 예외(Exception) 건수 가시화
- **사용자 관리**: Aegis 시스템 접근 권한 및 활동 로그 기록

---

## 3. 데이터 모델 (Data Model - Optimized)

- **sb_user**: 시스템 사용자 정보
- **sb_user_activity_log**: 활동 로그
- **aegis_system**: 모니터링 대상 원천 시스템 정보
- **aegis_control**: ITGC 기준 통제 정의 (APD, PC, PD, CO)
- **aegis_control_system**: 통제-시스템 매핑 및 커스텀 쿼리 정보
- **aegis_result**: 배치 실행 결과 및 예외 탐지 데이터

---

## 4. 향후 계획 (Future Roadmap)
- 설계/운영평가 모듈은 Aegis 모니터링 결과를 기반으로 하는 **자동 평가 엔진**으로 재설계하여 통합 예정. (기존 Snowball 레거시는 현재 모두 제거됨)
