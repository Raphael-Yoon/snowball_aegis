import os
import base64
import pickle
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders

# Gmail 인증 토큰 획득

def get_gmail_credentials():
    SCOPES = ['https://www.googleapis.com/auth/gmail.send']
    creds = None
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)
    return creds

# 텍스트 메일 전송

def send_gmail(to, subject, body, bcc=None):
    if os.getenv('MOCK_MAIL') == 'True':
        print(f"[MOCK_MAIL] To: {to}, Subject: {subject}")
        return {"id": "mock_id", "threadId": "mock_thread_id"}
    
    creds = get_gmail_credentials()
    service = build('gmail', 'v1', credentials=creds)
    
    # MIMEMultipart를 사용하여 BCC 처리
    message = MIMEMultipart()
    message['to'] = to
    message['subject'] = subject
    if bcc:
        message['Bcc'] = bcc
    else:
        message['Bcc'] = 'snowball2727@naver.com'  # 기본 BCC
    
    # 본문 추가
    message.attach(MIMEText(body, 'plain'))
    
    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    send_message = service.users().messages().send(userId="me", body={'raw': raw}).execute()
    return send_message

# 첨부파일 포함 메일 전송

def send_gmail_with_attachment(to, subject, body, file_stream=None, file_path=None, file_name=None):
    if os.getenv('MOCK_MAIL') == 'True':
        print(f"[MOCK_MAIL_ATTACH] To: {to}, Subject: {subject}, File: {file_name}")
        return {"id": "mock_id", "threadId": "mock_thread_id"}
    
    creds = get_gmail_credentials()
    service = build('gmail', 'v1', credentials=creds)

    # 메일 생성
    message = MIMEMultipart()
    message['to'] = to
    message['subject'] = subject
    message['Bcc'] = 'snowball2727@naver.com'
    message.attach(MIMEText(body, 'plain'))

    # 첨부파일 추가 (메모리 버퍼 우선, 없으면 파일 경로)
    part = MIMEBase('application', 'octet-stream')
    if file_stream is not None:
        file_stream.seek(0)
        part.set_payload(file_stream.read())
    elif file_path is not None:
        with open(file_path, 'rb') as f:
            part.set_payload(f.read())
    else:
        raise ValueError('첨부할 파일이 없습니다.')
    encoders.encode_base64(part)
    # 파일명 인코딩 처리 (한글 지원) - Gmail API 최적화
    import re
    from email.header import Header
    
    try:
        # 파일명이 None인 경우 기본값 설정
        if file_name is None:
            file_name = "ITGC_System.xlsx"
        
        # 파일명에서 위험한 문자만 제거 (한글은 유지)
        safe_filename = re.sub(r'[<>:"/\\|?*\x00-\x1f]', '_', file_name)
        safe_filename = re.sub(r'\s+', '_', safe_filename)
        safe_filename = re.sub(r'_+', '_', safe_filename)
        
        # Gmail API에서 한글 파일명 처리 - RFC 2047 인코딩 사용
        try:
            # 한글이 포함된 경우 RFC 2047 형식으로 인코딩
            if re.search(r'[가-힣]', safe_filename):
                # RFC 2047 형식으로 한글 파일명 인코딩
                encoded_filename = Header(safe_filename, 'utf-8').encode()
                part.add_header('Content-Disposition', f'attachment; filename={encoded_filename}')
            else:
                part.add_header('Content-Disposition', f'attachment; filename="{safe_filename}"')
        except Exception as inner_e:
            # 인코딩 실패 시 기본 파일명 사용
            print(f"한글 파일명 인코딩 실패: {inner_e}")
            part.add_header('Content-Disposition', f'attachment; filename="ITGC_System.xlsx"')
        
        # Content-Type 헤더 설정
        part.add_header('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
        
    except Exception as e:
        # 인코딩 실패 시 안전한 파일명 사용
        print(f"파일명 인코딩 오류: {e}")
        safe_filename = "ITGC_System.xlsx"
        part.add_header('Content-Disposition', f'attachment; filename="{safe_filename}"')
        part.add_header('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
    
    message.attach(part)

    raw = base64.urlsafe_b64encode(message.as_bytes()).decode()
    send_message = service.users().messages().send(userId="me", body={'raw': raw}).execute()
    return send_message