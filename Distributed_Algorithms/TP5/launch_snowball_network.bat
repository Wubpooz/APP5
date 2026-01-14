@echo off
REM launch_snowball_network.bat [N]
REM Usage: launch_snowball_network.bat 6

setlocal enabledelayedexpansion
set N=%1
if "%N%"=="" set N=6

for /L %%i in (0,1,%N%-1) do (
    start "Snowball Node %%i" cmd /k python snowy.py %%i --algorithm SNOWBALL
)
endlocal
