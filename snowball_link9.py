import hmac
import hashlib
import time
import re
from flask import Blueprint, request, render_template, redirect, url_for, session, current_app
from snowball_mail import send_gmail
from extensions import limiter
from logger_config import get_logger

bp_link9 = Blueprint('link9', __name__)
logger = get_logger('contact')

_URL_PATTERN = re.compile(r'https?://|www\.', re.IGNORECASE)

def _validate_form_token(token, min_seconds=3):
    """폼 제출 토큰 검증 — 최소 min_seconds초 경과 여부 확인"""
    if not token:
        return False
    try:
        timestamp_str, sig = token.split('.', 1)
        secret = current_app.config.get('SECRET_KEY', 'fallback-secret')
        expected = hmac.new(secret.encode(), timestamp_str.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(sig, expected):
            return False
        return (int(time.time()) - int(timestamp_str)) >= min_seconds
    except (ValueError, AttributeError):
        return False

def _contains_url(text):
    """메시지 본문에 URL이 포함되어 있는지 확인"""
    return bool(_URL_PATTERN.search(text or ''))

def _log_contact(endpoint, result, reason=None, extra=None):
    """Contact 폼 제출 시도를 로깅한다.
    result: 'blocked' | 'sent' | 'error'
    reason: 차단 사유 (blocked일 때)
    extra: 추가 정보 딕셔너리
    """
    ip = request.remote_addr
    ua = request.headers.get('User-Agent', 'unknown')[:120]
    base = f"[contact/{endpoint}] result={result} ip={ip} ua=\"{ua}\""
    if reason:
        base += f" reason={reason}"
    if extra:
        for k, v in extra.items():
            base += f" {k}={str(v)[:80]!r}"
    if result == 'blocked':
        logger.warning(base)
    elif result == 'error':
        logger.error(base)
    else:
        logger.info(base)

def is_logged_in():
    """로그인 상태 확인"""
    return 'user_id' in session

def get_user_info():
    """현재 로그인한 사용자 정보 반환 (세션 우선)"""
    from snowball import is_logged_in
    if is_logged_in():
        # 세션에 저장된 user_info를 우선 사용
        if 'user_info' in session:
            return session['user_info']
        # 없으면 데이터베이스에서 조회
        from auth import get_current_user
        db_user_info = get_current_user()
        return db_user_info
    return None

# Contact Us 관련 기능들

@bp_link9.route('/link9', methods=['GET', 'POST'])
@limiter.limit("5 per hour")
def link9():
    """서비스 문의 페이지 (Contact Us)"""
    user_logged_in = is_logged_in()
    user_info = get_user_info()

    if request.method == 'POST':
        # Honeypot: 봇 차단 (숨겨진 필드에 값이 있으면 봇으로 판단)
        if request.form.get('website'):
            _log_contact('link9', 'blocked', reason='honeypot')
            return render_template('link9.jsp', success=True, remote_addr=request.remote_addr,
                                 is_logged_in=user_logged_in, user_info=user_info)

        # 폼 제출 시간 검증: 3초 미만이면 봇으로 판단
        if not _validate_form_token(request.form.get('form_token')):
            _log_contact('link9', 'blocked', reason='form_token')
            return render_template('link9.jsp', success=False,
                                 error='잘못된 요청입니다. 잠시 후 다시 시도해주세요.',
                                 remote_addr=request.remote_addr,
                                 is_logged_in=user_logged_in, user_info=user_info)

        name = request.form.get('name')
        company_name = request.form.get('company_name')
        email = request.form.get('email')
        message = request.form.get('message')

        # URL 포함 메시지 차단
        if _contains_url(message):
            _log_contact('link9', 'blocked', reason='url_in_message', extra={'email': email})
            return render_template('link9.jsp', success=False,
                                 error='문의 내용에 URL을 포함할 수 없습니다.',
                                 remote_addr=request.remote_addr,
                                 is_logged_in=user_logged_in, user_info=user_info)

        subject = f'Contact Us 문의: {name}'
        body = f'이름: {name}\n회사명: {company_name}\n이메일: {email}\n문의내용:\n{message}'
        try:
            send_gmail(
                to='snowball1566@gmail.com',
                subject=subject,
                body=body
            )
            _log_contact('link9', 'sent', extra={'email': email, 'company': company_name})
            return render_template('link9.jsp', success=True, remote_addr=request.remote_addr,
                                 is_logged_in=user_logged_in, user_info=user_info)
        except Exception as e:
            _log_contact('link9', 'error', extra={'error': str(e)})
            return render_template('link9.jsp', success=False, error=str(e), remote_addr=request.remote_addr,
                                 is_logged_in=user_logged_in, user_info=user_info)
    return render_template('link9.jsp', remote_addr=request.remote_addr,
                         is_logged_in=user_logged_in, user_info=user_info)

@bp_link9.route('/service_inquiry', methods=['POST'])
@limiter.limit("5 per hour")
def service_inquiry():
    """서비스 문의 처리"""
    # Honeypot: 봇 차단
    if request.form.get('website'):
        _log_contact('service_inquiry', 'blocked', reason='honeypot')
        return render_template('login.jsp', service_inquiry_success=True,
                             remote_addr=request.remote_addr)

    # 폼 제출 시간 검증
    if not _validate_form_token(request.form.get('form_token')):
        _log_contact('service_inquiry', 'blocked', reason='form_token')
        return render_template('login.jsp', service_inquiry_error='잘못된 요청입니다. 잠시 후 다시 시도해주세요.',
                             remote_addr=request.remote_addr)

    try:
        company_name = request.form.get('company_name')
        contact_name = request.form.get('contact_name')
        contact_email = request.form.get('contact_email')
        
        
        subject = f'SnowBall 서비스 가입 문의: {company_name}'
        body = f'''SnowBall 서비스 가입 문의가 접수되었습니다.

회사명: {company_name}
담당자명: {contact_name}
이메일: {contact_email}

내부통제 평가 및 ITGC 관련 서비스에 관심을 보여주셔서 감사합니다.
빠른 시일 내에 담당자가 연락드리겠습니다.'''
        
        send_gmail(
            to=f'{contact_email}, snowball1566@gmail.com',
            subject=subject,
            body=body
        )
        _log_contact('service_inquiry', 'sent', extra={'email': contact_email, 'company': company_name})
        return render_template('login.jsp',
                             service_inquiry_success=True,
                             remote_addr=request.remote_addr)
    except Exception as e:
        _log_contact('service_inquiry', 'error', extra={'error': str(e)})
        return render_template('login.jsp',
                             service_inquiry_error=str(e),
                             remote_addr=request.remote_addr)

@bp_link9.route('/api/contact/send', methods=['POST'])
@limiter.limit("5 per hour")
def send_contact_message():
    """Contact 메시지 전송 API"""
    try:
        data = request.get_json()
        # Honeypot: JSON API는 website 필드로 봇 판단
        if data and data.get('website'):
            _log_contact('api', 'blocked', reason='honeypot')
            return {'success': True, 'message': '문의가 성공적으로 전송되었습니다.'}

        # 폼 제출 시간 검증
        if not _validate_form_token(data.get('form_token') if data else None):
            _log_contact('api', 'blocked', reason='form_token')
            return {'success': False, 'message': '잘못된 요청입니다. 잠시 후 다시 시도해주세요.'}, 400

        name = data.get('name')
        email = data.get('email')
        subject = data.get('subject', '일반 문의')
        message = data.get('message')

        # URL 포함 메시지 차단
        if _contains_url(message):
            _log_contact('api', 'blocked', reason='url_in_message', extra={'email': email})
            return {'success': False, 'message': '문의 내용에 URL을 포함할 수 없습니다.'}, 400

        if not all([name, email, message]):
            _log_contact('api', 'blocked', reason='missing_fields')
            return {
                'success': False,
                'message': '필수 정보가 누락되었습니다.'
            }, 400
        
        # 이메일 전송
        email_subject = f'[SnowBall] {subject} - {name}'
        email_body = f'''SnowBall 웹사이트를 통해 문의가 접수되었습니다.

■ 문의자 정보
이름: {name}
이메일: {email}
문의 유형: {subject}

■ 문의 내용
{message}

■ 기타 정보
접수 시간: {request.remote_addr}
IP 주소: {request.remote_addr}
User-Agent: {request.headers.get('User-Agent', 'Unknown')}
'''
        
        send_gmail(
            to='snowball1566@gmail.com',
            subject=email_subject,
            body=email_body
        )
        
        # 자동 응답 메일 (문의자에게)
        auto_reply_subject = '[SnowBall] 문의 접수 완료'
        auto_reply_body = f'''안녕하세요, {name}님.

SnowBall 서비스에 문의해 주셔서 감사합니다.
고객님의 문의가 정상적으로 접수되었습니다.

■ 접수된 문의 내용
문의 유형: {subject}
접수 내용: {message[:100]}{'...' if len(message) > 100 else ''}

담당자 검토 후 빠른 시일 내에 회신드리겠습니다.
일반적으로 1-2일 이내에 답변드리고 있습니다.

문의해 주셔서 다시 한 번 감사합니다.

SnowBall Team
snowball1566@gmail.com
'''
        
        send_gmail(
            to=email,
            subject=auto_reply_subject,
            body=auto_reply_body
        )
        
        _log_contact('api', 'sent', extra={'email': email, 'subject': subject})
        return {
            'success': True,
            'message': '문의가 성공적으로 전송되었습니다. 빠른 시일 내에 답변드리겠습니다.'
        }

    except Exception as e:
        _log_contact('api', 'error', extra={'error': str(e)})
        return {
            'success': False,
            'message': '메시지 전송 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.'
        }, 500

@bp_link9.route('/api/feedback', methods=['POST'])
def submit_feedback():
    """사용자 피드백 전송 API"""
    try:
        data = request.get_json()
        feedback_type = data.get('type', '일반 피드백')
        content = data.get('content')
        rating = data.get('rating')
        user_email = data.get('email', '익명')
        
        if not content:
            return {
                'success': False,
                'message': '피드백 내용을 입력해주세요.'
            }, 400
        
        # 피드백 이메일 전송
        email_subject = f'[SnowBall 피드백] {feedback_type}'
        email_body = f'''SnowBall 서비스에 대한 피드백이 접수되었습니다.

■ 피드백 정보
유형: {feedback_type}
평점: {rating}/5 {'★' * int(rating) if rating else 'N/A'}
이메일: {user_email}

■ 피드백 내용
{content}

■ 기술 정보
접수 시간: {request.remote_addr}
IP 주소: {request.remote_addr}
User-Agent: {request.headers.get('User-Agent', 'Unknown')}
'''
        
        send_gmail(
            to='snowball1566@gmail.com',
            subject=email_subject,
            body=email_body
        )
        
        return {
            'success': True,
            'message': '소중한 피드백 감사합니다. 서비스 개선에 적극 반영하겠습니다.'
        }
        
    except Exception as e:
        return {
            'success': False,
            'message': '피드백 전송 중 오류가 발생했습니다.'
        }, 500