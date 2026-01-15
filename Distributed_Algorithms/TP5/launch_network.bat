@echo off
REM =============================================
REM Script pour lancer N noeuds Snowflake dans des terminaux séparés
REM Utilisation :
REM   launch_network.bat [N]
REM   - N : nombre de noeuds à lancer (défaut : 6)
REM Chaque noeud reçoit la liste complète de ses voisins (tous les autres ports)
REM =============================================

REM Définir le nombre de noeuds (par défaut 6 si non précisé)
if "%1"=="" (
    set NODE_COUNT=6
) else (
    set NODE_COUNT=%1
)

REM Lancer chaque noeud dans un terminal séparé
 echo Lancement de %NODE_COUNT% noeuds...
for /L %%i in (0,1,%NODE_COUNT%) do (
    if %%i LSS %NODE_COUNT% (
        setlocal enabledelayedexpansion
        set "NEIGHBORS="
        for /L %%j in (0,1,%NODE_COUNT%) do (
            if %%j NEQ %%i if %%j LSS %NODE_COUNT% set "NEIGHBORS=!NEIGHBORS! 500%%j"
        )
        REM Lancer le noeud avec la liste complète des voisins
        start "Node %%i" cmd /k "python snowy.py %%i --neighbors!NEIGHBORS!"
        timeout /t 1 /nobreak >nul
        endlocal
    )
)

echo Tous les noeuds ont ete lances!
