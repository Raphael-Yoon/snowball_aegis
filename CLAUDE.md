# Snowball Aegis 기술 명세 (Technical Specs)

> [!IMPORTANT]
> 에이전트 페르소나, 직급 체계 및 전사 운영 규칙은 루트의 [global_rules.md](file:///c:/Python/.agent/rules/global_rules.md)를 준수한다. 본 파일은 프로젝트별 기술 명령어 및 파일 참조용으로만 활용한다.

## 1. 프로젝트 개요
**Snowball Aegis**는 Snowball 프로젝트의 Core(Link 5~8: RCM 및 운영평가)를 계승하고, 여기에 실시간 4대 모집단 모니터링 기능을 결합한 실시간 ITGC 감사 대응 시스템이다.

## 2. 주요 실행 명령어 (Workflows)

- **애플리케이션 실행**: `python snowball.py` (Aegis 모드)
- **모니터링 엔진(신규) 실행**: `python aegis_monitor.py`
- **모집단 추출 연동**: `python extractors/pop_connector.py`
- **관리자 기능**: `python snowball_admin.py`

## 3. 프로젝트 구성 (Core Modules)

| 모듈 | 설명 | 상태 |
|------|------|------|
| `auth.py` | 로그인 및 세션 관리 | **보존 (Existing)** |
| `snowball_admin.py` | 어드민 관리 기능 | **보존 (Existing)** |
| `snowball_link5.py` | RCM (Risk Control Matrix) 관리 | **보존 (Existing)** |
| `snowball_link6.py` | 설계평가 (Design Test) 로직 | **보존 (Existing)** |
| `snowball_link7.py` | 운영평가 (Operating Test) 로직 | **보존 (Existing)** |
| `snowball_link8.py` | 통제 테스트 및 샘플링 | **보존 (Existing)** |
| `aegis_monitor.py` | 실시간 모집단 대조 및 모니터링 | **신규 (To be Added)** |

## 4. 환경 관리 원칙 (Local)

- **보존 대상**: `snowball.db`, `static/`, `templates/`, `link5~8.py`
- **제거 대상 (Pruning)**: `link1~4.py`, `link9~11.py` 및 대외 공시 관련 Public 템플릿
- **삭제 지침**: 작업 중 생성한 임시 `.py` 스크립트 및 디버깅 데이터는 완료 후 즉시 제거
