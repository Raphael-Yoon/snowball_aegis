"""
커넥터 레지스트리

새 시스템 커넥터 추가 방법:
1. connectors/새시스템_connector.py 작성 (BaseConnector 상속)
2. IMPLEMENTED_CONTROLS에 실제 구현된 통제코드 선언
3. 아래 REGISTRY에 system_code: 클래스 등록
"""
from .trade_connector import TradeConnector
from .infosd_connector import InfosdConnector
from .generic_connector import GenericConnector

REGISTRY: dict = {
    'TRADE':  TradeConnector,
    'INFOSD': InfosdConnector,
}


def get_connector_info(system_code: str) -> dict:
    """
    시스템 코드에 대한 커넥터 상태 정보 반환.
    UI에서 커넥터 완료 여부 표시에 사용.
    """
    code = system_code.upper()
    cls = REGISTRY.get(code)
    if cls and cls.is_ready():
        return {
            'has_connector': True,
            'connector_name': cls.__name__,
            'implemented_controls': sorted(cls.IMPLEMENTED_CONTROLS),
        }
    return {
        'has_connector': False,
        'connector_name': 'GenericConnector',
        'implemented_controls': [],
    }


def get_connector(system: dict, control_code: str = '', query: str = '', threshold: int = 0):
    """
    system_code에 맞는 커넥터 인스턴스 반환.
    - 등록된 커넥터가 있고 해당 통제가 구현돼 있으면 전용 커넥터 사용
    - 아니면 GenericConnector(쿼리 기반) 사용
    """
    code = system.get('system_code', '').upper()
    cls = REGISTRY.get(code)
    if cls and cls.is_ready() and (not control_code or control_code in cls.IMPLEMENTED_CONTROLS):
        return cls(system)
    return GenericConnector(system, control_code=control_code, query=query, threshold=threshold)
