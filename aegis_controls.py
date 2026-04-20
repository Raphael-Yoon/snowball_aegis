from flask import Blueprint, request, jsonify, render_template, session
from auth import login_required, get_current_user
from db_config import get_db
from connectors import get_connector_info

bp_aegis_controls = Blueprint('aegis_controls', __name__)

CATEGORIES = ('APD', 'PC', 'PD', 'CO')
CATEGORY_LABELS = {
    'APD': 'Access to Programs & Data',
    'PC':  'Program Changes',
    'PD':  'Program Development',
    'CO':  'Computer Operations',
}


def get_user_info():
    return session.get('user_info') or get_current_user()


@bp_aegis_controls.route('/aegis/controls')
@login_required
def controls_list():
    user_info = get_user_info()
    with get_db() as conn:
        controls = conn.execute(
            'SELECT * FROM aegis_control ORDER BY category, control_code'
        ).fetchall()
        systems = conn.execute(
            'SELECT system_id, system_code, system_name FROM aegis_system WHERE is_active = ? ORDER BY system_code',
            ('Y',)
        ).fetchall()
        systems = [{**dict(s), **get_connector_info(s['system_code'])} for s in systems]
        mappings = conn.execute(
            'SELECT * FROM aegis_control_system WHERE is_active = ?', ('Y',)
        ).fetchall()

    mapping_set = {(m['control_id'], m['system_id']) for m in mappings}

    return render_template('aegis_controls.jsp',
                           controls=[dict(c) for c in controls],
                           systems=[dict(s) for s in systems],
                           mapping_set=mapping_set,
                           categories=CATEGORIES,
                           category_labels=CATEGORY_LABELS,
                           user_info=user_info,
                           is_logged_in=True)


@bp_aegis_controls.route('/api/aegis/controls', methods=['GET'])
@login_required
def api_controls_list():
    category = request.args.get('category')
    with get_db() as conn:
        if category and category in CATEGORIES:
            controls = conn.execute(
                'SELECT * FROM aegis_control WHERE category = ? ORDER BY control_code',
                (category,)
            ).fetchall()
        else:
            controls = conn.execute(
                'SELECT * FROM aegis_control ORDER BY category, control_code'
            ).fetchall()
    return jsonify({'success': True, 'controls': [dict(c) for c in controls]})


@bp_aegis_controls.route('/api/aegis/controls', methods=['POST'])
@login_required
def api_control_create():
    data = request.get_json()
    required = ['control_code', 'category', 'control_name']
    if not all(data.get(f) for f in required):
        return jsonify({'success': False, 'message': '필수 항목을 입력해주세요.'}), 400

    if data['category'] not in CATEGORIES:
        return jsonify({'success': False, 'message': f"카테고리는 {CATEGORIES} 중 하나여야 합니다."}), 400

    with get_db() as conn:
        existing = conn.execute(
            'SELECT control_id FROM aegis_control WHERE control_code = ?',
            (data['control_code'].upper(),)
        ).fetchone()
        if existing:
            return jsonify({'success': False, 'message': f"통제코드 '{data['control_code']}'가 이미 존재합니다."}), 400

        conn.execute('''
            INSERT INTO aegis_control (control_code, category, control_name, description, monitor_query, is_active)
            VALUES (?, ?, ?, ?, ?, 'Y')
        ''', (
            data['control_code'].upper(),
            data['category'],
            data['control_name'],
            data.get('description', ''),
            data.get('monitor_query', ''),
        ))
        conn.commit()

    return jsonify({'success': True, 'message': f"통제 '{data['control_name']}'이 등록되었습니다."})


@bp_aegis_controls.route('/api/aegis/controls/<int:control_id>', methods=['PUT'])
@login_required
def api_control_update(control_id):
    data = request.get_json()
    with get_db() as conn:
        existing = conn.execute(
            'SELECT control_id FROM aegis_control WHERE control_id = ?', (control_id,)
        ).fetchone()
        if not existing:
            return jsonify({'success': False, 'message': '통제를 찾을 수 없습니다.'}), 404

        conn.execute('''
            UPDATE aegis_control SET
                control_name = ?, description = ?, monitor_query = ?, is_active = ?
            WHERE control_id = ?
        ''', (
            data.get('control_name'),
            data.get('description', ''),
            data.get('monitor_query', ''),
            data.get('is_active', 'Y'),
            control_id,
        ))
        conn.commit()

    return jsonify({'success': True, 'message': '통제 정보가 업데이트되었습니다.'})


# 통제-시스템 매핑 관리
@bp_aegis_controls.route('/api/aegis/controls/<int:control_id>/systems', methods=['GET'])
@login_required
def api_control_systems(control_id):
    with get_db() as conn:
        mappings = conn.execute('''
            SELECT cs.*, s.system_code, s.system_name
            FROM aegis_control_system cs
            JOIN aegis_system s ON cs.system_id = s.system_id
            WHERE cs.control_id = ? AND cs.is_active = ?
            ORDER BY s.system_code
        ''', (control_id, 'Y')).fetchall()
    return jsonify({'success': True, 'mappings': [dict(m) for m in mappings]})


@bp_aegis_controls.route('/api/aegis/mappings', methods=['POST'])
@login_required
def api_mapping_create():
    data = request.get_json()
    control_id = data.get('control_id')
    system_id = data.get('system_id')

    if not control_id or not system_id:
        return jsonify({'success': False, 'message': 'control_id와 system_id가 필요합니다.'}), 400

    with get_db() as conn:
        existing = conn.execute(
            'SELECT mapping_id, is_active FROM aegis_control_system WHERE control_id = ? AND system_id = ?',
            (control_id, system_id)
        ).fetchone()

        if existing:
            if dict(existing)['is_active'] == 'Y':
                return jsonify({'success': False, 'message': '이미 매핑된 통제-시스템입니다.'}), 400
            conn.execute(
                'UPDATE aegis_control_system SET is_active = ?, custom_query = ?, threshold_count = ? WHERE mapping_id = ?',
                ('Y', data.get('custom_query', ''), data.get('threshold_count', 0), dict(existing)['mapping_id'])
            )
        else:
            conn.execute('''
                INSERT INTO aegis_control_system (control_id, system_id, custom_query, threshold_count, is_active)
                VALUES (?, ?, ?, ?, 'Y')
            ''', (control_id, system_id, data.get('custom_query', ''), data.get('threshold_count', 0)))
        conn.commit()

    return jsonify({'success': True, 'message': '통제-시스템 매핑이 완료되었습니다.'})


@bp_aegis_controls.route('/api/aegis/mappings/<int:mapping_id>', methods=['DELETE'])
@login_required
def api_mapping_delete(mapping_id):
    with get_db() as conn:
        conn.execute(
            'UPDATE aegis_control_system SET is_active = ? WHERE mapping_id = ?',
            ('N', mapping_id)
        )
        conn.commit()
    return jsonify({'success': True, 'message': '매핑이 해제되었습니다.'})
