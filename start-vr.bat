@echo off
setlocal
rem ==== VR player: serve this folder and the video folder over Tailscale (https) ====
set "TS=C:\Program Files\Tailscale\tailscale.exe"
set "PLAYER=%~dp0"
if "%PLAYER:~-1%"=="\" set "PLAYER=%PLAYER:~0,-1%"
rem Video folder (change this line if you keep videos somewhere else)
set "VIDEOS=%USERPROFILE%\Videos\vr_r"

if not exist "%TS%" (
  echo [ERROR] Tailscale is not installed. Install it from https://tailscale.com/download
  pause
  exit /b 1
)
if not exist "%VIDEOS%" mkdir "%VIDEOS%"

"%TS%" serve reset
"%TS%" serve --bg --set-path / "%PLAYER%"
"%TS%" serve --bg --set-path /videos "%VIDEOS%"
echo.
echo ===============================================================
echo  Video folder: %VIDEOS%
echo  Open the https://....ts.net/ address below in Safari on iPhone
echo ===============================================================
"%TS%" serve status
echo.
pause
