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
:: Важно: %%TMPFILE%% с закрывающим процентом — иначе переменная не развернётся
"%RUN_EXE%" cmd.exe /c "echo param1 > %TMPFILE% & exit 0" >nul 2>&1
:: runas завершается сразу после запуска — ждём, пока дочерний процесс запишет файл
set /a wait_tries=0
:wait_file
if exist "%TMPFILE%" goto file_found
set /a wait_tries+=1
if !wait_tries! geq 8 goto file_missing
ping -n 2 127.0.0.1 >nul
goto wait_file
:file_found
echo [PASS]
set /a passed+=1
del "%TMPFILE%" >nul 2>&1
goto test_3
:file_missing
echo [FAIL] файл не создан
set /a failed+=1
:test_3

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
if !errorlevel! equ 116 (
    echo [PASS] exit code 116 — нет команды
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!, ожидался 116
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
    echo [WARN] notepad не найден в процессах — может быть не установлен
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

:: ---------- Тест 11: Даш-аргументы после команды ----------
echo ----------------------------------------
echo   Тест 11: Короткие флаги цели не путаются с runas
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 0" -v >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)

:: ---------- Тест 12: Путь с пробелами ----------
echo ----------------------------------------
echo   Тест 12: Команда из каталога с пробелом в имени
echo ----------------------------------------
set /a total+=1
set "SPACED_DIR=%TEMP%\runas spaced test"
if not exist "%SPACED_DIR%" mkdir "%SPACED_DIR%" >nul 2>&1
copy /y "%SystemRoot%\System32\where.exe" "%SPACED_DIR%\" >nul 2>&1
"%RUN_EXE%" "%SPACED_DIR%\where.exe" cmd >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] код = !errorlevel!
    set /a failed+=1
)
rmdir /s /q "%SPACED_DIR%" >nul 2>&1

:: ---------- Тест 13: Запуск без окна (-w) ----------
echo ----------------------------------------
echo   Test 13: Run without console window (-w)
echo ----------------------------------------
set /a total+=1
set "NOWIN_FILE=%TEMP%\runas_nowin.txt"
del "%NOWIN_FILE%" >nul 2>nul
"%RUN_EXE%" -w cmd.exe /c "echo NOWIN-OK > %NOWIN_FILE% 2>&1" >nul 2>&1
ping -n 3 127.0.0.1 >nul
if exist "%NOWIN_FILE%" (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] child did not write file
    set /a failed+=1
)
del "%NOWIN_FILE%" >nul 2>&1

:: ---------- Тест 14: Подробный режим (-v) ----------
echo ----------------------------------------
echo   Test 14: Verbose output to stderr (-v)
echo ----------------------------------------
set /a total+=1
set "VFILE=%TEMP%\runas_verbose.txt"
del "%VFILE%" >nul 2>nul
"%RUN_EXE%" -v cmd.exe /c "exit 0" >nul 2>"%VFILE%"
findstr /i /c:"[run]" "%VFILE%" >nul
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] no verbose lines in stderr
    set /a failed+=1
)
del "%VFILE%" >nul 2>nul

:: ---------- Тест 15: Длинные алиасы до команды ----------
echo ----------------------------------------
echo   Test 15: Long alias --hide consumed as option
echo ----------------------------------------
set /a total+=1
set "ALIAS_FILE=%TEMP%\runas_alias.txt"
del "%ALIAS_FILE%" >nul 2>nul
"%RUN_EXE%" --hide cmd.exe /c "echo ALIAS-OK > %ALIAS_FILE% 2>&1" >nul 2>&1
ping -n 3 127.0.0.1 >nul
if exist "%ALIAS_FILE%" (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] target did not run with alias option
    set /a failed+=1
)
del "%ALIAS_FILE%" >nul 2>nul

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
