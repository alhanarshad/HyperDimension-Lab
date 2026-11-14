@echo off
setlocal
powershell.exe -NoLogo -NoProfile -File "%~dp0Start-4D.ps1"
if errorlevel 1 pause
endlocal
