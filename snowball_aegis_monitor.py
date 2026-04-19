from flask import Blueprint, request, jsonify, render_template, redirect, url_for, flash, session
from auth import login_required, get_current_user, log_user_activity, get_db
from aegis_monitor import AegisMonitorEngine
from datetime import datetime
import json

bp_aegis_monitor = Blueprint('aegis_monitor', __name__)

def get_user_info():
    if 'user_info' in session:
        return session['user_info']
    return get_current_user()

@bp_aegis_monitor.route('/aegis/monitor')
@login_required
def monitor_dashboard():
    """Aegis Real-time Monitoring Dashboard"""
    user_info = get_user_info()
    db = get_db()
    
    # In-Scope Systems requested by user
    in_scope_systems = ['snowball', 'infosd', 'trade', 'yujuduck']
    
    # Get latest logs for each category
    categories = ['UserAccess', 'ProgramChange', 'BatchJob', 'Interface']
    latest_logs = {}
    
    for cat in categories:
        log = db.execute('''
            SELECT * FROM aegis_monitor_log 
            WHERE category = ? 
            ORDER BY log_date DESC LIMIT 1
        ''', (cat,)).fetchone()
        latest_logs[cat] = dict(log) if log else None

    # Get recent history
    history = db.execute('''
        SELECT * FROM aegis_monitor_log 
        ORDER BY log_date DESC LIMIT 20
    ''').fetchall()

    log_user_activity(user_info, 'PAGE_ACCESS', 'Aegis Monitoring Dashboard', '/aegis/monitor',
                     request.remote_addr, request.headers.get('User-Agent'))

    return render_template('aegis_monitor.jsp', 
                         latest_logs=latest_logs, 
                         history=history,
                         in_scope_systems=in_scope_systems,
                         user_info=user_info)

@bp_aegis_monitor.route('/api/aegis/run-monitor', methods=['POST'])
@login_required
def run_monitor():
    """Trigger the Aegis Monitoring Engine"""
    user_info = get_user_info()
    engine = AegisMonitorEngine()
    results = engine.run_cycle()
    
    if results:
        log_user_activity(user_info, 'ACTION', 'Triggered Aegis Monitor', '/api/aegis/run-monitor',
                         request.remote_addr, request.headers.get('User-Agent'))
        return jsonify({'success': True, 'results': results})
    else:
        return jsonify({'success': False, 'message': 'Failed to run monitoring cycle.'}), 500

@bp_aegis_monitor.route('/api/aegis/seed-data', methods=['POST'])
@login_required
def seed_monitor_data():
    """Seed mock data for demonstration"""
    db = get_db()
    now = datetime.now()
    
    # Seed CSR approvals
    csr_data = [
        ('SR-2026-001', 'Apply Security Patch to snowball.py', 'Raphael', 'Admin', '2026-04-18 10:00:00', 'ProgramChange'),
        ('SR-2026-002', 'Add New User "TestUser"', 'Admin', 'Admin', '2026-04-19 09:00:00', 'UserAccess'),
        ('SR-2026-003', 'Database Backup Job Schedule', 'DBA', 'Admin', '2026-04-19 01:00:00', 'BatchJob')
    ]
    
    for sr in csr_data:
        db.execute('''
            INSERT OR IGNORE INTO aegis_csr_approval (sr_no, title, requester, approver, approval_date, system_category)
            VALUES (?, ?, ?, ?, ?, ?)
        ''', sr)
    
    db.commit()
    return jsonify({'success': True, 'message': 'Seed data injected.'})

@bp_aegis_monitor.route('/api/aegis/control-evidence/<control_code>')
@login_required
def get_monitoring_evidence(control_code):
    """Fetch monitoring results as evidence for a specific control"""
    # Simple mapping of control codes to monitoring categories
    mapping = {
        'APD01': 'UserAccess',
        'APD07': 'ProgramChange',
        'APD09': 'UserAccess',
        'APD12': 'UserAccess',
        'PC01': 'ProgramChange',
        'PC02': 'ProgramChange',
        'PC03': 'ProgramChange',
        'CO01': 'BatchJob'
    }
    
    category = mapping.get(control_code, 'Interface' if 'IF' in control_code else None)
    
    if not category:
        return jsonify({'success': False, 'message': 'No monitoring mapping for this control.'})
        
    db = get_db()
    log = db.execute('''
        SELECT * FROM aegis_monitor_log 
        WHERE category = ? 
        ORDER BY log_date DESC LIMIT 1
    ''', (category,)).fetchone()
    
    if log:
        return jsonify({
            'success': True, 
            'category': category,
            'summary': dict(log),
            'evidence_text': f"Aegis Monitoring Result ({log['log_date']}): "
                            f"Total {log['total_count']}, Matched {log['match_count']}, "
                            f"Unmapped {log['unmapped_count']}. Status: {log['status']}"
        })
    else:
        return jsonify({'success': False, 'message': 'No monitoring logs found for this category.'})
