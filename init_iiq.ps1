<#
.SYNOPSIS
    Runs import init.xml in IIQ Console

.DESCRIPTION
    Opens IIQ console and automatically runs "import init.xml"

.NOTES
    Run as Administrator
#>

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ============================================================================
# UI HELPER IMPORT
# ============================================================================
$uipath = "$PSScriptRoot\UI.ps1"
if (Test-Path $uipath) {
    . $uipath
} else { # Fallback
    function Write-Header { param($t) Write-Host "=== $t ===" }
    function Request-UserInput { param($m) Read-Host "$m" }
    function Write-Info { param($m) Write-Host "$m" }
    function Write-Success { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
}

# ============================================================================
# CONFIGURATION
# ============================================================================
# Helper function to find Tomcat
function Get-TomcatPath {
    $possiblePaths = @(
        "C:\Program Files\Apache Software Foundation\Tomcat 9.0",
        "C:\Program Files (x86)\Apache Software Foundation\Tomcat 9.0",
        "${env:CATALINA_HOME}"
    )

    foreach ($path in $possiblePaths) {
        if ($path -and (Test-Path $path)) {
            return $path
        }
    }
    return $null
}

# Detect Tomcat
$TomcatHome = Get-TomcatPath
if (-not $TomcatHome) {
    Write-Warning "Tomcat not found in default locations."
    $userInput = Request-UserInput -Message "Please enter the full path to Tomcat 9.0"
    if (Test-Path $userInput) {
        $TomcatHome = $userInput
    } else {
        Write-Error "Invalid path. Tomcat is required."
    }
}

$IIQBinPath = "$TomcatHome\webapps\identityiq\WEB-INF\bin"

# ============================================================================
# HEADER
# ============================================================================
Clear-Host
Write-Header "IMPORT INIT.XML"

# Check if path exists
if (-not (Test-Path $IIQBinPath)) {
    Write-Host "  ERROR: IIQ bin path not found: $IIQBinPath" -ForegroundColor Red
    Read-Host "  Press Enter to exit"
    exit 1
}

# Set JAVA_HOME
$javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if ($javaHome) { $env:JAVA_HOME = $javaHome }

# Run import init.xml
Write-Host "  Running: import init.xml" -ForegroundColor Cyan
Write-Host "  Location: $IIQBinPath" -ForegroundColor Gray
Write-Host ""
Write-Host "  ==========================================================================" -ForegroundColor DarkGray
Write-Host ""

Push-Location $IIQBinPath

# Pipe commands to iiq console
# Pipe commands to iiq console and capture output
Write-Host "  Starting IIQ Console... This may take a moment." -ForegroundColor Cyan
$cmd = @"
import init.xml
quit
"@

# Redirect stderr to stdout to capture everything
$output = $cmd | & cmd.exe /c "iiq.bat console" 2>&1

# Output the result
$output | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }

# Basic Check for Success (looking for "Imported" or lack of "Error" if simple)
# But since output is variable, we mostly just show it.
# However, we should warn if JAVA_HOME issues occurred.
if ($output -match "The system cannot find the path specified" -or $output -match "Exception") {
    Write-Host ""
    Write-Host "  [FAIL] Errors detected during import." -ForegroundColor Red
} else {
    Write-Host ""
    Write-Success "Import command execution completed."
}

Pop-Location

Write-Host ""
Read-Host "  Press Enter to finish this step"
