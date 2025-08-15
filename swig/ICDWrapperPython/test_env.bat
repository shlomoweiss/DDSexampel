@echo off
REM Script to test ICDWrapper Python bindings with proper environment setup

echo Setting up environment...
set PATH=%PATH%;C:\fastdds 3.2.2\bin\x64Win64VS2019;C:\cpp-prj\DDSexampel\DDSmessage\build\Release

echo Current directory: %CD%
echo.

echo Testing import...
python test_import.py

pause
