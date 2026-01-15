@echo off
REM =============================================
REM Script pour lancer N noeuds Snowflake avec un conflit initial de couleurs
REM Utilisation :
REM   launch_conflict_network.bat [N]
REM   - N : nombre de noeuds à lancer (défaut : 6)
REM Les 3 premiers noeuds sont BLUE, les 3 suivants sont RED (pour N=6)
REM =============================================

if "%1"=="" (
    set NODE_COUNT=6
) else (
    set NODE_COUNT=%1
)

REM Lancer chaque noeud dans un terminal séparé avec couleur initiale
for /L %%i in (0,1,%NODE_COUNT%) do (
    if %%i LSS %NODE_COUNT% (
        setlocal enabledelayedexpansion
        set "NEIGHBORS="
        for /L %%j in (0,1,%NODE_COUNT%) do (
            if %%j NEQ %%i if %%j LSS %NODE_COUNT% set "NEIGHBORS=!NEIGHBORS! 500%%j"
        )
        if %%i LSS %NODE_COUNT% (
            if %%i LSS %NODE_COUNT% (
                if %%i LSS %NODE_COUNT% (
                    if %%i LSS 3 (
                        set "COLOR=BLUE"
                    ) else (
                        set "COLOR=RED"
                    )
                )
            )
        )
        start "Node %%i" cmd /k "python snowy.py %%i --color !COLOR! --neighbors!NEIGHBORS!"
        timeout /t 1 /nobreak >nul
        endlocal
    )
)

echo Tous les noeuds ont ete lances avec conflit initial de couleurs!
