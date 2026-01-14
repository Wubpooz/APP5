@echo off
REM =============================================
REM Script pour lancer N noeuds Snowflake avec simulation de pannes
REM Utilisation :
REM   launch_crash_network.bat [N] [CRASH_PROB]
REM   - N : nombre de noeuds à lancer (défaut : 6)
REM   - CRASH_PROB : probabilité de panne (défaut : 0.05)
REM =============================================

if "%1"=="" (
    set NODE_COUNT=6
) else (
    set NODE_COUNT=%1
)
if "%2"=="" (
    set CRASH_PROB=0.05
) else (
    set CRASH_PROB=%2
)

for /L %%i in (0,1,%NODE_COUNT%) do (
    if %%i LSS %NODE_COUNT% (
        setlocal enabledelayedexpansion
        set "NEIGHBORS="
        for /L %%j in (0,1,%NODE_COUNT%) do (
            if %%j NEQ %%i if %%j LSS %NODE_COUNT% set "NEIGHBORS=!NEIGHBORS! 500%%j"
        )
        start "Node %%i" cmd /k "python snowflake.py %%i --neighbors!NEIGHBORS! --crash-prob %CRASH_PROB%"
        timeout /t 1 /nobreak >nul
        endlocal
    )
)

echo Tous les noeuds ont ete lances avec simulation de pannes!
