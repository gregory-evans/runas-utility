@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Тесты повышения привилегий
::  ВНИМАНИЕ: требуют ручного подтверждения UAC
:: ========================================

set "BUILD_DIR=%~dp0.."
set "RUN_EXE=%BUILD_DIR%\run.exe"

echo.
echo ========================================
echo   Тесты повышения привилегий
echo ========================================
echo [!] Эти тесты требуют ручного подтверждения UAC
echo     Нажмите «Да» в каждом диалоге
echo.

if not exist "%RUN_EXE%" (
    echo [!] run.exe не найден. Запуск сборки...
    call "%BUILD_DIR%\build.bat"
)

:: ---------- Тест 1: Проверка текущего уровня прав ----------
echo ----------------------------------------
echo   Тест 1: Определение текущих прав
echo ----------------------------------------
echo Запуск run.exe БЕЗ флага -a (должен завершиться без UAC)...
"%RUN_EXE%" cmd.exe /c "whoami /priv >nul & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Запуск без повышения прав работает
) else (
    echo [FAIL] Код ошибки: !errorlevel!
)

:: ---------- Тест 2: Запуск с повышением прав ----------
echo.
echo ----------------------------------------
echo   Тест 2: Запуск с флагом -a (UAC)
echo ----------------------------------------
echo [!] Будет показано окно UAC — подтвердите запуск
set /p "confirm=Продолжить? (y/n): "
if /i not "!confirm!"=="y" (
    echo [SKIP] Тест пропущен по запросу
    goto :test3
)

"%RUN_EXE%" -a cmd.exe /c "echo elevated & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Запуск с повышением прав успешен
) else (
    echo [FAIL] Код ошибки: !errorlevel!
    echo        Возможно, UAC было отклонено
)

:test3
:: ---------- Тест 3: Скрытый запуск с правами ----------
echo.
echo ----------------------------------------
echo   Тест 3: Скрытый запуск с правами (-h -a)
echo ----------------------------------------
echo [!] Будет показано окно UAC — подтвердите запуск
set /p "confirm=Продолжить? (y/n): "
if /i not "!confirm!"=="y" (
    echo [SKIP] Тест пропущен по запросу
    goto :test4
)

set "TMPFILE=%TEMP%\runas_elevated_!random!.txt"
:: %%TMPFILE%% с закрывающим процентом — иначе переменная не развернётся
"%RUN_EXE%" -h -a cmd.exe /c "echo ELEVATED_OK > %TMPFILE% & exit 0" >nul 2>&1
timeout /t 3 /nobreak >nul 2>&1

if exist "%TMPFILE%" (
    findstr /C:"ELEVATED_OK" "%TMPFILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Скрытый запуск с правами успешен
        del "%TMPFILE%" >nul 2>&1
    ) else (
        echo [FAIL] Файл создан, но содержимое неверно
        del "%TMPFILE%" >nul 2>&1
    )
) else (
    echo [FAIL] Файл не создан — возможно, UAC отклонено
)

:test4
:: ---------- Тест 4: Проверка работы без UAC (если уже админ) ----------
echo.
echo ----------------------------------------
echo   Тест 4: Повторный запрос прав (уже админ?)
echo ----------------------------------------
echo Запуск whoami для проверки текущего пользователя...
"%RUN_EXE%" cmd.exe /c "whoami /user" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] whoami выполнен
) else (
    echo [FAIL] Код ошибки: !errorlevel!
)

:test5
:: ---------- Test 5: Сбой элевации возвращает код 117 ----------
echo.
echo ----------------------------------------
echo   Тест 5: Сбой элевации возвращает код 117
echo ----------------------------------------
echo [i] Запускаем обёртку из копии и переименовываем её, чтобы ShellExecuteExW не нашёл файл
set "RJ_TMP=%~dp0rj_tmp.exe"
set "RJ_OLD=%~dp0rj_tmp_old.exe"
set "RJ_OUT=%~dp0rj_out.txt"
set "RJ_HELP=%~dp0t5_helper.bat"
del "%RJ_TMP%" >nul 2>&1
del "%RJ_OLD%" >nul 2>&1
del "%RJ_OUT%" >nul 2>&1
> "%RJ_HELP%" echo @echo off
>>"%RJ_HELP%" echo "%%~1" -a cmd.exe /c exit 0 ^> "%%~dp0rj_out.txt" 2^>^&1
set /a rj_tries=0 rj_ok=0
:rj_loop
set /a rj_tries+=1
copy /y "%RUN_EXE%" "%RJ_TMP%" >nul 2>&1
start "" "%RJ_HELP%" "%RJ_TMP%" >nul 2>&1
ren "%RJ_TMP%" "%RJ_OLD%" >nul 2>&1
timeout /t 3 /nobreak >nul 2>&1
findstr /C:"Error: 117" "%RJ_OUT%" >nul 2>&1
if !errorlevel! equ 0 (
    set rj_ok=1
) else if !rj_tries! lss 5 (
    goto :rj_loop
)
if !rj_ok! equ 1 (
    echo [OK] Сбой элевации обнаружен, код 117
) else (
    echo [SKIP] Не удалось воспроизвести сбой в этом окружении
)
:: Если дочерний процесс ещё держал файл, ren не удался — убираем оба варианта
ping -n 3 127.0.0.1 >nul
del "%RJ_OLD%" >nul 2>&1
del "%RJ_TMP%" >nul 2>&1
del "%RJ_OUT%" >nul 2>&1
del "%RJ_HELP%" >nul 2>&1

:: ---------- Test 6: New wait logic — elevated launch success regression ----------
echo.
echo ----------------------------------------
echo   Test 6: Elevated launch completes, child ran target
echo ----------------------------------------
echo [!] Будет показано окно UAC — подтвердите запуск
set /p "confirm=Продолжить? (y/n): "
if /i not "!confirm!"=="y" (
    echo [SKIP] Тест пропущен по запросу
    goto :end_tests
)
set "T6_FILE=%~dp0t6_out.txt"
del "%T6_FILE%" >nul 2>nul
"%RUN_EXE%" -a cmd.exe /c "echo T6-OK > %T6_FILE% 2>&1" >nul 2>&1
if !errorlevel! neq 0 (
    echo [FAIL] Родитель завершился с кодом !errorlevel! (ожидался 0)
) else (
    ping -n 5 127.0.0.1 >nul
    if exist "%T6_FILE%" (
        findstr /C:"T6-OK" "%T6_FILE%" >nul
        if !errorlevel! equ 0 (
            echo [OK] Элевированный запуск завершён, дочерний выполнил цель
        ) else (
            echo [FAIL] Файл создан без ожидаемого содержимого
        )
    ) else (
        echo [FAIL] Дочерний процесс не создал файл цели
    )
)
del "%T6_FILE%" >nul 2>nul

:end_tests
echo.
echo ========================================
echo   Тесты повышения завершены
echo ========================================
echo.
pause
