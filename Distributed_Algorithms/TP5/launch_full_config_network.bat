@echo off
REM launch_full_config_network.bat
REM Launches 10 nodes with all settings specified (localhost)

setlocal enabledelayedexpansion
set N=10
set SAMPLE_SIZE=5
set ACCEPTANCE_THRESHOLD=3
set CONSECUTIVE_SUCCESS_THRESHOLD=4
set CRASH_PROB=0.0
set COLOR=BLUE
set ALGO=SNOWFLAKE

for /L %%i in (0,1,%N%-1) do (
    set /A PORT=5000+%%i
    start "Node %%i" cmd /k python snowy.py %%i --port !PORT! --color !COLOR! --crash-prob !CRASH_PROB! --host 127.0.0.1 --algorithm !ALGO! --sample-size !SAMPLE_SIZE! --acceptance-threshold !ACCEPTANCE_THRESHOLD! --consecutive-success-threshold !CONSECUTIVE_SUCCESS_THRESHOLD!
)
endlocal
