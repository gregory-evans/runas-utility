@echo off

setlocal enabledelayedexpansion
set count=0

:loop
    if "%~1"=="" goto end
    set /a count+=1
    echo !count!: %1
    shift
goto loop

:end
if %count%==0 echo No parameters.
pause