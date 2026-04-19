"""
통합 평가 테이블(sb_evaluation_header, sb_evaluation_line) 관련 유틸리티 함수
ELC, TLC, ITGC 모든 평가 유형에서 사용
status와 progress를 line 데이터 기반으로 실시간 계산
"""

def calculate_design_progress(conn, header_id):
    """
    설계평가 진행률 계산

    Returns:
        int: 진행률 (0-100)
    """
    # 전체 통제 수
    total = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ?
    ''', (header_id,)).fetchone()
    total_count = dict(total)['count'] if total else 0

    if total_count == 0:
        return 0

    # 설계평가 완료 통제 수 (overall_effectiveness가 NULL이 아닌 것)
    completed = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ? AND overall_effectiveness IS NOT NULL
    ''', (header_id,)).fetchone()
    completed_count = dict(completed)['count'] if completed else 0

    return int((completed_count / total_count) * 100)


def calculate_operation_progress(conn, header_id):
    """
    운영평가 진행률 계산 (핵심통제 중 설계평가 결과가 '적정'인 통제만 대상)

    Returns:
        int: 진행률 (0-100)
    """
    # 설계평가 결과가 '적정'(effective)인 통제 수 (운영평가 대상)
    total = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ? AND overall_effectiveness IN ('적정', 'effective', '효과적')
    ''', (header_id,)).fetchone()
    total_count = dict(total)['count'] if total else 0

    if total_count == 0:
        return 0

    # 운영평가 완료 통제 수 (conclusion이 NULL이 아닌 것)
    completed = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ? AND overall_effectiveness IN ('적정', 'effective', '효과적') AND conclusion IS NOT NULL
    ''', (header_id,)).fetchone()
    completed_count = dict(completed)['count'] if completed else 0

    return int((completed_count / total_count) * 100)


# DEPRECATED: status는 더 이상 실시간 계산하지 않음
# DB에 저장된 status 값을 사용 (get_evaluation_status 참조)
# def calculate_status(conn, header_id):
#     """
#     평가 상태 계산 (line 데이터 기반)
#
#     이 함수는 더 이상 사용되지 않습니다.
#     status는 사용자 액션에 의해 명시적으로 변경되어야 합니다:
#     - 설계평가 시작: status = 0
#     - 설계평가 완료: status = 1
#     - 운영평가 시작: status = 2
#     - 운영평가 진행중: status = 3
#     - 운영평가 완료: status = 4
#     - 아카이브: archived = 1, status = 5 (표시용)
#     """
#     pass


def get_evaluation_status(conn, header_id):
    """
    평가 상태 정보 조회 (status, design_progress, operation_progress 포함)

    Returns:
        dict: {
            'status': int,
            'design_progress': int,
            'operation_progress': int,
            'design_completed_count': int,
            'design_total_count': int,
            'operation_completed_count': int,
            'operation_total_count': int
        }
    """
    # 전체 통제 수
    total = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ?
    ''', (header_id,)).fetchone()
    design_total = dict(total)['count'] if total else 0

    # 설계평가 완료 통제 수
    design_completed = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ? AND overall_effectiveness IS NOT NULL
    ''', (header_id,)).fetchone()
    design_completed_count = dict(design_completed)['count'] if design_completed else 0

    # 운영평가 대상 통제 수 (설계평가 결과가 '적정'(effective)인 것)
    operation_total = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ? AND overall_effectiveness IN ('적정', 'effective', '효과적')
    ''', (header_id,)).fetchone()
    operation_total_count = dict(operation_total)['count'] if operation_total else 0

    # 운영평가 완료 통제 수
    operation_completed = conn.execute('''
        SELECT COUNT(*) as count
        FROM sb_evaluation_line
        WHERE header_id = ? AND overall_effectiveness IN ('적정', 'effective', '효과적') AND conclusion IS NOT NULL
    ''', (header_id,)).fetchone()
    operation_completed_count = dict(operation_completed)['count'] if operation_completed else 0

    design_progress = int((design_completed_count / design_total) * 100) if design_total > 0 else 0
    operation_progress = int((operation_completed_count / operation_total_count) * 100) if operation_total_count > 0 else 0

    # DB에 저장된 status 사용 (실시간 계산하지 않음)
    header = conn.execute('''
        SELECT status, archived
        FROM sb_evaluation_header
        WHERE header_id = ?
    ''', (header_id,)).fetchone()

    if header:
        header_dict = dict(header)
        # archived가 1이면 status = 5로 처리
        if header_dict.get('archived', 0) == 1:
            status = 5
        else:
            status = header_dict.get('status', 0)
    else:
        status = 0

    return {
        'status': status,
        'design_progress': design_progress,
        'operation_progress': operation_progress,
        'design_completed_count': design_completed_count,
        'design_total_count': design_total,
        'operation_completed_count': operation_completed_count,
        'operation_total_count': operation_total_count
    }
