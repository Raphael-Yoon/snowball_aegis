import hmac
import hashlib
import time
from flask import Flask, render_template, request, redirect, url_for, session, jsonify
from flask_wtf.csrf import CSRFProtect
from extensions import limiter
from werkzeug.exceptions import HTTPException
from datetime import datetime, timedelta
from dotenv import load_dotenv
from pathlib import Path
import os
import traceback

_APP_DIR = Path(__file__).parent.resolve()
os.chdir(_APP_DIR)

env_path = _APP_DIR / '.env'
load_dotenv(dotenv_path=env_path)

from logger_config import setup_logging, get_logger
from aegis_systems import bp_aegis_systems
from aegis_controls import bp_aegis_controls
from aegis_monitor import bp_aegis_monitor
from snowball_admin import admin_bp
from auth import send_otp, verify_otp, get_current_user, find_user_by_email

app = Flask(__name__)

setup_logging()
logger = get_logger('aegis_main')

app.secret_key = os.getenv('FLASK_SECRET_KEY')
if not app.secret_key:
    logger.critical("FLASK_SECRET_KEY environment variable not set")
    raise ValueError("FLASK_SECRET_KEY environment variable must be set in .env file")

is_production = os.getenv('PYTHONANYWHERE_DOMAIN') is not None or 'pythonanywhere' in os.getenv('SERVER_NAME', '')
app.config.update(
    SESSION_COOKIE_SECURE=is_production,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    SESSION_COOKIE_MAX_AGE=timedelta(hours=24).total_seconds(),
    TEMPLATES_AUTO_RELOAD=True
)
app.jinja_env.auto_reload = True

csrf = CSRFProtect(app)
limiter.init_app(app)

csrf.exempt(bp_aegis_systems)
csrf.exempt(bp_aegis_controls)
csrf.exempt(bp_aegis_monitor)

is_production_env = os.getenv('PYTHONANYWHERE_DOMAIN') is not None
PYTHONANYWHERE_AUTH_CODE = os.getenv('PYTHONANYWHERE_AUTH_CODE')
if is_production_env and not PYTHONANYWHERE_AUTH_CODE:
    raise ValueError("PYTHONANYWHERE_AUTH_CODE must be set in production environment")


@app.context_processor
def inject_globals():
    timestamp = str(int(time.time()))
    sig = hmac.new(app.secret_key.encode(), timestamp.encode(), hashlib.sha256).hexdigest()
    return {
        'is_production': is_production,
        'form_token': f"{timestamp}.{sig}",
    }


def is_logged_in():
    return 'user_id' in session and get_current_user() is not None


def get_user_info():
    if is_logged_in():
        if 'user_info' in session:
            return session['user_info']
        return get_current_user()
    return None


@app.route('/')
def index():
    user_info = get_user_info()
    user_name = user_info['user_name'] if user_info else "Guest"
    return render_template('index.jsp',
                           user_name=user_name,
                           is_logged_in=is_logged_in(),
                           user_info=user_info,
                           remote_addr=request.remote_addr)


@app.route('/login', methods=['GET', 'POST'])
@csrf.exempt
def login():
    try:
        action = request.form.get('action') if request.method == 'POST' else None

        if action == 'send_otp':
            email = request.form.get('email')
            if not email:
                return render_template('login.jsp', error="이메일을 입력해주세요.", remote_addr=request.remote_addr)

            host = request.headers.get('Host', '')
            if host.startswith('snowball.pythonanywhere.com'):
                user = find_user_by_email(email)
                if not user:
                    return render_template('login.jsp', error="등록되지 않은 사용자입니다.", remote_addr=request.remote_addr, show_direct_login=True)
                session['login_email'] = email
                return render_template('login.jsp', step='verify', email=email,
                                       message="인증 코드를 입력해주세요.",
                                       remote_addr=request.remote_addr, show_direct_login=True)
            else:
                success, message = send_otp(email, method='email')
                if success:
                    session['login_email'] = email
                    return render_template('login.jsp', step='verify', email=email, message=message, remote_addr=request.remote_addr)
                else:
                    return render_template('login.jsp', error=message, remote_addr=request.remote_addr)

        elif action == 'verify_otp':
            email = session.get('login_email')
            otp_code = request.form.get('otp_code')
            host = request.headers.get('Host', '')

            if not email or not otp_code:
                return render_template('login.jsp', error="인증 코드를 입력해주세요.", remote_addr=request.remote_addr)

            if host.startswith('snowball.pythonanywhere.com'):
                if otp_code == PYTHONANYWHERE_AUTH_CODE:
                    user = find_user_by_email(email)
                    if user:
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
                        session.pop('login_email', None)
                        return redirect(url_for('index'))
                    else:
                        return render_template('login.jsp', step='verify', email=email,
                                               error="사용자 정보를 찾을 수 없습니다.", remote_addr=request.remote_addr, show_direct_login=True)
                else:
                    return render_template('login.jsp', step='verify', email=email,
                                           error="잘못된 인증 코드입니다.", remote_addr=request.remote_addr, show_direct_login=True)
            else:
                success, result = verify_otp(email, otp_code)
                if success:
                    user = result
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
                    session.pop('login_email', None)
                    return redirect(url_for('index'))
                else:
                    return render_template('login.jsp', step='verify', email=email, error=result, remote_addr=request.remote_addr)

        host = request.headers.get('Host', '')
        show_direct_login = host.startswith('snowball.pythonanywhere.com')
        return render_template('login.jsp', remote_addr=request.remote_addr, show_direct_login=show_direct_login)

    except Exception as e:
        logger.error(f"로그인 오류: {traceback.format_exc()}")
        return f"로그인 오류가 발생했습니다: {str(e)}", 500


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))


@app.route('/extend_session', methods=['POST'])
@csrf.exempt
def extend_session():
    if 'user_id' in session:
        session['last_activity'] = datetime.now().isoformat()
        return jsonify({'success': True})
    return jsonify({'success': False, 'message': '로그인이 필요합니다.'})


@app.route('/health')
def health_check():
    return {
        'status': 'ok',
        'service': 'Snowball Aegis',
        'timestamp': datetime.now().isoformat()
    }


@app.errorhandler(Exception)
def handle_exception(e):
    if isinstance(e, HTTPException):
        return e
    logger.error(f"Unhandled Exception: {traceback.format_exc()}")
    return "Internal Server Error: check logs", 500


app.register_blueprint(bp_aegis_systems)
app.register_blueprint(bp_aegis_controls)
app.register_blueprint(bp_aegis_monitor)
app.register_blueprint(admin_bp)


def main():
    app.run(host='0.0.0.0', debug=True, port=5002, use_reloader=False)


if __name__ == '__main__':
    main()
