import os
import pickle
from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from datetime import datetime
import io
from googleapiclient.http import MediaIoBaseUpload

# Google Drive & Docs API 인증


def get_drive_credentials():
    """Google Drive & Sheets API 인증 토큰 획득"""
    SCOPES = [
        'https://www.googleapis.com/auth/drive',  # 드라이브 전체 접근 권한 (기존 폴더 인식용)
        'https://www.googleapis.com/auth/spreadsheets'  # Google Sheets 편집
    ]
    creds = None

    # token_drive.pickle 파일에서 토큰 로드
    if os.path.exists('token_drive.pickle'):
        with open('token_drive.pickle', 'rb') as token:
            creds = pickle.load(token)

    # 토큰이 없거나 유효하지 않으면 새로 생성
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            flow = InstalledAppFlow.from_client_secrets_file('credentials.json', SCOPES)
            creds = flow.run_local_server(port=0)

        # 토큰 저장
        with open('token_drive.pickle', 'wb') as token:
            pickle.dump(creds, token)

    return creds


def create_or_get_folder(service, folder_name, parent_id=None):
    """특정 폴더 찾기 또는 생성"""
    # 폴더 검색 쿼리
    query = f"name='{folder_name}' and mimeType='application/vnd.google-apps.folder' and trashed=false"
    if parent_id:
        query += f" and '{parent_id}' in parents"

    results = service.files().list(
        q=query,
        spaces='drive',
        fields='files(id, name)'
    ).execute()

    items = results.get('files', [])

    if items:
        # 폴더가 이미 존재하면 해당 폴더 ID 반환
        return items[0]['id']
    else:
        # 폴더가 없으면 생성
        file_metadata = {
            'name': folder_name,
            'mimeType': 'application/vnd.google-apps.folder'
        }
        if parent_id:
            file_metadata['parents'] = [parent_id]

        folder = service.files().create(
            body=file_metadata,
            fields='id'
        ).execute()

        return folder.get('id')


def append_to_work_log(log_entry, user_name='', user_email='', log_date=None):
    """
    Google Sheets의 work_log 스프레드시트에 작업 내용 추가

    Args:
        log_entry (str): 추가할 작업 로그 내용
        user_name (str): 사용 안 함 (하위 호환성 유지)
        user_email (str): 사용 안 함 (하위 호환성 유지)
        log_date (str, optional): 작업 날짜 (YYYY-MM-DD). None이면 현재 날짜 사용.

    Returns:
        dict: 성공 여부와 메시지
    """
    try:
        creds = get_drive_credentials()
        drive_service = build('drive', 'v3', credentials=creds)
        sheets_service = build('sheets', 'v4', credentials=creds)

        # Pythons 폴더 찾기 또는 생성
        pythons_folder_id = create_or_get_folder(drive_service, 'Pythons')

        # Pythons 안에 Snowball 폴더 찾기 또는 생성
        folder_id = create_or_get_folder(drive_service, 'Snowball', pythons_folder_id)

        # work_log Google Sheets 문서 찾기
        query = f"name='work_log' and mimeType='application/vnd.google-apps.spreadsheet' and '{folder_id}' in parents and trashed=false"
        results = drive_service.files().list(
            q=query,
            spaces='drive',
            fields='files(id, name)'
        ).execute()

        items = results.get('files', [])

        # 날짜 설정
        if log_date:
            date_only = log_date
        else:
            date_only = datetime.now().strftime('%Y-%m-%d')

        # 새 행 데이터 (날짜, 작업 내용만)
        new_row = [date_only, log_entry]

        if items:
            # 스프레드시트가 이미 존재하면 행 추가
            spreadsheet_id = items[0]['id']

            # 새 행을 맨 위에 추가 (헤더 아래)
            body = {
                'values': [new_row]
            }

            sheets_service.spreadsheets().values().append(
                spreadsheetId=spreadsheet_id,
                range='Sheet1!A2',  # 헤더 다음 행부터
                valueInputOption='USER_ENTERED',
                insertDataOption='INSERT_ROWS',
                body=body
            ).execute()

            # 스프레드시트 URL 생성
            sheet_url = f'https://docs.google.com/spreadsheets/d/{spreadsheet_id}/edit'

            return {
                'success': True,
                'message': f'작업 로그가 Google Sheets에 추가되었습니다.',
                'spreadsheet_id': spreadsheet_id,
                'url': sheet_url
            }
        else:
            # 스프레드시트가 없으면 새로 생성
            spreadsheet = {
                'properties': {
                    'title': 'work_log'
                },
                'sheets': [{
                    'properties': {
                        'title': 'Sheet1',
                        'gridProperties': {
                            'frozenRowCount': 1  # 헤더 행 고정
                        }
                    }
                }]
            }

            spreadsheet_response = sheets_service.spreadsheets().create(
                body=spreadsheet
            ).execute()
            spreadsheet_id = spreadsheet_response.get('spreadsheetId')
            # 첫 번째 시트의 ID 가져오기
            sheet_id = spreadsheet_response['sheets'][0]['properties']['sheetId']

            # 생성된 스프레드시트를 폴더로 이동
            drive_service.files().update(
                fileId=spreadsheet_id,
                addParents=folder_id,
                fields='id, parents'
            ).execute()

            # 헤더 행 추가
            header = [['날짜', '작업 내용']]
            sheets_service.spreadsheets().values().update(
                spreadsheetId=spreadsheet_id,
                range='Sheet1!A1',
                valueInputOption='USER_ENTERED',
                body={'values': header}
            ).execute()

            # 헤더 서식 설정 (굵게, 배경색)
            requests = [
                {
                    'repeatCell': {
                        'range': {
                            'sheetId': sheet_id,
                            'startRowIndex': 0,
                            'endRowIndex': 1
                        },
                        'cell': {
                            'userEnteredFormat': {
                                'backgroundColor': {
                                    'red': 0.9,
                                    'green': 0.9,
                                    'blue': 0.9
                                },
                                'textFormat': {
                                    'bold': True
                                }
                            }
                        },
                        'fields': 'userEnteredFormat(backgroundColor,textFormat)'
                    }
                },
                # 열 너비 자동 조정
                {
                    'autoResizeDimensions': {
                        'dimensions': {
                            'sheetId': sheet_id,
                            'dimension': 'COLUMNS',
                            'startIndex': 0,
                            'endIndex': 2
                        }
                    }
                }
            ]

            sheets_service.spreadsheets().batchUpdate(
                spreadsheetId=spreadsheet_id,
                body={'requests': requests}
            ).execute()

            # 첫 번째 데이터 행 추가
            body = {
                'values': [new_row]
            }

            sheets_service.spreadsheets().values().append(
                spreadsheetId=spreadsheet_id,
                range='Sheet1!A2',
                valueInputOption='USER_ENTERED',
                body=body
            ).execute()

            # 스프레드시트 URL 생성
            sheet_url = f'https://docs.google.com/spreadsheets/d/{spreadsheet_id}/edit'

            return {
                'success': True,
                'message': f'새로운 작업 로그 스프레드시트가 생성되었습니다.',
                'spreadsheet_id': spreadsheet_id,
                'url': sheet_url
            }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'message': f'작업 로그 저장 중 오류가 발생했습니다: {str(e)}'
        }


def append_to_work_log_docs(log_entry, log_date=None):
    """
    Google Docs의 work_log 문서에 작업 내용 추가

    Args:
        log_entry (str): 추가할 작업 로그 내용
        log_date (str, optional): 작업 날짜 (YYYY-MM-DD). None이면 현재 날짜 사용.

    Returns:
        dict: 성공 여부와 메시지
    """
    try:
        creds = get_drive_credentials()
        drive_service = build('drive', 'v3', credentials=creds)
        docs_service = build('docs', 'v1', credentials=creds)

        # Pythons > Snowball 폴더 찾기
        pythons_folder_id = create_or_get_folder(drive_service, 'Pythons')
        folder_id = create_or_get_folder(drive_service, 'Snowball', pythons_folder_id)

        # work_log Google Docs 문서 찾기
        query = f"name='work_log' and mimeType='application/vnd.google-apps.document' and '{folder_id}' in parents and trashed=false"
        results = drive_service.files().list(
            q=query,
            spaces='drive',
            fields='files(id, name)'
        ).execute()

        items = results.get('files', [])
        
        if items:
            document_id = items[0]['id']
        else:
            # 문서가 없으면 새로 생성
            doc = docs_service.documents().create(body={'title': 'work_log'}).execute()
            document_id = doc.get('documentId')
            
            # 생성된 문서를 폴더로 이동
            drive_service.files().update(
                fileId=document_id,
                addParents=folder_id,
                fields='id, parents'
            ).execute()

        # 날짜 설정
        if log_date:
            date_str = f"\n\n## {log_date}\n"
        else:
            date_str = f"\n\n## {datetime.now().strftime('%Y-%m-%d')}\n"

        # 문서의 끝 위치 확인을 위해 문서 가져오기
        doc = docs_service.documents().get(documentId=document_id).execute()
        # 문서를 맨 위에 추가할지 맨 아래에 추가할지 결정 (여기서는 맨 위에 추가)
        # 실제로는 맨 앞에 추가하는 것이 최신 로그를 보기 편함
        
        requests = [
            {
                'insertText': {
                    'location': {'index': 1},
                    'text': f"{date_str}{log_entry}\n"
                }
            }
        ]

        docs_service.documents().batchUpdate(
            documentId=document_id,
            body={'requests': requests}
        ).execute()

        doc_url = f'https://docs.google.com/document/d/{document_id}/edit'

        return {
            'success': True,
            'message': '작업 로그가 Google Docs에 추가되었습니다.',
            'document_id': document_id,
            'url': doc_url
        }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'message': f'작업 로그(Docs) 저장 중 오류가 발생했습니다: {str(e)}'
        }


def get_work_log():
    """
    Google Sheets의 work_log 스프레드시트 내용 가져오기

    Returns:
        dict: 성공 여부, 메시지, 로그 데이터
    """
    try:
        creds = get_drive_credentials()
        drive_service = build('drive', 'v3', credentials=creds)
        sheets_service = build('sheets', 'v4', credentials=creds)

        # Pythons 폴더 찾기 또는 생성
        pythons_folder_id = create_or_get_folder(drive_service, 'Pythons')

        # Pythons 안에 Snowball 폴더 찾기 또는 생성
        folder_id = create_or_get_folder(drive_service, 'Snowball', pythons_folder_id)

        # work_log Google Sheets 문서 찾기
        query = f"name='work_log' and mimeType='application/vnd.google-apps.spreadsheet' and '{folder_id}' in parents and trashed=false"
        results = drive_service.files().list(
            q=query,
            spaces='drive',
            fields='files(id, name)'
        ).execute()

        items = results.get('files', [])

        if items:
            spreadsheet_id = items[0]['id']

            # 스프레드시트 내용 읽기
            result = sheets_service.spreadsheets().values().get(
                spreadsheetId=spreadsheet_id,
                range='Sheet1!A:B'  # 날짜, 작업 내용 컬럼만
            ).execute()

            values = result.get('values', [])

            # 스프레드시트 URL 생성
            sheet_url = f'https://docs.google.com/spreadsheets/d/{spreadsheet_id}/edit'

            return {
                'success': True,
                'message': '작업 로그를 불러왔습니다.',
                'data': values,
                'spreadsheet_id': spreadsheet_id,
                'url': sheet_url
            }
        else:
            return {
                'success': False,
                'message': '작업 로그 스프레드시트가 존재하지 않습니다.',
                'data': []
            }

    except Exception as e:
        import traceback
        traceback.print_exc()
        return {
            'success': False,
            'message': f'작업 로그 불러오기 중 오류가 발생했습니다: {str(e)}',
            'data': []
        }


# 사용 예시
if __name__ == '__main__':
    # 테스트용 로그 추가
    test_log = """Dashboard 기능 수정
- ELC/TLC 카드에 단계 인디케이터 추가
- 운영평가 상태 로직 개선 (모든 통제 평가 완료 기준)
- 버튼 텍스트와 단계 아이콘 일치하도록 수정"""

    result = append_to_work_log(
        log_entry=test_log,
        user_name='테스트 사용자',
        user_email='test@example.com'
    )
    print(result['message'])
    if result['success']:
        print(f"스프레드시트 URL: {result['url']}")

    # 로그 내용 확인
    log_result = get_work_log()
    if log_result['success']:
        print("\n=== 현재 작업 로그 ===")
        print(f"스프레드시트 URL: {log_result['url']}")
        print(f"총 {len(log_result['data'])}개 행")
        for i, row in enumerate(log_result['data'][:5]):  # 최근 5개만 표시
            print(f"{i}: {row}")
def get_work_log_docs():
    """
    Google Docs의 work_log 문서 정보 가져오기

    Returns:
        dict: 성공 여부, 메시지, 문서 URL
    """
    try:
        creds = get_drive_credentials()
        drive_service = build('drive', 'v3', credentials=creds)

        # Pythons > Snowball 폴더 찾기
        pythons_folder_id = create_or_get_folder(drive_service, 'Pythons')
        folder_id = create_or_get_folder(drive_service, 'Snowball', pythons_folder_id)

        # work_log Google Docs 문서 찾기
        query = f"name='work_log' and mimeType='application/vnd.google-apps.document' and '{folder_id}' in parents and trashed=false"
        results = drive_service.files().list(
            q=query,
            spaces='drive',
            fields='files(id, name)'
        ).execute()

        items = results.get('files', [])
        
        if not items:
            return {
                'success': False,
                'message': '작업 로그 문서를 찾을 수 없습니다.',
                'url': None
            }

        document_id = items[0]['id']
        doc_url = f'https://docs.google.com/document/d/{document_id}/edit'

        return {
            'success': True,
            'message': '작업 로그 문서를 찾았습니다.',
            'url': doc_url,
            'document_id': document_id
        }

    except Exception as e:
        return {
            'success': False,
            'message': f'작업 로그(Docs) 조회 중 오류가 발생했습니다: {str(e)}',
            'url': None
        }
