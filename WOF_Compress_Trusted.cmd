:: ========================================================================================================
:: ====================================== WOF_Compress_Trusted.cmd - January 16 2021 ======================
:: ========================================================================================================
@echo off
Setlocal EnableExtensions EnableDelayedExpansion

pushd "%~dp0"

SET ProgDir=%~dp0
SET ProgDir=%ProgDir:~0,-1%
cd /d "%ProgDir%"

:: ECHO.
:: ECHO Program Path = %ProgDir%
:: ECHO.
:: echo Use AdvancedRun to Run as Trusted Installer program WOF_Compress_x64.exe
:: echo.

set sysdrive=%SystemRoot:~0,1%
:: echo System Drive = %sysdrive%
:: In 10XPE Drive X - already Trusted Installer - AdvancedRun.exe does not work 

if "%sysdrive%"=="X" (
  %ProgDir%\WOF_Compress_x64.exe
) else (
  %ProgDir%\advancedrun-x64\AdvancedRun.exe /EXEFilename "%ProgDir%\WOF_Compress_x64.exe" /RunAs 8 /Run 
)
:: echo.
:: echo End of Program
:: echo.

popd

goto :eof
:: ========================================================================================================
:: ====================================== END WOF_Compress_Trusted.cmd ====================================
:: ========================================================================================================
