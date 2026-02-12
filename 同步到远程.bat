@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo 同步到远程仓库 - Agent Harness
echo ========================================
echo.

if not exist .git (
    echo [错误] 未找到Git仓库
    echo 请先运行: 初始化Git仓库.bat
    pause
    exit /b 1
)

echo 正在检查修改...
git status
echo.

set /p commit_msg="请输入提交信息（直接回车使用默认）: "
if "%commit_msg%"=="" set commit_msg=更新 agent-harness 项目

echo.
echo 正在添加文件...
git add .

echo.
echo 正在提交...
git commit -m "%commit_msg%"

echo.
REM 检查是否配置了远程仓库
git remote get-url origin >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ========================================
    echo [错误] 未配置远程仓库
    echo ========================================
    echo.
    echo 请先运行: 配置远程仓库.bat
    echo.
    pause
    exit /b 1
)

echo 正在推送到远程仓库...
echo.

REM 检查分支名称，如果不是main则重命名
git branch --show-current | findstr /C:"main" >nul
if %errorlevel% neq 0 (
    echo [提示] 当前分支不是main，正在重命名...
    git branch -M main
    echo.
)

git push -u origin main

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [成功] 已同步到远程仓库
    echo ========================================
) else (
    echo.
    echo ========================================
    echo [警告] 推送可能失败，请检查:
    echo 1. 是否已连接远程仓库: git remote -v
    echo 2. 网络连接是否正常
    echo 3. 远程仓库地址是否正确
    echo ========================================
)

echo.
pause
