@echo off
chcp 65001 > nul
echo ========================================
echo   전체 E2E 통합 테스트 (ITGC + ELC + TLC)
echo ========================================
echo.

cd /d "%~dp0.."
python test/test_e2e_evaluation.py --type=all %*

echo.
echo 테스트 완료. 아무 키나 누르면 종료합니다...
pause > nul
