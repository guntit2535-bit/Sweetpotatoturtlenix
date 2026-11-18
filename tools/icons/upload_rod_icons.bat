@echo off
chcp 65001 >nul
rem Uploads the 50 rod hotbar pictures and the shop button's gold coin (art\export\RodIcons) to the group.
rem Same as upload_icons.bat; the key is only kept in this window.
cd /d "%~dp0\..\.."
echo Paste the group's Open Cloud API key (Assets API read + write), then press Enter:
set /p ROBLOX_API_KEY=
lune run tools/icons/upload.luau art/export/RodIcons
set ROBLOX_API_KEY=
echo.
echo Finished. Tell Claude "upload rod icons done".
pause
