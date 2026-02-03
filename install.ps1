<#
.SYNOPSIS
    SailPoint IdentityIQ 8.3 - One-Click Bootstrap Installer

.DESCRIPTION
    Run this script with: irm https://raw.githubusercontent.com/PhyG0/sailpoint_iiq_prereqs_8.3/main/install.ps1 | iex
    
    This bootstrap script:
    1. Creates a temporary installation directory
    2. Downloads all required installation scripts from GitHub
    3. Launches the main installer

.NOTES
    Requires Administrator privileges and PowerShell 5.1+
#>

# Ensure running as Administrator
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This installer requires Administrator privileges." -ForegroundColor Yellow
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run this command in an elevated PowerShell:" -ForegroundColor Cyan
    Write-Host 'irm https://raw.githubusercontent.com/PhyG0/sailpoint_iiq_prereqs_8.3/main/install.ps1 | iex' -ForegroundColor White
    pause
    exit
}

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION
# ============================================================================
$RepoBase = "https://raw.githubusercontent.com/PhyG0/sailpoint_iiq_prereqs_8.3/main"
$InstallDir = "$env:TEMP\SailPointInstaller"

$Scripts = @(
    "UI.ps1",
    "download_prereqs.ps1",
    "install_jdk.ps1",
    "deploy_iiq.ps1",
    "init_iiq.ps1",
    "init_lcm.ps1",
    "iiq_console.ps1",
    "launcher.ps1"
)

# ============================================================================
# HEADER
# ============================================================================
Clear-Host
Write-Host ""
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host "  ||     SAILPOINT IDENTITYIQ 8.3 - ONE-CLICK INSTALLER                   ||" -ForegroundColor Cyan
Write-Host "  ||                      Bootstrap Downloader                            ||" -ForegroundColor Cyan
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================================
# CREATE INSTALL DIRECTORY
# ============================================================================
Write-Host "  Creating installation directory..." -ForegroundColor Gray

# If current path is in $InstallDir, move out to prevent locking
if ($PWD.Path -like "$InstallDir*") {
    Set-Location $env:TEMP
}

if (Test-Path $InstallDir) {
    try {
        Remove-Item $InstallDir -Recurse -Force -ErrorAction Stop
    } catch {
        Write-Warning "Could not clean existing directory. Proceeding with overwrite."
    }
}
New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
Write-Host "  Location: $InstallDir" -ForegroundColor Green
Write-Host ""

# ============================================================================
# DOWNLOAD SCRIPTS
# ============================================================================
Write-Host "  Downloading installation scripts..." -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'

foreach ($script in $Scripts) {
    $url = "$RepoBase/$script"
    $dest = "$InstallDir\$script"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "    [OK] $script" -ForegroundColor Green
    } catch {
        Write-Host "    [FAIL] $script - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Download Database Scripts
Write-Host "  Downloading database scripts..." -ForegroundColor Cyan
$DBDir = "$InstallDir\database"
if (-not (Test-Path $DBDir)) { New-Item -ItemType Directory -Path $DBDir -Force | Out-Null }

$DBScripts = @("create_identityiq_tables-8.3.mysql")
foreach ($dbScript in $DBScripts) {
    $url = "$RepoBase/database/$dbScript"
    $dest = "$DBDir\$dbScript"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
        Write-Host "    [OK] database/$dbScript" -ForegroundColor Green
    } catch {
        Write-Host "    [FAIL] database/$dbScript - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host "  Scripts downloaded. Launching installer..." -ForegroundColor Green
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host ""

Start-Sleep -Seconds 2

# ============================================================================
# LAUNCH MAIN INSTALLER
# ============================================================================
Set-Location $InstallDir
& "$InstallDir\launcher.ps1"
