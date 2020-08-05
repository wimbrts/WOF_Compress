:: ========================================================================================================
:: ====================================== WOF_Compress_Trusted.cmd - August 05 2020 =======================
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

%ProgDir%\advancedrun-x64\AdvancedRun.exe /EXEFilename "%ProgDir%\WOF_Compress_x64.exe" /RunAs 8 /Run 

:: echo.
:: echo End of Program
:: echo.

popd

goto :eof
:: ========================================================================================================
:: ====================================== END WOF_Compress_Trusted.cmd ==================================================
:: ========================================================================================================
