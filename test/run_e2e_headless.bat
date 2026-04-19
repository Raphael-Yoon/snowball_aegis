@echo off
chcp 65001 > nul
echo ========================================
echo   E2E 통합 테스트 (Headless 모드)
echo ========================================
echo.
echo 사용법: run_e2e_headless.bat [itgc^|elc^|tlc^|all]
echo.

set TYPE=%1
if "%TYPE%"=="" set TYPE=itgc

cd /d "%~dp0.."
python test/test_e2e_evaluation.py --type=%TYPE% --headless

echo.
echo 테스트 완료. 아무 키나 누르면 종료합니다...
pause > nul
