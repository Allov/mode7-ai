@echo off
echo Running LÖVE tests...
lovec . test %* 2>NUL
if %ERRORLEVEL% NEQ 0 (
    echo Tests failed!
    exit /b 1
)
echo All tests passed!
exit /b 0
