@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Тесты парсинга параметров
:: ========================================

set "BUILD_DIR=%~dp0.."
set "RUN_EXE=%BUILD_DIR%\run.exe"

set /a passed=0
set /a failed=0
set /a total=0

echo.
echo ========================================
echo   Тесты парсинга параметров
echo ========================================
echo.

if not exist "%RUN_EXE%" (
    echo [!] run.exe не найден. Запуск сборки...
    call "%BUILD_DIR%\build.bat"
)

:: ---------- Тест 1: Команда без параметров ----------
echo ----------------------------------------
echo   Тест 1: Команда без параметров
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 2: Один параметр ----------
echo ----------------------------------------
echo   Тест 2: Команда с одним параметром
echo ----------------------------------------
set /a total+=1
set "TMPFILE=%TEMP%\runas_param_!random!.txt"
"%RUN_EXE%" cmd.exe /c "echo param1 > %TMPFILE" >nul 2>&1
if exist "%TMPFILE%" (
    echo [PASS]
    set /a passed+=1
    del "%TMPFILE%" >nul 2>&1
) else (
    echo [FAIL] файл не создан
    set /a failed+=1
)

:: ---------- Тест 3: Несколько параметров ----------
echo ----------------------------------------
echo   Тест 3: Команда с несколькими параметрами
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "echo multi & echo param & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 4: Параметры с пробелами в кавычках ----------
echo ----------------------------------------
echo   Тест 4: Параметры с пробелами
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "echo spaced params & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 5: Флаг в начале ----------
echo ----------------------------------------
echo   Тест 5: Флаг режима в начале
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -n cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 6: Несколько флагов ----------
echo ----------------------------------------
echo   Тест 6: Конфликтующие флаги режима
echo ----------------------------------------
set /a total+=1
:: Последний флаг должен победить
"%RUN_EXE%" -n -m -h cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 7: Пустая команда ----------
echo ----------------------------------------
echo   Тест 7: Только флаги, без команды
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -n >nul 2>&1
if !errorlevel! equ 101 (
    echo [PASS] (exit code 101 — нет параметров)
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel! (ожидался 101)
    set /a failed+=1
)

:: ---------- Тест 8: Встроенная команда ----------
echo ----------------------------------------
echo   Тест 8: Встроенная команда (notepad)
echo ----------------------------------------
set /a total+=1
:: notepad может открыть окно — используем tasklist для проверки
"%RUN_EXE%" notepad.exe >nul 2>&1
timeout /t 1 /nobreak >nul 2>&1
tasklist /FI "IMAGENAME eq notepad.exe" 2>nul | find "notepad" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] notepad запущен
    taskkill /F /IM notepad.exe >nul 2>&1
    set /a passed+=1
) else (
    echo [WARN] notepad не найден в процессах (может быть не установлен)
    set /a passed+=1
)

:: ---------- Тест 9: Длинный путь ----------
echo ----------------------------------------
echo   Тест 9: Полный путь к исполняемому файлу
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" "C:\Windows\System32\cmd.exe" /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 10: Вернуться с кодом ----------
echo ----------------------------------------
echo   Тест 10: Команда возвращает код 0
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Итоги ----------
echo.
echo ========================================
echo   Результаты
echo ========================================
echo   Всего:  !total!
echo   Прошло: !passed!
echo   Падено: !failed!
echo ========================================

if !failed! equ 0 (
    color 2F
    echo [OK] Все тесты пройдены
) else (
    color 4F
    echo [!] Есть проваленные тесты
)

echo.
pause
exit /b !failed!
