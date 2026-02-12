@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo ========================================
echo 配置远程仓库 - Agent Harness
echo ========================================
echo.

if not exist .git (
    echo [错误] 未找到Git仓库
    echo 请先运行: 初始化Git仓库.bat
    pause
    exit /b 1
)

echo 当前远程仓库配置:
echo.
git remote -v
echo.

git remote get-url origin >nul 2>&1
if %errorlevel% equ 0 (
    echo [提示] 已配置远程仓库 origin
    echo.
    set /p change_remote="是否要更改远程仓库地址？(Y/N，默认N): "
    if /i not "%change_remote%"=="Y" (
        echo 已取消
        pause
        exit /b 0
    )
    echo.
    git remote remove origin
    echo [提示] 已删除原有远程仓库配置
    echo.
)

echo ========================================
echo 配置新的远程仓库
echo ========================================
echo.
echo 请选择远程仓库平台:
echo 1. GitHub (https://github.com)
echo 2. Gitee (https://gitee.com) - 国内推荐
echo 3. 其他Git服务
echo.
set /p platform="请输入选择 (1/2/3): "

if "%platform%"=="1" (
    set platform_name=GitHub
    set platform_url=https://github.com
) else if "%platform%"=="2" (
    set platform_name=Gitee
    set platform_url=https://gitee.com
) else (
    set platform_name=其他
    set platform_url=
)

echo.
echo ========================================
echo 配置步骤说明
echo ========================================
echo.
echo 1. 访问 %platform_url%
echo 2. 登录你的账号
echo 3. 创建新仓库（New Repository / 新建仓库）
echo 4. 复制仓库地址（Clone地址）
echo.
echo 仓库地址格式示例:
if "%platform%"=="1" (
    echo    https://github.com/用户名/仓库名.git
) else if "%platform%"=="2" (
    echo    https://gitee.com/用户名/仓库名.git
) else (
    echo    https://git.example.com/用户名/仓库名.git
)
echo.
echo ========================================
echo.

set /p repo_url="请输入仓库地址: "
if "%repo_url%"=="" (
    echo [错误] 仓库地址不能为空
    pause
    exit /b 1
)

echo.
echo 正在配置远程仓库...
git remote add origin "%repo_url%"

if %errorlevel% equ 0 (
    echo [成功] 远程仓库已配置
    echo.
    echo 当前远程仓库配置:
    git remote -v
    echo.
    echo 下一步: 运行 同步到远程.bat 推送代码
    echo.
) else (
    echo [错误] 配置失败，请检查仓库地址是否正确
    echo.
)

pause
