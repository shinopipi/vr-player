@echo off
rem ==== One-click setup for the VR player home streaming (Windows) ====
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
set "TS=C:\Program Files\Tailscale\tailscale.exe"
set "DEST=C:\vr-player"

echo.
echo [1/4] Installing Tailscale (skipped if already installed)...
if not exist "%TS%" (
  winget install --id Tailscale.Tailscale -e --accept-package-agreements --accept-source-agreements
)
if not exist "%TS%" (
  echo [ERROR] Tailscale could not be installed. Please install it from https://tailscale.com/download and run this again.
  pause
  exit /b 1
)

echo.
echo [2/4] Downloading the VR player to %DEST% ...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $z=Join-Path $env:TEMP 'vr-player.zip'; $x=Join-Path $env:TEMP 'vr-player-unzip'; Invoke-WebRequest 'https://github.com/shinopipi/vr-player/archive/refs/heads/main.zip' -OutFile $z; if(Test-Path $x){Remove-Item $x -Recurse -Force}; Expand-Archive $z $x -Force; New-Item -ItemType Directory -Force '%DEST%' | Out-Null; Copy-Item (Join-Path $x 'vr-player-main\*') '%DEST%' -Recurse -Force"
if not exist "%DEST%\start-vr.bat" (
  echo [ERROR] Download failed. Check the internet connection and run this again.
  pause
  exit /b 1
)

echo.
echo [3/4] Creating the video folder: %USERPROFILE%\Videos\vr_r
if not exist "%USERPROFILE%\Videos\vr_r" mkdir "%USERPROFILE%\Videos\vr_r"

echo.
echo [4/4] Tailscale sign-in. If a browser opens, sign in with the SAME account as your iPhone.
"%TS%" up
echo.
call "%DEST%\start-vr.bat"
