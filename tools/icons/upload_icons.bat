@echo off
chcp 65001 >nul
rem Uploads the 400 cat hotbar icons to the group (tools/icons/upload.luau). The key is only kept in this window.
cd /d "%~dp0\..\.."
echo Paste the group's Open Cloud API key (Assets API read + write), then press Enter:
set /p ROBLOX_API_KEY=
lune run tools/icons/upload.luau
set ROBLOX_API_KEY=
echo.
echo Finished. Tell Claude "upload icons done".
pause
