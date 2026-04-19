import hmac
import hashlib
import time
from flask import Flask, render_template, request, redirect, url_for, session, jsonify, flash
from flask_wtf.csrf import CSRFProtect
from extensions import limiter
from werkzeug.exceptions import HTTPException
from datetime import datetime, timedelta
from dotenv import load_dotenv
from pathlib import Path
import os
import traceback

# 작업 디렉토리를 이 파일이 위치한 디렉토리(snowball)로 강제 변경
# 이렇게 하면 어디서 실행하든 상대 경로가 올바르게 해석됨
_APP_DIR = Path(__file__).parent.resolve()
os.chdir(_APP_DIR)

# .env 파일 먼저 로드 (다른 모듈에서 환경변수 사용하기 전에)
# 현재 파일 기준으로 .env 파일 경로 지정 (작업 디렉토리와 무관하게 동작)
env_path = _APP_DIR / '.env'
load_dotenv(dotenv_path=env_path)

from logger_config import setup_logging, get_logger
from snowball_link5 import bp_link5
from snowball_link6 import bp_link6
from snowball_link7 import bp_link7
from snowball_link8 import bp_link8
from snowball_aegis_monitor import bp_aegis_monitor
from snowball_admin import admin_bp
from auth import send_otp, verify_otp, login_required, get_current_user, get_db, log_user_activity, find_user_by_email
from snowball_drive import get_work_log, append_to_work_log_docs

app = Flask(__name__)

# 로깅 초기화
setup_logging()
logger = get_logger('main')

# SECRET_KEY는 .env 파일에서 반드시 설정되어야 함 (보안 강화)
app.secret_key = os.getenv('FLASK_SECRET_KEY')
if not app.secret_key:
    logger.critical("FLASK_SECRET_KEY environment variable not set")
    raise ValueError("FLASK_SECRET_KEY environment variable must be set in .env file")

# 세션 만료 시간 설정 (24시간으로 연장)
# 브라우저 종료시에만 세션 만료 (permanent session 사용하지 않음)

# 세션 보안 설정 - 환경에 따른 동적 설정
is_production = os.getenv('PYTHONANYWHERE_DOMAIN') is not None or 'pythonanywhere' in os.getenv('SERVER_NAME', '')
app.config.update(
    SESSION_COOKIE_SECURE=is_production,  # 운영환경(HTTPS)에서만 True
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    # 브라우저 종료 후에도 세션 유지되도록 설정
    SESSION_COOKIE_MAX_AGE=timedelta(hours=24).total_seconds(),  # 24시간
    # 템플릿 자동 리로드 설정 (개발 환경)
    TEMPLATES_AUTO_RELOAD=True
)

# Jinja2 템플릿 자동 리로드 강제 설정
app.jinja_env.auto_reload = True

logger.info(f"세션 설정 - Production: {is_production}, Secure: {app.config['SESSION_COOKIE_SECURE']}")
logger.info(f"Flask 앱 시작 - Environment: {'Production' if is_production else 'Development'}")

# CSRF 보호 활성화 (단계적 적용을 위해 일부 엔드포인트 제외)
csrf = CSRFProtect(app)

# Rate Limiting 초기화 (스팸봇 차단)
limiter.init_app(app)

# CSRF 제외할 엔드포인트 (임시 - 향후 템플릿에 CSRF 토큰 추가 후 제거)
# csrf.exempt(bp_link1)  # CSRF 보호 적용 완료
csrf.exempt(bp_link5)
csrf.exempt(bp_link6)
csrf.exempt(bp_link7)
csrf.exempt(bp_link8)
csrf.exempt(bp_aegis_monitor)

logger.warning("CSRF Protection enabled with exemptions for API endpoints")

# --- File-based Progress Tracking ---
# 진행률 관련 기능은 snowball_link2_bak.py로 이동됨

# 시작할 질문 번호는 snowball_link2_bak.py에서 관리됨

# 보안 관련 상수 (환경변수에서 로드) - 운영 환경에서만 필수
is_production_env = os.getenv('PYTHONANYWHERE_DOMAIN') is not None
PYTHONANYWHERE_AUTH_CODE = os.getenv('PYTHONANYWHERE_AUTH_CODE')
if is_production_env and not PYTHONANYWHERE_AUTH_CODE:
    raise ValueError("PYTHONANYWHERE_AUTH_CODE must be set in production environment")

# 데이터베이스 초기화는 더 이상 서버 시작 시 자동 실행되지 않습니다.
# 마이그레이션 시스템을 사용하세요: python migrate.py upgrade

@app.context_processor
def inject_globals():
    """모든 템플릿에 전역 변수 주입"""
    timestamp = str(int(time.time()))
    sig = hmac.new(app.secret_key.encode(), timestamp.encode(), hashlib.sha256).hexdigest()
    return {
        'is_production': is_production,
        'form_token': f"{timestamp}.{sig}",
    }

def is_logged_in():
    """로그인 상태 확인 함수"""
    return 'user_id' in session and get_current_user() is not None

def get_user_info():
    """현재 로그인한 사용자 정보 반환 (없으면 None)"""
    if is_logged_in():
        # 세션에 저장된 user_info를 우선 사용
        if 'user_info' in session:
            return session['user_info']
        # 없으면 데이터베이스에서 조회
        return get_current_user()
    return None

def require_login_for_feature(feature_name="이 기능"):
    """특정 기능에 로그인이 필요할 때 사용하는 함수"""
    if not is_logged_in():
        return {
            'error': True,
            'message': f'{feature_name}을 사용하려면 로그인이 필요합니다.',
            'login_url': url_for('login')
        }
    return {'error': False}

@app.route('/')
def index():
    
    # 자동 로그인 로직 제거됨 (수동 로그인으로 변경)
    
    user_info = get_user_info()
    user_name = user_info['user_name'] if user_info else "Guest"
    
    # 로그인한 사용자만 활동 로그 기록
    host = request.headers.get('Host', '')
    # 로컬 환경에서는 로그인 로그 기록 안함
    if is_logged_in() and host.startswith('snowball.pythonanywhere.com'):
        log_user_activity(user_info, 'PAGE_ACCESS', '메인 페이지', '/',
                          request.remote_addr, request.headers.get('User-Agent'))

    # 카드 순서 정의 (Dashboard를 RCM 앞으로)
    card_order = ['dashboard', 'rcm', 'interview', 'design_evaluation', 'operation_evaluation']

    return render_template('index.jsp',
                         user_name=user_name, 
                         is_logged_in=is_logged_in(),
                         user_info=user_info,
                         return_code=0, 
                         remote_addr=request.remote_addr,
                         card_order=card_order)

@app.route('/login', methods=['GET', 'POST'])
@csrf.exempt
def login():
    try:
        print("로그인 페이지 접근 시작")
        action = None
        if request.method == 'POST':
            action = request.form.get('action')
            print(f"POST 요청 액션: {action}")
        else:
            # GET 요청 시에는 액션 없음
            action = None
        
        if action == 'admin_login':
            # 관리자 로그인
            client_ip = request.environ.get('REMOTE_ADDR', '')
            server_port = request.environ.get('SERVER_PORT', '')

            with get_db() as conn:
                user = conn.execute(
                    'SELECT * FROM sb_user WHERE user_email = %s AND (effective_end_date IS NULL OR effective_end_date > CURRENT_TIMESTAMP)',
                    ('snowball2727@naver.com',)
                ).fetchone()

                if user:
                    user_dict = dict(user)

                    session['user_id'] = user_dict['user_id']
                    session['user_email'] = user_dict['user_email']
                    session['user_info'] = {
                        'user_id': user_dict['user_id'],
                        'user_name': user_dict['user_name'],
                        'user_email': user_dict['user_email'],
                        'company_name': user_dict.get('company_name', ''),
                        'phone_number': user_dict.get('phone_number', ''),
                        'admin_flag': user_dict.get('admin_flag', 'N')
                    }
                    session['last_activity'] = datetime.now().isoformat()

                    print(f"관리자 로그인 성공: {user_dict['user_email']} (admin_flag: {user_dict.get('admin_flag', 'N')}) from {client_ip}:{server_port}")
                    return redirect(url_for('index'))
                else:
                    return render_template('login.jsp', error="관리자 계정을 찾을 수 없습니다.", remote_addr=request.remote_addr)
        
        elif action == 'send_otp':
            # OTP 발송 요청 (이메일만 지원)
            email = request.form.get('email')
            host = request.headers.get('Host', '')

            if not email:
                return render_template('login.jsp', error="이메일을 입력해주세요.", remote_addr=request.remote_addr, show_direct_login=host.startswith('snowball.pythonanywhere.com'))

            # snowball.pythonanywhere.com에서는 실제 OTP 발송하지 않고 고정 메시지 표시
            if host.startswith('snowball.pythonanywhere.com'):
                print(f"운영서버 OTP 발송 요청 - Host: {host}, Email: {email}")

                # 사용자가 존재하는지만 확인
                user = find_user_by_email(email)
                print(f"사용자 존재 확인 결과: {user is not None}")

                if not user:
                    print(f"등록되지 않은 사용자: {email}")
                    return render_template('login.jsp', error="등록되지 않은 사용자입니다.", remote_addr=request.remote_addr, show_direct_login=True)

                print(f"세션에 login_email 저장: {email}")
                session['login_email'] = email
                return render_template('login.jsp', step='verify', email=email,
                                     message="인증 코드를 입력해주세요.",
                                     remote_addr=request.remote_addr,
                                     show_direct_login=True)
            else:
                # 일반적인 OTP 발송 (이메일만)
                success, message = send_otp(email, method='email')
                if success:
                    session['login_email'] = email
                    return render_template('login.jsp', step='verify', email=email, message=message, remote_addr=request.remote_addr)
                else:
                    return render_template('login.jsp', error=message, remote_addr=request.remote_addr)
        
        elif action == 'verify_otp':
            # OTP 검증
            email = session.get('login_email')
            otp_code = request.form.get('otp_code')
            host = request.headers.get('Host', '')
            
            print(f"OTP 검증 시도 - Host: {host}, Session Email: {email}")

            if not email or not otp_code:
                print(f"필수 정보 누락 - Email: {email}")
                return render_template('login.jsp', error="인증 코드를 입력해주세요.", remote_addr=request.remote_addr)

            # snowball.pythonanywhere.com에서는 고정 코드 확인
            if host.startswith('snowball.pythonanywhere.com'):
                print(f"운영서버 로그인 시도 - Host: {host}, Email: {email}")
                
                if otp_code == PYTHONANYWHERE_AUTH_CODE:
                    # 사용자 정보 조회
                    user = find_user_by_email(email)
                    print(f"사용자 조회 결과: {user is not None}")
                    
                    if user:
                        print(f"사용자 정보: {user}")
                        # 로그인 성공
                        session['user_id'] = user['user_id']
                        session['user_name'] = user['user_name']
                        session['user_info'] = {
                            'user_id': user['user_id'],
                            'user_name': user['user_name'],
                            'user_email': user['user_email'],
                            'company_name': user.get('company_name', ''),
                            'phone_number': user.get('phone_number', ''),
                            'admin_flag': user.get('admin_flag', 'N')
                        }
                        session['login_time'] = datetime.now().isoformat()
                        session['last_activity'] = datetime.now().isoformat()
                        session.pop('login_email', None)  # 임시 이메일 정보 삭제
                        
                        # 마지막 로그인 날짜 업데이트
                        try:
                            with get_db() as conn:
                                conn.execute(
                                    'UPDATE sb_user SET last_login_date = CURRENT_TIMESTAMP WHERE user_email = %s',
                                    (email,)
                                )
                                conn.commit()
                            print(f"로그인 날짜 업데이트 성공")
                        except Exception as e:
                            print(f"로그인 날짜 업데이트 실패: {e}")
                        
                        print(f"고정 코드 로그인 성공: {user['user_name']} ({user['user_email']}) from {host}")
                        return redirect(url_for('index'))
                    else:
                        print(f"사용자를 찾을 수 없음: {email}")
                        return render_template('login.jsp', step='verify', email=email, error="사용자 정보를 찾을 수 없습니다.", remote_addr=request.remote_addr, show_direct_login=True)
                else:
                    print(f"잘못된 인증 코드 - Email: {email}")
                    return render_template('login.jsp', step='verify', email=email, error="잘못된 인증 코드입니다.", remote_addr=request.remote_addr, show_direct_login=True)
            else:
                # 일반적인 OTP 검증
                success, result = verify_otp(email, otp_code)
                if success:
                    # 로그인 성공
                    user = result
                    # session.permanent = True  # 브라우저 종료시 세션 만료
                    session['user_id'] = user['user_id']
                    session['user_name'] = user['user_name']
                    session['user_info'] = {
                        'user_id': user['user_id'],
                        'user_name': user['user_name'],
                        'user_email': user['user_email'],
                        'company_name': user.get('company_name', ''),
                        'phone_number': user.get('phone_number', ''),
                        'admin_flag': user.get('admin_flag', 'N')
                    }
                    session['login_time'] = datetime.now().isoformat()
                    session.pop('login_email', None)  # 임시 이메일 정보 삭제
                    print(f"로그인 성공: {user['user_name']} ({user['user_email']})")
                    return redirect(url_for('index'))
                else:
                    return render_template('login.jsp', step='verify', email=email, error=result, remote_addr=request.remote_addr)
    
        # GET 혹은 액션 미지정 시 로그인 폼 표시
        print("GET/기본 로그인 폼 표시")
        host = request.headers.get('Host', '')
        show_direct_login = host.startswith('snowball.pythonanywhere.com')
        print(f"폼 렌더 - Host: {host}, show_direct_login: {show_direct_login}")
        return render_template('login.jsp', remote_addr=request.remote_addr, show_direct_login=show_direct_login)
        
    except Exception as e:
        print(f"로그인 페이지 오류: {e}")
        traceback.print_exc()
        return f"로그인 페이지 오류가 발생했습니다: {str(e)}", 500


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

@app.route('/extend_session', methods=['POST'])
@csrf.exempt
def extend_session():
    """세션 연장 엔드포인트"""
    if 'user_id' in session:
        session['last_activity'] = datetime.now().isoformat()
        # session.permanent = True  # 브라우저 종료시 세션 만료
        print(f"세션 연장: {session.get('user_name', 'Unknown')}")
        return jsonify({'success': True, 'message': '세션이 연장되었습니다.'})
    return jsonify({'success': False, 'message': '로그인이 필요합니다.'})


@app.route('/health')
def health_check():
    """서버 상태 확인"""
    try:
        return {
            'status': 'ok', 
            'host': request.headers.get('Host', ''),
            'remote_addr': request.remote_addr,
            'timestamp': datetime.now().isoformat()
        }
    except Exception as e:
        return {'status': 'error', 'message': str(e)}, 500

@app.route('/clear_session', methods=['POST'])
@csrf.exempt
def clear_session():
    """브라우저 종료 시 세션 해제 엔드포인트"""
    if 'user_id' in session:
        user_name = session.get('user_name', 'Unknown')
        session.clear()
        print(f"브라우저 종료로 세션 해제: {user_name}")
    return '', 204

@app.errorhandler(Exception)
def handle_exception(e):
    if isinstance(e, HTTPException):
        return e
    logger.error(f"Unhandled Exception: {traceback.format_exc()}")
    return "Internal Server Error: check logs", 500

def main():
    app.run(host='0.0.0.0', debug=True, port=5001, use_reloader=False)
    #app.run(host='127.0.0.1', debug=False, port=8001)

@app.route('/user/design-evaluation', methods=['GET', 'POST'])
@login_required
@csrf.exempt
def user_design_evaluation():
    """설계평가 페이지 - 세션에 데이터 저장 후 설계평가 작업 페이지로 리디렉트"""
    if request.method == 'POST':
        # POST로 받은 데이터를 세션에 저장
        rcm_id = request.form.get('rcm_id')
        evaluation_session = request.form.get('session')

        if rcm_id and evaluation_session:
            # 세션에 저장 (설계평가 작업 페이지에서 사용)
            session['current_design_rcm_id'] = int(rcm_id)
            session['current_evaluation_session'] = evaluation_session

            # RCM 정보 조회하여 카테고리 확인
            with get_db() as conn:
                rcm = conn.execute("SELECT control_category FROM sb_rcm WHERE rcm_id = ?", (rcm_id,)).fetchone()

            if rcm:
                category = rcm['control_category']
                session['current_evaluation_type'] = category

            # 설계평가 작업 페이지로 리디렉트
            return redirect(url_for('link6.user_design_evaluation_rcm'))

        flash('잘못된 요청입니다.', 'danger')
        return redirect(url_for('link8.link8'))
    else:
        # GET 요청 - rcm_id가 있으면 해당 RCM으로 설계평가 시작 모달 표시
        rcm_id = request.args.get('rcm_id')
        if rcm_id:
            return redirect(url_for('link6.itgc_evaluation', start_design=rcm_id))
        return redirect(url_for('link6.itgc_evaluation'))


@app.route('/api/control-sample/upload', methods=['POST'])
@login_required
def upload_control_sample():
    """통제별 샘플 파일 업로드 API"""
    user_info = get_user_info()
    
    rcm_id = request.form.get('rcm_id')
    control_code = request.form.get('control_code')
    description = request.form.get('description', '')
    
    if not all([rcm_id, control_code]):
        return jsonify({
            'success': False,
            'message': '필수 데이터가 누락되었습니다.'
        })
    
    if 'files' not in request.files:
        return jsonify({
            'success': False,
            'message': '업로드할 파일이 없습니다.'
        })
    
    files = request.files.getlist('files')
    if not files or all(file.filename == '' for file in files):
        return jsonify({
            'success': False,
            'message': '업로드할 파일을 선택해주세요.'
        })
    
    try:
        # 사용자가 해당 RCM에 접근 권한이 있는지 확인
        with get_db() as conn:
            access_check = conn.execute('''
                SELECT permission_type FROM sb_user_rcm
                WHERE user_id = %s AND rcm_id = %s AND is_active = 'Y'
            ''', (user_info['user_id'], rcm_id)).fetchone()
            
            if not access_check:
                return jsonify({
                    'success': False,
                    'message': '해당 RCM에 대한 접근 권한이 없습니다.'
                })
        
        # 업로드 디렉토리 생성
        upload_dir = f"uploads/rcm_{rcm_id}/control_{control_code}"
        os.makedirs(upload_dir, exist_ok=True)
        
        uploaded_files = []
        
        for file in files:
            if file and file.filename:
                # 안전한 파일명 생성
                import uuid
                file_ext = os.path.splitext(file.filename)[1]
                safe_filename = f"{uuid.uuid4()}{file_ext}"
                file_path = os.path.join(upload_dir, safe_filename)
                
                # 파일 저장
                file.save(file_path)
                
                # 데이터베이스에 파일 정보 저장
                with get_db() as conn:
                    conn.execute('''
                        INSERT INTO sb_control_sample_files
                        (rcm_id, control_code, user_id, original_filename, stored_filename, 
                         file_path, file_size, description, upload_date)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, datetime('now'))
                    ''', (rcm_id, control_code, user_info['user_id'], file.filename, 
                          safe_filename, file_path, os.path.getsize(file_path), description))
                    conn.commit()
                
                uploaded_files.append({
                    'original_name': file.filename,
                    'stored_name': safe_filename
                })
        
        # 활동 로그 기록
        log_user_activity(user_info, 'SAMPLE_UPLOAD', f'통제 샘플 업로드 - {control_code}', 
                         '/api/control-sample/upload', 
                         request.remote_addr, request.headers.get('User-Agent'))
        
        return jsonify({
            'success': True,
            'message': f'{len(uploaded_files)}개 파일이 업로드되었습니다.',
            'uploaded_files': uploaded_files
        })
        
    except Exception as e:
        print(f"샘플 업로드 오류: {e}")
        return jsonify({
            'success': False,
            'message': '업로드 중 오류가 발생했습니다.'
        })

@app.route('/user/operation-evaluation', methods=['GET', 'POST'])
@login_required
def user_operation_evaluation():
    """운영평가 페이지 - 세션에 데이터 저장 후 운영평가 작업 페이지로 리디렉트"""
    if request.method == 'POST':
        # POST로 받은 데이터를 세션에 저장
        rcm_id = request.form.get('rcm_id')
        evaluation_session = request.form.get('session')

        if rcm_id and evaluation_session:
            # 세션에 저장 (운영평가 페이지에서 사용)
            session['current_operation_rcm_id'] = int(rcm_id)
            session['current_design_evaluation_session'] = evaluation_session
            session['redirect_to_operation'] = True

            # 운영평가 작업 페이지로 리디렉트
            return redirect(url_for('link7.user_operation_evaluation_rcm'))

        flash('잘못된 요청입니다.', 'danger')
        return redirect(url_for('link8.link8'))
    else:
        # GET 요청 - 레거시 지원
        return redirect(url_for('link7.user_operation_evaluation'))

@app.route('/api/rcm/update_controls', methods=['POST'])
@login_required
def api_rcm_update_controls():
    """RCM 통제 정보 업데이트 API (인라인 편집)"""
    user_info = get_current_user()

    try:
        data = request.get_json()
        updates = data.get('updates', [])

        if not updates:
            return jsonify({'success': False, 'message': '업데이트할 데이터가 없습니다.'}), 400

        with get_db() as conn: # with 문으로 DB 연결을 안전하게 관리
            updated_count = 0

            # 각 통제에 대해 업데이트 수행
            for update in updates:
                detail_id = update.get('detail_id')
                fields = update.get('fields', {})

                if not detail_id or not fields:
                    continue

                # 해당 통제가 속한 RCM에 대한 접근 권한 확인
                rcm_check_result = conn.execute('''
                    SELECT rcm_id FROM sb_rcm_detail WHERE detail_id = %s
                ''', (detail_id,)).fetchone()

                if not rcm_check_result:
                    continue

                rcm_id = rcm_check_result['rcm_id']

                # 권한 확인 로직을 반복문 안으로 이동
                access = conn.execute('''
                    SELECT permission_type FROM sb_user_rcm
                    WHERE rcm_id = %s AND user_id = %s
                ''', (rcm_id, user_info['user_id'])).fetchone()

                # admin 또는 edit 권한이 있는지 확인
                if not access or access['permission_type'] not in ('admin', 'edit'):
                    continue

                # 허용된 필드만 업데이트 (통제코드와 통제명은 제외)
                allowed_fields = [
                    'control_description', 'key_control', 'control_frequency',
                    'control_type', 'control_nature', 'process_area',
                    'risk_description', 'risk_impact', 'risk_likelihood', 'population',
                    'population_completeness_check', 'population_count', 'test_procedure',
                    'control_owner', 'control_performer', 'evidence_type',
                    'recommended_sample_size'  # 권장 표본수 필드 추가
                ]

                # SQL UPDATE 문 생성
                update_fields = []
                update_values = []

                for field, value in fields.items():
                    if field in allowed_fields:
                        update_fields.append(f"{field} = %s")
                        update_values.append(value if value else None)

                if update_fields:
                    update_values.append(detail_id)
                    sql = f"UPDATE sb_rcm_detail SET {', '.join(update_fields)} WHERE detail_id = %s"
                    conn.execute(sql, update_values)
                    updated_count += 1

            # 모든 업데이트가 끝난 후 한 번만 커밋

        return jsonify({
            'success': True,
            'message': f'{updated_count}개 통제 정보가 업데이트되었습니다.',
            'updated_count': updated_count
        })

    except Exception as e:
        traceback.print_exc()
        return jsonify({'success': False, 'message': f'업데이트 중 오류가 발생했습니다: {str(e)}'}), 500

@app.route('/api/work-log', methods=['GET', 'POST'])
@login_required
def work_log_api():
    """작업 로그 API - Google Drive에 저장"""
    user_info = get_user_info()

    if request.method == 'POST':
        # 작업 로그 추가
        data = request.get_json()
        log_entry = data.get('log_entry', '')

        if not log_entry:
            return jsonify({
                'success': False,
                'message': '로그 내용이 비어있습니다.'
            })

        # 사용자 정보와 함께 로그 작성
        result = append_to_work_log_docs(
            log_entry=log_entry,
            log_date=datetime.now().strftime('%Y-%m-%d')
        )


        # 활동 로그 기록
        if result['success']:
            log_user_activity(user_info, 'WORK_LOG', '작업 로그 작성', '/api/work-log',
                            request.remote_addr, request.headers.get('User-Agent'))

        return jsonify(result)

    else:
        # 작업 로그 조회
        result = get_work_log()

        if result['success']:
            log_user_activity(user_info, 'WORK_LOG_VIEW', '작업 로그 조회', '/api/work-log',
                            request.remote_addr, request.headers.get('User-Agent'))

        return jsonify(result)

@app.route('/api/check-operation-evaluation/<control_type>')
@login_required
def check_operation_evaluation(control_type):
    """진행 중인 운영평가가 있는지 확인하는 API

    Args:
        control_type: ELC, TLC, ITGC 중 하나

    Returns:
        JSON: {
            "has_operation_evaluation": true/false,
            "evaluation_sessions": [...] (있는 경우)
        }
    """
    user_info = get_current_user()

    with get_db() as conn:
        # 특정 control_type의 RCM에 대한 운영평가 헤더 조회
        # sb_rcm.control_category로 필터링 (훨씬 간단!)
        headers = conn.execute('''
            SELECT DISTINCT
                oeh.evaluation_session,
                oeh.design_evaluation_session,
                oeh.rcm_id,
                r.rcm_name,
                r.control_category
            FROM sb_evaluation_header oeh
            JOIN sb_rcm r ON oeh.rcm_id = r.rcm_id
            WHERE oeh.user_id = %s
              AND r.control_category = %s
            ORDER BY oeh.evaluation_session DESC
        ''', (user_info['user_id'], control_type.upper())).fetchall()

        evaluation_sessions = []
        for header in headers:
            evaluation_sessions.append({
                "rcm_id": header['rcm_id'],
                "rcm_name": header['rcm_name'],
                "evaluation_session": header['evaluation_session'],
                "design_evaluation_session": header['design_evaluation_session']
            })

        return jsonify({
            "has_operation_evaluation": len(evaluation_sessions) > 0,
            "evaluation_sessions": evaluation_sessions,
            "control_type": control_type.upper()
        })


app.register_blueprint(bp_link5)
app.register_blueprint(bp_link6)
app.register_blueprint(bp_link7)
app.register_blueprint(bp_link8)
app.register_blueprint(bp_aegis_monitor)
app.register_blueprint(admin_bp)

if __name__ == '__main__':
    main()