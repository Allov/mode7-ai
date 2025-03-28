@echo off
echo Running Luacheck...
echo.

:: Run luacheck and store its output and exit code
set "temp_file=%TEMP%\luacheck_output.txt"
vendor\luacheck.exe main.lua src --config .luacheckrc > "%temp_file%" 2>&1
set LUACHECK_EXIT=%ERRORLEVEL%

:: Display the stored output
type "%temp_file%"
del "%temp_file%"

:: Display final status at the bottom
echo.
if %LUACHECK_EXIT% EQU 0 (
    echo ===============================
    echo No issues found!
    echo ===============================
    exit /b 0
) else (
    echo ===============================
    echo Issues found. Please review the output above.
    echo ===============================
    exit /b 1
)
