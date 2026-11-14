@echo off
setlocal enabledelayedexpansion

:: ========================================
::  RunAs Utility - main test suite
:: ========================================

set "TESTS_DIR=%~dp0"
set "BUILD_DIR=%TESTS_DIR%.."
set "RUN_EXE=%BUILD_DIR%\run.exe"

set /a passed=0
set /a failed=0
set /a skipped=0
set /a total=0

color 07

echo.
echo ========================================
echo   RunAs Utility - Test Suite
echo ========================================
echo.

:: ---------- Check that the binary exists ----------
if not exist "%RUN_EXE%" (
    echo [!] run.exe not found. Attempting build...
    call "%BUILD_DIR%\build.bat"
    if errorlevel 1 (
        echo [FAIL] Build failed. Cannot continue tests.
        pause
        exit /b 1
    )
)

echo.
echo ----------------------------------------
echo   Test 1: No parameters - exit code 101
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" >nul 2>&1
if !errorlevel! equ 101 (
    echo [PASS] Exit code = 101
    set /a passed+=1
) else (
    echo [FAIL] Expected 101, got !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 2: -? flag - exit code 102
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -? >nul 2>&1
if !errorlevel! equ 102 (
    echo [PASS] Exit code = 102
    set /a passed+=1
) else (
    echo [FAIL] Expected 102, got !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 3: -H flag - exit code 102
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -H >nul 2>&1
if !errorlevel! equ 102 (
    echo [PASS] Exit code = 102
    set /a passed+=1
) else (
    echo [FAIL] Expected 102, got !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 4: Invalid flag - exit code 103
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -x >nul 2>&1
if !errorlevel! equ 103 (
    echo [PASS] Exit code = 103
    set /a passed+=1
) else (
    echo [FAIL] Expected 103, got !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 5: Help output contains version
echo ----------------------------------------
set /a total+=1
:: Direct pipe: for/f would keep only the last line of the output
"%RUN_EXE%" -? 2>nul | findstr /R "RunAs Utility v[0-9]" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Help contains version string
    set /a passed+=1
) else (
    echo [FAIL] Help does not contain version string
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 6: Launch cmd.exe (normal mode)
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -n cmd.exe /c "echo OK & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] cmd.exe launched successfully
    set /a passed+=1
) else (
    echo [FAIL] cmd.exe launch failed, exit code = !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 7: Launch with parameters
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 42" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Command with parameters executed
    set /a passed+=1
) else (
    echo [FAIL] Command with parameters failed, exit code = !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 8: Launch non-existent file
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" nonexistent_program_xyz.exe >nul 2>&1
if !errorlevel! neq 0 (
    echo [PASS] Non-existent file returned error, code !errorlevel!
    set /a passed+=1
) else (
    echo [FAIL] Non-existent file should have failed
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 9: Write output to temp file
echo ----------------------------------------
set /a total+=1
set "TMPFILE=%TEMP%\runas_test_!random!.txt"
:: %%TMPFILE%% with the closing percent - otherwise the variable will not expand
"%RUN_EXE%" cmd.exe /c "echo TEST_OUTPUT > %TMPFILE% & exit 0" >nul 2>&1
:: runas exits right after launching - wait until the child process writes the file
set /a wait_tries=0
:wait_test9
if exist "%TMPFILE%" goto test9_check
set /a wait_tries+=1
if !wait_tries! geq 8 goto test9_missing
ping -n 2 127.0.0.1 >nul
goto wait_test9
:test9_missing
echo [FAIL] Output file was not created
set /a failed+=1
goto test9_done
:test9_check
findstr /C:"TEST_OUTPUT" "%TMPFILE%" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Output file created with expected content
    del "%TMPFILE%" >nul 2>&1
    set /a passed+=1
) else (
    echo [FAIL] Output file has unexpected content
    del "%TMPFILE%" >nul 2>&1
    set /a failed+=1
)
:test9_done

echo.
echo ----------------------------------------
echo   Test 10: Multiple parameters with spaces
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "echo hello world & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Multiple parameters handled correctly
    set /a passed+=1
) else (
    echo [FAIL] Multiple parameters failed, exit code = !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 11: Hidden mode (-h)
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -h cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Hidden mode launched successfully
    set /a passed+=1
) else (
    echo [FAIL] Hidden mode failed, exit code = !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 12: Minimized mode (-m)
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -m cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Minimized mode launched successfully
    set /a passed+=1
) else (
    echo [FAIL] Minimized mode failed, exit code = !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 13: Maximized mode (-M)
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -M cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] Maximized mode launched successfully
    set /a passed+=1
) else (
    echo [FAIL] Maximized mode failed, exit code = !errorlevel!
    set /a failed+=1
)

echo.
echo ----------------------------------------
echo   Test 14: Combined flags (-n -a)
echo ----------------------------------------
set /a total+=1
:: This test will trigger UAC - skip in automated runs
echo [SKIP] Requires manual UAC confirmation
set /a skipped+=1
set /a total-=1

echo.
echo ========================================
echo   Test results
echo ========================================
echo   Total:   !total!
echo   Passed:  !passed!
echo   Failed:  !failed!
echo   Skipped: !skipped!
echo ========================================

if !failed! equ 0 (
    echo [OK] All tests passed!
    color 2F
) else (
    echo [!] Some tests failed.
    color 4F
)

echo.
pause
exit /b !failed!
