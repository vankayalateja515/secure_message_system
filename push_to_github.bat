@echo off
title Push to GitHub - Secure Messaging System
cd /d "%~dp0"
echo ========================================================
echo Pushing Secure Messaging System to GitHub Repository...
echo Repository: https://github.com/vankayalateja515/secure_message_system.git
echo ========================================================
echo.

"C:\Users\ADMIN.DESKTOP-Q0I4REQ\AppData\Local\Programs\Git\cmd\git.exe" push -u origin main

echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================================
    echo SUCCESS! Project successfully pushed to GitHub!
    echo View repository at:
    echo https://github.com/vankayalateja515/secure_message_system
    echo ========================================================
) else (
    echo ========================================================
    echo PUSH FAILED. Please ensure you are logged in to GitHub.
    echo ========================================================
)
echo.
pause
