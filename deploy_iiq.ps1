<#
.SYNOPSIS
    Deploys SailPoint IdentityIQ WAR to Tomcat and configures iiq.properties.

.DESCRIPTION
    This script:
    1. Copies identityiq.war to Tomcat webapps
    2. Restarts Tomcat to extract the WAR
    3. Configures iiq.properties with MySQL database connection

.NOTES
    Run as Administrator
#>

param(
    [string]$WarFilePath
)

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -WarFilePath `"$WarFilePath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"


# ============================================================================
# ANTI-FREEZE: Disable QuickEdit Mode
# ============================================================================
if ($Host.Name -eq 'ConsoleHost') {
    $code = @'
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll")]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll")]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
    $type = Add-Type -MemberDefinition $code -Name "Win32" -Namespace Win32 -PassThru
    $handle = $type::GetStdHandle(-10) # STD_INPUT_HANDLE
    $mode = 0
    $type::GetConsoleMode($handle, [ref]$mode)
    $mode = $mode -band -bNOT 0x0040 # ENABLE_QUICK_EDIT_MODE
    $type::SetConsoleMode($handle, $mode)
}

$ErrorActionPreference = "Stop"

# ============================================================================
# UI HELPER IMPORT
# ============================================================================
$uipath = "$PSScriptRoot\UI.ps1"
if (Test-Path $uipath) {
    . $uipath
} else { # Fallback
    function Write-Header { param($t) Write-Host "=== $t ===" }
    function Write-Section { param($m) Write-Host "`n--- $m ---" }
    function Request-UserInput { param($m) Read-Host "$m" }
    function Wait-ProcessWithSpinner { param($Process, $Message) $Process | Wait-Process; Write-Host "$Message Done" }
    function Update-Spinner { param($c) Write-Host "." -NoNewline }
    function Write-Success { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
    function Write-Info { param($m) Write-Host "$m" }
}

Write-Header "SAILPOINT IIQ DEPLOYMENT"

# Configuration
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

# 1. Detect Tomcat
Write-Host "Detecting Tomcat installation..." -ForegroundColor Cyan
$tomcatHome = Get-TomcatPath

if (-not $tomcatHome) {
    Write-Warning "Tomcat not found in default locations."
    $userInput = Request-UserInput -Message "Please enter the full path to Tomcat 9.0"
    if (Test-Path $userInput) {
        $tomcatHome = $userInput
    } else {
        Write-Error "Invalid path provided. Tomcat is required."
    }
}

$webappsDir = "$tomcatHome\webapps"
$iiqDir = "$webappsDir\identityiq"

# Validate WAR Parameter
if (-not $WarFilePath) {
    Write-Warning "WAR file path not provided."
    $WarFilePath = Request-UserInput -Message "Please enter the full path to identityiq.war"
}

if (-not (Test-Path $WarFilePath -PathType Leaf)) {
    Write-Error "IdentityIQ WAR file not found at: $WarFilePath"
}

$warFile = Get-Item $WarFilePath

Write-Host "Found WAR file: $($warFile.Name)" -ForegroundColor Green
Write-Host "Tomcat location: $tomcatHome" -ForegroundColor Green

# Get database configuration
Write-Host "`n--- MySQL Database Configuration ---" -ForegroundColor Cyan
$dbName = "identityiq"
$dbUser = "identityiq"
Write-Info "Using Database Name: $dbName"
Write-Info "Using Database User: $dbUser"

$dbPassword = Request-UserInput -Message "Enter Database Password for '$dbUser'" -IsPassword
if ([string]::IsNullOrWhiteSpace($dbPassword)) {
    Write-Error "Database password cannot be empty."
}

# Helper to find Tomcat Service
function Get-TomcatServiceName {
    $svc = Get-Service -Name "Tomcat9" -ErrorAction SilentlyContinue
    if ($svc) { return "Tomcat9" }
    
    # Try finding by display name wildcards
    $svc = Get-Service -DisplayName "Apache Tomcat*" | Select-Object -First 1
    if ($svc) { return $svc.Name }
    
    $svc = Get-Service -Name "Tomcat*" | Select-Object -First 1
    if ($svc) { return $svc.Name }
    
    return $null
}

$tomcatServiceName = Get-TomcatServiceName
if (-not $tomcatServiceName) {
    Write-Warning "Could not auto-detect Tomcat service name. Defaulting to 'Tomcat9'."
    $tomcatServiceName = "Tomcat9"
} else {
    Write-Host "Detected Tomcat Service: $tomcatServiceName" -ForegroundColor Gray
}

# Step 1: Stop Tomcat
Write-Host "`nStopping Tomcat service..." -ForegroundColor Cyan
$tomcatService = Get-Service -Name $tomcatServiceName -ErrorAction SilentlyContinue
if ($tomcatService -and $tomcatService.Status -eq "Running") {
    Stop-Service -Name $tomcatServiceName -Force -WarningAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "Tomcat stopped." -ForegroundColor Green
}

# Step 2: Clean existing deployment (optional)
if (Test-Path $iiqDir) {
    Write-Host "Removing existing identityiq deployment..." -ForegroundColor Yellow
    Remove-Item -Path $iiqDir -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

# Step 3: Copy WAR to webapps
Write-Host "`nCopying WAR file to Tomcat webapps..." -ForegroundColor Cyan
Copy-Item -Path $warFile.FullName -Destination $webappsDir -Force
Write-Host "WAR file copied." -ForegroundColor Green

# Step 4: Start Tomcat to extract WAR
Write-Host "`nStarting Tomcat to extract WAR..." -ForegroundColor Cyan
try {
    Start-Service -Name $tomcatServiceName -ErrorAction Stop
} catch {
    Write-Warning "Start-Service failed. Trying 'net start'..."
    try {
        & net start $tomcatServiceName
        if ($LASTEXITCODE -ne 0) { throw "net start failed" }
    } catch {
        # Fallback to startup.bat if service fails (bypasses service wrapper issues)
        Write-Warning "Service Start failed. Attempting to run via startup.bat..."
        
        $startupBat = "$tomcatHome\bin\startup.bat"
        if (Test-Path $startupBat) {
            Start-Process -FilePath $startupBat -WindowStyle Minimized
            Write-Host "Triggered startup.bat. Waiting for initialization..." -ForegroundColor Yellow
        } else {
            Write-Error "Could not start Tomcat service and startup.bat not found."
            Write-Host "Please start Tomcat ($tomcatServiceName) MANUALLY now." -ForegroundColor Yellow
            Read-Host "Press Enter once Tomcat is RUNNING to continue..."
        }
    }
}

# Wait for WAR extraction
Write-Host "Waiting for WAR extraction... " -NoNewline -ForegroundColor Cyan
$maxWait = 60
$waited = 0
$c = 0
while (-not (Test-Path "$iiqDir\WEB-INF\classes\iiq.properties") -and $waited -lt $maxWait) {
    Start-Sleep -Seconds 2
    $waited += 2
    Update-Spinner -Counter ([ref]$c)
}
Write-Host ""

if (-not (Test-Path "$iiqDir\WEB-INF\classes\iiq.properties")) {
    Write-Error "WAR extraction failed or took too long. Check Tomcat logs."
}
Write-Host "WAR extracted successfully." -ForegroundColor Green

# Step 4b: Stop Tomcat for Configuration
Write-Host "`nStopping Tomcat for configuration..." -ForegroundColor Cyan
Stop-Service -Name $tomcatServiceName -Force -WarningAction SilentlyContinue
Start-Sleep -Seconds 3
Write-Host "Tomcat stopped." -ForegroundColor Green

# Step 5a: Install MySQL Driver
Write-Host "`nChecking for MySQL Driver..." -ForegroundColor Cyan
$driverDest = "$iiqDir\WEB-INF\lib"

# Check if already installed
$existingDriver = Get-ChildItem -Path $driverDest -Filter "mysql-connector-*.jar" -ErrorAction SilentlyContinue
if ($existingDriver) {
    Write-Host "MySQL Driver already present: $($existingDriver.Name)" -ForegroundColor Green
} else {
    # Look for driver zip or jar in script dir
    $driverZip = Get-ChildItem -Path $PSScriptRoot -Filter "mysql-connector-j-*.zip" | Select-Object -First 1
    $driverJarSource = Get-ChildItem -Path $PSScriptRoot -Filter "mysql-connector-j-*.jar" | Select-Object -First 1
    
    if ($driverJarSource) {
        Write-Host "Found driver JAR: $($driverJarSource.Name)" -ForegroundColor Gray
        Copy-Item -Path $driverJarSource.FullName -Destination $driverDest -Force
        Write-Host "Driver installed to WEB-INF/lib." -ForegroundColor Green
    } elseif ($driverZip) {
        Write-Host "Found driver ZIP: $($driverZip.Name). Extracting using tar..." -ForegroundColor Gray
        $tempDir = "$env:TEMP\mysql-connector-extract"
        if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
        New-Item -ItemType Directory -Path $tempDir | Out-Null
        
        # Use tar for extraction (more robust)
        tar -xf $driverZip.FullName -C $tempDir
        
        # Find the jar inside
        $foundJar = Get-ChildItem -Path $tempDir -Recurse -Filter "mysql-connector-j-*.jar" | Where-Object { $_.Name -notmatch "javadoc|sources" } | Select-Object -First 1
        
        if ($foundJar) {
            Copy-Item -Path $foundJar.FullName -Destination $driverDest -Force
            Write-Host "Driver extracted and installed to WEB-INF/lib." -ForegroundColor Green
        } else {
            Write-Error "Could not find mysql-connector-j-*.jar inside the ZIP file."
        }
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Warning "MySQL Driver not found in script directory!"
        Write-Warning "Please download 'mysql-connector-j' (ZIP or JAR) and place it here."
        Write-Warning "The application will likely fail to start (404) without it."
    }
}

# Step 5b: Configure iiq.properties
Write-Host "`nConfiguring iiq.properties..." -ForegroundColor Cyan
$iiqPropertiesPath = "$iiqDir\WEB-INF\classes\iiq.properties"

# Read existing content
$content = Get-Content -Path $iiqPropertiesPath -Raw

# Build the MySQL JDBC URL
$jdbcUrl = "jdbc:mysql://localhost:3306/${dbName}?useSSL=false&allowPublicKeyRetrieval=true&useUnicode=true&characterEncoding=UTF-8"

# Update dataSource properties
$replacements = @{
    'dataSource\.url\s*=.*' = "dataSource.url=$jdbcUrl"
    'dataSource\.username\s*=.*' = "dataSource.username=$dbUser"
    'dataSource\.password\s*=.*' = "dataSource.password=$dbPassword"
    'dataSource\.driverClassName\s*=.*' = "dataSource.driverClassName=com.mysql.cj.jdbc.Driver"
}

foreach ($pattern in $replacements.Keys) {
    if ($content -match $pattern) {
        $content = $content -replace $pattern, $replacements[$pattern]
    }
}

# Write updated content
Set-Content -Path $iiqPropertiesPath -Value $content
Write-Host "iiq.properties configured." -ForegroundColor Green

# Step 6: Final Status Check
Write-Host "`nEnsuring Tomcat is stopped..." -ForegroundColor Cyan
if ((Get-Service -Name $tomcatServiceName).Status -eq "Running") {
    Stop-Service -Name $tomcatServiceName -Force
    Write-Host "Tomcat stopped." -ForegroundColor Green
} else {
    Write-Host "Tomcat is already stopped." -ForegroundColor Green
}

# Step 7: Initialize MySQL Database
Write-Host "`n--- Initializing MySQL Database ---" -ForegroundColor Cyan

# Locate mysql.exe first (needed for password validation)
$mysqlPath = $null
$mysqlCmd = Get-Command "mysql" -ErrorAction SilentlyContinue
if ($mysqlCmd) {
    $mysqlPath = $mysqlCmd.Path
} else {
    # Try common paths dynamically
    $possibleMysqlPaths = @(
        "$env:ProgramFiles\MySQL",
        "${env:ProgramFiles(x86)}\MySQL"
    )
    
    foreach ($path in $possibleMysqlPaths) {
        if (Test-Path $path) {
            $mysqlItem = Get-ChildItem "$path\MySQL Server*\bin\mysql.exe" | Select-Object -First 1
            if ($mysqlItem) {
                $mysqlPath = $mysqlItem.FullName
                break
            }
        }
    }
}

if (-not $mysqlPath) {
    # If still not found, ask user
    Write-Warning "mysql.exe not found in default locations."
    $userInput = Request-UserInput -Message "Please enter the full path to mysql.exe"
    if (Test-Path $userInput) {
        $mysqlPath = $userInput
    }
}

if (-not $mysqlPath) {
    Write-Error "mysql.exe not found. Ensure MySQL is installed and in Path."
}

# Password validation function
function Test-MySQLRootPassword {
    param([string]$Password, [string]$MySQL)
    $ErrorActionPreference = "SilentlyContinue"
    $pArg = if ($Password) { "-p$Password" } else { "" }
    $result = & $MySQL -u root $pArg -e "SELECT 1;" 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    return ($exitCode -eq 0)
}

# Get root password with validation
$maxAttempts = 3
$attempt = 0
$rootPasswordValid = $false

while (-not $rootPasswordValid -and $attempt -lt $maxAttempts) {
    $attempt++
    $rootPassword = Request-UserInput -Message "Enter MySQL Root Password (Attempt $attempt/$maxAttempts)" -IsPassword
    
    # Validate password
    Write-Host "Validating root password..." -ForegroundColor Gray
    if (Test-MySQLRootPassword -Password $rootPassword -MySQL $mysqlPath) {
        $rootPasswordValid = $true
        Write-Host "Password validated successfully." -ForegroundColor Green
    } else {
        if ($attempt -lt $maxAttempts) {
            Write-Warning "Incorrect password. Please try again."
        } else {
             Write-Error-Custom "Incorrect password after $maxAttempts attempts."
             $choice = Request-UserInput -Message "Validation failed. (R)etry or (E)xit?"
             if ($choice -match "^[Rr]") {
                 $attempt = 0 
             } else {
                 Write-Error "Exiting due to authentication failure." 
             }
        }
    }
}

# Locate SQL file
$sqlFile = Get-ChildItem -Path "$PSScriptRoot\database" -Filter "create_identityiq_tables-*.mysql" | Select-Object -First 1
if (-not $sqlFile) {
    Write-Error "SQL script 'create_identityiq_tables-*.mysql' not found in database folder."
}
Write-Host "Found SQL script: $($sqlFile.Name)" -ForegroundColor Gray

# Create Database and User
Write-Host "Resetting Database '$dbName' and User '$dbUser'..." -ForegroundColor Cyan

$commands = @(
    "DROP DATABASE IF EXISTS $dbName;",
    "CREATE DATABASE $dbName CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;",
    "DROP USER IF EXISTS '$dbUser'@'localhost';",
    "DROP USER IF EXISTS '$dbUser'@'%';",
    "CREATE USER '$dbUser'@'localhost' IDENTIFIED BY '$dbPassword';",
    "CREATE USER '$dbUser'@'%' IDENTIFIED BY '$dbPassword';",
    "GRANT ALL PRIVILEGES ON $dbName.* TO '$dbUser'@'localhost';",
    "GRANT ALL PRIVILEGES ON $dbName.* TO '$dbUser'@'%';",
    "FLUSH PRIVILEGES;"
)

$cmdString = $commands -join " "

# Execute Setup Commands using cmd.exe to avoid PowerShell argument parsing issues
Write-Host "Executing database setup commands..." -ForegroundColor Gray
$pArg = if ($rootPassword) { "-p`"$rootPassword`"" } else { "" }
$fullCmd = "`"$mysqlPath`" -u root $pArg -e `"$cmdString`" 2>&1"

# Use Invoke-Expression with error action to suppress the password warning
$ErrorActionPreference = "SilentlyContinue"
$setupResult = cmd.exe /c $fullCmd
$setupExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($setupExitCode -eq 0) {
    Write-Host "[DONE] Creating Database & User - Completed" -ForegroundColor Green
} else {
    Write-Host "[FAIL] Creating Database & User - Failed (Code: $setupExitCode)" -ForegroundColor Red
    Write-Host "Error: $setupResult" -ForegroundColor Red
}

if ($setupExitCode -eq 0) {

    Write-Host "Database and User created successfully." -ForegroundColor Green
} else {
    Write-Error "Failed to create database/user. Check root password."
}

# Import Schema
Write-Host "Importing Schema from $($sqlFile.Name)..." -ForegroundColor Cyan

# Use mysql source command via cmd.exe to avoid PowerShell argument issues
$sqlPath = $sqlFile.FullName -replace '\\', '/'
$importCmd = "`"$mysqlPath`" -u root $pArg -e `"source $sqlPath`" 2>&1"

$ErrorActionPreference = "SilentlyContinue"
$importResult = cmd.exe /c $importCmd
$importExitCode = $LASTEXITCODE
$ErrorActionPreference = "Stop"

if ($importExitCode -eq 0) {
    Write-Host "[DONE] Schema imported successfully." -ForegroundColor Green
} else {
    Write-Host "[FAIL] Schema import failed (Code: $importExitCode)" -ForegroundColor Red
    Write-Host "Error: $importResult" -ForegroundColor Red
    Write-Error "Failed to import schema."
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Deployment & Initialization Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  WAR deployed to: $webappsDir" -ForegroundColor White
Write-Host "  Database: $dbName (Initialized)" -ForegroundColor White
Write-Host "  DB User: $dbUser" -ForegroundColor White
Write-Host "  Tomcat: Stopped (Ready for Initialization)" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan


# Removed local Read-Host
