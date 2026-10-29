@echo off
cd /d "%~dp0"
title Project 38 JIT Lab - FREE Entra ID only
echo ============================================================
echo  Project 38 - JIT privileged access (100%% FREE)
echo  Tenant: niazkhanghostgmail.onmicrosoft.com
echo ============================================================
echo.
echo A NEW PowerShell window will open.
echo Sign in in the browser when prompted, then the scripts will run.
echo.
pause
start "JIT Lab" /wait powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0_run_jit_lab.ps1"
if errorlevel 1 (
    echo.
    echo ERROR: Lab script failed. See the PowerShell window for details.
    pause
    exit /b 1
)
echo.
echo Done. Evidence is in the evidence folder.
pause
