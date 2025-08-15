@echo off
echo Setting up DDS Node.js addon environment...

REM Add FastDDS DLLs to PATH
set "PATH=%PATH%;C:\fastdds 3.2.2\bin\x64Win64VS2019"

REM Add DDS facade DLL to PATH
set "PATH=%PATH%;C:\cpp-prj\DDSexampel\DDSmessage\build\Release"

echo Environment setup complete!
echo You can now run:
echo   node examples/test.js       - Run comprehensive test
echo   node examples/publisher.js  - Run publisher example
echo   node examples/subscriber.js - Run subscriber example
echo.
