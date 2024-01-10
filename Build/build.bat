@echo off
pushd ..\Src\ConsoleApplication1

set VSPROG="%VS80COMNTOOLS%\..\..\Common7\IDE\devenv.exe"
%VSPROG% "ConsoleApplication1.sln" /rebuild release

popd