# Apache Tomcat Maintenance Script (Windows)

![Windows](https://img.shields.io/badge/OS-Windows-blue)
![Batch](https://img.shields.io/badge/Language-Batch-green)
![Automation](https://img.shields.io/badge/Type-Automation-orange)
![Tomcat](https://img.shields.io/badge/Service-Apache%20Tomcat-red)

Batch script for safe maintenance of multiple Apache Tomcat instances on Windows environments.

## Purpose

Automate Tomcat maintenance to prevent disk space issues by **archiving logs**, cleaning temporary directories, and safely restarting services.

## What it does

For each configured Tomcat instance:

- Stops the Tomcat Windows service  
- Archives logs to a backup directory (date/instance based)  
- Cleans `temp` and `work` directories  
- Restarts the service and verifies it is running  
- Cleans old backups based on retention policy  
- Writes a detailed execution log

## Key practices

- Service is stopped before any cleanup  
- Logs are **archived, not deleted**  
- Forced termination (`taskkill`) is used only as a fallback  
- Retention policy for backups (days-based)  
- Locale-independent date handling  
- Post-start service verification

## Configuration

Main variables to adjust:

    set "BASE_DIR=C:\Tomcat"
    set "LOG_DIR=C:\Tomcat\script_logs"
    set "BACKUP_DIR=C:\Tomcat\logs_backup"
    set "PORTS=7070 8080 8087 9090"
    set "SERVICE_PREFIX=Apache Tomcat"
    set "MAX_BACKUP_DAYS=30"

## Requirements

- Windows OS  
- Apache Tomcat installed as a Windows Service  
- Administrative privileges  

## Usage

- Run manually as Administrator  
- Or schedule via Windows Task Scheduler (recommended outside peak hours)

## Notes

- Test in non-production environments before use  
- Intended for corporate / legacy Windows infrastructure scenarios
