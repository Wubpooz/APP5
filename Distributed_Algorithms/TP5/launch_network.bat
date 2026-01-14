@echo off
REM Script pour lancer N noeuds dans des terminaux séparés
REM Usage: launch_network.bat [nombre_de_noeuds]
REM Défaut: 6 noeuds

if "%1"=="" (
    set NODE_COUNT=6
) else (
    set NODE_COUNT=%1
)

echo Lancement de %NODE_COUNT% noeuds...

for /L %%i in (0,1,%NODE_COUNT%) do (
    if %%i LSS %NODE_COUNT% (
        start "Node %%i" cmd /k "python snowflake.py %%i"
        timeout /t 1 /nobreak >nul
    )
)

echo Tous les noeuds ont ete lances!
