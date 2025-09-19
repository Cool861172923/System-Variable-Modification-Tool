@echo off
setlocal enabledelayedexpansion

:: Get current script directory
set "CURRENT_DIR=%~dp0"
:: Remove trailing backslash
set "CURRENT_DIR=%CURRENT_DIR:~0,-1%"

echo ================================
echo PATH Environment Variable Removal Tool
echo ================================
echo Current directory: %CURRENT_DIR%
echo.

:: Check if running as administrator
echo Checking administrator privileges...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Administrator privileges detected
    set "CHECK_SYSTEM=1"
    set "CHECK_USER=1"
) else (
    echo [INFO] No administrator privileges detected
    set "CHECK_SYSTEM=0"
    set "CHECK_USER=1"
)

echo.

set "FOUND=0"
set "SUCCESS_COUNT=0"

:: Process system environment variables
if "%CHECK_SYSTEM%"=="1" (
    echo Checking system environment variables...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do (
        set "SYSTEM_PATH=%%b"
        echo !SYSTEM_PATH! | findstr /i /c:"%CURRENT_DIR%" >nul
        if !errorLevel! == 0 (
            echo [FOUND] Path found in system PATH
            call :RemoveFromPath "!SYSTEM_PATH!" "%CURRENT_DIR%" SYSTEM_NEW_PATH
            echo Updating system registry...
            reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!SYSTEM_NEW_PATH!" /f
            if !errorLevel! == 0 (
                echo [OK] Successfully removed from system PATH
                set "FOUND=1"
                set /a SUCCESS_COUNT+=1
            ) else (
                echo [ERROR] Failed to remove from system PATH
            )
        ) else (
            echo [INFO] Path not found in system PATH
        )
    )
    echo.
)

:: Process user environment variables
if "%CHECK_USER%"=="1" (
    echo Checking user environment variables...
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do (
        set "USER_PATH=%%b"
        echo !USER_PATH! | findstr /i /c:"%CURRENT_DIR%" >nul
        if !errorLevel! == 0 (
            echo [FOUND] Path found in user PATH
            call :RemoveFromPath "!USER_PATH!" "%CURRENT_DIR%" USER_NEW_PATH
            echo Updating user registry...
            reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "!USER_NEW_PATH!" /f
            if !errorLevel! == 0 (
                echo [OK] Successfully removed from user PATH
                set "FOUND=1"
                set /a SUCCESS_COUNT+=1
            ) else (
                echo [ERROR] Failed to remove from user PATH
            )
        ) else (
            echo [INFO] Path not found in user PATH
        )
    )
)

echo.
echo ================================

if "%FOUND%"=="0" (
    echo No Action Required
    echo ================================
    echo [INFO] Path "%CURRENT_DIR%" was not found in any PATH environment variables
    echo Nothing to remove.
    goto :end
)

if !SUCCESS_COUNT! gtr 0 (
    echo Operation Completed Successfully!
    echo ================================
    echo [SUCCESS] Removed "%CURRENT_DIR%" from !SUCCESS_COUNT! location^(s^)
    echo.
    echo [INFO] Note: Environment variable changes may require:
    echo     - Restart command prompt/PowerShell
    echo     - Re-login to Windows user
    echo     - Or run refreshenv command
    echo.
    
    :: Broadcast environment variable change message
    echo Notifying system of environment variable changes...
    powershell -Command "& {[System.Environment]::SetEnvironmentVariable('PATH', [System.Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Process')}" 2>nul
    if !errorLevel! == 0 (
        echo [OK] Environment variable change notification sent
    ) else (
        echo [WARNING] Notification failed, but PATH was successfully updated
    )
    
    echo.
    echo To verify removal, open a new command prompt and type:
    echo   echo %%PATH%%
) else (
    echo Operation Failed
    echo ================================
    echo [ERROR] Path was found but could not be removed
    echo Please check:
    echo 1. Administrator privileges ^(for system PATH^)
    echo 2. Registry access permissions
    echo 3. Antivirus software blocking registry modifications
)

:end
echo.
echo Press any key to exit...
pause >nul
exit /b 0

:: Function: Remove specified path from PATH string
:RemoveFromPath
setlocal enabledelayedexpansion
set "ORIGINAL_PATH=%~1"
set "REMOVE_PATH=%~2"
set "RESULT_VAR=%~3"

:: Initialize result
set "NEW_PATH="

:: Split PATH and reassemble, skipping the path to remove
for %%i in ("%ORIGINAL_PATH:;=" "%") do (
    set "CURRENT_ITEM=%%~i"
    :: Remove quotes
    set "CURRENT_ITEM=!CURRENT_ITEM:"=!"
    
    :: Check if this is the path to remove ^(case insensitive^)
    set "MATCH=0"
    if /i "!CURRENT_ITEM!"=="%REMOVE_PATH%" set "MATCH=1"
    
    :: If no match, add to new PATH
    if "!MATCH!"=="0" (
        if "!CURRENT_ITEM!" neq "" (
            if defined NEW_PATH (
                set "NEW_PATH=!NEW_PATH!;!CURRENT_ITEM!"
            ) else (
                set "NEW_PATH=!CURRENT_ITEM!"
            )
        )
    )
)

:: Return result
endlocal & set "%RESULT_VAR%=%NEW_PATH%"
goto :eof
