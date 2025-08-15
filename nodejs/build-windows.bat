@echo off
REM Build script for DDS Node.js addon on Windows

echo Building DDS Node.js addon for Windows...
cd /d "%~dp0"

REM Check if DDS library exists
if not exist "..\DDSmessage\build\Release\ICD.lib" (
    echo Error: DDS library not found at ..\DDSmessage\build\Release\ICD.lib
    echo Please build the DDS library first using Visual Studio:
    echo   1. Open DDSmessage\build\icd_library.sln
    echo   2. Build in Release configuration
    exit /b 1
)

REM Install dependencies and build
echo Installing Node.js dependencies...
npm install

if %errorlevel% neq 0 (
    echo Build failed!
    exit /b 1
)

echo Build successful!
echo.
echo To run examples:
echo   setup-env.bat
echo   node examples\test.js
echo   node examples\test-domain.js
