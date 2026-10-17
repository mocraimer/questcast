@echo off
rem QuestCast - show a Meta Quest's view in a window over Wi-Fi so OBS can capture it.
rem Usage: questcast.bat [headset-ip]
rem Override any setting below by setting an environment variable first, e.g.
rem   set CROP=1600:900:420:700 & questcast.bat
setlocal

if not defined ADB set "ADB=adb"
if not defined SCRCPY set "SCRCPY=scrcpy"
if not defined PORT set "PORT=5555"
if not defined CROP set "CROP=1600:900:420:700"
if not defined BITRATE set "BITRATE=20M"
if not defined FPS set "FPS=60"
if not defined TITLE set "TITLE=QuestCast"
set "IPFILE=%~dp0questcast.ip"

set "QUEST=%~1"
if not defined QUEST if exist "%IPFILE%" set /p QUEST=<"%IPFILE%"
if not defined QUEST goto usb

call :try_connect
if not errorlevel 1 goto run

:usb
echo Wi-Fi adb is not reachable. Setting it up over USB...
"%ADB%" -d tcpip %PORT% >nul 2>&1
if errorlevel 1 (
  echo No headset found over USB. Plug it in, accept the USB debugging prompt in the headset, and run this again.
  pause
  exit /b 1
)
timeout /t 3 /nobreak >nul
set "QUEST="
"%ADB%" -d shell ip -f inet addr show wlan0 > "%TEMP%\questcast_ip.txt" 2>nul
for /f "tokens=2" %%a in ('findstr /c:"inet " "%TEMP%\questcast_ip.txt"') do for /f "delims=/" %%b in ("%%a") do set "QUEST=%%b"
del "%TEMP%\questcast_ip.txt" >nul 2>&1
if not defined QUEST (
  echo Could not read the headset's Wi-Fi address. Is the headset on Wi-Fi?
  pause
  exit /b 1
)
call :try_connect
if errorlevel 1 (
  echo Could not connect to %QUEST%:%PORT%. Check the headset and PC are on the same network.
  pause
  exit /b 1
)
>"%IPFILE%" echo %QUEST%

:run
echo Casting %QUEST%:%PORT% - close the "%TITLE%" window to stop.
"%SCRCPY%" -s %QUEST%:%PORT% --crop=%CROP% --video-bit-rate=%BITRATE% --max-fps=%FPS% --no-audio --no-control --window-title=%TITLE%
exit /b %errorlevel%

:try_connect
"%ADB%" connect %QUEST%:%PORT% 2>&1 | find "connected to" >nul
exit /b %errorlevel%
