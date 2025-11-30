<#
.SYNOPSIS
    Installs and updates Android ADB, Fastboot, and Google USB Drivers.

.DESCRIPTION
    This script downloads the latest Android Platform Tools and Google USB Drivers,
    installs them to C:\AdbTool, adds them to the system PATH, and sets up a
    scheduled task for automatic updates.

.PARAMETER Install
    Run the installation process.

.PARAMETER Update
    Run the update process (checked against ETag).

.EXAMPLE
    .\Install-AdbTool.ps1 -Install

.NOTES
    Author: Krishnendu Paul (@bidhata)
#>

param (
    [switch]$Install,
    [switch]$Update
)

# Configuration
$InstallDir = "C:\AdbTool"
$PlatformToolsUrl = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip"
$UsbDriverUrl = "https://dl.google.com/android/repository/latest_usb_driver_windows.zip"
$VersionFile = "$InstallDir\version_info.json"
$LogFile = "$InstallDir\install_log.txt"

# Helper: Write to Log
function Write-Log {
    param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] $Message"
    Write-Host $LogEntry
    if (Test-Path $InstallDir) {
        Add-Content -Path $LogFile -Value $LogEntry
    }
}

# Helper: Check Admin Privileges
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Helper: Elevate Script
function Invoke-Elevated {
    if (-not (Test-Admin)) {
        Write-Host "Requesting Administrator privileges..."
        $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
        $newProcess.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $PSBoundParameters"
        $newProcess.Verb = "runas"
        [System.Diagnostics.Process]::Start($newProcess)
        exit
    }
}

# Helper: Download and Extract
function Install-Component {
    param (
        [string]$Url,
        [string]$DestinationPath,
        [string]$Name
    )

    Write-Log "Downloading $Name from $Url..."
    $ZipPath = "$env:TEMP\$Name.zip"
    
    try {
        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
        
        if (Test-Path $DestinationPath) {
            Write-Log "Removing old $Name..."
            Remove-Item -Path $DestinationPath -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Log "Extracting $Name..."
        Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
        
        # Cleanup
        Remove-Item $ZipPath -Force
        return $true
    }
    catch {
        Write-Log "Error installing ${Name}: $_"
        return $false
    }
}

# Helper: Get Remote ETag
function Get-RemoteETag {
    param ([string]$Url)
    try {
        $Request = [System.Net.WebRequest]::Create($Url)
        $Request.Method = "HEAD"
        $Response = $Request.GetResponse()
        $ETag = $Response.Headers["ETag"]
        $Response.Close()
        return $ETag
    }
    catch {
        Write-Log "Failed to get ETag for ${Url}: $_"
        return $null
    }
}

# Action: Install
function Invoke-Install {
    Invoke-Elevated

    if (-not (Test-Path $InstallDir)) {
        New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    }

    Write-Log "Starting Installation..."

    # 1. Install Platform Tools
    $PlatformToolsETag = Get-RemoteETag $PlatformToolsUrl
    if (Install-Component -Url $PlatformToolsUrl -DestinationPath "$InstallDir\platform-tools" -Name "platform-tools") {
        Write-Log "Platform Tools installed successfully."
    }

    # 2. Install USB Drivers
    $UsbDriverETag = Get-RemoteETag $UsbDriverUrl
    if (Install-Component -Url $UsbDriverUrl -DestinationPath "$InstallDir\usb_driver" -Name "usb_driver") {
        Write-Log "USB Drivers downloaded."
        
        # Install Drivers via pnputil
        $InfPath = "$InstallDir\usb_driver\android_winusb.inf"
        if (Test-Path $InfPath) {
            Write-Log "Installing driver from $InfPath..."
            $PnpOutput = pnputil /add-driver $InfPath /install
            Write-Log "Driver Install Output: $PnpOutput"
        }
        else {
            Write-Log "Driver INF file not found at $InfPath"
        }
    }

    # 3. Update PATH
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $AdbPath = "$InstallDir\platform-tools"
    if ($CurrentPath -notlike "*$AdbPath*") {
        Write-Log "Adding $AdbPath to System PATH..."
        [Environment]::SetEnvironmentVariable("Path", "$CurrentPath;$AdbPath", "Machine")
        Write-Log "PATH updated. You may need to restart your terminal."
    }
    else {
        Write-Log "PATH already contains ADB."
    }

    # 4. Save Version Info
    $VersionInfo = @{
        PlatformToolsETag = $PlatformToolsETag
        UsbDriverETag     = $UsbDriverETag
        LastUpdate        = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }
    $VersionInfo | ConvertTo-Json | Set-Content $VersionFile

    # 5. Create Scheduled Task
    $TaskName = "AdbToolAutoUpdate"
    $TaskCommand = "PowerShell.exe"
    $TaskArgs = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`" -Update"
    
    Write-Log "Creating Scheduled Task '$TaskName'..."
    $Action = New-ScheduledTaskAction -Execute $TaskCommand -Argument $TaskArgs
    $Trigger = New-ScheduledTaskTrigger -Daily -At 3am
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName $TaskName -Force | Out-Null
    
    Write-Log "Installation Complete!"
}

# Action: Update
function Invoke-Update {
    if (-not (Test-Path $VersionFile)) {
        Write-Log "Version file not found. Running full install."
        Invoke-Install
        return
    }

    $LocalInfo = Get-Content $VersionFile | ConvertFrom-Json
    $NewPlatformToolsETag = Get-RemoteETag $PlatformToolsUrl
    $NewUsbDriverETag = Get-RemoteETag $UsbDriverUrl
    $Updated = $false

    # Check Platform Tools
    if ($NewPlatformToolsETag -ne $null -and $NewPlatformToolsETag -ne $LocalInfo.PlatformToolsETag) {
        Write-Log "Update found for Platform Tools. Updating..."
        if (Install-Component -Url $PlatformToolsUrl -DestinationPath "$InstallDir\platform-tools" -Name "platform-tools") {
            $LocalInfo.PlatformToolsETag = $NewPlatformToolsETag
            $Updated = $true
        }
    }

    # Check USB Drivers
    if ($NewUsbDriverETag -ne $null -and $NewUsbDriverETag -ne $LocalInfo.UsbDriverETag) {
        Write-Log "Update found for USB Drivers. Updating..."
        if (Install-Component -Url $UsbDriverUrl -DestinationPath "$InstallDir\usb_driver" -Name "usb_driver") {
            
            # Re-install driver
            $InfPath = "$InstallDir\usb_driver\android_winusb.inf"
            if (Test-Path $InfPath) {
                pnputil /add-driver $InfPath /install | Out-Null
            }

            $LocalInfo.UsbDriverETag = $NewUsbDriverETag
            $Updated = $true
        }
    }

    if ($Updated) {
        $LocalInfo.LastUpdate = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        $LocalInfo | ConvertTo-Json | Set-Content $VersionFile
        Write-Log "Update completed successfully."
    }
    else {
        Write-Log "No updates found."
    }
}

# Main Entry Point
if ($Install) {
    Invoke-Install
}
elseif ($Update) {
    Invoke-Update
}
else {
    Write-Host "Usage: .\Install-AdbTool.ps1 -Install | -Update"
    Write-Host "  -Install : Installs tools, drivers, and scheduled task."
    Write-Host "  -Update  : Checks for updates (used by scheduled task)."
}
