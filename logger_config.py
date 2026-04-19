"""
로깅 설정 모듈
- 개발/운영 환경별 로그 레벨 설정
- 파일 및 콘솔 출력
- 로그 로테이션
"""
import logging
import os
from logging.handlers import RotatingFileHandler
from pathlib import Path

def setup_logging():
    """로깅 설정 초기화"""

    # .env에서 로그 레벨 가져오기 (기본값: INFO)
    log_level_str = os.getenv('LOG_LEVEL', 'INFO')
    log_level = getattr(logging, log_level_str.upper(), logging.INFO)

    # 로그 디렉토리 생성
    log_dir = Path(__file__).parent / 'logs'
    log_dir.mkdir(exist_ok=True)

    # 로그 파일 경로
    log_file = log_dir / 'snowball.log'

    # 로그 포맷 설정
    log_format = '%(asctime)s [%(levelname)s] %(name)s:%(funcName)s:%(lineno)d - %(message)s'
    date_format = '%Y-%m-%d %H:%M:%S'

    # 핸들러 설정
    handlers = []

    # 1. 파일 핸들러 (로테이션)
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=10 * 1024 * 1024,  # 10MB
        backupCount=5,  # 최대 5개 파일 보관
        encoding='utf-8'
    )
    file_handler.setLevel(log_level)
    file_handler.setFormatter(logging.Formatter(log_format, date_format))
    handlers.append(file_handler)

    # 2. 콘솔 핸들러 (개발 환경에서만)
    if os.getenv('FLASK_ENV') == 'development' or os.getenv('LOG_TO_CONSOLE', 'true').lower() == 'true':
        console_handler = logging.StreamHandler()
        console_handler.setLevel(log_level)
        console_handler.setFormatter(logging.Formatter(log_format, date_format))
        handlers.append(console_handler)

    # 루트 로거 설정
    logging.basicConfig(
        level=log_level,
        format=log_format,
        datefmt=date_format,
        handlers=handlers
    )

    # 애플리케이션 로거 반환
    logger = logging.getLogger('snowball')
    logger.info(f"로깅 시스템 초기화 완료 - 레벨: {log_level_str}")

    return logger


def get_logger(name):
    """모듈별 로거 가져오기"""
    return logging.getLogger(f'snowball.{name}')
