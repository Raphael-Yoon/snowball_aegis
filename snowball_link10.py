# -*- coding: utf-8 -*-
import sys
import os
import json
import io
from datetime import datetime
from flask import Blueprint, render_template, jsonify, send_file, request, session

# Windows 콘솔 UTF-8 설정
if os.name == 'nt':
    os.system('chcp 65001 > nul')
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

bp_link10 = Blueprint('link10', __name__)

# 결과 파일 저장 디렉토리 (사용 안함 - 데이터베이스 저장)
# RESULTS_DIR = os.path.join(os.path.dirname(__file__), 'results')
# if not os.path.exists(RESULTS_DIR):
#     os.makedirs(RESULTS_DIR, exist_ok=True)

# ============================================================================
# Google Drive Integration Functions
# ============================================================================

def get_drive_service():
    """구글 드라이브 서비스 객체 생성 (읽기 전용)"""
    try:
        import pickle
        from googleapiclient.discovery import build
        from google_auth_oauthlib.flow import InstalledAppFlow
        from google.auth.transport.requests import Request

        # 읽기 전용 권한
        SCOPES = ['https://www.googleapis.com/auth/drive.readonly']
        creds = None

        # snowball 프로젝트의 token_link10.pickle 사용 (Gmail 토큰과 분리)
        snowball_dir = os.path.dirname(__file__)
        token_path = os.path.join(snowball_dir, 'token_link10.pickle')
        credentials_path = os.path.join(snowball_dir, 'credentials.json')

        if os.path.exists(token_path):
            with open(token_path, 'rb') as token:
                creds = pickle.load(token)

        if not creds or not creds.valid:
            if creds and creds.expired and creds.refresh_token:
                creds.refresh(Request())
            else:
                if not os.path.exists(credentials_path):
                    raise FileNotFoundError(f"credentials.json을 찾을 수 없습니다: {credentials_path}")
                flow = InstalledAppFlow.from_client_secrets_file(credentials_path, SCOPES)
                creds = flow.run_local_server(port=0)

            with open(token_path, 'wb') as token:
                pickle.dump(creds, token)

        return build('drive', 'v3', credentials=creds)
    except Exception as e:
        print(f"구글 드라이브 인증 오류: {e}")
        return None

def get_or_create_folder(service, folder_name):
    """구글 드라이브에서 특정 이름의 폴더를 찾거나 생성"""
    try:
        query = f"name = '{folder_name}' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
        results = service.files().list(q=query, fields="files(id, name)").execute()
        items = results.get('files', [])

        if items:
            return items[0]['id']
        else:
            folder_metadata = {
                'name': folder_name,
                'mimeType': 'application/vnd.google-apps.folder'
            }
            folder = service.files().create(body=folder_metadata, fields='id').execute()
            return folder.get('id')
    except Exception as e:
        print(f"폴더 조회/생성 오류: {e}")
        return None

def list_drive_files(folder_name="Stock_Analysis_Results"):
    """구글 드라이브 특정 폴더의 파일 목록 가져오기"""
    try:
        service = get_drive_service()
        if not service:
            return []

        folder_id = get_or_create_folder(service, folder_name)
        if not folder_id:
            return []

        query = f"'{folder_id}' in parents and trashed = false"
        results = service.files().list(
            q=query,
            fields="files(id, name, mimeType, createdTime, webViewLink, size)",
            orderBy="createdTime desc"
        ).execute()

        return results.get('files', [])
    except Exception as e:
        print(f"구글 드라이브 목록 조회 오류: {e}")
        return []

def download_from_drive(file_id):
    """구글 드라이브에서 파일을 엑셀 형식으로 다운로드"""
    try:
        service = get_drive_service()
        if not service:
            return None

        # 구글 시트를 엑셀로 내보내기
        request = service.files().export_media(
            fileId=file_id,
            mimeType='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        )
        return request.execute()
    except Exception as e:
        print(f"구글 드라이브 다운로드 오류: {e}")
        return None

def get_google_doc_content(doc_id):
    """구글 문서의 HTML 내용 가져오기"""
    try:
        from googleapiclient.discovery import build
        service = get_drive_service()
        if not service:
            return None

        # 구글 문서를 HTML로 내보내기
        request = service.files().export_media(
            fileId=doc_id,
            mimeType='text/html'
        )
        content = request.execute()

        # 바이트 데이터인 경우 디코딩
        if isinstance(content, bytes):
            # UTF-8로 시도, 실패하면 다른 인코딩 시도
            try:
                return content.decode('utf-8')
            except UnicodeDecodeError:
                try:
                    return content.decode('utf-8-sig')  # BOM 포함 UTF-8
                except UnicodeDecodeError:
                    return content.decode('latin-1')  # 최후의 수단
        else:
            # 이미 문자열인 경우 그대로 반환
            return content
    except Exception as e:
        print(f"구글 문서 조회 오류: {e}")
        import traceback
        traceback.print_exc()
        return None

# ============================================================================
# Flask Helper Functions
# ============================================================================

def is_logged_in():
    """로그인 상태 확인"""
    return 'user_id' in session

def get_user_info():
    """현재 로그인한 사용자 정보 반환 (세션 우선)"""
    if is_logged_in():
        if 'user_info' in session:
            return session['user_info']
        try:
            from auth import get_current_user
            return get_current_user()
        except ImportError:
            pass
    return None

@bp_link10.route('/link10')
def index():
    """메인 페이지"""
    user_logged_in = is_logged_in()
    user_info = get_user_info()
    return render_template('link10.jsp',
                         is_logged_in=user_logged_in,
                         user_info=user_info)

@bp_link10.route('/link10/api/results', methods=['GET'])
def list_results():
    """구글 드라이브의 결과 파일 목록 조회"""
    try:
        drive_files = list_drive_files()

        # 스프레드시트와 문서를 매핑
        spreadsheets = {}  # {name: file_info}
        documents = {}     # {name: file_info}

        for file in drive_files:
            if file['mimeType'] == 'application/vnd.google-apps.spreadsheet':
                spreadsheets[file['name']] = file
            elif file['mimeType'] == 'application/vnd.google-apps.document':
                documents[file['name']] = file

        # 결과 리스트 생성
        results = []
        for name, sheet_file in spreadsheets.items():
            # 해당 스프레드시트에 대응하는 AI 리포트 찾기
            # 형식: "AI 분석 리포트 - kospi_top100_20251228_162053"
            doc_name = f"AI 분석 리포트 - {name}"
            has_ai = doc_name in documents
            doc_id = documents[doc_name]['id'] if has_ai else None

            results.append({
                'filename': f"{name}.xlsx",  # UI 표시용
                'spreadsheet_id': sheet_file['id'],
                'doc_id': doc_id,
                'size': int(sheet_file.get('size', 0)) if sheet_file.get('size') else 0,
                'created_at': sheet_file.get('createdTime'),
                'drive_link': sheet_file.get('webViewLink'),
                'has_ai': has_ai
            })

        # 최신순 정렬
        results.sort(key=lambda x: x['created_at'] if x['created_at'] else '', reverse=True)
        return jsonify(results)

    except Exception as e:
        print(f"결과 목록 조회 오류: {e}")
        return jsonify({'error': str(e)}), 500

@bp_link10.route('/link10/api/ai_result/<filename>', methods=['GET'])
def get_ai_result(filename):
    """구글 문서에서 AI 분석 결과 조회"""
    try:
        # filename에서 .xlsx 제거하여 스프레드시트 이름 추출
        sheet_name = filename.replace('.xlsx', '')

        # 구글 드라이브에서 파일 목록 가져오기
        drive_files = list_drive_files()

        # AI 분석 리포트 문서 찾기
        doc_name = f"AI 분석 리포트 - {sheet_name}"
        doc_id = None
        doc_link = None

        for file in drive_files:
            if file['name'] == doc_name and file['mimeType'] == 'application/vnd.google-apps.document':
                doc_id = file['id']
                doc_link = file.get('webViewLink')
                break

        if not doc_id:
            return jsonify({'success': False, 'message': 'AI 분석 리포트를 찾을 수 없습니다.'}), 404

        # 구글 문서 내용 가져오기
        content = get_google_doc_content(doc_id)

        if content:
            return jsonify({
                'success': True,
                'result': content,
                'drive_link': doc_link
            })
        else:
            return jsonify({'success': False, 'message': '문서 내용을 불러올 수 없습니다.'}), 500

    except Exception as e:
        print(f"AI 결과 조회 오류: {e}")
        return jsonify({'success': False, 'message': f'오류 발생: {str(e)}'}), 500

@bp_link10.route('/link10/api/download/<filename>', methods=['GET'])
def download_file(filename):
    """엑셀 파일 다운로드 기능 비활성화 (AI 리포트 다운로드로 대체됨)"""
    return jsonify({
        'success': False,
        'message': '엑셀 파일 다운로드 기능은 더 이상 지원되지 않습니다. AI 분석 리포트를 다운로드하시려면 "리포트 다운로드" 버튼을 이용해주세요.'
    }), 410  # 410 Gone - 리소스가 영구적으로 제거됨

@bp_link10.route('/link10/api/download_report/<filename>', methods=['GET'])
def download_report(filename):
    """구글 드라이브에서 AI 분석 리포트 다운로드 (PDF, DOCX, TXT 형식 지원)"""
    try:
        # filename에서 .xlsx 제거하여 스프레드시트 이름 추출
        sheet_name = filename.replace('.xlsx', '')

        # 다운로드 형식 가져오기 (기본값: pdf)
        format_type = request.args.get('format', 'pdf').lower()

        # 지원하는 형식 확인
        supported_formats = {
            'pdf': {
                'mimetype': 'application/pdf',
                'export_type': 'application/pdf',
                'extension': '.pdf'
            },
            'docx': {
                'mimetype': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'export_type': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
                'extension': '.docx'
            },
            'txt': {
                'mimetype': 'text/plain',
                'export_type': 'text/plain',
                'extension': '.txt'
            }
        }

        if format_type not in supported_formats:
            return jsonify({'error': f'지원하지 않는 형식입니다. (지원 형식: pdf, docx, txt)'}), 400

        # 구글 드라이브에서 파일 목록 가져오기
        drive_files = list_drive_files()

        # AI 분석 리포트 문서 찾기
        doc_name = f"AI 분석 리포트 - {sheet_name}"
        doc_id = None

        for file in drive_files:
            if file['name'] == doc_name and file['mimeType'] == 'application/vnd.google-apps.document':
                doc_id = file['id']
                break

        if not doc_id:
            return jsonify({'error': 'AI 분석 리포트를 찾을 수 없습니다.'}), 404

        # 구글 문서를 지정된 형식으로 다운로드
        service = get_drive_service()
        if not service:
            return jsonify({'error': '구글 드라이브 인증에 실패했습니다.'}), 500

        format_info = supported_formats[format_type]
        request_export = service.files().export_media(
            fileId=doc_id,
            mimeType=format_info['export_type']
        )
        file_content = request_export.execute()

        if file_content:
            # 작성일 추출 (파일명에서 타임스탬프 부분 파싱)
            # 형식: kospi_top100_20251228_162053 -> 2025-12-28
            import re
            date_match = re.search(r'_(\d{8})_\d{6}$', sheet_name)
            if date_match:
                date_str = date_match.group(1)
                formatted_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}"
            else:
                # 타임스탬프가 없으면 현재 날짜 사용
                from datetime import datetime
                formatted_date = datetime.now().strftime('%Y-%m-%d')

            # 사용자 친화적인 파일명 생성 (영문)
            # 파일명 파싱: kospi_top100_20251228_162053
            file_parts = sheet_name.split('_')
            if len(file_parts) >= 2:
                market = file_parts[0].upper()
                count = file_parts[1]

                # 종목 개수 라벨 (영문)
                count_label = ''
                if count == 'all':
                    count_label = 'All'
                elif count.startswith('top'):
                    num = count.replace('top', '')
                    count_label = f'Top{num}'

                # 파일명 생성: "KOSPI_Top100_2025-12-28.pdf"
                if market and count_label:
                    download_filename = f"{market}_{count_label}_{formatted_date}{format_info['extension']}"
                else:
                    download_filename = f"AI_Report_{formatted_date}{format_info['extension']}"
            else:
                download_filename = f"AI_Report_{formatted_date}{format_info['extension']}"

            return send_file(
                io.BytesIO(file_content),
                as_attachment=True,
                download_name=download_filename,
                mimetype=format_info['mimetype']
            )
        else:
            return jsonify({'error': '리포트 다운로드에 실패했습니다.'}), 500

    except Exception as e:
        print(f"리포트 다운로드 오류: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': f'다운로드 중 오류: {str(e)}'}), 500

@bp_link10.route('/link10/api/send_report', methods=['POST'])
def send_report():
    """AI 분석 리포트를 이메일로 전송"""
    try:
        data = request.get_json()
        filename = data.get('filename')
        recipient_email = data.get('email')

        if not filename or not recipient_email:
            return jsonify({'success': False, 'message': '필수 정보가 누락되었습니다.'}), 400

        # 이메일 유효성 검사
        import re
        email_pattern = r'^[^\s@]+@[^\s@]+\.[^\s@]+$'
        if not re.match(email_pattern, recipient_email):
            return jsonify({'success': False, 'message': '올바른 이메일 주소가 아닙니다.'}), 400

        # filename에서 .xlsx 제거하여 스프레드시트 이름 추출
        sheet_name = filename.replace('.xlsx', '')

        # 구글 드라이브에서 파일 목록 가져오기
        drive_files = list_drive_files()

        # AI 분석 리포트 문서 찾기
        doc_name = f"AI 분석 리포트 - {sheet_name}"
        doc_id = None

        for file in drive_files:
            if file['name'] == doc_name and file['mimeType'] == 'application/vnd.google-apps.document':
                doc_id = file['id']
                break

        if not doc_id:
            return jsonify({'success': False, 'message': 'AI 분석 리포트를 찾을 수 없습니다.'}), 404

        # 구글 문서를 PDF로 다운로드
        service = get_drive_service()
        if not service:
            return jsonify({'success': False, 'message': '구글 드라이브 인증에 실패했습니다.'}), 500

        request_export = service.files().export_media(
            fileId=doc_id,
            mimeType='application/pdf'
        )
        file_content = request_export.execute()

        if not file_content:
            return jsonify({'success': False, 'message': 'PDF 생성에 실패했습니다.'}), 500

        # 작성일 추출
        date_match = re.search(r'_(\d{8})_\d{6}$', sheet_name)
        if date_match:
            date_str = date_match.group(1)
            formatted_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}"
        else:
            from datetime import datetime
            formatted_date = datetime.now().strftime('%Y-%m-%d')

        # 사용자 친화적인 파일명 생성 (영문)
        file_parts = sheet_name.split('_')
        if len(file_parts) >= 2:
            market = file_parts[0].upper()
            count = file_parts[1]

            # 시장명 (한글, 이메일 본문용)
            market_label_ko = ''
            if market == 'KOSPI':
                market_label_ko = 'KOSPI'
            elif market == 'KOSDAQ':
                market_label_ko = 'KOSDAQ'
            elif market == 'ALL':
                market_label_ko = '전체시장'

            # 종목 개수 (한글, 이메일 본문용)
            count_label_ko = ''
            if count == 'all':
                count_label_ko = '전체 종목'
            elif count.startswith('top'):
                num = count.replace('top', '')
                count_label_ko = f'상위 {num}개'

            # 종목 개수 (영문, 파일명용)
            count_label_en = ''
            if count == 'all':
                count_label_en = 'All'
            elif count.startswith('top'):
                num = count.replace('top', '')
                count_label_en = f'Top{num}'

            # 파일명 생성 (영문): "KOSPI_Top100_2025-12-28.pdf"
            if market and count_label_en:
                pdf_filename = f"{market}_{count_label_en}_{formatted_date}.pdf"
                display_name = f"{market_label_ko} {count_label_ko} 분석"
            else:
                pdf_filename = f"AI_Report_{formatted_date}.pdf"
                display_name = "AI 분석 리포트"
        else:
            pdf_filename = f"AI_Report_{formatted_date}.pdf"
            display_name = "AI 분석 리포트"

        # 이메일 전송
        from snowball_mail import send_gmail_with_attachment

        subject = f"[Snowball] {display_name} - {formatted_date}"
        body = f"""
안녕하세요,

요청하신 Snowball AI 주식 시장 분석 리포트를 전송드립니다.

분석 일자: {formatted_date}
분석 내용: {display_name}

첨부된 PDF 파일을 확인해주세요.

감사합니다.

---
Snowball AI Analysis Team
        """

        # BytesIO 객체 생성
        file_stream = io.BytesIO(file_content)

        try:
            send_gmail_with_attachment(
                to=recipient_email,
                subject=subject,
                body=body,
                file_stream=file_stream,
                file_name=pdf_filename
            )
            success = True
        except Exception as email_error:
            print(f"Gmail 전송 오류: {email_error}")
            success = False

        if success:
            print(f"리포트 이메일 전송 성공: {recipient_email}")
            return jsonify({'success': True, 'message': '이메일이 성공적으로 전송되었습니다.'})
        else:
            print(f"리포트 이메일 전송 실패: {recipient_email}")
            return jsonify({'success': False, 'message': '이메일 전송에 실패했습니다.'}), 500

    except Exception as e:
        print(f"리포트 이메일 전송 오류: {e}")
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'message': f'오류 발생: {str(e)}'}), 500

@bp_link10.route('/link10/api/delete/<filename>', methods=['DELETE'])
def delete_file(filename):
    """삭제 기능 비활성화 (읽기 전용 모드)"""
    return jsonify({
        'success': False,
        'message': 'Link10은 읽기 전용 모드입니다. 파일 삭제는 Trade 프로젝트에서 수행해주세요.'
    }), 403
