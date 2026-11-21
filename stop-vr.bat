@echo off
rem ---- needs Administrator: re-launch itself elevated if not ----
net session >nul 2>&1
if %errorlevel% neq 0 (
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)
"C:\Program Files\Tailscale\tailscale.exe" serve reset
echo VR player stopped.
pause
