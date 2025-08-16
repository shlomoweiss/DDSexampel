@echo off
REM Build script for DDS Node.js addon on Windows

echo Building DDS Node.js addon for Windows...
cd /d "%~dp0\.."

REM Install dependencies and build (this will also build the DDS library)
echo Installing Node.js dependencies...
npm install

if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)

echo Build successful!
echo.
echo To run examples:
echo   scripts\setup-env.bat
echo   node examples\test.js
echo   node examples\test-domain.js
