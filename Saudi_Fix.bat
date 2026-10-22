@echo off
:: ============================================================================
::  Saudi-Fix Tweaking Utility
::  Saudi-Fix (c) 2026 - Rashid Alghamdi. All rights reserved.
::  Official source: github.com/Scrim-Fix/Saudi-Fix
::
::  Free for personal use. Selling this file, redistributing it, publishing
::  modified copies, or presenting it as someone else's work is prohibited.
::  See the LICENSE file in the official repository.
::
::  Windows 10 / 11 optimization for gaming PCs and laptops:
::  fewer background processes, higher FPS, lower input latency.
::
::  Safety:
::   - a restore point is created on every launch, before any change
::   - original registry keys are exported on the first run
::   - every service, value and device setting is saved before it is changed,
::     so [R] Revert puts back exactly what the user had
::   - every change is logged to C:\SaudiFix\SaudiFix.log
::   - nothing is downloaded, nothing is installed
:: ============================================================================
setlocal EnableExtensions DisableDelayedExpansion
title Saudi-Fix Tweaking Utility - Rashid Alghamdi
set "SF_VER=2.0"
set "SF_DIR=%SystemDrive%\SaudiFix"
set "SF_LOG=%SystemDrive%\SaudiFix\SaudiFix.log"
set "SF_PLAN=5a0d1f1e-5a0d-4f1e-8000-000000000001"

:: ---------------------------------------------------------------- admin check
fltmc >nul 2>&1
if not errorlevel 1 goto :is_admin
echo.
echo   Requesting administrator rights...
powershell -NoProfile -NonInteractive -Command "Start-Process -FilePath '%~f0' -Verb RunAs" >nul 2>&1
if not errorlevel 1 exit /b
echo.
echo   Saudi-Fix needs administrator rights to apply tweaks.
echo   Right-click Saudi_Fix.bat and choose "Run as administrator".
echo.
pause
exit /b

:is_admin
cd /d "%~dp0"
chcp 65001 >nul 2>&1
reg add "HKCU\Console" /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: ---------------------------------------------------------------- colors
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "g=%ESC%[38;2;0;190;100m"
set "w=%ESC%[97m"
set "d=%ESC%[90m"
set "r=%ESC%[91m"
set "y=%ESC%[93m"
set "n=%ESC%[0m"
set "o=%g%[%w%"
set "c=%g%]%w%"
set "LINE=══════════════════════════════════════════════════════════════════════════════════════"
set "THIN=──────────────────────────────────────────────────────────────────────────────────────"

if not exist "%SF_DIR%" md "%SF_DIR%" >nul 2>&1
>>"%SF_LOG%" echo.
>>"%SF_LOG%" echo ===== Saudi-Fix %SF_VER% started %date% %time% =====

:: laptops get the power plan only on request, never from the preset
set "IS_LAPTOP=0"
for /f %%A in ('powershell -NoProfile -NonInteractive -Command "if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) {1} else {0}"') do set "IS_LAPTOP=%%A"
set "PC_TYPE=Desktop"
if "%IS_LAPTOP%"=="1" set "PC_TYPE=Laptop"

:: HKCU tweaks land in the elevated account, warn when that is not the signed-in user
set "SF_CONSOLE="
for /f "delims=" %%A in ('powershell -NoProfile -NonInteractive -Command "(Get-CimInstance Win32_ComputerSystem).UserName"') do set "SF_CONSOLE=%%A"
if not defined SF_CONSOLE goto :user_ok
if /i "%SF_CONSOLE%"=="%USERDOMAIN%\%USERNAME%" goto :user_ok
cls
echo.
echo   %y%  Saudi-Fix is running as %USERDOMAIN%\%USERNAME%, but %SF_CONSOLE% is signed in.%n%
echo   %w%  Personal settings - mouse, keyboard, notifications, visual effects - would be
echo   %w%  applied to %USERNAME% instead of you. Sign in with an administrator account
echo   %w%  and run Saudi-Fix from there for best results.
echo.
choice /c CQ /n /m "  %o%C%c% Continue anyway   %o%Q%c% Quit : "
if errorlevel 2 exit /b
:user_ok

:: ---------------------------------------------------------------- welcome
cls
call :banner
echo.
echo   %w%  This tool changes Windows settings to reduce background processes,
echo   %w%  raise FPS and lower input latency.
echo.
echo   %g%  ✔%w% A restore point is created automatically before anything is changed.
echo   %g%  ✔%w% Every change can be undone from the %g%[R] Revert%w% menu.
echo   %y%  ⚠%w% Options marked %y%(!)%w% have side effects. Options marked %r%(security)%w% lower protection.
echo   %y%  ⚠%w% Read every warning before pressing a key. Use at your own risk.
echo.
echo   %d%  Saudi-Fix © 2026 - Rashid Alghamdi. All rights reserved.
echo   %d%  Free for personal use. Selling, re-uploading or re-branding it is prohibited.
echo   %d%  Official download only: %w%github.com/Scrim-Fix/Saudi-Fix%d%
echo   %d%  Detected: %PC_TYPE%
echo.
echo   %g%%LINE%
echo   %w%  Press any key to continue...%n%
pause >nul

:: ---------------------------------------------------------------- backup + restore point
call :backup_original
goto :make_rp

:make_rp
cls
call :header "Restore Point" "Creating a mandatory restore point before any change"
echo   %w%  Please wait, this can take up to a minute...%n%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -NonInteractive -Command "Enable-ComputerRestore -Drive '%SystemDrive%\'; Checkpoint-Computer -Description 'Saudi-Fix Restore Point' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop" >nul 2>&1
if errorlevel 1 (set "RP_OK=0") else set "RP_OK=1"
:: put the Windows 24-hour restore point limit back
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v SystemRestorePointCreationFrequency /f >nul 2>&1
if "%RP_OK%"=="0" goto :rp_failed
call :log "Restore point created"
echo.
echo   %g%  ✔ Restore point created successfully.%n%
timeout /t 2 /nobreak >nul
goto :menu

:rp_failed
call :log "Restore point FAILED"
echo.
echo   %r%  ✖ Could not create a restore point.%n%
echo   %w%  System Protection may be turned off for drive %SystemDrive%.
echo   %w%  Without a restore point, the Revert menu is your only way back.
echo.
choice /c RCQ /n /m "  %o%R%c% Retry   %o%C%c% Continue without restore point   %o%Q%c% Quit : "
if errorlevel 3 exit /b
if errorlevel 2 goto :menu
goto :make_rp

:: ============================================================================
::  MAIN MENU
:: ============================================================================
:menu
cls
call :banner
echo.
echo        %o%1%c%  Process and Services Optimization   %d%Fewer background processes and services%w%
echo.
echo        %o%2%c%  FPS and Gaming Performance          %d%Game priority, GPU and visual effects%w%
echo.
echo        %o%3%c%  Input Latency                       %d%Mouse, keyboard and USB response%w%
echo.
echo        %o%4%c%  PC Clean and Memory                 %d%Temp files, shader cache and RAM%w%
echo.
echo        %o%5%c%  Power and CPU Tweaks %y%(!)%w%            %d%Power plan, throttling and timers%w%
echo.
echo        %o%6%c%  Debloat                             %d%Remove apps, ads and tracking%w%
echo.
echo        %o%7%c%  System Tools                        %d%Storage, repair and security options%w%
echo.
echo   %g%%LINE%
echo.
echo        %o%A%c% Apply Recommended   %o%R%c% Revert   %o%P%c% Restore Point   %o%H%c% Help   %o%X%c% Exit
echo.
echo   %g%%LINE%%n%
call :ask
if "%in%"=="1" goto :m_process
if "%in%"=="2" goto :m_fps
if "%in%"=="3" goto :m_input
if "%in%"=="4" goto :m_clean
if "%in%"=="5" goto :w_power
if "%in%"=="6" goto :m_debloat
if "%in%"=="7" goto :m_system
if /i "%in%"=="A" goto :m_preset
if /i "%in%"=="R" goto :m_revert
if /i "%in%"=="P" goto :m_restore
if /i "%in%"=="H" goto :m_help
if /i "%in%"=="X" exit /b
call :invalid
goto :menu

:: ============================================================================
::  1. PROCESS AND SERVICES OPTIMIZATION
:: ============================================================================
:m_process
call :proc_count
call :header "Process and Services Optimization" "Running now: %PC_ALL% processes - %PC_SVC% of them are svchost"
echo   %g%  Safe for desktops and laptops%w%
echo        %o%1%c% Group Svchost Processes          %o%2%c% Disable Telemetry Services
echo        %o%3%c% Disable Unneeded Services        %o%4%c% Disable Tracking Scheduled Tasks
echo        %o%5%c% Disable Widgets, Copilot, Chat   %o%6%c% Stop Edge Running In Background
echo        %o%7%c% Stop Update Sharing Uploads      %o%8%c% Disable Error Reporting
echo        %o%9%c% %g%Apply All Safe Options 1-8%w%
echo.
echo   %y%  Have side effects - each one asks first%w%
echo       %o%10%c% Background Store Apps %y%(!)%w%       %o%11%c% Search Indexing %y%(!)%w%
echo       %o%12%c% SysMain / Superfetch %y%(!)%w%        %o%13%c% Printing Services %y%(!)%w%
echo       %o%14%c% Bluetooth Services %y%(!)%w%          %o%15%c% Xbox Services %y%(!)%w%
echo       %o%16%c% Diagnostics Services %y%(!)%w%        %o%17%c% Phone Link, Nearby Share %y%(!)%w%
echo       %o%18%c% Automatic Maintenance %y%(!)%w%
echo.
echo        %o%S%c% Show What Is Running             %o%T%c% Open Startup Apps Manager
echo        %o%M%c% Back to menu
call :footer "Option 1 alone usually removes 30 to 50 processes. Restart to see the result."
call :ask
if "%in%"=="1" call :t_svchost & call :done & goto :m_process
if "%in%"=="2" call :t_telemetry & call :done & goto :m_process
if "%in%"=="3" call :t_services & call :done & goto :m_process
if "%in%"=="4" call :t_tasks & call :done & goto :m_process
if "%in%"=="5" call :t_copilot & call :done & goto :m_process
if "%in%"=="6" call :t_edge & call :done & goto :m_process
if "%in%"=="7" call :t_delivery & call :done & goto :m_process
if "%in%"=="8" call :t_wer & call :done & goto :m_process
if "%in%"=="9" call :p_safe & call :done & goto :m_process
if "%in%"=="10" goto :x_bgapps
if "%in%"=="11" goto :x_search
if "%in%"=="12" goto :x_sysmain
if "%in%"=="13" goto :x_print
if "%in%"=="14" goto :x_bluetooth
if "%in%"=="15" goto :x_xbox
if "%in%"=="16" goto :x_diag
if "%in%"=="17" goto :x_phonelink
if "%in%"=="18" goto :x_maintenance
if /i "%in%"=="S" goto :proc_report
if /i "%in%"=="T" start "" taskmgr.exe /0 /startup & goto :m_process
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_process

:p_safe
call :t_svchost
call :t_telemetry
call :t_services
call :t_tasks
call :t_copilot
call :t_edge
call :t_delivery
call :t_wer
exit /b

:proc_report
cls
call :header "What Is Running" "Top 20 processes by memory use"
powershell -NoProfile -NonInteractive -Command "Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 @{n='Process';e={$_.ProcessName}}, @{n='RAM (MB)';e={[math]::Round($_.WorkingSet64/1MB)}}, @{n='CPU (s)';e={[math]::Round($_.CPU)}} | Format-Table -AutoSize | Out-String -Width 100"
call :proc_count
echo   %w%  Total: %PC_ALL% processes, %PC_SVC% svchost.%n%
echo.
echo   %w%  Press any key to go back...%n%
pause >nul
goto :m_process

:x_bgapps
call :confirm "Store apps like WhatsApp, Teams and Phone Link stop getting messages in the background." "You will miss their notifications until you open them."
if errorlevel 1 goto :m_process
call :t_bgapps & call :done & goto :m_process

:x_search
call :confirm "Searching files from Start and File Explorer becomes much slower." "Outlook search may stop working. Apps and settings are still found."
if errorlevel 1 goto :m_process
call :step "Disable Windows Search indexing"
call :svc_off WSearch
call :done & goto :m_process

:x_sysmain
call :confirm "SysMain speeds up app launches, especially on hard drives (HDD)." "Disable it only if Windows is installed on an SSD."
if errorlevel 1 goto :m_process
call :step "Disable SysMain - Superfetch"
call :svc_off SysMain
call :done & goto :m_process

:x_print
call :confirm "You will not be able to print, scan to PC or use Microsoft Print to PDF." "Only continue if you do not use a printer."
if errorlevel 1 goto :m_process
call :step "Disable printing services"
call :svc_off Spooler
call :svc_off PrintNotify
call :done & goto :m_process

:x_bluetooth
call :confirm "Bluetooth headsets, controllers, mice and keyboards will stop working." "Most laptops use Bluetooth. Only continue if you never do."
if errorlevel 1 goto :m_process
call :step "Disable Bluetooth services"
for %%S in (BTAGService bthserv BthAvctpSvc BluetoothUserService) do call :svc_off %%S
call :done & goto :m_process

:x_xbox
call :confirm "Xbox app, Game Pass, Minecraft and other Xbox sign-in games and cloud saves stop working." "Xbox controllers keep working."
if errorlevel 1 goto :m_process
call :step "Disable Xbox services"
for %%S in (XblAuthManager XblGameSave XboxNetApiSvc) do call :svc_off %%S
call :done & goto :m_process

:x_diag
call :confirm "Windows troubleshooters and the network data usage page stop working." "Nothing else is affected. Revert brings them back."
if errorlevel 1 goto :m_process
call :step "Disable diagnostics services"
for %%S in (DPS WdiServiceHost WdiSystemHost) do call :svc_off %%S
call :done & goto :m_process

:x_phonelink
call :confirm "Phone Link, Nearby Sharing and clipboard sync between devices stop working." "Local copy and paste keeps working."
if errorlevel 1 goto :m_process
call :step "Disable Connected Devices Platform"
call :svc_manual CDPSvc
call :svc_off CDPUserSvc
call :done & goto :m_process

:x_maintenance
call :confirm "Windows stops its scheduled SSD TRIM, Defender scans and system cleanup." "Run System Tools - Optimize All Drives once a month yourself."
if errorlevel 1 goto :m_process
call :t_maintenance & call :done & goto :m_process

:t_svchost
call :step "Group svchost processes by installed RAM"
set "RAMKB="
for /f %%A in ('powershell -NoProfile -NonInteractive -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1KB)"') do set "RAMKB=%%A"
if not defined RAMKB exit /b
call :save_reg "HKLM\SYSTEM\CurrentControlSet\Control" SvcHostSplitThresholdInKB svchost
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d %RAMKB% /f >nul 2>&1
exit /b

:t_telemetry
call :step "Disable telemetry services and autologgers"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
call :svc_off DiagTrack
call :svc_off dmwappushservice
call :svc_off diagnosticshub.standardcollector.service
exit /b

:t_services
:: nothing here is needed by Wi-Fi, battery, sensors, touch, pen, fingerprint or sound
call :step "Disable unneeded background services"
for %%S in (MapsBroker RetailDemo Fax RemoteRegistry WMPNetworkSvc wisvc AJRouter) do call :svc_off %%S
for %%S in (PcaSvc TrkWks) do call :svc_manual %%S
exit /b

:t_tasks
call :step "Disable tracking and telemetry scheduled tasks"
call :tasks_list /disable
exit /b

:tasks_list
:: tasks_list /disable or /enable - the same list is used by Revert
for %%T in (
  "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
  "\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser Exp"
  "\Microsoft\Windows\Application Experience\ProgramDataUpdater"
  "\Microsoft\Windows\Application Experience\PcaPatchDbTask"
  "\Microsoft\Windows\Application Experience\MareBackup"
  "\Microsoft\Windows\Application Experience\StartupAppTask"
  "\Microsoft\Windows\Autochk\Proxy"
  "\Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
  "\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
  "\Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
  "\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
  "\Microsoft\Windows\Feedback\Siuf\DmClient"
  "\Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
  "\Microsoft\Windows\Maps\MapsToastTask"
  "\Microsoft\Windows\Maps\MapsUpdateTask"
  "\Microsoft\Windows\NetTrace\GatherNetworkInfo"
  "\Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem"
  "\Microsoft\Windows\Windows Error Reporting\QueueReporting"
  "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary"
  "\Microsoft\Windows\Speech\SpeechModelDownloadTask"
  "\Microsoft\Windows\RetailDemo\CleanupOfflineContent"
  "\Microsoft\Office\OfficeTelemetryAgentLogOn2016"
  "\Microsoft\Office\OfficeTelemetryAgentFallBack2016"
) do schtasks /change /tn %%T %~1 >nul 2>&1
exit /b

:t_copilot
call :step "Disable Widgets, Copilot and Teams Chat"
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1
exit /b

:t_edge
call :step "Stop Microsoft Edge running in the background"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_delivery
call :step "Stop uploading Windows updates to other PCs"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_wer
call :step "Disable Windows Error Reporting"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
call :svc_off WerSvc
exit /b

:t_bgapps
call :step "Disable background Store apps"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_maintenance
call :step "Disable automatic maintenance"
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:: ============================================================================
::  2. FPS AND GAMING PERFORMANCE
:: ============================================================================
:m_fps
call :header "FPS and Gaming Performance" "More CPU and GPU time for the game in front of you"
echo   %g%  Safe for desktops and laptops%w%
echo        %o%1%c% Enable Game Mode                 %o%2%c% Gaming Priority - MMCSS
echo        %o%3%c% Foreground CPU Priority          %o%4%c% Disable Fullscreen Optimizations
echo        %o%5%c% Disable Game DVR Recording       %o%6%c% Lower Network Latency
echo        %o%7%c% Visual Effects For Performance   %o%8%c% Optimize Windowed Games
echo        %o%9%c% %g%Apply All Safe Options 1-6%w%
echo.
echo   %y%  Hardware dependent - read before using%w%
echo       %o%10%c% Hardware GPU Scheduling         %o%11%c% Disable GPU Power Saving %y%(!)%w%
echo       %o%12%c% GPU MSI Mode %y%(!)%w%                %o%13%c% Clear Shader Cache
echo.
echo        %o%M%c% Back to menu
call :footer "Supports NVIDIA, AMD and Intel. Restart after applying."
call :ask
if "%in%"=="1" call :t_gamemode & call :done & goto :m_fps
if "%in%"=="2" call :t_mmcss & call :done & goto :m_fps
if "%in%"=="3" call :t_priosep & call :done & goto :m_fps
if "%in%"=="4" call :t_fso & call :done & goto :m_fps
if "%in%"=="5" call :t_gamedvr & call :done & goto :m_fps
if "%in%"=="6" call :t_nagle & call :done & goto :m_fps
if "%in%"=="7" call :t_visual & call :done & goto :m_fps
if "%in%"=="8" call :t_windowed & call :done & goto :m_fps
if "%in%"=="9" call :f_safe & call :done & goto :m_fps
if "%in%"=="10" call :t_hags & call :done & goto :m_fps
if "%in%"=="11" goto :x_gpupower
if "%in%"=="12" goto :x_msi
if "%in%"=="13" call :t_cleanshader & call :done & goto :m_fps
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_fps

:f_safe
call :t_gamemode
call :t_mmcss
call :t_priosep
call :t_fso
call :t_gamedvr
call :t_nagle
exit /b

:x_gpupower
call :confirm "The graphics card stays at full clock speed, even on the desktop." "More heat and power use. Not recommended on laptops."
if errorlevel 1 goto :m_fps
call :t_gpupower & call :done & goto :m_fps

:x_msi
call :confirm "MSI mode lowers GPU interrupt latency on most modern cards." "On very old GPUs it can cause a black screen. The restore point fixes it."
if errorlevel 1 goto :m_fps
call :t_msi & call :done & goto :m_fps

:t_gamemode
call :step "Enable Game Mode"
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:t_mmcss
call :step "Gaming priority - MMCSS profile"
set "K=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
reg add "%K%" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
reg add "%K%" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f >nul 2>&1
reg add "%K%\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "%K%\Tasks\Games" /v Priority /t REG_DWORD /d 6 /f >nul 2>&1
reg add "%K%\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d High /f >nul 2>&1
reg add "%K%\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d High /f >nul 2>&1
exit /b

:t_priosep
call :step "Foreground CPU priority - Win32PrioritySeparation 0x26"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 0x26 /f >nul 2>&1
exit /b

:t_fso
call :step "Disable fullscreen optimizations globally"
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:t_gamedvr
call :step "Disable Game DVR and background recording"
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AudioCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v HistoricalCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_nagle
call :step "Lower network latency - disable Nagle on all adapters"
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "{"') do (
  reg add "%%K" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
)
exit /b

:t_visual
call :step "Visual effects for performance - transparency and animations off"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
call :save_reg "HKCU\Control Panel\Desktop" UserPreferencesMask upm
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_windowed
call :step "Enable optimizations for windowed games"
:: merged into the existing string so Auto HDR and VRR settings are kept
powershell -NoProfile -NonInteractive -Command "$k = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'; if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }; $v = (Get-ItemProperty -Path $k -Name DirectXUserGlobalSettings -ErrorAction SilentlyContinue).DirectXUserGlobalSettings; $p = @(($v -split ';') | Where-Object { $_ -and $_ -notlike 'SwapEffectUpgradeEnable=*' }) + 'SwapEffectUpgradeEnable=1'; Set-ItemProperty -Path $k -Name DirectXUserGlobalSettings -Value (($p -join ';') + ';')" >nul 2>&1
exit /b

:t_hags
call :step "Enable hardware-accelerated GPU scheduling"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
exit /b

:t_gpupower
call :step "Disable GPU power saving - NVIDIA PowerMizer, AMD ULPS"
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /b "HKEY"') do (
  reg query "%%K" /v DriverDesc 2>nul | findstr /i "NVIDIA" >nul && (
    reg add "%%K" /v PerfLevelSrc /t REG_DWORD /d 0x2222 /f >nul 2>&1
    reg add "%%K" /v PowerMizerEnable /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "%%K" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
  )
  reg query "%%K" /v DriverDesc 2>nul | findstr /i "AMD Radeon" >nul && (
    reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  )
)
exit /b

:t_msi
call :step "Enable MSI mode for display adapters"
powershell -NoProfile -NonInteractive -Command "Get-PnpDevice -Class Display -PresentOnly | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; New-Item -Path $p -Force | Out-Null; Set-ItemProperty -Path $p -Name MSISupported -Value 1 -Type DWord }" >nul 2>&1
exit /b

:: ============================================================================
::  3. INPUT LATENCY
:: ============================================================================
:m_input
call :header "Input Latency" "Raw mouse movement, faster keyboard and no USB sleep"
echo   %g%  Mouse and keyboard%w%
echo        %o%1%c% Disable Mouse Acceleration       %o%2%c% Faster Keyboard Repeat
echo        %o%3%c% Disable Sticky/Filter Keys       %o%4%c% Smaller Input Buffer
echo.
echo   %g%  USB and responsiveness%w%
echo        %o%5%c% Disable USB Selective Suspend    %o%6%c% Disable Device Power Saving
echo        %o%7%c% Disable USB Hub Power Saving     %o%8%c% Faster Menus and Shutdown
echo.
echo        %o%9%c% %g%Apply All Options 1-8%w%
echo        %o%M%c% Back to menu
call :footer "Fixes mouse lag spikes and USB disconnects. Sign out or restart to apply."
call :ask
if "%in%"=="1" call :t_mouseaccel & call :done & goto :m_input
if "%in%"=="2" call :t_keyboard & call :done & goto :m_input
if "%in%"=="3" call :t_stickykeys & call :done & goto :m_input
if "%in%"=="4" call :t_queue & call :done & goto :m_input
if "%in%"=="5" call :t_usbsuspend & call :done & goto :m_input
if "%in%"=="6" call :t_devpower & call :done & goto :m_input
if "%in%"=="7" call :t_usbhub & call :done & goto :m_input
if "%in%"=="8" call :t_fastui & call :done & goto :m_input
if "%in%"=="9" call :i_all & call :done & goto :m_input
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_input

:i_all
call :t_mouseaccel
call :t_keyboard
call :t_stickykeys
call :t_queue
call :t_usbsuspend
call :t_devpower
call :t_usbhub
call :t_fastui
exit /b

:t_mouseaccel
call :step "Disable mouse acceleration - Enhance pointer precision off"
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >nul 2>&1
exit /b

:t_keyboard
call :step "Faster keyboard repeat"
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d 31 /f >nul 2>&1
exit /b

:t_stickykeys
call :step "Disable Sticky, Filter and Toggle keys shortcuts"
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 506 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d 122 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d 58 /f >nul 2>&1
exit /b

:t_queue
call :step "Smaller mouse and keyboard input buffers"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t REG_DWORD /d 50 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 50 /f >nul 2>&1
exit /b

:t_usbsuspend
call :step "Disable USB selective suspend"
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg -setactive scheme_current >nul 2>&1
exit /b

:t_devpower
call :step "Disable 'allow the computer to turn off this device'"
:: each device's original state is saved first so Revert puts back exactly that
powershell -NoProfile -NonInteractive -Command "$bk = Join-Path $env:SF_DIR 'Backup\device_power.csv'; $d = Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue; if (-not (Test-Path $bk)) { New-Item -ItemType Directory -Force -Path (Split-Path $bk) | Out-Null; $d | Select-Object InstanceName, Enable | Export-Csv -NoTypeInformation -Path $bk }; $d | ForEach-Object { Set-CimInstance -InputObject $_ -Property @{Enable=$false} -ErrorAction SilentlyContinue }" >nul 2>&1
exit /b

:t_usbhub
call :step "Disable USB hub and device power management"
powershell -NoProfile -NonInteractive -Command "$bk = Join-Path $env:SF_DIR 'Backup\usb_power.csv'; $names = 'EnhancedPowerManagementEnabled','AllowIdleIrpInD3'; $keys = Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Enum\USB' -Recurse -ErrorAction SilentlyContinue | Where-Object PSChildName -eq 'Device Parameters'; if (-not (Test-Path $bk)) { New-Item -ItemType Directory -Force -Path (Split-Path $bk) | Out-Null; $keys | ForEach-Object { $k = $_.PSPath; foreach ($n in $names) { [pscustomobject]@{ Key = $k; Name = $n; Value = (Get-ItemProperty -Path $k -Name $n -ErrorAction SilentlyContinue).$n } } } | Export-Csv -NoTypeInformation -Path $bk }; $keys | ForEach-Object { foreach ($n in $names) { Set-ItemProperty -Path $_.PSPath -Name $n -Value 0 -Type DWord -ErrorAction SilentlyContinue } }" >nul 2>&1
exit /b

:t_fastui
call :step "Faster menus and shutdown"
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 2000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 1000 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseHoverTime /t REG_SZ /d 10 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:: ============================================================================
::  4. PC CLEAN AND MEMORY
:: ============================================================================
:m_clean
call :header "PC Clean and Memory" "Free disk space and keep RAM for your games"
echo   %g%  Cleaning%w%
echo        %o%1%c% Temporary Files                  %o%2%c% GPU Shader Cache
echo        %o%3%c% Windows Update Cache             %o%4%c% Empty Recycle Bin
echo        %o%5%c% %g%Clean Everything 1-4%w%
echo        %o%6%c% Component Store Cleanup          %o%7%c% Open Disk Cleanup
echo.
echo   %g%  Memory%w%
echo        %o%8%c% Keep Kernel In RAM               %o%9%c% Disable Memory Compression %y%(!)%w%
echo.
echo        %o%M%c% Back to menu
call :footer "Files in use are skipped. Games rebuild shader cache on first launch."
call :ask
if "%in%"=="1" call :t_cleantemp & call :done & goto :m_clean
if "%in%"=="2" call :t_cleanshader & call :done & goto :m_clean
if "%in%"=="3" call :t_cleanwu & call :done & goto :m_clean
if "%in%"=="4" call :t_cleanbin & call :done & goto :m_clean
if "%in%"=="5" call :t_cleantemp & call :t_cleanshader & call :t_cleanwu & call :t_cleanbin & call :done & goto :m_clean
if "%in%"=="6" call :t_cleandism & call :done & goto :m_clean
if "%in%"=="7" start "" cleanmgr.exe /d %SystemDrive% & goto :m_clean
if "%in%"=="8" call :t_pagingexec & call :done & goto :m_clean
if "%in%"=="9" goto :x_memcomp
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_clean

:x_memcomp
call :confirm "On PCs with 8 GB RAM or less this can make games stutter more." "Recommended only with 16 GB RAM or more."
if errorlevel 1 goto :m_clean
call :t_memcomp & call :done & goto :m_clean

:t_cleantemp
call :step "Cleaning temporary files"
call :wipe "%TEMP%"
call :wipe "%SystemRoot%\Temp"
call :wipe "%LOCALAPPDATA%\CrashDumps"
exit /b

:t_cleanshader
call :step "Cleaning DirectX, NVIDIA, AMD and Intel shader cache"
call :wipe "%LOCALAPPDATA%\D3DSCache"
call :wipe "%LOCALAPPDATA%\NVIDIA\DXCache"
call :wipe "%LOCALAPPDATA%\NVIDIA\GLCache"
call :wipe "%ProgramData%\NVIDIA Corporation\NV_Cache"
call :wipe "%LOCALAPPDATA%\AMD\DxCache"
call :wipe "%LOCALAPPDATA%\AMD\DxcCache"
call :wipe "%LOCALAPPDATA%\AMD\VkCache"
call :wipe "%LOCALAPPDATA%\AMD\GLCache"
call :wipe "%LOCALAPPDATA%\Intel\ShaderCache"
call :wipe "%USERPROFILE%\AppData\LocalLow\Intel\ShaderCache"
exit /b

:t_cleanwu
call :step "Cleaning Windows Update download cache"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
call :wipe "%SystemRoot%\SoftwareDistribution\Download"
net start bits >nul 2>&1
net start wuauserv >nul 2>&1
exit /b

:t_cleanbin
call :step "Emptying Recycle Bin"
powershell -NoProfile -NonInteractive -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
exit /b

:t_cleandism
call :step "Cleaning component store - this can take several minutes"
dism /online /cleanup-image /startcomponentcleanup
exit /b

:t_pagingexec
call :step "Keep kernel and drivers in RAM - DisablePagingExecutive"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:t_memcomp
call :step "Disable memory compression"
powershell -NoProfile -NonInteractive -Command "Disable-MMAgent -MemoryCompression" >nul 2>&1
exit /b

:: ============================================================================
::  5. POWER AND CPU
:: ============================================================================
:w_power
call :header "Power and CPU Tweaks - Warning" "Read before continuing"
echo   %y%  These tweaks make the PC run at full power all the time.%w%
echo.
echo     - Desktop PCs: recommended.
echo     - Laptops: more heat and less battery. Use only while plugged in.
echo     - Options marked (security) turn off protections against CPU attacks and
echo       kernel exploits. Only use them on a PC used for gaming.
echo     - Some anti-cheat systems need Core Isolation to stay on.
echo     - Every option here can be reverted from the Revert menu.
echo.
echo   %d%  Detected: %PC_TYPE%%w%
echo.
choice /c CM /n /m "  %o%C%c% Continue   %o%M%c% Back to menu : "
if errorlevel 2 goto :menu
goto :m_power

:m_power
call :header "Power and CPU Tweaks" "Power plan, throttling, core parking and timers"
echo   %g%  Power%w%
echo        %o%1%c% Saudi-Fix Ultimate Power Plan    %o%2%c% Disable Power Throttling
echo        %o%3%c% Disable Core Parking             %o%4%c% Disable Hibernation %y%(!)%w%
echo.
echo   %g%  CPU%w%
echo        %o%5%c% Optimize System Timer            %o%6%c% Disable Spectre/Meltdown Fix %r%(security)%w%
echo        %o%7%c% Disable Core Isolation - VBS %r%(security)%w%
echo.
echo        %o%8%c% Open Power Options
echo        %o%M%c% Back to menu
call :footer "The power plan disables CPU, PCIe, USB and disk power saving on AC power."
call :ask
if "%in%"=="1" goto :x_powerplan
if "%in%"=="2" call :t_throttle & call :done & goto :m_power
if "%in%"=="3" call :t_parking & call :done & goto :m_power
if "%in%"=="4" goto :x_hiber
if "%in%"=="5" call :t_timer & call :done & goto :m_power
if "%in%"=="6" goto :x_spectre
if "%in%"=="7" goto :x_vbs
if "%in%"=="8" start "" control.exe powercfg.cpl & goto :m_power
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_power

:x_powerplan
if not "%IS_LAPTOP%"=="1" goto :x_powerplan_go
call :confirm "This is a laptop. The Ultimate plan keeps the CPU at full speed while plugged in." "Switch back to Balanced in Power Options when you run on battery."
if errorlevel 1 goto :m_power
:x_powerplan_go
call :t_powerplan & call :done & goto :m_power

:x_hiber
call :confirm "Hibernation and Fast Startup are turned off and hiberfil.sys is deleted." "Laptops will not hibernate when the battery runs low."
if errorlevel 1 goto :m_power
call :step "Disable hibernation"
powercfg /h off >nul 2>&1
call :done & goto :m_power

:x_spectre
call :confirm "This turns off Windows protection against Spectre and Meltdown CPU attacks." "Gains are small on new CPUs. Do not use on a PC with sensitive data."
if errorlevel 1 goto :m_power
call :t_spectre & call :done & goto :m_power

:x_vbs
call :confirm "This turns off Core Isolation, Memory Integrity and Virtualization Based Security." "It can give extra FPS but makes the kernel easier to attack."
if errorlevel 1 goto :m_power
call :t_vbs & call :done & goto :m_power

:t_powerplan
call :step "Create and activate Saudi-Fix Ultimate power plan"
powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
powercfg -delete %SF_PLAN% >nul 2>&1
powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 %SF_PLAN% >nul 2>&1
if errorlevel 1 powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c %SF_PLAN% >nul 2>&1
if errorlevel 1 powercfg -duplicatescheme 381b4222-f694-41f0-9685-ff5bb260df2e %SF_PLAN% >nul 2>&1
powercfg -changename %SF_PLAN% "Saudi-Fix Ultimate" "Maximum performance plan by Saudi-Fix" >nul 2>&1
powercfg -setacvalueindex %SF_PLAN% 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
powercfg -setacvalueindex %SF_PLAN% 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg -setacvalueindex %SF_PLAN% 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg -setacvalueindex %SF_PLAN% 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg -setacvalueindex %SF_PLAN% 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
powercfg -setacvalueindex %SF_PLAN% 238c9fa8-0aad-41ed-83f4-97be242c8f20 29f6c1db-86da-48c5-9fdb-f2b67b1f44da 0 >nul 2>&1
powercfg -setactive %SF_PLAN% >nul 2>&1
exit /b

:t_throttle
call :step "Disable power throttling"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:t_parking
call :step "Disable core parking and keep CPU at full speed on AC power"
powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg -setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 100 >nul 2>&1
powercfg -setactive scheme_current >nul 2>&1
exit /b

:t_timer
call :step "Optimize system timer"
call :bitlocker_pause
bcdedit /set disabledynamictick yes >nul 2>&1
bcdedit /deletevalue useplatformclock >nul 2>&1
exit /b

:t_spectre
call :step "Disable Spectre and Meltdown mitigations"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
exit /b

:t_vbs
call :step "Disable Core Isolation and VBS"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:: ============================================================================
::  6. DEBLOAT
:: ============================================================================
:m_debloat
call :header "Debloat" "Remove preinstalled apps, ads and tracking"
echo   %g%  Safe - can be reverted%w%
echo        %o%1%c% Disable Ads, Tips, Auto Installs %o%2%c% Disable Notifications
echo        %o%3%c% Disable Cortana                  %o%4%c% Disable Activity History
echo        %o%5%c% Disable Customer Experience      %o%6%c% Disable Office Telemetry
echo        %o%7%c% Disable Settings Sync            %o%8%c% Disable Web Results In Search
echo        %o%9%c% %g%Apply All Options 1-8%w%
echo.
echo   %y%  Permanent - cannot be reverted%w%
echo       %o%10%c% Uninstall Bloatware Apps %y%(!)%w%
echo.
echo        %o%M%c% Back to menu
call :footer "Uninstalled apps can be reinstalled from the Microsoft Store."
call :ask
if "%in%"=="1" call :t_ads & call :done & goto :m_debloat
if "%in%"=="2" call :t_notifications & call :done & goto :m_debloat
if "%in%"=="3" call :t_cortana & call :done & goto :m_debloat
if "%in%"=="4" call :t_activity & call :done & goto :m_debloat
if "%in%"=="5" call :t_ceip & call :done & goto :m_debloat
if "%in%"=="6" call :t_office & call :done & goto :m_debloat
if "%in%"=="7" call :t_sync & call :done & goto :m_debloat
if "%in%"=="8" call :t_websearch & call :done & goto :m_debloat
if "%in%"=="9" call :d_all & call :done & goto :m_debloat
if "%in%"=="10" goto :x_apps
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_debloat

:d_all
call :t_ads
call :t_notifications
call :t_cortana
call :t_activity
call :t_ceip
call :t_office
call :t_sync
call :t_websearch
exit /b

:x_apps
echo.
echo   %w%  These apps will be uninstalled for all users:
echo   %d%  News, Weather, Bing Search, Tips, Solitaire, People, Feedback Hub, Movies and TV,
echo   %d%  Maps, Office Hub, Skype, To Do, Power Automate, Clipchamp, Cortana, 3D Viewer,
echo   %d%  Paint 3D, Mixed Reality Portal, OneNote for Windows 10, Mail and Calendar,
echo   %d%  Teams personal chat, Copilot app, Dev Home
echo.
echo   %g%  Kept:%d% Store, Xbox app, Photos, Paint, Notepad, Calculator, Clock, Snipping Tool,
echo   %d%  Media Player, Camera, Phone Link, Edge, OneDrive
call :confirm "Apps are removed for every user on this PC." "Revert cannot bring them back - reinstall them from the Microsoft Store."
if errorlevel 1 goto :m_debloat
call :t_apps & call :done & goto :m_debloat

:t_ads
call :step "Disable ads, tips, suggestions and silent app installs"
set "K=HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%V in (ContentDeliveryAllowed OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled SilentInstalledAppsEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SoftLandingEnabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled) do (
  reg add "%K%" /v %%V /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:t_notifications
call :step "Disable notifications"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_cortana
call :step "Disable Cortana"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_activity
call :step "Disable activity history"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_ceip
call :step "Disable Customer Experience Improvement Program"
reg add "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\SQMClient\Windows" /v CEIPEnable /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_office
call :step "Disable Office telemetry"
reg add "HKCU\Software\Microsoft\Office\Common\ClientTelemetry" /v DisableTelemetry /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\Common\ClientTelemetry" /v SendTelemetry /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\Common" /v sendcustomerdata /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\Common" /v qmenable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\Common" /v updatereliabilitydata /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\Common\Feedback" /v enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\Common\Feedback" /v includescreenshot /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\Common\ptwatson" /v ptwoptin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\OSM" /v Enablelogging /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Office\16.0\OSM" /v EnableUpload /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_sync
call :step "Disable settings synchronization"
for %%G in (Accessibility AppSync BrowserSettings Credentials DesktopTheme Language PackageState Personalization StartLayout Windows) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\%%G" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
)
exit /b

:t_websearch
call :step "Disable Bing web results in Start search"
reg add "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:t_apps
call :step "Uninstalling bloatware apps - please wait"
powershell -NoProfile -NonInteractive -Command "$apps = 'Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSearch','Microsoft.Getstarted','Microsoft.MicrosoftSolitaireCollection','Microsoft.People','Microsoft.WindowsFeedbackHub','Microsoft.ZuneVideo','Microsoft.WindowsMaps','Microsoft.MicrosoftOfficeHub','Microsoft.SkypeApp','Microsoft.Todos','Microsoft.PowerAutomateDesktop','Clipchamp.Clipchamp','Microsoft.549981C3F5F10','Microsoft.Microsoft3DViewer','Microsoft.MSPaint','Microsoft.MixedReality.Portal','Microsoft.Office.OneNote','microsoft.windowscommunicationsapps','MicrosoftTeams','Microsoft.Copilot','Microsoft.Windows.DevHome'; foreach ($a in $apps) { Get-AppxPackage -AllUsers -Name $a | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online | Where-Object DisplayName -eq $a | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null }" >nul 2>&1
exit /b

:: ============================================================================
::  7. SYSTEM TOOLS
:: ============================================================================
:m_system
call :header "System Tools" "Storage, Windows repair and security options"
echo   %g%  Storage%w%
echo        %o%1%c% Optimize All Drives - TRIM       %o%2%c% Enable Disk Write Cache %y%(!)%w%
echo        %o%3%c% Disable Last Access Timestamp    %o%4%c% Disable 8.3 Short Names
echo.
echo   %g%  Repair%w%
echo        %o%5%c% SFC /scannow                     %o%6%c% DISM RestoreHealth
echo        %o%7%c% Check Disk - online scan         %o%8%c% Reset Network %y%(!)%w%
echo        %o%9%c% Flush DNS Cache
echo.
echo   %g%  Windows Update and security%w%
echo       %o%10%c% Block Driver Updates Via WU     %o%11%c% Disable SmartScreen %r%(security)%w%
echo.
echo        %o%M%c% Back to menu
call :footer "Windows acting strange? Run 6 first, then 5."
call :ask
if "%in%"=="1" call :t_optimize & call :done & goto :m_system
if "%in%"=="2" goto :x_writecache
if "%in%"=="3" call :t_lastaccess & call :done & goto :m_system
if "%in%"=="4" call :t_8dot3 & call :done & goto :m_system
if "%in%"=="5" call :step "Running SFC" & sfc /scannow & call :done & goto :m_system
if "%in%"=="6" call :step "Running DISM RestoreHealth" & dism /online /cleanup-image /restorehealth & call :done & goto :m_system
if "%in%"=="7" call :step "Running CHKDSK online scan" & chkdsk %SystemDrive% /scan & call :done & goto :m_system
if "%in%"=="8" goto :x_netreset
if "%in%"=="9" call :step "Flushing DNS cache" & ipconfig /flushdns >nul 2>&1 & call :done & goto :m_system
if "%in%"=="10" call :t_wudrivers & call :done & goto :m_system
if "%in%"=="11" goto :x_smartscreen
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_system

:x_writecache
call :confirm "Write caching is faster, but a power cut can corrupt files being written." "Recommended for laptops or desktops with stable power. USB drives are skipped."
if errorlevel 1 goto :m_system
call :t_writecache & call :done & goto :m_system

:x_netreset
call :confirm "Network settings are reset. VPN and custom DNS settings may be lost." "A restart is required afterwards."
if errorlevel 1 goto :m_system
call :step "Resetting network stack"
netsh winsock reset >nul 2>&1
netsh int ip reset >nul 2>&1
ipconfig /release >nul 2>&1
ipconfig /renew >nul 2>&1
ipconfig /flushdns >nul 2>&1
call :done & goto :m_system

:x_smartscreen
call :confirm "SmartScreen protects you from malicious downloads and apps." "Disabling it lowers your security for almost no performance gain."
if errorlevel 1 goto :m_system
call :t_smartscreen & call :done & goto :m_system

:t_optimize
call :step "Optimizing all drives"
defrag /C /O /H /U
exit /b

:t_writecache
call :step "Enable disk write cache"
:: USB flash drives and external disks are skipped - they get unplugged without ejecting
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /f "{4d36e967-e325-11ce-bfc1-08002be10318}" /d /s 2^>nul ^| findstr /b "HKEY" ^| findstr /v /i "USBSTOR"') do (
  reg add "%%K\Device Parameters\Disk" /v UserWriteCacheSetting /t REG_DWORD /d 1 /f >nul 2>&1
)
exit /b

:t_lastaccess
call :step "Disable NTFS last access timestamp"
call :save_reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" NtfsDisableLastAccessUpdate lastaccess
fsutil behavior set disablelastaccess 1 >nul 2>&1
exit /b

:t_8dot3
call :step "Disable 8.3 short name creation"
call :save_reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" NtfsDisable8dot3NameCreation 8dot3
fsutil behavior set disable8dot3 1 >nul 2>&1
exit /b

:t_wudrivers
call :step "Stop Windows Update from replacing your drivers"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:t_smartscreen
call :step "Disable SmartScreen"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d Off /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:: ============================================================================
::  A. RECOMMENDED PRESET
:: ============================================================================
:m_preset
call :header "Apply Recommended" "One key, safe tweaks only"
echo   %w%  Applies only safe tweaks - nothing marked (!) or (security):
echo.
echo   %d%    1 Processes: svchost grouping, telemetry, unneeded services, tracking tasks,
echo   %d%                 Widgets/Copilot, Edge background, update uploads, error reporting
echo   %d%    2 FPS:       Game Mode, MMCSS, CPU priority, fullscreen opt., Game DVR, network
echo   %d%    3 Input:     mouse acceleration off, sticky keys off, USB selective suspend off
echo   %d%    4 Clean:     temporary files
echo   %d%    5 Power:     Saudi-Fix Ultimate power plan - desktops only
echo   %d%    6 Debloat:   ads and tips, customer experience program
echo.
if "%IS_LAPTOP%"=="1" echo   %y%    Laptop detected - the power plan is skipped to protect your battery.%n%
if "%IS_LAPTOP%"=="1" echo.
choice /c AM /n /m "  %o%A%c% Apply   %o%M%c% Back to menu : "
if errorlevel 2 goto :menu
call :p_safe
call :f_safe
call :t_mouseaccel
call :t_stickykeys
call :t_usbsuspend
call :t_cleantemp
if not "%IS_LAPTOP%"=="1" call :t_powerplan
call :t_ads
call :t_ceip
call :done
goto :menu

:: ============================================================================
::  R. REVERT
:: ============================================================================
:m_revert
call :header "Revert" "Put back your original settings, section by section"
echo        %o%1%c% Process and Services             %o%2%c% FPS and Gaming
echo        %o%3%c% Input Latency                    %o%4%c% PC Clean and Memory
echo        %o%5%c% Power and CPU                    %o%6%c% Debloat
echo        %o%7%c% System Tools
echo.
echo        %o%8%c% %g%Revert Everything%w%
echo        %o%M%c% Back to menu
call :footer "Uninstalled apps and cleaned files cannot be brought back by Revert."
call :ask
if "%in%"=="1" call :rv_process & call :done & goto :m_revert
if "%in%"=="2" call :rv_fps & call :done & goto :m_revert
if "%in%"=="3" call :rv_input & call :done & goto :m_revert
if "%in%"=="4" call :rv_memory & call :done & goto :m_revert
if "%in%"=="5" call :rv_power & call :done & goto :m_revert
if "%in%"=="6" call :rv_debloat & call :done & goto :m_revert
if "%in%"=="7" call :rv_system & call :done & goto :m_revert
if "%in%"=="8" goto :x_revertall
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_revert

:x_revertall
call :confirm "Every Saudi-Fix change in every section is set back to your original settings." "Custom power plans are reset to the Windows defaults."
if errorlevel 1 goto :m_revert
call :rv_process & call :rv_fps & call :rv_input & call :rv_memory
call :rv_power & call :rv_debloat & call :rv_system
call :done & goto :m_revert

:rv_process
call :step "Revert process and services tweaks"
call :restore_reg "HKLM\SYSTEM\CurrentControlSet\Control" SvcHostSplitThresholdInKB svchost || reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d 3670016 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Siuf\Rules" /v NumberOfSIUFInPeriod /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AutoLogger-Diagtrack-Listener" /v Start /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger" /v Start /t REG_DWORD /d 1 /f >nul 2>&1
call :svc_restore DiagTrack auto
call :svc_restore dmwappushservice demand
call :svc_restore diagnosticshub.standardcollector.service demand
call :svc_restore MapsBroker delayed-auto
call :svc_restore RetailDemo demand
call :svc_restore Fax demand
call :svc_restore RemoteRegistry disabled
call :svc_restore WMPNetworkSvc demand
call :svc_restore wisvc demand
call :svc_restore AJRouter demand
call :svc_restore PcaSvc auto
call :svc_restore TrkWks auto
call :tasks_list /enable
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v StartupBoostEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v BackgroundModeEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 0 /f >nul 2>&1
call :svc_restore WerSvc demand
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BackgroundAppGlobalToggle /f >nul 2>&1
call :svc_restore WSearch delayed-auto
call :svc_restore SysMain auto
call :svc_restore Spooler auto
call :svc_restore PrintNotify demand
for %%S in (BTAGService bthserv BthAvctpSvc BluetoothUserService) do call :svc_restore %%S demand
for %%S in (XblAuthManager XblGameSave XboxNetApiSvc) do call :svc_restore %%S demand
call :svc_restore DPS auto
call :svc_restore WdiServiceHost demand
call :svc_restore WdiSystemHost demand
call :svc_restore CDPSvc delayed-auto
call :svc_restore CDPUserSvc auto
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\Maintenance" /v MaintenanceDisabled /f >nul 2>&1
exit /b

:rv_fps
call :step "Revert FPS and gaming tweaks"
set "K=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
reg add "%K%" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
reg add "%K%" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
reg add "%K%\Tasks\Games" /v Priority /t REG_DWORD /d 2 /f >nul 2>&1
reg add "%K%\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d Medium /f >nul 2>&1
reg add "%K%\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d Normal /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AudioCaptureEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v HistoricalCaptureEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v AllowGameDVR /f >nul 2>&1
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul ^| findstr /i "{"') do (
  reg delete "%%K" /v TcpAckFrequency /f >nul 2>&1
  reg delete "%%K" /v TCPNoDelay /f >nul 2>&1
)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 1 /f >nul 2>&1
call :restore_reg "HKCU\Control Panel\Desktop" UserPreferencesMask upm || reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9e3e078012000000 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
powershell -NoProfile -NonInteractive -Command "$k = 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences'; $v = (Get-ItemProperty -Path $k -Name DirectXUserGlobalSettings -ErrorAction SilentlyContinue).DirectXUserGlobalSettings; if ($v) { $p = @(($v -split ';') | Where-Object { $_ -and $_ -notlike 'SwapEffectUpgradeEnable=*' }); if ($p.Count) { Set-ItemProperty -Path $k -Name DirectXUserGlobalSettings -Value (($p -join ';') + ';') } else { Remove-ItemProperty -Path $k -Name DirectXUserGlobalSettings } }" >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /f >nul 2>&1
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /b "HKEY"') do (
  reg delete "%%K" /v PerfLevelSrc /f >nul 2>&1
  reg delete "%%K" /v PowerMizerEnable /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevel /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevelAC /f >nul 2>&1
  reg query "%%K" /v EnableUlps >nul 2>&1 && reg add "%%K" /v EnableUlps /t REG_DWORD /d 1 /f >nul 2>&1
)
powershell -NoProfile -NonInteractive -Command "Get-PnpDevice -Class Display -PresentOnly | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if (Test-Path $p) { Remove-ItemProperty -Path $p -Name MSISupported -ErrorAction SilentlyContinue } }" >nul 2>&1
exit /b

:rv_input
call :step "Revert input latency tweaks"
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 6 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 10 /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d 31 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 510 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t REG_SZ /d 126 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d 62 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /f >nul 2>&1
powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg -setactive scheme_current >nul 2>&1
powershell -NoProfile -NonInteractive -Command "$bk = Join-Path $env:SF_DIR 'Backup\device_power.csv'; if (Test-Path $bk) { $s = @{}; Import-Csv $bk | ForEach-Object { $s[$_.InstanceName] = ($_.Enable -eq 'True') }; Get-CimInstance -Namespace root\wmi -ClassName MSPower_DeviceEnable -ErrorAction SilentlyContinue | Where-Object { $s.ContainsKey($_.InstanceName) } | ForEach-Object { Set-CimInstance -InputObject $_ -Property @{Enable=$s[$_.InstanceName]} -ErrorAction SilentlyContinue }; Remove-Item $bk }" >nul 2>&1
powershell -NoProfile -NonInteractive -Command "$bk = Join-Path $env:SF_DIR 'Backup\usb_power.csv'; if (Test-Path $bk) { Import-Csv $bk | ForEach-Object { if ($_.Value -eq '') { Remove-ItemProperty -Path $_.Key -Name $_.Name -ErrorAction SilentlyContinue } else { Set-ItemProperty -Path $_.Key -Name $_.Name -Value ([int]$_.Value) -Type DWord -ErrorAction SilentlyContinue } }; Remove-Item $bk }" >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 400 /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /f >nul 2>&1
reg delete "HKCU\Control Panel\Desktop" /v HungAppTimeout /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseHoverTime /t REG_SZ /d 400 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 5000 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /f >nul 2>&1
exit /b

:rv_memory
call :step "Revert memory tweaks"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -NonInteractive -Command "Enable-MMAgent -MemoryCompression" >nul 2>&1
exit /b

:rv_power
call :step "Revert power and CPU tweaks"
powercfg -restoredefaultschemes >nul 2>&1
powercfg /h on >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1
bcdedit /enum {current} | findstr /i "disabledynamictick" >nul 2>&1 && call :bitlocker_pause && bcdedit /deletevalue disabledynamictick >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
:: Memory Integrity is never forced back on from here - with an incompatible
:: driver installed that can stop Windows from booting. Windows Security checks
:: drivers before enabling it, so the user turns it on there.
reg query "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled 2>nul | findstr /i "0x0" >nul || exit /b
echo   %y%  Turn Memory Integrity back on in the Windows Security window that opens now.%n%
start "" windowsdefender://coreisolation
exit /b

:rv_debloat
call :step "Revert debloat tweaks"
set "K=HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
for %%V in (ContentDeliveryAllowed OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled SilentInstalledAppsEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SoftLandingEnabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled) do (
  reg add "%K%" /v %%V /t REG_DWORD /d 1 /f >nul 2>&1
)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableWindowsConsumerFeatures /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_NOTIFICATION_SOUND /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" /v NOC_GLOBAL_SETTING_ALLOW_CRITICAL_TOASTS_ABOVE_LOCK /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Windows.SystemToast.SecurityAndMaintenance" /v Enabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCloudSearch /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\SQMClient\Windows" /v CEIPEnable /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Office\Common\ClientTelemetry" /v DisableTelemetry /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Office\Common\ClientTelemetry" /v SendTelemetry /f >nul 2>&1
for %%G in (Accessibility AppSync BrowserSettings Credentials DesktopTheme Language PackageState Personalization StartLayout Windows) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SettingSync\Groups\%%G" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
)
reg delete "HKCU\Software\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /f >nul 2>&1
exit /b

:rv_system
call :step "Revert system tools tweaks"
for /f "delims=" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Enum" /f "{4d36e967-e325-11ce-bfc1-08002be10318}" /d /s 2^>nul ^| findstr /b "HKEY"') do (
  reg delete "%%K\Device Parameters\Disk" /v UserWriteCacheSetting /f >nul 2>&1
)
call :restore_reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" NtfsDisableLastAccessUpdate lastaccess || fsutil behavior set disablelastaccess 2 >nul 2>&1
call :restore_reg "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" NtfsDisable8dot3NameCreation 8dot3 || fsutil behavior set disable8dot3 2 >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v ExcludeWUDriversInQualityUpdate /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableSmartScreen /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d Warn /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v EnableWebContentEvaluation /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:: ============================================================================
::  P. RESTORE POINT
:: ============================================================================
:m_restore
call :header "Restore Point" "Go back to how your PC was before Saudi-Fix"
echo        %o%1%c% Open System Restore              %o%2%c% Create New Restore Point
echo        %o%3%c% Open Saudi-Fix Folder - logs and backups
echo.
echo        %o%M%c% Back to menu
call :footer "Choose the restore point named 'Saudi-Fix Restore Point'."
call :ask
if "%in%"=="1" start "" rstrui.exe & goto :m_restore
if "%in%"=="2" goto :make_rp
if "%in%"=="3" start "" explorer.exe "%SF_DIR%" & goto :m_restore
if /i "%in%"=="M" goto :menu
call :invalid
goto :m_restore

:: ============================================================================
::  H. HELP
:: ============================================================================
:m_help
call :header "Help" "How to use Saudi-Fix - full guide in ReadMe.txt"
echo   %w%  1. Type the number or letter of an option and press ENTER.
echo   %w%  2. New here? Press %g%A%w% on the main menu - it applies safe tweaks only.
echo   %w%  3. Want fewer processes? Section %g%1%w%, then option %g%9%w%, then restart.
echo   %w%  4. Want more FPS? Section %g%2%w%, then option %g%9%w%. Desktops: section %g%5%w%, option %g%1%w%.
echo   %w%  5. Options marked %y%(!)%w% have side effects. Options marked %r%(security)%w%
echo   %w%     lower your PC's protection. Both explain and ask before applying.
echo   %w%  6. Restart your PC after applying tweaks.
echo   %w%  7. Something wrong? %g%R%w% Revert, or %g%P%w% Restore Point.
echo.
echo   %d%  Log file:        %SF_LOG%
echo   %d%  Backups:         %SF_DIR%\Backup
echo   %d%  Official source: github.com/Scrim-Fix/Saudi-Fix
echo   %d%  Saudi-Fix © 2026 - Rashid Alghamdi. All rights reserved.
echo.
echo   %g%%LINE%
echo   %w%  Press any key to go back...%n%
pause >nul
goto :menu

:: ============================================================================
::  HELPERS
:: ============================================================================
:banner
echo.
echo.
echo   %g%        ███████╗ █████╗ ██╗   ██╗██████╗ ██╗       ███████╗██╗██╗  ██╗
echo   %g%        ██╔════╝██╔══██╗██║   ██║██╔══██╗██║       ██╔════╝██║╚██╗██╔╝
echo   %g%        ███████╗███████║██║   ██║██║  ██║██║█████╗ █████╗  ██║ ╚███╔╝
echo   %g%        ╚════██║██╔══██║██║   ██║██║  ██║██║╚════╝ ██╔══╝  ██║ ██╔██╗
echo   %g%        ███████║██║  ██║╚██████╔╝██████╔╝██║       ██║     ██║██╔╝ ██╗
echo   %g%        ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝       ╚═╝     ╚═╝╚═╝  ╚═╝
echo.
echo   %w%             Saudi-Fix © 2026 - Rashid Alghamdi  %g%║%w%  Version %SF_VER%  %g%║%w%  %PC_TYPE%
echo   %g%%LINE%
exit /b

:header
cls
echo.
echo   %g%%LINE%
echo   %w%  SAUDI-FIX  %g%»%w%  %~1
echo   %d%  %~2
echo   %g%%LINE%%w%
echo.
exit /b

:footer
echo.
echo   %g%%THIN%
echo   %d%  %~1
echo   %g%%THIN%%n%
exit /b

:ask
set "in="
echo.
set /p "in=  %g%Saudi-Fix%w% » %n%"
if not defined in exit /b
set "in=%in:"=%"
if not defined in exit /b
set "in=%in: =%"
exit /b

:invalid
echo.
echo   %r%  Invalid choice, try again.%n%
timeout /t 1 /nobreak >nul
exit /b

:confirm
:: exit code 0 = user accepted, 1 = user declined
echo.
echo   %r%  ╔══ ⚠ WARNING ════════════════════════════════════════════════════════════
echo   %r%  ║%w% %~1
echo   %r%  ║%w% %~2
echo   %r%  ╚═════════════════════════════════════════════════════════════════════════%n%
echo.
choice /c YN /n /m "  Are you sure? %o%Y%c% Yes   %o%N%c% No : "
if errorlevel 2 exit /b 1
exit /b 0

:step
echo   %g%  »%w% %~1...%n%
call :log "%~1"
exit /b

:done
echo.
echo   %g%  ╔════════════════════════════════════════════════════════════╗
echo   %g%  ║%w%   ✔ Done. Restart your PC if needed. Press any key...     %g%║
echo   %g%  ╚════════════════════════════════════════════════════════════╝%n%
pause >nul
exit /b

:log
>>"%SF_LOG%" echo [%date% %time%] %~1
exit /b

:proc_count
set "PC_ALL=?"
set "PC_SVC=?"
for /f "tokens=1,2" %%A in ('powershell -NoProfile -NonInteractive -Command "$p = Get-Process; [string]$p.Count + ' ' + ($p.ProcessName -eq 'svchost').Count"') do set "PC_ALL=%%A" & set "PC_SVC=%%B"
exit /b

:save_reg
:: save_reg KEY VALUE ID - remembers a value's original type and data, first time only
set "SV_F=%SF_DIR%\Backup\values\%~3.txt"
if exist "%SV_F%" exit /b
md "%SF_DIR%\Backup\values" >nul 2>&1
set "SV_T=" & set "SV_D="
for /f "tokens=2,*" %%A in ('reg query "%~1" /v "%~2" 2^>nul ^| findstr /c:"REG_"') do set "SV_T=%%A" & set "SV_D=%%B"
if defined SV_T (>"%SV_F%" echo %SV_T%^|%SV_D%) else (>"%SV_F%" echo MISSING)
exit /b

:restore_reg
:: restore_reg KEY VALUE ID - puts back what save_reg stored; exit code 1 if nothing was saved
set "SV_F=%SF_DIR%\Backup\values\%~3.txt"
if not exist "%SV_F%" exit /b 1
set "SV_L="
set /p SV_L=<"%SV_F%"
if "%SV_L%"=="MISSING" (
  reg delete "%~1" /v "%~2" /f >nul 2>&1
) else (
  for /f "tokens=1,* delims=|" %%A in ("%SV_L%") do reg add "%~1" /v "%~2" /t %%A /d "%%B" /f >nul 2>&1
)
del "%SV_F%" >nul 2>&1
exit /b 0

:svc_save
:: svc_save NAME - remembers a service's original start type, first time only
set "SS_F=%SF_DIR%\Backup\services\%~1.txt"
if exist "%SS_F%" exit /b
md "%SF_DIR%\Backup\services" >nul 2>&1
set "SS_S=" & set "SS_D=0x0"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start 2^>nul ^| findstr /c:"REG_"') do set "SS_S=%%A"
for /f "tokens=3" %%A in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v DelayedAutostart 2^>nul ^| findstr /c:"REG_"') do set "SS_D=%%A"
if defined SS_S (>"%SS_F%" echo %SS_S% %SS_D%)
exit /b

:svc_off
:: svc_off NAME - saves the start type, stops and disables; skips services this PC does not have
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1 || exit /b
call :svc_save "%~1"
sc stop "%~1" >nul 2>&1
sc config "%~1" start= disabled >nul 2>&1 || reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
exit /b

:svc_manual
:: svc_manual NAME - saves the start type and sets it to start only when needed
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1 || exit /b
call :svc_save "%~1"
sc config "%~1" start= demand >nul 2>&1 || reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
exit /b

:svc_restore
:: svc_restore NAME DEFAULT - puts back the saved start type, or DEFAULT if none was saved
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1 || exit /b
set "SS_F=%SF_DIR%\Backup\services\%~1.txt"
if not exist "%SS_F%" (
  sc config "%~1" start= %~2 >nul 2>&1
  exit /b
)
for /f "usebackq tokens=1,2" %%A in ("%SS_F%") do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start /t REG_DWORD /d %%A /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v DelayedAutostart /t REG_DWORD /d %%B /f >nul 2>&1
)
del "%SS_F%" >nul 2>&1
exit /b

:bitlocker_pause
:: BCD changes can trigger the BitLocker recovery screen on encrypted PCs.
:: Protection is suspended for the next restart only, then Windows resumes it.
:: Does nothing when the drive is not encrypted.
manage-bde -protectors -disable %SystemDrive% -RebootCount 1 >nul 2>&1
exit /b 0

:wipe
:: deletes the contents of a folder, refusing empty or system root paths
set "WP=%~1"
if not defined WP exit /b
if not exist "%WP%\" exit /b
if /i "%WP%"=="%SystemDrive%\" exit /b
if /i "%WP%"=="%SystemDrive%" exit /b
if /i "%WP%"=="%SystemRoot%" exit /b
if /i "%WP%"=="%USERPROFILE%" exit /b
del /f /s /q "%WP%\*" >nul 2>&1
for /d %%D in ("%WP%\*") do rd /s /q "%%D" >nul 2>&1
exit /b

:backup_original
:: one-time export of the registry keys Saudi-Fix touches, before the first change
set "BK=%SF_DIR%\Backup\original"
if exist "%BK%\done.txt" exit /b
md "%BK%" >nul 2>&1
cls
call :header "Backup" "Saving your original registry settings - first run only"
reg export "HKCU\Control Panel" "%BK%\HKCU_ControlPanel.reg" /y >nul 2>&1
reg export "HKCU\System\GameConfigStore" "%BK%\HKCU_GameConfigStore.reg" /y >nul 2>&1
reg export "HKCU\Software\Policies" "%BK%\HKCU_Policies.reg" /y >nul 2>&1
reg export "HKLM\SOFTWARE\Policies" "%BK%\HKLM_Policies.reg" /y >nul 2>&1
reg export "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "%BK%\HKLM_SystemProfile.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" "%BK%\HKLM_PriorityControl.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "%BK%\HKLM_MemoryManagement.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" "%BK%\HKLM_GraphicsDrivers.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" "%BK%\HKLM_DeviceGuard.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" "%BK%\HKLM_GPU.reg" /y >nul 2>&1
reg export "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" "%BK%\HKLM_TcpipInterfaces.reg" /y >nul 2>&1
powershell -NoProfile -NonInteractive -Command "Get-Service | Select-Object Name, StartType | Export-Csv -NoTypeInformation -Path '%BK%\services.csv'" >nul 2>&1
powercfg /list > "%BK%\powerplans.txt" 2>nul
>"%BK%\done.txt" echo %date% %time%
call :log "Original registry backup saved"
exit /b
