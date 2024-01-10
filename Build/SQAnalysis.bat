@echo off
set XXUnzipApp="%CD%\7z_x86.exe"
set XXBuildVersion=1.0.0

REM download build-wrapper and sonar-scanner
echo.
echo -download build-wrapper
curl -SL --output %USERPROFILE%\build-wrapper-win-x86.zip https://sonarqube.syntecclub.com/static/cpp/build-wrapper-win-x86.zip
echo -download sonar-scanner
curl -SL --output %USERPROFILE%\sonar-scanner-cli-4.8.0.2856-windows.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-4.8.0.2856-windows.zip

REM extract zip
echo.
echo -extract build-wrapper
%XXUnzipApp% x -y -o"%USERPROFILE%\" "%USERPROFILE%\build-wrapper-win-x86.zip"
echo -extract sonar-scanner
%XXUnzipApp% x -y -o"%USERPROFILE%\" "%USERPROFILE%\sonar-scanner-cli-4.8.0.2856-windows.zip"

REM add to PATH
echo.
echo -add build-wrapper file path into environment variable
set PATH=%PATH%;%USERPROFILE%\build-wrapper-win-x86
echo -add sonar-scanner file path into environment variable
set PATH=%PATH%;%USERPROFILE%\sonar-scanner-4.8.0.2856-windows\bin

REM define New Code
rem master/main branch
if %CI_COMMIT_BRANCH% == %CI_DEFAULT_BRANCH% (
    set newcode="sonar.projectVersion=%XXBuildVersion%"
    goto sonar
)
rem release beanch
echo %CI_COMMIT_BRANCH%|findstr /r "^release_">nul
if %Errorlevel% EQU 0 ( 
	set newcode="sonar.projectVersion=%XXBuildVersion%"
	goto sonar
)
rem feature/bug branch
set newcode="sonar.newCode.referenceBranch=%NewCodeRefBranch%"
goto sonar

:sonar
REM start to build
echo.
echo ==== SonarQube build ====
build-wrapper-win-x86-64 --out-dir .\SonarQube build.bat

REM start to scan
echo.
echo ==== SonarQube scan ====
pushd ..
cmd /c sonar-scanner -D"sonar.cfamily.build-wrapper-output=Build\SonarQube" -D"sonar.host.url=%SONAR_HOST_URL%" -D"sonar.login=%SONAR_TOKEN%" -D%newcode%
if %Errorlevel% NEQ 0 exit 1
popd

REM clean up
echo.
echo -clean up
del /q /f %USERPROFILE%\build-wrapper-win-x86.zip
del /q /f %USERPROFILE%\sonar-scanner-cli-4.8.0.2856-windows.zip
rd /q /s %USERPROFILE%\build-wrapper-win-x86
rd /q /s %USERPROFILE%\sonar-scanner-4.8.0.2856-windows

REM check scan status
echo.
echo -check scan status
setlocal enabledelayedexpansion
for /f "tokens=*" %%i in ('findstr "ceTaskUrl" ..\.scannerwork\report-task.txt') do set TASK_URL=%%i
set TASK_URL=!TASK_URL:~10!
curl -u %SONAR_TOKEN%: %TASK_URL% 2>&1 | findstr "SUCCESS" >nul
if %Errorlevel% EQU 0 (
	set STATUS=SUCCESS
	echo Scan Status : !STATUS!
) else (
	set STATUS=FAILED
	echo Scan Status : !STATUS!
	exit 1
)
