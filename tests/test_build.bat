@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Тест сборки проекта
:: ========================================

set "BUILD_DIR=%~dp0.."
set "FPC_FOUND=0"

echo.
echo ========================================
echo   Тест сборки
echo ========================================
echo.

:: ---------- Проверка fpc ----------
echo [1/4] Проверка Free Pascal Compiler...
where fpc >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] fpc найден
    set FPC_FOUND=1
) else (
    echo [FAIL] fpc не найден в PATH
    echo        Установите Free Pascal или добавьте в PATH
    goto :summary
)

:: ---------- Проверка существования исходников ----------
echo.
echo [2/4] Проверка исходных файлов...
if not exist "%BUILD_DIR%\run.pas" (
    echo [FAIL] run.pas не найден
    goto :summary
)
if not exist "%BUILD_DIR%\includes.pas" (
    echo [FAIL] includes.pas не найден
    goto :summary
)
echo [OK] Исходные файлы присутствуют

:: ---------- Компиляция ----------
echo.
echo [3/4] Компиляция...
cd /d "%BUILD_DIR%"
fpc -O3 -CX -XX -Xs run.pas
if !errorlevel! neq 0 (
    echo [FAIL] Компиляция завершена с ошибкой (код !errorlevel!)
    goto :summary
)
echo [OK] Компиляция успешна

:: ---------- Проверка бинарника ----------
echo.
echo [4/4] Проверка бинарника...
if not exist "%BUILD_DIR%\run.exe" (
    echo [FAIL] run.exe не создан
    goto :summary
)

for %%F in ("%BUILD_DIR%\run.exe") do set "size=%%~zF"
echo [OK] run.exe создан (размер: !size! байт)

:: ---------- Проверка strip (опционально) ----------
echo.
echo [бонус] Проверка strip...
where strip >nul 2>&1
if !errorlevel! equ 0 (
    set "size_before=!size!"
    strip run.exe
    for %%F in ("%BUILD_DIR%\run.exe") do set "size_after=%%~zF"
    echo [OK] strip применён (!size_before! → !size_after! байт)
) else (
    echo [WARN] strip не найден — бинарник не будет уменьшен
)

:summary
echo.
echo ========================================
if exist "%BUILD_DIR%\run.exe" (
    echo [OK] Сборка успешна
    color 2F
) else (
    echo [FAIL] Сборка не удалась
    color 4F
)
echo ========================================
echo.
pause
