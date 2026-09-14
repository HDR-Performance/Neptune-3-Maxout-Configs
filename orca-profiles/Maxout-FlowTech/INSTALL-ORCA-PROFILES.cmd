@echo off
setlocal
title Install Maxout FlowTech OrcaSlicer Profiles
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Maxout-Orca-Profiles.ps1"
if errorlevel 1 (
  echo.
  echo Installation did not complete. Read the message above, then try again.
)
echo.
pause
