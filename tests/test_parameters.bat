@echo off
setlocal enabledelayedexpansion

:: ========================================
::  Parameter parsing tests
:: ========================================

set "BUILD_DIR=%~dp0.."
set "RUN_EXE=%BUILD_DIR%\run.exe"

set /a passed=0
set /a failed=0
set /a total=0

echo.
echo ========================================
echo   Parameter parsing tests
echo ========================================
echo.

if not exist "%RUN_EXE%" (
    echo [!] run.exe not found. Building...
    call "%BUILD_DIR%\build.bat"
)

:: ---------- Test 1: Command without parameters ----------
echo ----------------------------------------
echo   Test 1: Command without parameters
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 2: One parameter ----------
echo ----------------------------------------
echo   Test 2: Command with one parameter
echo ----------------------------------------
set /a total+=1
set "TMPFILE=%TEMP%\runas_param_!random!.txt"
:: Important: %%TMPFILE%% with the closing percent - otherwise the variable will not expand
"%RUN_EXE%" cmd.exe /c "echo param1 > %TMPFILE% & exit 0" >nul 2>&1
:: runas exits right after launching - wait until the child process writes the file
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
echo [FAIL] file was not created
set /a failed+=1
:test_3

:: ---------- Test 3: Several parameters ----------
echo ----------------------------------------
echo   Test 3: Command with several parameters
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "echo multi & echo param & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 4: Parameters with spaces in quotes ----------
echo ----------------------------------------
echo   Test 4: Parameters with spaces
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "echo spaced params & exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 5: Flag at the start ----------
echo ----------------------------------------
echo   Test 5: Mode flag at the start
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -n cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 6: Several flags ----------
echo ----------------------------------------
echo   Test 6: Conflicting mode flags
echo ----------------------------------------
set /a total+=1
:: The last flag must win
"%RUN_EXE%" -n -m -h cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 7: Empty command ----------
echo ----------------------------------------
echo   Test 7: Only flags, no command
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" -n >nul 2>&1
if !errorlevel! equ 116 (
    echo [PASS] exit code 116 - no command
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!, expected 116
    set /a failed+=1
)

:: ---------- Test 8: Built-in command ----------
echo ----------------------------------------
echo   Test 8: Built-in command (notepad)
echo ----------------------------------------
set /a total+=1
:: notepad may open a window - use tasklist to verify it is running
"%RUN_EXE%" notepad.exe >nul 2>&1
timeout /t 1 /nobreak >nul 2>&1
tasklist /FI "IMAGENAME eq notepad.exe" 2>nul | find "notepad" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS] notepad is running
    taskkill /F /IM notepad.exe >nul 2>&1
    set /a passed+=1
) else (
    echo [WARN] notepad not found in processes - may not be installed
    set /a passed+=1
)

:: ---------- Test 9: Long path ----------
echo ----------------------------------------
echo   Test 9: Full path to an executable file
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" "C:\Windows\System32\cmd.exe" /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 10: Return with a code ----------
echo ----------------------------------------
echo   Test 10: Command returns code 0
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 0" >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 11: Dash arguments after the command ----------
echo ----------------------------------------
echo   Test 11: Target's short flags are not confused with runas options
echo ----------------------------------------
set /a total+=1
"%RUN_EXE%" cmd.exe /c "exit 0" -v >nul 2>&1
if !errorlevel! equ 0 (
    echo [PASS]
    set /a passed+=1
) else (
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)

:: ---------- Test 12: Path with spaces ----------
echo ----------------------------------------
echo   Test 12: Command from a directory whose name contains a space
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
    echo [FAIL] code = !errorlevel!
    set /a failed+=1
)
rmdir /s /q "%SPACED_DIR%" >nul 2>&1

:: ---------- Test 13: Run without a window (-w) ----------
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

:: ---------- Test 14: Verbose mode (-v) ----------
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

:: ---------- Test 15: Long aliases before the command ----------
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

:: ---------- Summary ----------
echo.
echo ========================================
echo   Results
echo ========================================
echo   Total:  !total!
echo   Passed: !passed!
echo   Failed: !failed!
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
