:: ========================================================================================================
:: ====================================== h_list.cmd - July 23 2020 =======================================
:: ========================================================================================================
@echo off
Setlocal EnableExtensions EnableDelayedExpansion

set WorkList=%1

pushd "%~dp0"

SET ProgDir=%~dp0
SET ProgDir=%ProgDir:~0,-1%
cd /d "%ProgDir%"

chcp 437 >nul
:: mode con cols=105

Set datum=%DATE%
FOR /F "tokens=2 delims= " %%G in ('ECHO %datum%') DO (
  set datum=%%G
)

FOR /F "tokens=1,2,3 delims=/.-" %%G in ('ECHO !datum!') DO (
  set datum=%%I-%%H-%%G
)

if not defined WorkList set WorkList=P_WinSxS.txt
if not exist %WorkList% (echo Error: List of Files %WorkList% not found &pause &goto :eof)

ECHO.
ECHO Program Path  = %ProgDir%
ECHO File_List     = %WorkList%
ECHO.
echo Search for Single and Multi Hardlink data in File_List - can take 10 minutes ....
echo.

pause

set /A file_cnt=0
set /A file_h1_cnt=0
set /A file_h2_cnt=0

Set start_time=%TIME:~0,-3%

echo.
echo start = !datum!  !start_time!
echo.
echo Search for Single and Multi Hardlink data is Running ..... Please Wait - can take 10 minutes ....
echo.

if exist %ProgDir%\Single_Hard_Link_List_%datum%.txt del %ProgDir%\Single_Hard_Link_List_%datum%.txt
if exist %ProgDir%\Multi_Hard_Link_List_%datum%.txt del %ProgDir%\Multi_Hard_Link_List_%datum%.txt

for /f %%f in ('TYPE !WorkList! ^| findstr .*') do (
  set /A file_cnt=!file_cnt!+1
  set /A h_count=0
  set /A  mod_rest=file_cnt%%1000
  if !mod_rest! EQU 0 (
    echo File     %%f
  )
  if exist %%f (
    for /f "tokens=1,2* delims= " %%a in ('fsutil.exe hardlink list %%f ^| findstr /N .*') do (
      set /A h_count=!h_count!+1
      if !mod_rest! EQU 0 (
        echo Hardlink %%a
      )
    ) 
    if !h_count! EQU 1 (
      set /A file_h1_cnt=!file_h1_cnt!+1 && echo %%f >> Single_Hard_Link_List_%datum%.txt
    ) else (
      set /A file_h2_cnt=!file_h2_cnt!+1 && echo %%f >> Multi_Hard_Link_List_%datum%.txt
    )
  )
  if !mod_rest! EQU 0 (
    echo Total  file  count = !file_cnt!
    echo Single file  count = !file_h1_cnt!
    echo Multi  file  count = !file_h2_cnt!
    echo.
  )
)

if exist %ProgDir%\Single_Hard_Link_List_%datum%.txt echo Finshed - File %ProgDir%\Single_Hard_Link_List_%datum%.txt created
if exist %ProgDir%\Multi_Hard_Link_List_%datum%.txt echo Finshed - File %ProgDir%\Multi_Hard_Link_List_%datum%.txt created

echo.
echo Total  file  count = !file_cnt!
echo Single file  count = !file_h1_cnt!
echo Multi  file  count = !file_h2_cnt!
echo.
echo start = !datum!  !start_time!
echo end   = !datum!  %TIME:~0,-3%
echo.

pause

if exist %ProgDir%\Single_Hard_Link_List_%datum%.txt notepad.exe %ProgDir%\Single_Hard_Link_List_%datum%.txt
if exist %ProgDir%\Multi_Hard_Link_List_%datum%.txt notepad.exe %ProgDir%\Multi_Hard_Link_List_%datum%.txt

echo.
echo End of Program
echo.

pause

popd

goto :eof
:: ========================================================================================================
:: ====================================== END h_list.cmd ==================================================
:: ========================================================================================================
