@echo off
chcp 65001 > nul
echo ========================================
echo   ELC E2E 통합 테스트
echo ========================================
echo.

cd /d "%~dp0.."
python test/test_e2e_evaluation.py --type=elc %*

echo.
echo 테스트 완료. 아무 키나 누르면 종료합니다...
pause > nul
