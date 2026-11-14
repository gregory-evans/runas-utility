@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Error message tests (messages.inc)
:: ========================================

set "TESTS_DIR=%~dp0"
set "BUILD_DIR=%TESTS_DIR%.."
set "RUN_EXE=%BUILD_DIR%\run.exe"
set "OUT_FILE=%TEMP%\runas_msg_out.txt"

set /a passed=0
set /a failed=0
set /a skipped=0
set /a total=0

echo.
echo ========================================
echo   Error message tests
echo ========================================
echo.

if not exist "%RUN_EXE%" (
    echo [!] run.exe not found. Building...
    call "%BUILD_DIR%\build.bat"
)

:: ---------- Test 1: code 103 - unknown flag (code only, help is printed) ----------
echo ----------------------------------------
echo   Test 1: Unknown flag returns code 103
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -x >nul 2>&1
if !errorlevel! equ 103 (
    echo [PASS] exit code = 103
    set /a passed+=1
) else (
    echo [FAIL] expected 103, got !errorlevel!
    set /a failed+=1
)

:: ---------- Test 2: code 116 - flags only, message printed ----------
echo ----------------------------------------
echo   Test 2: No command returns 116 with its message
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -n > "%OUT_FILE%" 2>&1
if !errorlevel! equ 116 (
    findstr /i /c:"only flags were passed, no command was specified" "%OUT_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [PASS] code 116 + message printed
        set /a passed+=1
    ) else (
        echo [FAIL] code 116 but the message is missing
        set /a failed+=1
    )
) else (
    echo [FAIL] expected 116, got !errorlevel!
    set /a failed+=1
)

:: ---------- Test 3: code 118 - path with separator does not exist ----------
echo ----------------------------------------
echo   Test 3: Non-existent path returns 118 with its message
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" "%TEMP%\no_such_dir_xyz\prog.exe" > "%OUT_FILE%" 2>&1
if !errorlevel! equ 118 (
    findstr /i /c:"executable does not exist at the specified path" "%OUT_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [PASS] code 118 + message printed
        set /a passed+=1
    ) else (
        echo [FAIL] code 118 but the message is missing
        set /a failed+=1
    )
) else (
    echo [FAIL] expected 118, got !errorlevel!
    set /a failed+=1
)

:: ---------- Test 4: code 104 - bare name not found on PATH ----------
echo ----------------------------------------
echo   Test 4: Non-existent bare name returns 104 with its message
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" no_such_bare_prog_xyz > "%OUT_FILE%" 2>&1
if !errorlevel! equ 104 (
    findstr /i /c:"failed to create the process" "%OUT_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo [PASS] code 104 + message printed
        set /a passed+=1
    ) else (
        echo [FAIL] code 104 but the message is missing
        set /a failed+=1
    )
) else (
    echo [FAIL] expected 104, got !errorlevel!
    set /a failed+=1
)

:: ---------- Test 5: localization - swap messages.inc and rebuild ----------
echo ----------------------------------------
echo   Test 5: Custom messages.inc is picked up after rebuild
echo ----------------------------------------
set /a total+=1
where fpc >nul 2>&1
if !errorlevel! neq 0 (
    echo [SKIP] fpc not found in PATH, cannot build the localized variant
    set /a skipped+=1
    set /a total-=1
    goto :summary
)

set "MT_DIR=%TEMP%\runas_msg_test"
del /q /s "%MT_DIR%" >nul 2>&1
mkdir "%MT_DIR%" >nul 2>&1
copy /y "%BUILD_DIR%\run.pas" "%MT_DIR%\" >nul
copy /y "%BUILD_DIR%\includes.pas" "%MT_DIR%\" >nul
:: Custom text resources with per-code markers (all constants must be defined)
>  "%MT_DIR%\messages.inc" echo ERROR_NO_PARAMETERS_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_REQUEST_HELP_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_UNDEFINED_PARAMETERS_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_CREATE_PROCESS_TEXT = 'MARKER_104';
>>"%MT_DIR%\messages.inc" echo ERROR_CANT_OPEN_SECURITY_TOKEN_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_CANT_WRITE_MMF_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_CREATE_MMF_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_CREATE_EVENT_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_ON_WAITING_EVENT_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_SHELL_EXECUTE_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_READ_MMF_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_OPEN_MMF_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_MAP_MMF_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_OPEN_EVENT_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_SET_EVENT_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_NO_COMMAND_TEXT = 'MARKER_116';
>>"%MT_DIR%\messages.inc" echo ERROR_UAC_DENIED_TEXT = 'unused';
>>"%MT_DIR%\messages.inc" echo ERROR_COMMAND_NOT_FOUND_TEXT = 'MARKER_118';
>>"%MT_DIR%\messages.inc" echo ERROR_ELEVATED_CHILD_FAILED_TEXT = 'unused';

cd /d "%MT_DIR%"
fpc -O3 run.pas >nul 2>&1
if !errorlevel! neq 0 (
    echo [FAIL] localized variant did not compile
    set /a failed+=1
    goto :mt_cleanup
)

set /a mt_ok=0
"%MT_DIR%\run.exe" -n > "%OUT_FILE%" 2>&1
if !errorlevel! equ 116 (
    findstr /c:"MARKER_116" "%OUT_FILE%" >nul 2>&1 && set /a mt_ok+=1
)

"%MT_DIR%\run.exe" no_such_bare_prog_xyz > "%OUT_FILE%" 2>&1
if !errorlevel! equ 104 (
    findstr /c:"MARKER_104" "%OUT_FILE%" >nul 2>&1 && set /a mt_ok+=1
)

"%MT_DIR%\run.exe" "%TEMP%\no_such_dir_xyz\prog.exe" > "%OUT_FILE%" 2>&1
if !errorlevel! equ 118 (
    findstr /c:"MARKER_118" "%OUT_FILE%" >nul 2>&1 && set /a mt_ok+=1
)

if !mt_ok! equ 3 (
    echo [PASS] all three markers from the custom messages.inc were printed
    set /a passed+=1
) else (
    echo [FAIL] one or more markers were not printed by the localized build
    set /a failed+=1
)

:mt_cleanup
cd /d "%TESTS_DIR%"
del /q /s "%MT_DIR%" >nul 2>&1
del "%OUT_FILE%" >nul 2>&1

:summary
echo.
echo ========================================
echo   Results
echo ========================================
echo   Total:   !total!
echo   Passed:  !passed!
echo   Failed:  !failed!
echo   Skipped: !skipped!
echo ========================================

if !failed! equ 0 (
    color 2F
    echo [OK] All tests passed
) else (
    color 4F
    echo [!] Some tests failed
)

echo.
pause
exit /b !failed!
