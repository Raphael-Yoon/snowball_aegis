import json
from datetime import date
from flask import Blueprint, request, jsonify, render_template, session
from auth import login_required, get_current_user
from db_config import get_db
from logger_config import get_logger
from connectors import get_connector

logger = get_logger('aegis_monitor')
bp_aegis_monitor = Blueprint('aegis_monitor', __name__)

CATEGORY_LABELS = {
    'APD': 'Access to Programs & Data',
    'PC':  'Program Changes',
    'PD':  'Program Development',
    'CO':  'Computer Operations',
}


def get_user_info():
    return session.get('user_info') or get_current_user()


# ---------------------------------------------------------------------------
# 모니터링 엔진
# ---------------------------------------------------------------------------

def run_control_check(system: dict, control: dict, mapping: dict) -> dict:
    """
    커넥터를 통해 단일 통제-시스템 점검 수행.
    - 등록된 커넥터(TradeConnector 등)가 있으면 해당 클래스의 메서드 호출
    - 없으면 GenericConnector(SQL 쿼리 기반) 폴백
    """
    control_code = control['control_code']
    query = mapping.get('custom_query') or control.get('monitor_query') or ''
    threshold = int(mapping.get('threshold_count') or 0)

    try:
        connector = get_connector(system, control_code=control_code, query=query, threshold=threshold)
        raw = connector.run(control_code)

        exception_count = raw.get('exception_count', 0)
        status = 'PASS' if exception_count <= threshold else 'FAIL'

        # [N/A] 또는 [미구현] 메시지면 PENDING 처리
        msg = raw.get('message', '')
        if msg.startswith('[N/A]') or msg.startswith('[미구현]'):
            status = 'PENDING'

        return {
            'status': status,
            'total_count': raw.get('total_count', 0),
            'exception_count': exception_count,
            'result_detail': json.dumps({
                'rows': raw.get('rows', [])[:100],
                'message': msg,
                'truncated': len(raw.get('rows', [])) > 100,
            }, ensure_ascii=False, default=str),
        }

    except Exception as e:
        logger.error(f"[Monitor] {system['system_code']}-{control_code} 오류: {e}")
        return {
            'status': 'ERROR',
            'total_count': 0,
            'exception_count': 0,
            'result_detail': json.dumps({'error': str(e)}, ensure_ascii=False),
        }


def run_batch(run_date: str = None, system_id: int = None, control_id: int = None):
    """
    일배치 실행. 활성 통제-시스템 매핑 전체(또는 특정 조합)에 대해 모니터링 수행.
    run_date: 'YYYY-MM-DD' (기본값: 오늘)
    """
    run_date = run_date or date.today().isoformat()
    logger.info(f"[Batch] 배치 시작 - run_date={run_date}")

    with get_db() as conn:
        query = '''
            SELECT cs.mapping_id, cs.control_id, cs.system_id,
                   cs.custom_query, cs.threshold_count,
                   c.control_code, c.control_name, c.category, c.monitor_query,
                   s.system_code, s.system_name, s.db_type, s.db_host,
                   s.db_port, s.db_name, s.db_user, s.db_password, s.db_path
            FROM aegis_control_system cs
            JOIN aegis_control c ON cs.control_id = c.control_id
            JOIN aegis_system s ON cs.system_id = s.system_id
            WHERE cs.is_active = 'Y' AND c.is_active = 'Y' AND s.is_active = 'Y'
        '''
        params = []
        if system_id:
            query += ' AND cs.system_id = ?'
            params.append(system_id)
        if control_id:
            query += ' AND cs.control_id = ?'
            params.append(control_id)

        mappings = conn.execute(query, params).fetchall()

    results = []
    for row in mappings:
        m = dict(row)
        system = {k: m[k] for k in ('system_code', 'system_name', 'db_type', 'db_host',
                                     'db_port', 'db_name', 'db_user', 'db_password', 'db_path')}
        control = {k: m[k] for k in ('control_code', 'control_name', 'category', 'monitor_query')}
        mapping = {'custom_query': m['custom_query'], 'threshold_count': m['threshold_count']}

        result = run_control_check(system, control, mapping)

        with get_db() as conn:
            conn.execute('''
                INSERT INTO aegis_result
                    (control_id, system_id, run_date, total_count, exception_count, status, result_detail, run_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
            ''', (
                m['control_id'], m['system_id'], run_date,
                result['total_count'], result['exception_count'],
                result['status'], result['result_detail'],
            ))
            conn.commit()

        results.append({
            'system_code': m['system_code'],
            'control_code': m['control_code'],
            **result,
        })
        logger.info(f"[Batch] {m['system_code']}-{m['control_code']}: {result['status']}")

    logger.info(f"[Batch] 배치 완료 - {len(results)}건 처리")
    return results


# ---------------------------------------------------------------------------
# Flask Blueprint Routes
# ---------------------------------------------------------------------------

@bp_aegis_monitor.route('/aegis/dashboard')
@login_required
def dashboard():
    user_info = get_user_info()
    today = date.today().isoformat()

    with get_db() as conn:
        systems = conn.execute(
            'SELECT * FROM aegis_system WHERE is_active = ? ORDER BY system_code', ('Y',)
        ).fetchall()

        controls = conn.execute(
            'SELECT * FROM aegis_control WHERE is_active = ? ORDER BY category, control_code', ('Y',)
        ).fetchall()

        # 오늘 날짜 기준 최신 결과 (없으면 가장 최근 날짜)
        latest_date = conn.execute(
            'SELECT MAX(run_date) as max_date FROM aegis_result'
        ).fetchone()
        result_date = (dict(latest_date)['max_date'] or today) if latest_date else today

        results = conn.execute(
            'SELECT * FROM aegis_result WHERE run_date = ?', (result_date,)
        ).fetchall()

        # 요약 통계
        stats = conn.execute('''
            SELECT status, COUNT(*) as cnt FROM aegis_result
            WHERE run_date = ? GROUP BY status
        ''', (result_date,)).fetchall()

    result_map = {}
    for r in results:
        rd = dict(r)
        result_map[(rd['control_id'], rd['system_id'])] = rd

    stats_dict = {dict(s)['status']: dict(s)['cnt'] for s in stats}

    return render_template('aegis_dashboard.jsp',
                           systems=[dict(s) for s in systems],
                           controls=[dict(c) for c in controls],
                           result_map=result_map,
                           result_date=result_date,
                           stats=stats_dict,
                           category_labels=CATEGORY_LABELS,
                           user_info=user_info,
                           is_logged_in=True)


@bp_aegis_monitor.route('/aegis/results')
@login_required
def results_view():
    user_info = get_user_info()
    run_date = request.args.get('run_date', date.today().isoformat())
    system_id = request.args.get('system_id', type=int)
    category = request.args.get('category')
    status = request.args.get('status')

    with get_db() as conn:
        query = '''
            SELECT r.*, c.control_code, c.control_name, c.category,
                   s.system_code, s.system_name
            FROM aegis_result r
            JOIN aegis_control c ON r.control_id = c.control_id
            JOIN aegis_system s ON r.system_id = s.system_id
            WHERE r.run_date = ?
        '''
        params = [run_date]
        if system_id:
            query += ' AND r.system_id = ?'
            params.append(system_id)
        if category:
            query += ' AND c.category = ?'
            params.append(category)
        if status:
            query += ' AND r.status = ?'
            params.append(status)
        query += ' ORDER BY c.category, c.control_code, s.system_code'

        results = conn.execute(query, params).fetchall()
        systems = conn.execute(
            'SELECT system_id, system_code, system_name FROM aegis_system WHERE is_active = ? ORDER BY system_code', ('Y',)
        ).fetchall()
        run_dates = conn.execute(
            'SELECT DISTINCT run_date FROM aegis_result ORDER BY run_date DESC LIMIT 30'
        ).fetchall()

    return render_template('aegis_results.jsp',
                           results=[dict(r) for r in results],
                           systems=[dict(s) for s in systems],
                           run_dates=[dict(d)['run_date'] for d in run_dates],
                           run_date=run_date,
                           selected_system=system_id,
                           selected_category=category,
                           selected_status=status,
                           category_labels=CATEGORY_LABELS,
                           user_info=user_info,
                           is_logged_in=True)


@bp_aegis_monitor.route('/api/aegis/run-batch', methods=['POST'])
@login_required
def api_run_batch():
    """수동 배치 실행 (관리자 또는 버튼 트리거)"""
    data = request.get_json() or {}
    run_date = data.get('run_date', date.today().isoformat())
    system_id = data.get('system_id')
    control_id = data.get('control_id')

    try:
        results = run_batch(run_date=run_date, system_id=system_id, control_id=control_id)
        pass_count = sum(1 for r in results if r['status'] == 'PASS')
        fail_count = sum(1 for r in results if r['status'] == 'FAIL')
        error_count = sum(1 for r in results if r['status'] == 'ERROR')
        return jsonify({
            'success': True,
            'message': f"배치 완료 - 총 {len(results)}건 (PASS: {pass_count}, FAIL: {fail_count}, ERROR: {error_count})",
            'results': results,
        })
    except Exception as e:
        logger.error(f"[API] 배치 실행 오류: {e}")
        return jsonify({'success': False, 'message': str(e)}), 500


@bp_aegis_monitor.route('/api/aegis/results', methods=['GET'])
@login_required
def api_results():
    run_date = request.args.get('run_date', date.today().isoformat())
    with get_db() as conn:
        results = conn.execute('''
            SELECT r.*, c.control_code, c.control_name, c.category,
                   s.system_code, s.system_name
            FROM aegis_result r
            JOIN aegis_control c ON r.control_id = c.control_id
            JOIN aegis_system s ON r.system_id = s.system_id
            WHERE r.run_date = ?
            ORDER BY c.category, c.control_code
        ''', (run_date,)).fetchall()
    return jsonify({'success': True, 'results': [dict(r) for r in results]})


@bp_aegis_monitor.route('/api/aegis/results/<int:result_id>', methods=['GET'])
@login_required
def api_result_detail(result_id):
    with get_db() as conn:
        result = conn.execute('''
            SELECT r.*, c.control_code, c.control_name, c.category, c.description,
                   s.system_code, s.system_name
            FROM aegis_result r
            JOIN aegis_control c ON r.control_id = c.control_id
            JOIN aegis_system s ON r.system_id = s.system_id
            WHERE r.result_id = ?
        ''', (result_id,)).fetchone()
    if not result:
        return jsonify({'success': False, 'message': '결과를 찾을 수 없습니다.'}), 404
    return jsonify({'success': True, 'result': dict(result)})
