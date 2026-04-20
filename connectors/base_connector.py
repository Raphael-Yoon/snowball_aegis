"""
Aegis 커넥터 추상 베이스 클래스

모든 시스템 커넥터는 이 클래스를 상속하고,
적용 가능한 통제 메서드를 구현한다.

반환 형식 (공통):
    {
        'exception_count': int,   # 예외 건수 (0이면 PASS)
        'total_count':     int,   # 전체 점검 대상 건수
        'rows':            list,  # 예외 상세 레코드 (최대 100건)
        'message':         str,   # 요약 메시지 (선택)
    }
"""
from abc import ABC
from datetime import date


class BaseConnector(ABC):

    # 실제 구현이 완료된 통제코드 목록. 서브클래스에서 반드시 선언.
    IMPLEMENTED_CONTROLS: frozenset = frozenset()

    def __init__(self, system: dict):
        """
        system: aegis_system 테이블의 row dict
        """
        self.system = system
        self.system_code = system.get('system_code', '')
        self.run_date = date.today().isoformat()

    @classmethod
    def is_ready(cls) -> bool:
        """구현 완료된 통제가 하나라도 있으면 True"""
        return len(cls.IMPLEMENTED_CONTROLS) > 0

    # ------------------------------------------------------------------
    # 공통 유틸
    # ------------------------------------------------------------------

    def result(self, rows: list, total_count: int = None, message: str = '') -> dict:
        """표준 결과 dict 생성"""
        rows = rows or []
        return {
            'exception_count': len(rows),
            'total_count': total_count if total_count is not None else len(rows),
            'rows': rows[:100],
            'message': message,
        }

    def not_applicable(self, reason: str = '해당 시스템에 적용되지 않는 통제입니다.') -> dict:
        """이 시스템에 적용 불가한 통제일 때 반환"""
        return {
            'exception_count': 0,
            'total_count': 0,
            'rows': [],
            'message': f'[N/A] {reason}',
        }

    def not_implemented(self, control_code: str) -> dict:
        """아직 구현되지 않은 통제"""
        return {
            'exception_count': 0,
            'total_count': 0,
            'rows': [],
            'message': f'[미구현] {control_code} 점검 로직이 아직 작성되지 않았습니다.',
        }

    # ------------------------------------------------------------------
    # APD - Access to Programs & Data
    # ------------------------------------------------------------------

    def check_APD01(self) -> dict:
        """사용자 계정 생성 및 부여 - 승인 없이 생성된 계정"""
        return self.not_implemented('APD-01')

    def check_APD02(self) -> dict:
        """사용자 접근권한 변경 - 승인 없이 변경된 권한"""
        return self.not_implemented('APD-02')

    def check_APD03(self) -> dict:
        """사용자 계정 삭제/비활성화 - 만료 후 미처리 계정"""
        return self.not_implemented('APD-03')

    def check_APD04(self) -> dict:
        """주기적 접근권한 검토 - 미검토 계정"""
        return self.not_implemented('APD-04')

    # ------------------------------------------------------------------
    # PC - Program Changes
    # ------------------------------------------------------------------

    def check_PC01(self) -> dict:
        """변경 요청 등록 및 승인 - 미승인 변경"""
        return self.not_implemented('PC-01')

    def check_PC02(self) -> dict:
        """변경 테스트 수행 - 테스트 미수행 배포"""
        return self.not_implemented('PC-02')

    def check_PC03(self) -> dict:
        """운영 배포 승인 - 미승인 배포"""
        return self.not_implemented('PC-03')

    # ------------------------------------------------------------------
    # PD - Program Development
    # ------------------------------------------------------------------

    def check_PD01(self) -> dict:
        """개발 방법론 준수"""
        return self.not_implemented('PD-01')

    def check_PD02(self) -> dict:
        """개발-운영 환경 분리"""
        return self.not_implemented('PD-02')

    # ------------------------------------------------------------------
    # CO - Computer Operations
    # ------------------------------------------------------------------

    def check_CO01(self) -> dict:
        """배치 작업 모니터링 - 실패한 배치"""
        return self.not_implemented('CO-01')

    def check_CO02(self) -> dict:
        """백업 수행 확인 - 미수행 백업"""
        return self.not_implemented('CO-02')

    def check_CO03(self) -> dict:
        """장애 및 이슈 처리 - 미처리 장애"""
        return self.not_implemented('CO-03')

    # ------------------------------------------------------------------
    # 디스패처: 통제코드 → 메서드 호출
    # ------------------------------------------------------------------

    _DISPATCH = {
        'APD-01': 'check_APD01', 'APD-02': 'check_APD02',
        'APD-03': 'check_APD03', 'APD-04': 'check_APD04',
        'PC-01':  'check_PC01',  'PC-02':  'check_PC02',  'PC-03': 'check_PC03',
        'PD-01':  'check_PD01',  'PD-02':  'check_PD02',
        'CO-01':  'check_CO01',  'CO-02':  'check_CO02',  'CO-03': 'check_CO03',
    }

    def run(self, control_code: str) -> dict:
        """통제코드를 받아 해당 메서드를 실행하고 결과 반환"""
        method_name = self._DISPATCH.get(control_code)
        if not method_name:
            return self.not_implemented(control_code)
        return getattr(self, method_name)()
