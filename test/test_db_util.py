import sqlite3
import os
import sys
from pathlib import Path

# 프로젝트 루트 경로
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

from db_config import SQLITE_DATABASE

def create_test_db(db_path):
    """테스트용 데이터베이스 생성 및 초기 데이터 적재"""
    print(f"🛠️ 테스트용 DB 생성: {db_path}")
    
    # 기존 DB 파일 삭제
    if os.path.exists(db_path):
        os.remove(db_path)
    
    # 원본 DB에서 스키마 복사 (또는 migrate.py 실행 가능)
    # 여기서는 간단하게 원본 파일을 복사함 (또는 새로 생성)
    if os.path.exists(SQLITE_DATABASE):
        import shutil
        shutil.copy2(SQLITE_DATABASE, db_path)
    else:
        # DB가 없으면 migrate.py를 실행해야 함
        print("⚠️ 원본 DB가 없어 migrate.py를 실행합니다.")
        os.environ['SQLITE_DB_PATH'] = db_path
        import subprocess
        subprocess.run([sys.executable, str(project_root / "migrate.py"), "upgrade"], check=True)

    # 테스트 유저 추가
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # 1. 일반 사용자 (admin_flag = 'N')
    cursor.execute('''
        INSERT INTO sb_user (user_email, user_name, company_name, admin_flag, effective_start_date)
        VALUES (?, ?, ?, ?, ?)
    ''', ('user@test.com', '일반사용자', '테스트컴퍼니', 'N', '2000-01-01 00:00:00'))
    
    # 2. 관리자 (admin_flag = 'Y')
    # 관리자는 이미 DB에 있을 수 있으므로 확인 후 추가
    cursor.execute("SELECT user_id FROM sb_user WHERE user_email = 'admin@test.com'")
    if not cursor.fetchone():
        cursor.execute('''
            INSERT INTO sb_user (user_email, user_name, company_name, admin_flag, effective_start_date)
            VALUES (?, ?, ?, ?, ?)
        ''', ('admin@test.com', '관리자', '테스트컴퍼니', 'Y', '2000-01-01 00:00:00'))
    
    # OTP 코드 고정 (테스트 용)
    cursor.execute("UPDATE sb_user SET otp_code = '123456', otp_expires_at = '2099-12-31 23:59:59'")
    
    conn.commit()
    conn.close()
    print("✅ 테스트 데이터 적재 완료 (user@test.com, admin@test.com)")

if __name__ == "__main__":
    test_db = os.path.join(project_root, 'test_snowball.db')
    create_test_db(test_db)
