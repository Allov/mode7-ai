@echo off
echo Running tests before launch...
call test.bat
if %ERRORLEVEL% NEQ 0 (
    echo Aborting launch due to test failures.
    pause
    exit /b 1
)

echo Tests passed! Launching game...
call st.bat %*