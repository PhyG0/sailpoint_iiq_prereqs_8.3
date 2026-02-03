<#
.SYNOPSIS
    SailPoint IdentityIQ Complete Installation Launcher

.DESCRIPTION
    Runs all installation scripts in sequence:
    1. install_jdk.ps1 - Prerequisites (JDK, Tomcat, MySQL)
    2. deploy_iiq.ps1 - Deploy WAR and configure database
    3. Stop Tomcat
    4. init_iiq.ps1 - Import init.xml
    5. init_lcm.ps1 - Import init-lcm.xml
    6. Start Tomcat

.NOTES
    Run as Administrator
#>

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Disable QuickEdit Mode
if ($Host.Name -eq 'ConsoleHost') {
    $code = @'
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    [DllImport("kernel32.dll")]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out uint lpMode);
    [DllImport("kernel32.dll")]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, uint dwMode);
'@
    $type = Add-Type -MemberDefinition $code -Name "Win32Console" -Namespace Win32Console -PassThru -ErrorAction SilentlyContinue
    if ($type) {
        $handle = $type::GetStdHandle(-10)
        $mode = 0
        $type::GetConsoleMode($handle, [ref]$mode)
        $mode = $mode -band -bNOT 0x0040
        $type::SetConsoleMode($handle, $mode)
    }
}

# ============================================================================
# CONFIGURATION
# ============================================================================
$ScriptDir = $PSScriptRoot
$Scripts = @(
    @{ Name = "install_jdk.ps1"; Desc = "Prerequisites (JDK, Tomcat, MySQL)" },
    @{ Name = "deploy_iiq.ps1"; Desc = "Deploy WAR and Configure Database" },
    @{ Name = "init_iiq.ps1"; Desc = "Import init.xml" },
    @{ Name = "init_lcm.ps1"; Desc = "Import init-lcm.xml" }
)

# ============================================================================
# UI HELPER IMPORT
# ============================================================================
$uipath = "$PSScriptRoot\UI.ps1"
if (Test-Path $uipath) {
    . $uipath
} else {
    Write-Host "UI.ps1 not found. Standard output will be used." -ForegroundColor Yellow
    function Write-Header { param($t) Write-Host "=== $t ===" }
    function Write-Section { param($m) Write-Host "`n--- $m ---" }
    function Request-Confirmation { param($m) Read-Host "$m (Press Enter)" }
    function Write-Logo { } # No logo if missing
}

# ============================================================================
# CONFIGURATION
# ============================================================================




function Write-StatusBar {
    param([int]$CurrentStep, [array]$StepStatus)
    
    Write-Host "  +-------------------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  INSTALLATION PROGRESS                                                  |" -ForegroundColor Gray
    Write-Host "  +-------------------------------------------------------------------------+" -ForegroundColor DarkGray
    
    $stepNames = @(
        "Step 1: Prerequisites - JDK, Tomcat, MySQL",
        "Step 2: Deploy WAR and Configure Database",
        "Step 3: Import init.xml",
        "Step 4: Import init-lcm.xml"
    )
    
    for ($i = 0; $i -lt 4; $i++) {
        $status = $StepStatus[$i]
        $name = $stepNames[$i]
        
        if ($status -eq "done") {
            Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
            Write-Host "[DONE]" -ForegroundColor Green -NoNewline
            Write-Host " $name" -ForegroundColor Green -NoNewline
            $pad = 43 - $name.Length
            Write-Host (" " * $pad) -NoNewline
            Write-Host "COMPLETE |" -ForegroundColor Green
        } elseif ($status -eq "running") {
            Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
            Write-Host "[>>>>]" -ForegroundColor Yellow -NoNewline
            Write-Host " $name" -ForegroundColor White -NoNewline
            $pad = 43 - $name.Length
            Write-Host (" " * $pad) -NoNewline
            Write-Host "RUNNING  |" -ForegroundColor Yellow
        } elseif ($status -eq "failed") {
            Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
            Write-Host "[FAIL]" -ForegroundColor Red -NoNewline
            Write-Host " $name" -ForegroundColor Red -NoNewline
            $pad = 43 - $name.Length
            Write-Host (" " * $pad) -NoNewline
            Write-Host "FAILED   |" -ForegroundColor Red
        } else {
            Write-Host "  |  " -ForegroundColor DarkGray -NoNewline
            Write-Host "[    ]" -ForegroundColor DarkGray -NoNewline
            Write-Host " $name" -ForegroundColor DarkGray -NoNewline
            $pad = 43 - $name.Length
            Write-Host (" " * $pad) -NoNewline
            Write-Host "PENDING  |" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "  +-------------------------------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Step {
    param([string]$StepName)
    Write-Section "EXECUTING: $StepName"
}

function Show-Success {
    Write-Host ""
    Write-Host "  ==========================================================================" -ForegroundColor Green
    Write-Host "  ||                                                                      ||" -ForegroundColor Green
    Write-Host "  ||        * * *  INSTALLATION COMPLETED SUCCESSFULLY  * * *             ||" -ForegroundColor Green
    Write-Host "  ||                                                                      ||" -ForegroundColor Green
    Write-Host "  ||    SailPoint IdentityIQ 8.3 is ready!                                ||" -ForegroundColor White
    Write-Host "  ||                                                                      ||" -ForegroundColor Green
    Write-Host "  ||    Access: http://localhost:8080/identityiq                          ||" -ForegroundColor Cyan
    Write-Host "  ||    Login:  spadmin / admin                                           ||" -ForegroundColor Gray
    Write-Host "  ||                                                                      ||" -ForegroundColor Green
    Write-Host "  ==========================================================================" -ForegroundColor Green
    Write-Host ""
}

# ============================================================================
# TOMCAT CONTROL
# ============================================================================

function Get-TomcatServiceName {
    $svc = Get-Service -Name "Tomcat9" -ErrorAction SilentlyContinue
    if ($svc) { return "Tomcat9" }
    
    # Try finding by display name wildcards
    $svc = Get-Service -DisplayName "Apache Tomcat*" | Select-Object -First 1
    if ($svc) { return $svc.Name }
    
    $svc = Get-Service -Name "Tomcat*" | Select-Object -First 1
    if ($svc) { return $svc.Name }
    
    return $null
    return $null
}

function Get-TomcatPath {
    $possiblePaths = @(
        "C:\Program Files\Apache Software Foundation\Tomcat 9.0",
        "C:\Program Files (x86)\Apache Software Foundation\Tomcat 9.0",
        "${env:CATALINA_HOME}"
    )
    foreach ($path in $possiblePaths) {
        if ($path -and (Test-Path $path)) { return $path }
    }
    return $null
}

function Stop-TomcatServer {
    $svcName = Get-TomcatServiceName
    if (-not $svcName) { $svcName = "Tomcat9" }

    Write-Host "  Stopping Tomcat server ($svcName)..." -ForegroundColor Yellow
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        Write-Host "  Tomcat stopped." -ForegroundColor Green
    } else {
        Write-Host "  Tomcat is already stopped." -ForegroundColor Gray
    }
}

function Start-TomcatServer {
    $svcName = Get-TomcatServiceName
    if (-not $svcName) { $svcName = "Tomcat9" }

    Write-Host "  Starting Tomcat server ($svcName)..." -ForegroundColor Yellow
    
    try {
        Start-Service -Name $svcName -ErrorAction Stop
    } catch {
        Write-Warning "Start-Service failed. Trying 'net start'..."
        try {
            & net start $svcName
            if ($LASTEXITCODE -ne 0) { throw "net start failed" }
        } catch {
            Write-Warning "Start-Service failed. Trying 'net start'..."
            try {
                & net start $svcName
                if ($LASTEXITCODE -ne 0) { throw "net start failed" }
            } catch {
                # Fallback to startup.bat
                Write-Warning "Service Start failed. Attempting startup.bat..."
                $tomcatHome = Get-TomcatPath
                if ($tomcatHome) {
                    $startupBat = "$tomcatHome\bin\startup.bat"
                    if (Test-Path $startupBat) {
                        Start-Process -FilePath $startupBat -WindowStyle Minimized
                        Write-Host "Triggered startup.bat." -ForegroundColor Yellow
                        return
                    }
                }

                Write-Error "Could not start Tomcat service and startup.bat not found."
                Write-Host "Please start Tomcat ($svcName) MANUALLY now." -ForegroundColor Yellow
                Request-Confirmation "Press Enter once Tomcat is RUNNING to continue..."
            }
        }
    }

    Start-Sleep -Seconds 5
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if ($svc -and $svc.Status -eq "Running") {
        Write-Host "  Tomcat started successfully." -ForegroundColor Green
    } else {
        Write-Host "  Warning: Tomcat might not be running. Please check." -ForegroundColor Yellow
    }
}

# ============================================================================
# MAIN
# ============================================================================

Clear-Host
Write-Logo
Write-Header

# ============================================================================
# CHECK FOR PREREQUISITES
# ============================================================================
Write-Host "  Checking for prerequisite files..." -ForegroundColor Cyan

$prereqPatterns = @("*jdk*.exe", "apache-tomcat-*.exe", "mysql-*.msi", "VC_redist*.exe", "mysql-connector-j-*.zip")
$missingPrereqs = @()

foreach ($pattern in $prereqPatterns) {
    $found = Get-ChildItem -Path $ScriptDir -Filter $pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $found) {
        $missingPrereqs += $pattern
    }
}

if ($missingPrereqs.Count -gt 0) {
    Write-Host ""
    Write-Host "  WARNING: $($missingPrereqs.Count) prerequisite file(s) are missing:" -ForegroundColor Yellow
    foreach ($m in $missingPrereqs) {
        Write-Host "    - $m" -ForegroundColor Gray
    }
    Write-Host ""
    $downloadChoice = Read-Host "  Would you like to download them now? (Y/N)"
    
    if ($downloadChoice -match "^[Yy]") {
        Write-Host "  Starting download script..." -ForegroundColor Cyan
        Write-Host "  Starting download script..." -ForegroundColor Cyan
        $proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\download_prereqs.ps1`"" -PassThru
        $proc.WaitForExit()

        
        # Refresh check
        Clear-Host
        Write-Logo
        Write-Header
        Write-Host "  Prerequisites downloaded. Continuing..." -ForegroundColor Green
    } else {
        Write-Host "  Skipping download. Installation may fail if files are missing." -ForegroundColor Yellow
    }
}

Write-Host ""

# Request WAR File Path immediately
$UserWarPath = ""
while (-not $UserWarPath) {
    $input = Read-Host "  Please enter the full path to 'identityiq.war' (or the folder containing it)"
    
    if ([string]::IsNullOrWhiteSpace($input)) {
        Write-Warning "Path cannot be empty."
        continue
    }

    # Clean quotes if user copied as path
    $input = $input -replace '"', ''

    if (Test-Path $input -PathType Container) {
        # Input is a directory, check for war inside
        $potentialPath = Join-Path $input "identityiq.war"
        if (Test-Path $potentialPath -PathType Leaf) {
            $UserWarPath = $potentialPath
            Write-Host "  Found WAR file in directory: $UserWarPath" -ForegroundColor Green
        } else {
            Write-Warning "Directory found, but 'identityiq.war' does not exist in: $input"
        }
    } elseif (Test-Path $input -PathType Leaf) {
        # Input is a file
        if ($input -match "\.war$") {
            $UserWarPath = $input
            Write-Host "  Using WAR file: $UserWarPath" -ForegroundColor Green
        } else {
            Write-Warning "The file provided does not have a .war extension."
        }
    } else {
        Write-Warning "File or Directory not found: $input"
    }
}

$stepStatus = @("pending", "pending", "pending", "pending")
Write-StatusBar -CurrentStep 0 -StepStatus $stepStatus

Write-Host "  This installer will:" -ForegroundColor White
Write-Host "    1. Install JDK 17, Apache Tomcat 9, and MySQL 8" -ForegroundColor Gray
Write-Host "    2. Deploy IdentityIQ WAR and configure database" -ForegroundColor Gray
Write-Host "    3. Import init.xml" -ForegroundColor Gray
Write-Host "    4. Import init-lcm.xml" -ForegroundColor Gray
Write-Host ""
Request-Confirmation "Press ENTER to begin installation"

# ============================================================================
# STEP 1: Install Prerequisites
# ============================================================================
$stepStatus[0] = "running"
Clear-Host
Write-Logo
Write-Header
Write-StatusBar -CurrentStep 1 -StepStatus $stepStatus
Show-Step "Prerequisites Installation"

$proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\install_jdk.ps1`"" -PassThru
$proc.WaitForExit()
if ($proc.ExitCode -ne 0) {
    $stepStatus[0] = "failed"
    Write-Host "  Step 1 failed!" -ForegroundColor Red
    Request-Confirmation "Press Enter to exit"
    exit 1
}
$stepStatus[0] = "done"

Write-Host "`n  Proceeding to Step 2..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

# ============================================================================
# STEP 2: Deploy IIQ
# ============================================================================
$stepStatus[1] = "running"
Clear-Host
Write-Logo
Write-Header
Write-StatusBar -CurrentStep 2 -StepStatus $stepStatus
Show-Step "Deploy IdentityIQ"

$proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\deploy_iiq.ps1`" -WarFilePath `"$UserWarPath`"" -PassThru
$proc.WaitForExit()
if ($proc.ExitCode -ne 0) {
    $stepStatus[1] = "failed"
    Write-Host "  Step 2 failed!" -ForegroundColor Red
    Request-Confirmation "Press Enter to exit"
    exit 1
}
$stepStatus[1] = "done"

# STOP TOMCAT after deploy
Write-Host ""
Stop-TomcatServer

Write-Host "`n  Proceeding to Step 3..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

# ============================================================================
# STEP 3: Import init.xml
# ============================================================================
$stepStatus[2] = "running"
Clear-Host
Write-Logo
Write-Header
Write-StatusBar -CurrentStep 3 -StepStatus $stepStatus
Show-Step "Import init.xml"

$proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\init_iiq.ps1`"" -PassThru
$proc.WaitForExit()
if ($proc.ExitCode -ne 0) {
    $stepStatus[2] = "failed"
    Write-Host "  Step 3 failed!" -ForegroundColor Red
    Request-Confirmation "Press Enter to exit"
    exit 1
}
$stepStatus[2] = "done"

Write-Host "`n  Proceeding to Step 4..." -ForegroundColor Cyan
Start-Sleep -Seconds 2

# ============================================================================
# STEP 4: Import init-lcm.xml
# ============================================================================
$stepStatus[3] = "running"
Clear-Host
Write-Logo
Write-Header
Write-StatusBar -CurrentStep 4 -StepStatus $stepStatus
Show-Step "Import init-lcm.xml"

$proc = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptDir\init_lcm.ps1`"" -PassThru
$proc.WaitForExit()
if ($proc.ExitCode -ne 0) {
    $stepStatus[3] = "failed"
    Write-Host "  Step 4 failed!" -ForegroundColor Red
    Request-Confirmation "Press Enter to exit"
    exit 1
}
$stepStatus[3] = "done"

# ============================================================================
# FINAL SUCCESS
# ============================================================================

Write-Logo
Write-Header
Write-StatusBar -CurrentStep 0 -StepStatus $stepStatus
Show-Success

Write-Host ""
Write-Host "  ===========================================================================" -ForegroundColor Yellow
Write-Host "  ||  ACTION REQUIRED: START TOMCAT MANUALLY                               ||" -ForegroundColor Yellow
Write-Host "  ===========================================================================" -ForegroundColor Yellow
Write-Host ""

$finalTomcatPath = Get-TomcatPath
if ($finalTomcatPath) {
    Write-Host "  1. Open a new Administrator PowerShell window." -ForegroundColor White
    Write-Host "  2. Navigate to: $finalTomcatPath\bin" -ForegroundColor Gray
    Write-Host "  3. Run: .\startup.bat" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  4. Access IdentityIQ at: http://localhost:8080/identityiq" -ForegroundColor Green
} else {
    Write-Host "  Please locate 'startup.bat' in your Tomcat installation and run it." -ForegroundColor White
}
Write-Host ""

Read-Host "  Press Enter to exit"
