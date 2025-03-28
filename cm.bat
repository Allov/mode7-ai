@echo off
echo Running code checks...
call check.bat
if %ERRORLEVEL% NEQ 0 (
    echo Aborting commit due to code issues.
    exit /b 1
)

echo Running tests...
call test.bat
if %ERRORLEVEL% NEQ 0 (
    echo Aborting commit due to test failures.
    exit /b 1
)

echo All checks passed! Proceeding with commit...
git add .
git commit
