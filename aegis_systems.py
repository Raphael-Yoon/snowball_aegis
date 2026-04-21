from flask import Blueprint, request, jsonify, render_template, session
from auth import login_required, get_current_user
from db_config import get_db
from connectors import get_connector_info

bp_aegis_systems = Blueprint('aegis_systems', __name__)


def get_user_info():
    return session.get('user_info') or get_current_user()


def _enrich_system(s: dict) -> dict:
    """시스템 dict에 커넥터 구현 완료 여부 및 매핑된 통제 수 추가"""
    info = get_connector_info(s.get('system_code', ''))
    with get_db() as conn:
        row = conn.execute(
            'SELECT COUNT(*) as cnt FROM aegis_control_system WHERE system_id = ? AND is_active = ?',
            (s['system_id'], 'Y')
        ).fetchone()
    mapped_count = dict(row)['cnt'] if row else 0
    return {**s, **info, 'mapped_control_count': mapped_count}


@bp_aegis_systems.route('/aegis/systems')
@login_required
def systems_list():
    user_info = get_user_info()
    with get_db() as conn:
        systems = conn.execute(
            'SELECT * FROM aegis_system ORDER BY system_code'
        ).fetchall()
    systems = [_enrich_system(dict(s)) for s in systems]
    return render_template('aegis_systems.jsp',
                           systems=systems,
                           user_info=user_info,
                           is_logged_in=True)


@bp_aegis_systems.route('/api/aegis/systems', methods=['GET'])
@login_required
def api_systems_list():
    with get_db() as conn:
        systems = conn.execute(
            'SELECT * FROM aegis_system ORDER BY system_code'
        ).fetchall()
    return jsonify({'success': True, 'systems': [dict(s) for s in systems]})


@bp_aegis_systems.route('/api/aegis/systems', methods=['POST'])
@login_required
def api_system_create():
    data = request.get_json()
    required = ['system_code', 'system_name', 'db_type']
    if not all(data.get(f) for f in required):
        return jsonify({'success': False, 'message': '필수 항목(system_code, system_name, db_type)을 입력해주세요.'}), 400

    with get_db() as conn:
        existing = conn.execute(
            'SELECT system_id FROM aegis_system WHERE system_code = ?',
            (data['system_code'].upper(),)
        ).fetchone()
        if existing:
            return jsonify({'success': False, 'message': f"시스템 코드 '{data['system_code']}'가 이미 존재합니다."}), 400

        conn.execute('''
            INSERT INTO aegis_system
                (system_code, system_name, description, db_type, db_host, db_port, db_name, db_user, db_password, db_path, is_active)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Y')
        ''', (
            data['system_code'].upper(),
            data['system_name'],
            data.get('description', ''),
            data['db_type'],
            data.get('db_host', ''),
            data.get('db_port'),
            data.get('db_name', ''),
            data.get('db_user', ''),
            data.get('db_password', ''),
            data.get('db_path', ''),
        ))
        conn.commit()

    return jsonify({'success': True, 'message': f"시스템 '{data['system_name']}'이 등록되었습니다."})


@bp_aegis_systems.route('/api/aegis/systems/<int:system_id>', methods=['PUT'])
@login_required
def api_system_update(system_id):
    data = request.get_json()
    with get_db() as conn:
        existing = conn.execute(
            'SELECT system_id FROM aegis_system WHERE system_id = ?', (system_id,)
        ).fetchone()
        if not existing:
            return jsonify({'success': False, 'message': '시스템을 찾을 수 없습니다.'}), 404

        conn.execute('''
            UPDATE aegis_system SET
                system_name = ?, description = ?, db_type = ?,
                db_host = ?, db_port = ?, db_name = ?,
                db_user = ?, db_password = ?, db_path = ?,
                is_active = ?, updated_at = CURRENT_TIMESTAMP
            WHERE system_id = ?
        ''', (
            data.get('system_name'),
            data.get('description', ''),
            data.get('db_type', 'sqlite'),
            data.get('db_host', ''),
            data.get('db_port'),
            data.get('db_name', ''),
            data.get('db_user', ''),
            data.get('db_password', ''),
            data.get('db_path', ''),
            data.get('is_active', 'Y'),
            system_id,
        ))
        conn.commit()

    return jsonify({'success': True, 'message': '시스템 정보가 업데이트되었습니다.'})


@bp_aegis_systems.route('/api/aegis/systems/<int:system_id>', methods=['DELETE'])
@login_required
def api_system_delete(system_id):
    with get_db() as conn:
        mapped = conn.execute(
            'SELECT COUNT(*) as cnt FROM aegis_control_system WHERE system_id = ? AND is_active = ?',
            (system_id, 'Y')
        ).fetchone()
        if mapped and dict(mapped)['cnt'] > 0:
            return jsonify({'success': False, 'message': '해당 시스템에 연결된 활성 통제가 있습니다. 먼저 매핑을 해제해주세요.'}), 400

        conn.execute(
            'UPDATE aegis_system SET is_active = ?, updated_at = CURRENT_TIMESTAMP WHERE system_id = ?',
            ('N', system_id)
        )
        conn.commit()

    return jsonify({'success': True, 'message': '시스템이 비활성화되었습니다.'})


@bp_aegis_systems.route('/api/aegis/systems/<int:system_id>/test', methods=['POST'])
@login_required
def api_system_test(system_id):
    """DB 연결 테스트"""
    with get_db() as conn:
        system = conn.execute(
            'SELECT * FROM aegis_system WHERE system_id = ?', (system_id,)
        ).fetchone()

    if not system:
        return jsonify({'success': False, 'message': '시스템을 찾을 수 없습니다.'}), 404

    s = dict(system)
    try:
        if s['db_type'] == 'sqlite':
            import sqlite3
            from pathlib import Path
            import flask
            raw_path = s.get('db_path') or ''
            if not raw_path:
                return jsonify({'success': False, 'message': 'DB 파일 경로가 설정되지 않았습니다.'})
            db_path = Path(raw_path)
            # 상대 경로인 경우 Flask 앱 루트 기준으로 resolve
            if not db_path.is_absolute():
                app_root = Path(flask.current_app.root_path)
                db_path = (app_root / db_path).resolve()
            if not db_path.exists():
                return jsonify({'success': False, 'message': f"DB 파일을 찾을 수 없습니다: {db_path}"})
            test_conn = sqlite3.connect(str(db_path))
            test_conn.execute('SELECT 1')
            test_conn.close()

        elif s['db_type'] in ('mysql', 'mariadb'):
            import pymysql
            test_conn = pymysql.connect(
                host=s['db_host'], port=int(s['db_port'] or 3306),
                user=s['db_user'], password=s['db_password'],
                database=s['db_name'], connect_timeout=5
            )
            test_conn.close()

        else:
            return jsonify({'success': False, 'message': f"지원하지 않는 DB 타입: {s['db_type']}"})

        return jsonify({'success': True, 'message': 'DB 연결 성공'})

    except Exception as e:
        return jsonify({'success': False, 'message': f'연결 실패: {str(e)}'})
