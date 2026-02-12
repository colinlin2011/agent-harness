@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo 初始化Git仓库 - Agent Harness
echo ========================================
echo.

if exist .git (
    echo [提示] Git仓库已存在
    echo.
    echo 当前Git状态:
    git status
    echo.
) else (
    echo 正在初始化Git仓库...
    git init
    echo [成功] Git仓库已初始化
    echo.
)

echo ========================================
echo Git配置检查
echo ========================================
echo.

git config user.name >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 未配置Git用户名称
    echo 请运行: git config user.name "你的姓名"
    echo.
) else (
    echo [已配置] 用户名称: 
    git config user.name
    echo.
)

git config user.email >nul 2>&1
if %errorlevel% neq 0 (
    echo [警告] 未配置Git用户邮箱
    echo 请运行: git config user.email "你的邮箱"
    echo.
) else (
    echo [已配置] 用户邮箱: 
    git config user.email
    echo.
)

echo ========================================
echo 下一步操作
echo ========================================
echo.
echo 1. 如果还未配置用户信息，请运行:
echo    git config user.name "你的姓名"
echo    git config user.email "你的邮箱"
echo.
echo 2. 添加文件到Git:
echo    git add .
echo.
echo 3. 提交文件:
echo    git commit -m "初始提交"
echo.
echo 4. 创建远程仓库后，连接并推送:
echo    git remote add origin ^<仓库地址^>
echo    git branch -M main
echo    git push -u origin main
echo.
echo 或运行: 配置远程仓库.bat 和 同步到远程.bat
echo.

pause
