@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Project build test
:: ========================================

set "BUILD_DIR=%~dp0.."
set "FPC_FOUND=0"

echo.
echo ========================================
echo   Build test
echo ========================================
echo.

:: ---------- Check fpc ----------
echo [1/4] Checking Free Pascal Compiler...
where fpc >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] fpc found
    set FPC_FOUND=1
) else (
    echo [FAIL] fpc not found in PATH
    echo        Install Free Pascal or add it to PATH
    goto :summary
)

:: ---------- Check that the sources exist ----------
echo.
echo [2/4] Checking source files...
if not exist "%BUILD_DIR%\run.pas" (
    echo [FAIL] run.pas not found
    goto :summary
)
if not exist "%BUILD_DIR%\includes.pas" (
    echo [FAIL] includes.pas not found
    goto :summary
)
echo [OK] Source files are present

:: ---------- Compile ----------
echo.
echo [3/4] Compiling...
cd /d "%BUILD_DIR%"
fpc -O3 -CX -XX -Xs run.pas
if !errorlevel! neq 0 (
    echo [FAIL] Compilation finished with an error, code !errorlevel!
    goto :summary
)
echo [OK] Compilation succeeded

:: ---------- Check the binary ----------
echo.
echo [4/4] Checking the binary...
if not exist "%BUILD_DIR%\run.exe" (
    echo [FAIL] run.exe was not created
    goto :summary
)

for %%F in ("%BUILD_DIR%\run.exe") do set "size=%%~zF"
echo [OK] run.exe created (size: !size! bytes)

:: ---------- Check strip (optional) ----------
echo.
echo [bonus] Checking strip...
where strip >nul 2>&1
if !errorlevel! equ 0 (
    set "size_before=!size!"
    strip run.exe
    for %%F in ("%BUILD_DIR%\run.exe") do set "size_after=%%~zF"
    echo [OK] strip applied: !size_before! -^> !size_after! bytes
) else (
    echo [WARN] strip not found - the binary will not be reduced
)

:summary
echo.
echo ========================================
if exist "%BUILD_DIR%\run.exe" (
    echo [OK] Build succeeded
    color 2F
) else (
    echo [FAIL] Build failed
    color 4F
)
echo ========================================
echo.
pause
