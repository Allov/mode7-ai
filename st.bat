@echo off
echo Running code checks...
call check.bat
if %ERRORLEVEL% NEQ 0 (
    echo Aborting launch due to code issues.
    pause
    exit /b 1
)

echo Checks passed! Launching game...
lovec . %*

