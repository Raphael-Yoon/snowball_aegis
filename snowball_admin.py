from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for, session
from auth import get_db, get_current_user, login_required, admin_required, get_user_activity_logs, get_activity_log_count
from logger_config import get_logger
import os
from datetime import date, timedelta
import base64

# 로거 초기화
logger = get_logger('admin')

# Blueprint 생성
admin_bp = Blueprint('admin', __name__, url_prefix='/admin')


# Helper functions
def encode_id(id_value):
    """ID를 Base64로 인코딩"""
    return base64.urlsafe_b64encode(str(id_value).encode()).decode()

def decode_id(encoded_value):
    """Base64 인코딩된 ID를 디코딩"""
    try:
        return int(base64.urlsafe_b64decode(encoded_value.encode()).decode())
    except:
        return None

def get_user_info():
    """현재 로그인한 사용자 정보 반환"""
    user_id = session.get('user_id')
    if not user_id:
        return None
    
    with get_db() as conn:
        user = conn.execute(
            'SELECT * FROM sb_user WHERE user_id = %s', (user_id,)
        ).fetchone()
        return dict(user) if user else None

def is_logged_in():
    """로그인 상태 확인"""
    return 'user_id' in session

# 관리자 메인 페이지
@admin_bp.route('/')
@admin_required
def admin():
    """관리자 메인 페이지"""
    return render_template('admin.jsp',
                         is_logged_in=is_logged_in(),
                         user_info=get_user_info(),
                         remote_addr=request.remote_addr)

# 사용자 관리
@admin_bp.route('/users')
@admin_required
def admin_users():
    """사용자 관리 페이지"""
    page = int(request.args.get('page', 1))
    per_page = 20
    offset = (page - 1) * per_page

    with get_db() as conn:
        total_count = conn.execute('SELECT COUNT(*) as count FROM sb_user').fetchone()['count']
        users = conn.execute('''
            SELECT user_id, company_name, user_name, user_email, phone_number,
                   admin_flag, effective_start_date, effective_end_date,
                   creation_date, last_login_date
            FROM sb_user
            ORDER BY creation_date DESC
            LIMIT %s OFFSET %s
        ''', (per_page, offset)).fetchall()
        users_list = [dict(user) for user in users]

    total_pages = (total_count + per_page - 1) // per_page

    return render_template('admin_users.jsp',
                         users=users_list,
                         current_page=page,
                         total_pages=total_pages,
                         total_count=total_count,
                         is_logged_in=is_logged_in(),
                         user_info=get_user_info(),
                         remote_addr=request.remote_addr)

@admin_bp.route('/users/add', methods=['POST'])
@admin_required
def admin_add_user():
    """사용자 추가"""
    try:
        company_name = request.form.get('company_name')
        user_name = request.form.get('user_name')
        user_email = request.form.get('user_email')
        phone_number = request.form.get('phone_number')
        admin_flag = request.form.get('admin_flag', 'N')
        effective_start_date = request.form.get('effective_start_date')
        effective_end_date = request.form.get('effective_end_date')
        
        if not effective_end_date:
            effective_end_date = None
        
        with get_db() as conn:
            conn.execute('''
                INSERT INTO sb_user (company_name, user_name, user_email, phone_number, 
                                   admin_flag, effective_start_date, effective_end_date)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            ''', (company_name, user_name, user_email, phone_number, 
                 admin_flag, effective_start_date, effective_end_date))
            conn.commit()
        flash('사용자가 성공적으로 추가되었습니다.')
    except Exception as e:
        flash(f'사용자 추가 중 오류가 발생했습니다: {str(e)}')
    return redirect(url_for('admin.admin_users'))

@admin_bp.route('/users/edit/<int:user_id>', methods=['POST'])
@admin_required
def admin_edit_user(user_id):
    """사용자 정보 수정"""
    try:
        company_name = request.form.get('company_name')
        user_name = request.form.get('user_name')
        user_email = request.form.get('user_email')
        phone_number = request.form.get('phone_number')
        admin_flag = request.form.get('admin_flag', 'N')
        effective_start_date = request.form.get('effective_start_date')
        effective_end_date = request.form.get('effective_end_date')
        
        if not effective_end_date:
            effective_end_date = None
        
        with get_db() as conn:
            conn.execute('''
                UPDATE sb_user 
                SET company_name = %s, user_name = %s, user_email = %s, phone_number = %s, 
                    admin_flag = %s, effective_start_date = %s, effective_end_date = %s
                WHERE user_id = %s
            ''', (company_name, user_name, user_email, phone_number, 
                 admin_flag, effective_start_date, effective_end_date, user_id))
            conn.commit()
        flash('사용자 정보가 성공적으로 수정되었습니다.')
    except Exception as e:
        flash(f'사용자 정보 수정 중 오류가 발생했습니다: {str(e)}')
    return redirect(url_for('admin.admin_users'))

@admin_bp.route('/users/delete/<int:user_id>', methods=['POST'])
@admin_required
def admin_delete_user(user_id):
    """사용자 삭제"""
    try:
        with get_db() as conn:
            conn.execute('DELETE FROM sb_user WHERE user_id = %s', (user_id,))
            conn.commit()
        flash('사용자가 성공적으로 삭제되었습니다.')
    except Exception as e:
        flash(f'사용자 삭제 중 오류가 발생했습니다: {str(e)}')
    return redirect(url_for('admin.admin_users'))

# 로그 관리
@admin_bp.route('/logs')
@admin_required
def admin_logs():
    """사용자 활동 로그 조회 페이지"""
    page = int(request.args.get('page', 1))
    per_page = 20
    offset = (page - 1) * per_page
    
    user_filter = request.args.get('user_id')
    
    if user_filter:
        logs = get_user_activity_logs(limit=per_page, offset=offset, user_id=user_filter)
        total_count = get_activity_log_count(user_id=user_filter)
    else:
        logs = get_user_activity_logs(limit=per_page, offset=offset)
        total_count = get_activity_log_count()
    
    total_pages = (total_count + per_page - 1) // per_page
    
    with get_db() as conn:
        users = conn.execute('SELECT user_id, user_name, user_email FROM sb_user ORDER BY user_name').fetchall()
        users_list = [dict(user) for user in users]
    
    return render_template('admin_logs.jsp',
                         logs=logs,
                         users=users_list,
                         current_page=page,
                         total_pages=total_pages,
                         total_count=total_count,
                         user_filter=user_filter,
                         is_logged_in=is_logged_in(),
                         user_info=get_user_info(),
                         remote_addr=request.remote_addr)
