@echo off
fpc -O3 -CX -XX -Xs run.pas
strip run.exe
timeout /t 1 /nobreak >nul
del *.o
del *.ppu
del *.a
