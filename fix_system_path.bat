@echo off
setlocal enabledelayedexpansion

echo ================================
echo System PATH Recovery Tool
echo ================================
echo.

:: Check if running as administrator
echo Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] This script requires administrator privileges!
    echo Please right-click and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo [OK] Administrator privileges detected
echo.

:: Backup current PATH (even if corrupted)
echo Creating backup of current system PATH...
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do (
    set "BACKUP_PATH=%%b"
)
echo Current PATH (backup): !BACKUP_PATH!
echo.

:: Set default system PATH
echo Restoring default system PATH...
set "DEFAULT_PATH=C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH\"

:: Add common program directories if they exist
if exist "C:\Program Files\dotnet\" (
    set "DEFAULT_PATH=!DEFAULT_PATH!;C:\Program Files\dotnet\"
)
if exist "C:\Program Files\Git\cmd\" (
    set "DEFAULT_PATH=!DEFAULT_PATH!;C:\Program Files\Git\cmd"
)
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\" (
    set "DEFAULT_PATH=!DEFAULT_PATH!;C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\"
)

echo New system PATH will be:
echo !DEFAULT_PATH!
echo.

:: Confirm with user
set /p "CONFIRM=Do you want to proceed? (Y/N): "
if /i "!CONFIRM!" neq "Y" (
    echo Operation cancelled by user.
    pause
    exit /b 0
)

:: Apply the fix
echo Applying system PATH fix...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!DEFAULT_PATH!" /f
if !errorLevel! == 0 (
    echo [SUCCESS] System PATH has been restored!
    echo.
    echo IMPORTANT: You need to restart your computer or log out and log back in
    echo for the changes to take effect system-wide.
    echo.
    
    :: Broadcast environment change
    echo Notifying system of environment variable changes...
    powershell -Command "& {[System.Environment]::SetEnvironmentVariable('PATH', [System.Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Process')}" 2>nul
    if !errorLevel! == 0 (
        echo [OK] Environment change notification sent
    )
) else (
    echo [ERROR] Failed to restore system PATH
    echo Please check system permissions and try again
)

echo.
echo ================================
echo Recovery Complete
echo ================================
echo.
echo Press any key to exit...
pause >nul