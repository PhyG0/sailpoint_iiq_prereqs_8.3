<#
.SYNOPSIS
    Launches the SailPoint IdentityIQ Console

.DESCRIPTION
    Opens the IIQ console from the IdentityIQ WEB-INF/bin directory.
    Equivalent to running "iiq console" manually.

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
    function Write-Error-Custom { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red }
    function Request-Confirmation { param($m) Read-Host "$m" }
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
$IIQBat = "$IIQBinPath\iiq.bat"

# ============================================================================
# HEADER
# ============================================================================
Clear-Host
Write-Header "IDENTITYIQ CONSOLE LAUNCHER"

# ============================================================================
# VALIDATION
# ============================================================================

# Check if Tomcat exists
if (-not (Test-Path $TomcatHome)) {
    Write-Error-Custom "Tomcat not found at: $TomcatHome"
    Request-Confirmation "Press Enter to exit"
    exit 1
}

# Check if IIQ is deployed
if (-not (Test-Path $IIQBinPath)) {
    Write-Error-Custom "IdentityIQ not deployed. Path not found: $IIQBinPath"
    Write-Warning "Please run the installation first."
    Request-Confirmation "Press Enter to exit"
    exit 1
}

# Check if iiq.bat exists
if (-not (Test-Path $IIQBat)) {
    Write-Error-Custom "iiq.bat not found at: $IIQBat"
    Request-Confirmation "Press Enter to exit"
    exit 1
}

# ============================================================================
# ENSURE JAVA_HOME IS SET
# ============================================================================
$javaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")
if (-not $javaHome) {
    # Try to find JDK
    $jdkPath = Get-ChildItem "C:\Program Files\Java\jdk-*" -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if ($jdkPath) {
        $env:JAVA_HOME = $jdkPath.FullName
        Write-Host "  Set JAVA_HOME to: $($jdkPath.FullName)" -ForegroundColor Gray
    }
} else {
    $env:JAVA_HOME = $javaHome
}

# ============================================================================
# LAUNCH CONSOLE
# ============================================================================
Write-Info "Launching IIQ Console..."
Write-Info "Location: $IIQBinPath"
Write-Section "Interactive Console Session"

# Change to IIQ bin directory and run console
Push-Location $IIQBinPath

try {
    # Run iiq console
    & cmd.exe /c "iiq.bat console"
} finally {
    Pop-Location
}

Write-Info "IIQ Console session ended."
Request-Confirmation "Press Enter to exit"
