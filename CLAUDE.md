# Aegis 모니터링 시스템 기술 명세 (Technical Specs)

> [!IMPORTANT]
> 에이전트 페르소나, 직급 체계 및 전사 운영 규칙은 루트의 [CLAUDE.md](file:///c:/Python/CLAUDE.md)를 준수한다. 본 파일은 프로젝트별 기술 명령어 및 파일 참조용으로만 활용한다.

## 1. 프로젝트 개요
**Aegis Monitoring System**은 Snowball 프로젝트에서 독립되어 실시간 ITGC 감사 대응에 특화된 모니터링 플랫폼이다. 불필요한 레거시(RCM 관리, 설계/운영평가 등)를 제거하고 실시간 4대 모집단(APD/PC/PD/CO) 모니터링 및 배치 실행 기능에 집중한다.

## 2. 주요 실행 명령어 (Workflows)

- **애플리케이션 실행**: `python snowball.py` (메인 플라스크 앱)
- **모니터링 대시보드**: `/aegis/dashboard` 경로 접속
- **배치 엔진 실행**: `python aegis_batch.py`
- **사용자/로그 관리**: `python snowball_admin.py` (Blueprint)

## 3. 핵심 모듈 구성 (Core Modules)

| 모듈 | 설명 | 상태 |
|------|------|------|
| `auth.py` | 사용자 인증, DB 유틸리티, 활동 로그 | **경량화 완료** |
| `snowball.py` | 메인 앱 엔트리포인트 및 설정 | **최적화 완료** |
| `aegis_monitor.py` | 모니터링 엔진 및 결과 조회 | **핵심 기능** |
| `aegis_systems.py` | 모니터링 대상 시스템 설정 | **핵심 기능** |
| `aegis_controls.py` | ITGC 기준통제 및 시스템 매핑 | **핵심 기능** |
| `snowball_admin.py` | 사용자 계정 및 시스템 접속 로그 관리 | **최적화 완료** |

## 4. 환경 관리 원칙 (Local)

- **DB 관리**: `snowball.db` 내 `aegis_` 프리픽스 테이블이 핵심 데이터 모델이다.
- **클린업 완료**: `link1~11.py`, `evaluation_utils.py`, `gmail_schedule.py` 등 레거시 모듈이 모두 제거되었다.
- **버전 관리**: `migrations/versions`에는 Aegis 전용 스키마 정의 파일(040번 이후)만 유지한다.
