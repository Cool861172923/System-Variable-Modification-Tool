@echo off
setlocal enabledelayedexpansion

:: 获取当前脚本所在的目录
set "CURRENT_DIR=%~dp0"
:: 移除末尾的反斜杠
set "CURRENT_DIR=%CURRENT_DIR:~0,-1%"

echo ================================
echo PATH环境变量添加工具
echo ================================
echo 当前目录: %CURRENT_DIR%
echo.

:: 检查是否以管理员身份运行
echo 正在检查管理员权限...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [√] 检测到管理员权限，将添加到系统环境变量
    set "TARGET=SYSTEM"
) else (
    echo [i] 未检测到管理员权限，将添加到用户环境变量
    set "TARGET=USER"
)

echo.

:: 获取当前PATH环境变量
echo 正在读取当前PATH环境变量...
if "%TARGET%"=="SYSTEM" (
    echo 从系统注册表读取PATH...
    for /f "tokens=2*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
) else (
    echo 从用户注册表读取PATH...
    for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
)

if not defined CURRENT_PATH (
    echo [!] 警告：未找到现有PATH变量，将创建新的PATH
) else (
    echo [√] 成功读取到PATH变量
)

:: 如果PATH不存在，创建一个空的
if not defined CURRENT_PATH set "CURRENT_PATH="

:: 检查路径是否已经存在
echo 正在检查路径是否已存在...
echo %CURRENT_PATH% | findstr /i /c:"%CURRENT_DIR%" >nul
if %errorLevel% == 0 (
    echo [!] 路径 "%CURRENT_DIR%" 已经存在于PATH环境变量中
    echo 无需重复添加。
    echo.
    goto :end
) else (
    echo [√] 路径不存在，可以添加
)

:: 添加路径到PATH
echo 正在构建新的PATH变量...
if defined CURRENT_PATH (
    set "NEW_PATH=%CURRENT_PATH%;%CURRENT_DIR%"
    echo [√] 将在现有PATH后追加新路径
) else (
    set "NEW_PATH=%CURRENT_DIR%"
    echo [√] 创建新的PATH变量
)

:: 更新注册表
echo 正在更新注册表...
if "%TARGET%"=="SYSTEM" (
    echo 尝试写入系统环境变量...
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f
    if !errorLevel! == 0 (
        echo [√] 成功将 "%CURRENT_DIR%" 添加到系统PATH环境变量
    ) else (
        echo [×] 添加到系统PATH失败 (错误代码: !errorLevel!)
        echo 请确保以管理员身份运行此脚本
        goto :error
    )
) else (
    echo 尝试写入用户环境变量...
    reg add "HKCU\Environment" /v PATH /t REG_EXPAND_SZ /d "!NEW_PATH!" /f
    if !errorLevel! == 0 (
        echo [√] 成功将 "%CURRENT_DIR%" 添加到用户PATH环境变量
    ) else (
        echo [×] 添加到用户PATH失败 (错误代码: !errorLevel!)
        goto :error
    )
)

echo.
echo ================================
echo 操作完成！
echo ================================
echo [i] 注意：环境变量更改可能需要：
echo     - 重启命令提示符/PowerShell
echo     - 重新登录Windows用户
echo     - 或运行 refreshenv 命令
echo.

:: 广播环境变量更改消息
echo 正在通知系统环境变量已更改...
powershell -Command "& {[System.Environment]::SetEnvironmentVariable('PATH', [System.Environment]::GetEnvironmentVariable('PATH', 'Machine'), 'Process')}" 2>nul
if !errorLevel! == 0 (
    echo [√] 环境变量更改通知已发送
) else (
    echo [!] 环境变量更改通知发送失败，但PATH已成功添加
)

echo.
echo [√] 路径添加完成！
echo 您现在可以使用来自以下位置的程序: %CURRENT_DIR%
echo.
echo 要验证，请打开新的命令提示符并输入：
echo   echo %%PATH%%
echo.
goto :end

:error
echo.
echo ================================
echo 操作失败
echo ================================
echo 请检查以下可能的原因：
echo 1. 权限不足（尝试以管理员身份运行）
echo 2. 注册表访问被阻止
echo 3. 系统安全策略限制
echo.
goto :end

:end
echo.
echo 按任意键退出...
pause >nul