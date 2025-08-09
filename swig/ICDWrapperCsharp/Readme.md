 # 1. generate code
swig -c++ -csharp -I"../DDSmessage" ICD.i

# 2.move the cxx file to ICDWrapperCpp
Move-Item ICD_wrap.cxx ICDWrapperCpp

# 3.move the cs file to ICDWrapperSharp
Move-Item *.cs ICDWrapperCSharp

# 4. build ICDWrapper
cd ICDWrapperCpp
mkdir build
cd build
cmake ..
cmake --build . --config Release

# 5. build ICDWrapperSharp
dotnet new classlib -n ICDWrapperSharp -o .
Remove-Item .\Class1.cs -ErrorAction SilentlyContinue
Get-ChildItem -Filter *.cs | ForEach-Object { dotnet add ICDWrapperSharp.csproj reference $_.Name }
dotnet build -c Release