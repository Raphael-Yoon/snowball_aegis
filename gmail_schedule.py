#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Gmail 스케줄 스크립트
- MySQL → SQLite 백업 실행 (migrations/backup_mysql_to_sqlite.py 사용)
- 결과를 Gmail로 전송
"""

import base64
from email.mime.text import MIMEText
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import pickle
import os
import sys
from datetime import datetime, timedelta
from dotenv import load_dotenv

# migrations 폴더를 path에 추가
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'migrations'))

# backup_mysql_to_sqlite 모듈 import
from backup_mysql_to_sqlite import backup_mysql_to_sqlite as run_backup

# .env 파일 로드
load_dotenv()

# 필요한 권한 범위 설정
SCOPES = ['https://www.googleapis.com/auth/gmail.send']

# ============================================================================
# 백업 설정
# ============================================================================

# 백업 디렉토리
BACKUP_DIR = '/home/itap/snowball/backups'

# 보관 기간 (일)
RETENTION_DAYS = 7

# ============================================================================
# Gmail API 함수
# ============================================================================

def get_gmail_service():
    """Gmail API 서비스 객체 생성"""
    creds = None

    # 토큰이 이미 있으면 사용
    if os.path.exists('token.pickle'):
        with open('token.pickle', 'rb') as token:
            creds = pickle.load(token)

    # 토큰이 없거나 만료된 경우
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file(
                'credentials.json', SCOPES)
            creds = flow.run_local_server(port=8080)

        # 나중에 사용하기 위해 토큰 저장
        with open('token.pickle', 'wb') as token:
            pickle.dump(creds, token)

    return build('gmail', 'v1', credentials=creds)


def send_email(service, to, subject, body):
    """이메일 보내기"""
    message = MIMEText(body)
    message['to'] = to
    message['subject'] = subject

    raw_message = base64.urlsafe_b64encode(message.as_string().encode('utf-8')).decode('utf-8')

    try:
        sent_message = service.users().messages().send(
            userId='me',
            body={'raw': raw_message}
        ).execute()
        print(f'메시지 ID: {sent_message["id"]}')
        return sent_message
    except Exception as e:
        print(f'에러 발생: {e}')
        return None


# ============================================================================
# MySQL → SQLite 백업 함수
# ============================================================================

def get_backup_filename():
    """오늘 날짜로 백업 파일명 생성"""
    today = datetime.now().strftime('%Y%m%d')
    return f'snowball_{today}.db'


def backup_mysql_to_sqlite():
    """MySQL 데이터를 SQLite로 백업 (backup_mysql_to_sqlite.py 사용)"""

    # 백업 디렉토리 생성
    os.makedirs(BACKUP_DIR, exist_ok=True)

    # 백업 파일 경로
    backup_filename = get_backup_filename()
    backup_path = os.path.join(BACKUP_DIR, backup_filename)

    # 이미 오늘 백업이 있으면 삭제
    if os.path.exists(backup_path):
        print(f"[INFO] 기존 백업 파일 삭제: {backup_filename}")
        os.remove(backup_path)

    print(f"[INFO] 백업 파일: {backup_path}")
    print("")

    try:
        # 로그 캡처를 위한 변수
        import io
        from contextlib import redirect_stdout

        log_buffer = io.StringIO()

        # stdout을 캡처하면서 백업 실행
        with redirect_stdout(log_buffer):
            # backup_mysql_to_sqlite 모듈의 함수 직접 호출
            # (내부적으로 print를 사용하므로 로그가 캡처됨)
            import pymysql
            import sqlite3
            from backup_mysql_to_sqlite import (
                get_mysql_table_schema,
                create_sqlite_table,
                migrate_table_data,
                MYSQL_CONFIG
            )

            # MySQL 연결
            print("[CONNECT] MySQL 연결 중...")
            mysql_conn = pymysql.connect(**MYSQL_CONFIG)
            print("  ✅ MySQL 연결 성공")

            # SQLite 연결
            print(f"[CONNECT] SQLite 파일 생성 중... ({backup_path})")
            sqlite_conn = sqlite3.connect(backup_path)
            print("  ✅ SQLite 파일 생성 완료")
            print("")

            # MySQL에서 모든 테이블 조회
            mysql_cursor = mysql_conn.cursor()
            mysql_cursor.execute("SHOW TABLES")
            table_results = mysql_cursor.fetchall()

            # 테이블 이름 추출
            tables = []
            for row in table_results:
                if isinstance(row, dict):
                    table_name = list(row.values())[0]
                else:
                    table_name = row[0]
                tables.append(table_name)

            print("=" * 70)
            print(f"백업 대상 테이블: {len(tables)}개")
            print("=" * 70)
            print("")

            total_rows = 0
            success_count = 0

            # 각 테이블 백업
            for i, table_name in enumerate(tables, 1):
                print(f"[{i}/{len(tables)}] {table_name}")
                print("-" * 70)

                try:
                    # 스키마 조회
                    columns = get_mysql_table_schema(mysql_conn, table_name)

                    # SQLite 테이블 생성
                    create_sqlite_table(sqlite_conn, table_name, columns)

                    # 데이터 마이그레이션
                    row_count = migrate_table_data(mysql_conn, sqlite_conn, table_name)
                    total_rows += row_count
                    success_count += 1

                except Exception as e:
                    print(f"   ❌ 오류 발생: {e}")

            # 연결 종료
            sqlite_conn.close()
            mysql_conn.close()

            print("")
            print("=" * 70)
            print("백업 완료!")
            print("=" * 70)
            print(f"✅ 성공: {success_count}/{len(tables)} 테이블")
            print(f"📊 총 백업된 데이터: {total_rows:,} rows")
            print(f"💾 백업 파일: {backup_path}")
            print(f"📦 파일 크기: {os.path.getsize(backup_path) / 1024 / 1024:.2f} MB")
            print("=" * 70)

        # 로그 가져오기
        log_content = log_buffer.getvalue()

        # 콘솔에도 출력
        print(log_content)

        return {
            'success': True,
            'log': log_content,
            'backup_file': backup_filename,
            'total_tables': len(tables),
            'total_rows': total_rows,
            'file_size': os.path.getsize(backup_path)
        }

    except Exception as e:
        import traceback
        error_log = f"❌ 백업 실패!\n오류: {e}\n{traceback.format_exc()}"
        print(error_log)

        return {
            'success': False,
            'log': error_log,
            'error': str(e)
        }


def cleanup_old_backups():
    """7일 이상 된 백업 파일 삭제"""

    log_lines = []

    def log(message):
        print(message)
        log_lines.append(message)

    log("=" * 70)
    log("오래된 백업 파일 정리")
    log("=" * 70)

    if not os.path.exists(BACKUP_DIR):
        log("[INFO] 백업 디렉토리 없음")
        return {'success': True, 'log': '\n'.join(log_lines), 'deleted_count': 0}

    cutoff_date = datetime.now() - timedelta(days=RETENTION_DAYS)
    cutoff_str = cutoff_date.strftime('%Y%m%d')

    log(f"보관 기간: {RETENTION_DAYS}일")
    log(f"삭제 기준: {cutoff_str} 이전 파일")
    log("")

    deleted_count = 0
    deleted_size = 0

    for filename in os.listdir(BACKUP_DIR):
        if not filename.startswith('snowball_') or not filename.endswith('.db'):
            continue

        try:
            date_str = filename.replace('snowball_', '').replace('.db', '')

            if len(date_str) != 8 or not date_str.isdigit():
                continue

            if date_str < cutoff_str:
                file_path = os.path.join(BACKUP_DIR, filename)
                file_size = os.path.getsize(file_path)

                os.remove(file_path)
                deleted_count += 1
                deleted_size += file_size

                log(f"  🗑️  삭제: {filename} ({file_size / 1024 / 1024:.2f} MB)")

        except Exception as e:
            log(f"  ⚠️  {filename} 처리 실패: {e}")

    log("")
    if deleted_count > 0:
        log(f"✅ {deleted_count}개 파일 삭제됨 (총 {deleted_size / 1024 / 1024:.2f} MB)")
    else:
        log("✅ 삭제할 파일 없음")
    log("")

    return {
        'success': True,
        'log': '\n'.join(log_lines),
        'deleted_count': deleted_count,
        'deleted_size': deleted_size
    }


def send_backup_result_email(service, to, subject, backup_result, cleanup_result):
    """백업 결과를 포함한 이메일 보내기"""
    now = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    # 이메일 본문 구성
    body_lines = [
        f'MySQL to SQLite 백업 실행 결과',
        f'실행 일시: {now}',
        f'',
        f'=' * 60,
        f'백업 상태: {"✅ 성공" if backup_result["success"] else "❌ 실패"}',
    ]

    if backup_result['success']:
        body_lines.append(f'백업 파일: {backup_result["backup_file"]}')
        body_lines.append(f'총 테이블: {backup_result["total_tables"]}개')
        body_lines.append(f'총 데이터: {backup_result["total_rows"]:,}개 행')
        body_lines.append(f'파일 크기: {backup_result["file_size"] / 1024 / 1024:.2f} MB')
    else:
        body_lines.append(f'오류: {backup_result.get("error", "알 수 없는 오류")}')

    body_lines.append(f'=' * 60)
    body_lines.append(f'')

    # 정리 결과
    if cleanup_result['deleted_count'] > 0:
        body_lines.append(f'오래된 백업 삭제: {cleanup_result["deleted_count"]}개')
        body_lines.append(f'')

    # 백업 로그
    body_lines.append('[ 백업 로그 ]')
    body_lines.append(backup_result['log'])
    body_lines.append('')

    # 정리 로그
    if cleanup_result.get('log'):
        body_lines.append('[ 정리 로그 ]')
        body_lines.append(cleanup_result['log'])
        body_lines.append('')

    body = '\n'.join(body_lines)

    # 이메일 전송
    message = MIMEText(body)
    message['to'] = to
    message['subject'] = subject
    raw_message = base64.urlsafe_b64encode(message.as_string().encode('utf-8')).decode('utf-8')

    try:
        sent_message = service.users().messages().send(
            userId='me',
            body={'raw': raw_message}
        ).execute()
        print(f'메시지 ID: {sent_message["id"]}')
        return sent_message
    except Exception as e:
        print(f'에러 발생: {e}')
        return None


# ============================================================================
# 메인 실행
# ============================================================================

if __name__ == '__main__':
    # 받는 사람과 제목 설정
    to = 'snowball1566@gmail.com'
    subject = 'MySQL to SQLite 백업 결과'

    print('Gmail 서비스 인증 중...')
    service = get_gmail_service()

    print('\nMySQL to SQLite 백업 실행 중...')
    backup_result = backup_mysql_to_sqlite()

    print('\n오래된 백업 파일 정리 중...')
    cleanup_result = cleanup_old_backups()

    print('\n결과 메일 전송 중...')
    result = send_backup_result_email(
        service=service,
        to=to,
        subject=subject,
        backup_result=backup_result,
        cleanup_result=cleanup_result
    )

    if result:
        print('메일이 성공적으로 전송되었습니다.')
        print(f'백업 상태: {"성공" if backup_result["success"] else "실패"}')
    else:
        print('메일 전송에 실패했습니다.')
