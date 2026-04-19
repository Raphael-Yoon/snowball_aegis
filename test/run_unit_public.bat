@echo off
chcp 65001 > nul
echo ========================================
echo   Public 기능 통합 Unit 테스트
echo ========================================
echo.
echo 로그인 없이 접근 가능한 Public 기능 테스트
echo 대상: Link 1, 2, 3, 4, 9, 10, 11
echo.

cd /d "%~dp0.."

if "%1"=="" (
    python test/test_unit_public.py
) else if "%1"=="--headless" (
    python test/test_unit_public.py --headless
) else (
    python test/test_unit_public.py %*
)

echo.
echo 테스트 완료. 아무 키나 누르면 종료합니다...
pause > nul
