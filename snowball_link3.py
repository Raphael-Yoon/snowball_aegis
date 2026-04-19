from flask import Blueprint, request, render_template, session, send_file
from auth import log_user_activity
import os

# Blueprint 생성
bp_link3 = Blueprint('link3', __name__)


def get_user_info():
    """현재 로그인한 사용자 정보 반환 (세션 우선)"""
    from snowball import is_logged_in
    from auth import get_current_user
    if is_logged_in():
        if 'user_info' in session:
            return session['user_info']
        return get_current_user()
    return None


def is_logged_in():
    """로그인 상태 확인"""
    from snowball import is_logged_in as main_is_logged_in
    return main_is_logged_in()


@bp_link3.route('/link3')
def link3():
    """운영평가 테스트 페이지 (Operation Test)"""
    user_info = get_user_info()

    if is_logged_in():
        log_user_activity(user_info, 'PAGE_ACCESS', 'Operation Test 페이지', '/link3',
                         request.remote_addr, request.headers.get('User-Agent'))

    return render_template('link3.jsp',
                         is_logged_in=is_logged_in(),
                         user_info=user_info,
                         remote_addr=request.remote_addr)


@bp_link3.route('/paper_template_download', methods=['POST'])
def paper_template_download():
    """운영평가 템플릿 다운로드"""
    template_path = os.path.join("static", "Design_Template.xlsx")

    if os.path.exists(template_path):
        return send_file(template_path, as_attachment=True)
    else:
        return render_template('link3.jsp',
                             is_logged_in=is_logged_in(),
                             user_info=get_user_info(),
                             remote_addr=request.remote_addr)
