@echo off
setlocal
set "DIR=%~dp0"
set "DIR=%DIR:~0,-1%"

:: Background update check (once per day)
set "UPDATE_CHECK=%USERPROFILE%\.aurora\.last-update-check"
if not exist "%UPDATE_CHECK%" (
  echo 1 > "%UPDATE_CHECK%"
  start /b "" "%DIR%\update.ps1" -quiet
) else (
  for /f "tokens=2" %%a in ('dir "%UPDATE_CHECK%" ^| findstr /i "File"') do set "FILESIZE=%%a"
  if not defined FILESIZE (
    echo 1 > "%UPDATE_CHECK%"
    start /b "" "%DIR%\update.ps1" -quiet
  )
)

start "" "%DIR%\chrome-win\chrome.exe" --user-data-dir="%DIR%\profile" --no-first-run --disable-features=TranslateUI --load-extension="%DIR%\extension" %*
