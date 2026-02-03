@echo off
setlocal EnableDelayedExpansion

:: ========================================================
::  TOMCAT MAINTENANCE SCRIPT (ENHANCED)
::  Stops, Archives Logs, Cleans Temp, Restarts
:: ========================================================

:: ================= CONFIGURACOES =================
set "BASE_DIR=C:\Autbank\portal"
set "LOG_DIR=C:\Autbank\portal\logs_script"
set "BACKUP_DIR=C:\Autbank\portal\logs_backup"
set "PORTAS=7070 8080 8087 9090"
set "SERVICE_PREFIX=Apache Tomcat9 -"
set "MAX_BACKUP_DAYS=30"

:: ================= LOGGING SETUP =================
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

:: Robust Date Retrieval (PowerShell) - Region Independent
for /f "usebackq tokens=1-3 delims=-" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd'"`) do (
    set "YEAR=%%a" & set "MONTH=%%b" & set "DAY=%%c"
)
set "DATA_HOJE=%YEAR%-%MONTH%-%DAY%"
set "ARQUIVO_LOG=%LOG_DIR%\maintenance_%DATA_HOJE%.log"

:: Call Main and redirect output
call :Main >> "%ARQUIVO_LOG%" 2>&1
exit /b

:: ========================================================
::  MAIN
:: ========================================================
:Main
echo ========================================================
echo TOMCAT MAINTENANCE STARTED
echo DATE: %DATE% - TIME: %TIME%
echo ========================================================

:: Clean old backups first (files older than 30 days)
echo [MAINTENANCE] Cleaning backups older than %MAX_BACKUP_DAYS% days...
forfiles /p "%BACKUP_DIR%" /s /m *.* /d -%MAX_BACKUP_DAYS% /c "cmd /c del @path" 2>nul

for %%p in (%PORTAS%) do (
    call :ProcessarInstancia %%p
)

echo ========================================================
echo MAINTENANCE FINISHED
echo DATE: %DATE% - TIME: %TIME%
echo ========================================================
exit /b

:: ========================================================
::  PROCESS INSTANCE
:: ========================================================
:ProcessarInstancia
set "PORTA=%~1"
set "SERVICE_NAME=%SERVICE_PREFIX% %PORTA%"
set "TOMCAT_DIR=%BASE_DIR%\Tomcat9%PORTA%"

echo.
echo --------------------------------------------------------
echo PROCESSING TOMCAT INSTANCE - PORT %PORTA%
echo --------------------------------------------------------

:: ========== STEP 1 - STOP SERVICE ==========
echo [STEP 1] Stopping service "%SERVICE_NAME%"...
net stop "%SERVICE_NAME%" >nul 2>&1
timeout /t 5 /nobreak >nul
call :KillByPort %PORTA%

:: ========== STEP 2 - ARCHIVE & CLEAN ==========
if exist "%TOMCAT_DIR%" (
    echo [STEP 2] Archiving logs and cleaning directories...
    
    :: Archive Logs before deleting
    call :ArchiveLogs "%TOMCAT_DIR%\logs" "%PORTA%"

    :: Clean Temp/Work (Safe to delete immediately)
    call :CleanDir "%TOMCAT_DIR%\work"
    call :CleanDir "%TOMCAT_DIR%\temp"
) else (
    echo [ERROR] Tomcat directory not found: %TOMCAT_DIR%
)

:: ========== STEP 3 - START SERVICE ==========
echo [STEP 3] Starting service "%SERVICE_NAME%"...
net start "%SERVICE_NAME%" >nul 2>&1

:: Verify if it started
timeout /t 5 /nobreak >nul
sc query "%SERVICE_NAME%" | find "RUNNING" >nul
if %errorlevel%==0 (
    echo [SUCCESS] Service is RUNNING.
) else (
    echo [CRITICAL ERROR] Service FAILED to start or is not running!
)

exit /b

:: ========================================================
::  HELPER: KILL BY PORT
:: ========================================================
:KillByPort
set "PORTA_KILL=%~1"
set "PID=0"
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORTA_KILL% " ^| findstr LISTENING') do set "PID=%%a"

if not "%PID%"=="0" (
    echo [WARNING] Port %PORTA_KILL% still active. Forcing PID %PID% kill...
    taskkill /F /PID %PID% >nul 2>&1
) else (
    echo [INFO] Port %PORTA_KILL% is free.
)
exit /b

:: ========================================================
::  HELPER: CLEAN DIRECTORY (Delete only)
:: ========================================================
:CleanDir
set "TARGET_DIR=%~1"
if exist "%TARGET_DIR%" (
    echo    Cleaning: %TARGET_DIR%
    pushd "%TARGET_DIR%" >nul 2>&1
    del /F /Q *.* >nul 2>&1
    for /D %%d in (*) do rmdir /S /Q "%%d" >nul 2>&1
    popd
)
exit /b

:: ========================================================
::  HELPER: ARCHIVE LOGS (Move to Backup)
:: ========================================================
:ArchiveLogs
set "SOURCE_LOGS=%~1"
set "INSTANCE_ID=%~2"
set "TODAY_BACKUP=%BACKUP_DIR%\%DATA_HOJE%\%INSTANCE_ID%"

if exist "%SOURCE_LOGS%" (
    if not exist "%TODAY_BACKUP%" mkdir "%TODAY_BACKUP%"
    echo    Archiving: %SOURCE_LOGS% to %TODAY_BACKUP%
    
    :: Move files instead of delete. If move fails (locked file), we try to delete what we can.
    move /y "%SOURCE_LOGS%\*.*" "%TODAY_BACKUP%\" >nul 2>&1
    
    :: Ensure folder is empty for fresh start
    del /F /Q "%SOURCE_LOGS%\*.*" >nul 2>&1
)
exit /b