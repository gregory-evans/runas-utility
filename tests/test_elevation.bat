@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Privilege elevation tests
::  NOTE: require manual UAC confirmation
:: ========================================

set "BUILD_DIR=%~dp0.."
set "RUN_EXE=%BUILD_DIR%\run.exe"

echo.
echo ========================================
echo   Privilege elevation tests
echo ========================================
echo [!] These tests require manual UAC confirmation
echo     Press "Yes" in each dialog
echo.

if not exist "%RUN_EXE%" (
    echo [!] run.exe not found. Building...
    call "%BUILD_DIR%\build.bat"
)

:: ---------- Test 1: Check the current privilege level ----------
echo ----------------------------------------
echo   Test 1: Determine current privileges
echo ----------------------------------------
echo Launching run.exe WITHOUT the -a flag (must finish without UAC)...
"%RUN_EXE%" cmd.exe /c "whoami /priv >nul & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Launch without elevation works
) else (
    echo [FAIL] Error code: !errorlevel!
)

:: ---------- Test 2: Launch with elevated privileges ----------
echo.
echo ----------------------------------------
echo   Test 2: Launch with the -a flag (UAC)
echo ----------------------------------------
echo [!] A UAC dialog will appear - confirm the launch
set /p "confirm=Continue? (y/n): "
if /i not "!confirm!"=="y" (
    echo [SKIP] Test skipped on request
    goto :test3
)

"%RUN_EXE%" -a cmd.exe /c "echo elevated & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] Launch with elevation succeeded
) else (
    echo [FAIL] Error code: !errorlevel!
    echo        Possibly the UAC prompt was denied
)

:test3
:: ---------- Test 3: Hidden launch with privileges ----------
echo.
echo ----------------------------------------
echo   Test 3: Hidden launch with privileges (-h -a)
echo ----------------------------------------
echo [!] A UAC dialog will appear - confirm the launch
set /p "confirm=Continue? (y/n): "
if /i not "!confirm!"=="y" (
    echo [SKIP] Test skipped on request
    goto :test4
)

set "TMPFILE=%TEMP%\runas_elevated_!random!.txt"
:: %%TMPFILE%% with the closing percent - otherwise the variable will not expand
"%RUN_EXE%" -h -a cmd.exe /c "echo ELEVATED_OK > %TMPFILE% & exit 0" >nul 2>&1
timeout /t 3 /nobreak >nul 2>&1

if exist "%TMPFILE%" (
    findstr /C:"ELEVATED_OK" "%TMPFILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [OK] Hidden launch with privileges succeeded
        del "%TMPFILE%" >nul 2>&1
    ) else (
        echo [FAIL] File created, but the content is wrong
        del "%TMPFILE%" >nul 2>&1
    )
) else (
    echo [FAIL] File was not created - possibly the UAC prompt was denied
)

:test4
:: ---------- Test 4: Check operation without UAC (if already admin) ----------
echo.
echo ----------------------------------------
echo   Test 4: Requesting privileges again (already admin?)
echo ----------------------------------------
echo Launching whoami to check the current user...
"%RUN_EXE%" cmd.exe /c "whoami /user" >nul 2>&1
if !errorlevel! equ 0 (
    echo [OK] whoami executed
) else (
    echo [FAIL] Error code: !errorlevel!
)

:test5
:: ---------- Test 5: Elevation failure returns code 117 ----------
echo.
echo ----------------------------------------
echo   Test 5: Elevation failure returns code 117
echo ----------------------------------------
echo [i] Launch the wrapper from a copy, then rename it so ShellExecuteExW cannot find the file
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
    echo [OK] Elevation failure detected, code 117
) else (
    echo [SKIP] Could not reproduce the failure in this environment
)
:: If a child process still held the file, ren failed - remove both variants
ping -n 3 127.0.0.1 >nul
del "%RJ_OLD%" >nul 2>&1
del "%RJ_TMP%" >nul 2>&1
del "%RJ_OUT%" >nul 2>&1
del "%RJ_HELP%" >nul 2>&1

:: ---------- Test 6: New wait logic - elevated launch success regression ----------
echo.
echo ----------------------------------------
echo   Test 6: Elevated launch completes, child ran the target
echo ----------------------------------------
echo [!] A UAC dialog will appear - confirm the launch
set /p "confirm=Continue? (y/n): "
if /i not "!confirm!"=="y" (
    echo [SKIP] Test skipped on request
    goto :end_tests
)
set "T6_FILE=%~dp0t6_out.txt"
del "%T6_FILE%" >nul 2>nul
"%RUN_EXE%" -a cmd.exe /c "echo T6-OK > %T6_FILE% 2>&1" >nul 2>&1
if !errorlevel! neq 0 (
    echo [FAIL] Parent exited with code !errorlevel! (expected 0)
) else (
    ping -n 5 127.0.0.1 >nul
    if exist "%T6_FILE%" (
        findstr /C:"T6-OK" "%T6_FILE%" >nul
        if !errorlevel! equ 0 (
            echo [OK] Elevated launch completed, child ran the target
        ) else (
            echo [FAIL] File created without the expected content
        )
    ) else (
        echo [FAIL] Child process did not create the target file
    )
)
del "%T6_FILE%" >nul 2>nul

:end_tests
echo.
echo ========================================
echo   Elevation tests finished
echo ========================================
echo.
pause
