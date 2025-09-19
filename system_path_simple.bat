@echo off
echo ================================
echo System PATH Manager (Simple)
echo ================================
echo.

:: Check admin privileges first
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Administrator privileges required!
    echo.
    echo Please do the following:
    echo 1. Right-click this script: %~nx0
    echo 2. Select "Run as administrator"
    echo 3. Click "Yes" in UAC prompt
    echo.
    echo Script will now exit...
    pause
    exit /b 1
)

echo [OK] Administrator privileges confirmed
echo.

:menu
echo ================================
echo Main Menu
echo ================================
echo.
echo [1] Add directory to SYSTEM PATH
echo [2] Remove directory from SYSTEM PATH  
echo [3] View current SYSTEM PATH
echo [Q] Quit
echo.
set /p "choice=Enter choice: "

if /i "%choice%"=="Q" goto :quit
if "%choice%"=="1" goto :add_path
if "%choice%"=="2" goto :remove_path
if "%choice%"=="3" goto :show_path

echo Invalid choice. Please try again.
goto :menu

:show_path
echo.
echo Current SYSTEM PATH:
echo ================================
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do (
    echo %%b
)
echo.
pause
goto :menu

:add_path
echo.
echo Add Directory to SYSTEM PATH
echo ================================
echo.
set /p "new_path=Enter directory path (or drag folder here): "
set "new_path=%new_path:"=%"

if not exist "%new_path%" (
    echo [ERROR] Directory does not exist: %new_path%
    pause
    goto :menu
)

if not exist "%new_path%\*" (
    echo [ERROR] Not a directory: %new_path%
    pause
    goto :menu
)

echo.
echo Will add: %new_path%
echo To: SYSTEM PATH (affects all users)
echo.
set /p "confirm=Continue? (Y/N): "
if /i "%confirm%" neq "Y" goto :menu

:: Get current PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do (
    set "current_path=%%b"
)

:: Check if already exists
echo %current_path% | findstr /i /c:"%new_path%" >nul
if %errorLevel% == 0 (
    echo [INFO] Path already exists in SYSTEM PATH
    pause
    goto :menu
)

:: Add to PATH
set "updated_path=%current_path%;%new_path%"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "%updated_path%" /f

if %errorLevel% == 0 (
    echo [SUCCESS] Path added to SYSTEM PATH
    echo.
    echo IMPORTANT: Changes take effect after:
    echo - Restarting command prompt
    echo - Logging out and back in
    echo - Rebooting computer
) else (
    echo [ERROR] Failed to update SYSTEM PATH
)

pause
goto :menu

:remove_path
echo.
echo Remove Directory from SYSTEM PATH
echo ================================
echo.
set /p "remove_path=Enter directory path to remove: "
set "remove_path=%remove_path:"=%"

:: Get current PATH
for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do (
    set "current_path=%%b"
)

:: Check if exists
echo %current_path% | findstr /i /c:"%remove_path%" >nul
if %errorLevel% neq 0 (
    echo [INFO] Path not found in SYSTEM PATH
    pause
    goto :menu
)

echo.
echo Will remove: %remove_path%
echo From: SYSTEM PATH (affects all users)
echo.
set /p "confirm=Continue? (Y/N): "
if /i "%confirm%" neq "Y" goto :menu

:: Remove from PATH by rebuilding it
setlocal enabledelayedexpansion
set "new_path="
for %%i in ("%current_path:;=" "%") do (
    set "item=%%~i"
    set "item=!item:"=!"
    if /i "!item!" neq "%remove_path%" (
        if "!item!" neq "" (
            if defined new_path (
                set "new_path=!new_path!;!item!"
            ) else (
                set "new_path=!item!"
            )
        )
    )
)

reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!new_path!" /f

if !errorLevel! == 0 (
    echo [SUCCESS] Path removed from SYSTEM PATH
    echo.
    echo IMPORTANT: Changes take effect after:
    echo - Restarting command prompt
    echo - Logging out and back in
    echo - Rebooting computer
) else (
    echo [ERROR] Failed to update SYSTEM PATH
)

endlocal
pause
goto :menu

:quit
echo.
echo Thank you for using System PATH Manager!
echo.
pause
exit /b 0