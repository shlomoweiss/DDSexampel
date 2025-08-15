@echo off
REM Build script for Python bindings

echo Generating SWIG wrapper...
swig -python -c++ -I../../DDSmessage -o ICD_wrap.cxx ../ICD.i

if errorlevel 1 (
    echo SWIG generation failed!
    pause
    exit /b 1
)

echo Building Python extension...
python setup.py build_ext --inplace

if errorlevel 1 (
    echo Python build failed!
    pause
    exit /b 1
)

echo Build completed successfully!
echo Files generated:
echo - ICD_wrap.cxx
echo - ICDWrapper.py  
echo - _ICDWrapper.pyd

pause
