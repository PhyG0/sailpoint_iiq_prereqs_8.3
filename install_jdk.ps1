<#
.SYNOPSIS
    Installs JDK 17 and Apache Tomcat 9, configuring Tomcat to use the installed JDK.

.DESCRIPTION
    This script installs a local JDK 17 installer, sets System environment variables,
    installs a local Apache Tomcat 9, and configures the Tomcat service to explicitly use the JDK 17 JVM.

.NOTES
    Date: 2026-02-01
#>

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"

# ============================================================================
# UI HELPER IMPORT
# ============================================================================
$uipath = "$PSScriptRoot\UI.ps1"
if (Test-Path $uipath) {
    . $uipath
} else {
    # Fallback minimal
    function Write-Header { param($t) Write-Host "=== $t ===" }
    function Write-Section { param($m) Write-Host "`n--- $m ---" }
    function Request-UserInput { param($m) Read-Host "$m" }
    function Wait-ProcessWithSpinner { param($Process, $Message) $Process | Wait-Process; Write-Host "$Message Done" }
    function Write-Success { param($m) Write-Host "[OK] $m" -ForegroundColor Green }
    function Write-Info { param($m) Write-Host "$m" }
    function Write-Warning-Custom { param($m) Write-Warning $m }
}
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

# 1. Identify the local installer
$installerPattern = "*jdk*.exe"
$installer = Get-ChildItem -Path $PSScriptRoot -Filter $installerPattern | Where-Object { $_.Name -notlike "*install_jdk.ps1*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $installer) {
    Write-Error "No JDK installer ($installerPattern) found in the script directory."
}

Write-Host "Found installer: $($installer.Name)" -ForegroundColor Cyan

# 2. Check for Existing Installation
Write-Section "Checking for Existing JDK"

# Parse version from installer filename
$versionMatch = [Regex]::Match($installer.Name, "jdk-?(\d+)")
if ($versionMatch.Success) {
    $targetVersion = $versionMatch.Groups[1].Value
} else {
    $targetVersion = "17" # Default if not found
}

$possibleRoots = @(
    "$env:ProgramFiles\Java", 
    "${env:ProgramFiles(x86)}\Java",
    "$env:ProgramFiles\Microsoft",
    "${env:ProgramFiles(x86)}\Microsoft"
)
$jdkDir = $null

foreach ($root in $possibleRoots) {
    if (Test-Path $root) {
        $found = Get-ChildItem -Path $root -Filter "jdk-$targetVersion*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($found) {
            $jdkDir = $found
            break
        }
    }
}

if ($jdkDir) {
    Write-Host "JDK $targetVersion already installed at: $($jdkDir.FullName)" -ForegroundColor Green
} else {
    # 3. Run the installer silently
    Write-Section "Installing JDK"
    
    if ($installer.Name -like "microsoft*") {
        $args = "/quiet"
    } else {
        $args = "/s"
    }

    $installProcess = Start-Process -FilePath $installer.FullName -ArgumentList $args -PassThru
    Wait-ProcessWithSpinner -Process $installProcess -Message "Installing JDK 17"

    if ($installProcess.ExitCode -eq 0) {
        Write-Success "JDK Installation completed."
    } elseif ($installProcess.ExitCode -eq 1603) {
        Write-Warning "Installer returned code 1603 (Fatal Error). This often means it is ALREADY installed."
    } elseif ($installProcess.ExitCode -ne 3010) { 
        Write-Warning "Installer finished with code $($installProcess.ExitCode). Process might have failed."
    }
}

# 3. Detect Installation Path (if not already found)
if (-not $jdkDir) {
    if (-not $targetVersion) {
         # Fallback re-parse if needed (rare case)
         $versionMatch = [Regex]::Match($installer.Name, "jdk-?(\d+)")
         if ($versionMatch.Success) {
             $targetVersion = $versionMatch.Groups[1].Value
         } else {
             $targetVersion = "*"
         }
    }
    
    $possibleRoots = @(
        "$env:ProgramFiles\Java", 
        "${env:ProgramFiles(x86)}\Java",
        "$env:ProgramFiles\Microsoft",
        "${env:ProgramFiles(x86)}\Microsoft"
    )

    # Re-detect if it was a fresh install
    foreach ($root in $possibleRoots) {
        if (Test-Path $root) {
            Write-Host "Searching in $root for jdk-$targetVersion..." -ForegroundColor Gray
            $found = Get-ChildItem -Path $root -Filter "jdk-$targetVersion*" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            if ($found) {
                $jdkDir = $found
                break
            }
        }
    }
}

if (-not $jdkDir) {
    # Fallback: check checking for any JDK if specific version failed (though unlikely if install succeeded)
    Write-Warning "Could not find specific jdk-$targetVersion. Searching for any latest JDK..."
    foreach ($root in $possibleRoots) {
        if (Test-Path $root) {
            $found = Get-ChildItem -Path $root -Filter "jdk-*" -Directory | Sort-Object Name -Descending | Select-Object -First 1
            if ($found) {
                $jdkDir = $found
                break
            }
        }
    }
}

if (-not $jdkDir) {
    Write-Error "No JDK directory found in default locations."
}

$javaHome = $jdkDir.FullName
Write-Host "Detected JAVA_HOME: $javaHome" -ForegroundColor Cyan

# 4. Set Environment Variables (User Scope)

# 4. Set Environment Variables (System/Machine Scope)

# Target: Machine (System) Level
$scope = [EnvironmentVariableTarget]::Machine

# Set JAVA_HOME
$currentJavaHome = [Environment]::GetEnvironmentVariable("JAVA_HOME", $scope)

if ($currentJavaHome -ne $javaHome) {
    [Environment]::SetEnvironmentVariable("JAVA_HOME", $javaHome, $scope)
    Write-Host "Set System JAVA_HOME to: $javaHome" -ForegroundColor Green
} else {
    Write-Host "System JAVA_HOME is already set to correct path." -ForegroundColor Gray
}

# Update PATH (Prepend to System Path)
$currentPath = [Environment]::GetEnvironmentVariable("Path", $scope)
$binPath = "$javaHome\bin"
$pathParts = $currentPath -split ';'

# Check if already present and at the start
if ($pathParts[0] -eq $binPath) {
    Write-Host "System Path already starts with JDK bin." -ForegroundColor Gray
} else {
    # Remove existing references to avoid duplicates
    $pathParts = $pathParts | Where-Object { $_ -ne $binPath -and $_ -ne "" }
    
    # Prepend
    $newPath = "$binPath;$($pathParts -join ';')"
    [Environment]::SetEnvironmentVariable("Path", $newPath, $scope)
    Write-Host "Prepended $binPath to System Path." -ForegroundColor Green
}

# 5. Verification
Write-Host "`nVerifying configuration..." -ForegroundColor Cyan

# Update current session temporarily to test
$env:JAVA_HOME = $javaHome
$env:Path = "$binPath;$env:Path"

$javaExe = "$binPath\java.exe"

if (-not (Test-Path $javaExe)) {
    Write-Error "Constructed java executable path not found: $javaExe"
}

try {
    Write-Host "Executing: $javaExe -version" -ForegroundColor Gray
    $verProc = Start-Process -FilePath $javaExe -ArgumentList "-version" -NoNewWindow -Wait -PassThru
    
    if ($verProc.ExitCode -eq 0) {
        Write-Host "SUCCESS: Java executed successfully." -ForegroundColor Green
    } else {
         Write-Host "WARNING: Java exited with code $($verProc.ExitCode)." -ForegroundColor Yellow
    }
} catch {
    Write-Error "Failed to execute java command for verification. Details: $($_.Exception.Message)"
}

Write-Host "`nSetup complete! Please restart any open terminals to use the new System variables." -ForegroundColor Green

# 6. Install Apache Tomcat
Write-Host "`nStarting Apache Tomcat Installation..." -ForegroundColor Cyan

# Identify Tomcat installer
$tomcatInstallerPattern = "apache-tomcat-*.exe"
$tomcatInstaller = Get-ChildItem -Path $PSScriptRoot -Filter $tomcatInstallerPattern | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if (-not $tomcatInstaller) {
    Write-Warning "No Apache Tomcat installer ($tomcatInstallerPattern) found. Skipping Tomcat setup."
} else {
    Write-Host "Found Tomcat installer: $($tomcatInstaller.Name)" -ForegroundColor Cyan
    
    # Run Installer Silently
    # Run Installer Silently
    Write-Section "Installing Tomcat 9"
    $tomcatProc = Start-Process -FilePath $tomcatInstaller.FullName -ArgumentList "/S" -PassThru
    Wait-ProcessWithSpinner -Process $tomcatProc -Message "Installing Apache Tomcat"

    if ($tomcatProc.ExitCode -eq 0) {
        Write-Success "Tomcat installer completed."
    } else {
        Write-Error "Tomcat installation failed with code $($tomcatProc.ExitCode)."
    }
    
    # 7. Configure Tomcat to use our JDK 17
    Write-Host "Configuring Tomcat to use JDK 17..." -ForegroundColor Cyan
    
    # Dynamic Tomcat Path Detection
    $tomcatResultPath = $null
    $possibleTomcatPaths = @(
        "$env:ProgramFiles\Apache Software Foundation\Tomcat 9.0",
        "${env:ProgramFiles(x86)}\Apache Software Foundation\Tomcat 9.0",
        "$env:CATALINA_HOME"
    )
    
    foreach ($path in $possibleTomcatPaths) {
        if ($path -and (Test-Path $path)) {
            $tomcatResultPath = $path
            break
        }
    }
    
    if (-not $tomcatResultPath) {
        Write-Warning "Could not find Tomcat installation at default locations."
        # Ask user for path using new UI
        $userInput = Request-UserInput -Message "Please enter the full path to the Tomcat 9.0 folder"
        if (Test-Path $userInput) {
            $tomcatResultPath = $userInput
        } else {
             Write-Error "Invalid Tomcat path provided. Cannot configure Tomcat."
        }
    }
    
    Write-Host "Tomcat found at: $tomcatResultPath" -ForegroundColor Gray

    # 7. Set Tomcat Environment Variables (System Scope)
    $catalinaHome = $tomcatResultPath
    $currentCatalinaHome = [Environment]::GetEnvironmentVariable("CATALINA_HOME", [EnvironmentVariableTarget]::Machine)

    if ($currentCatalinaHome -ne $catalinaHome) {
        [Environment]::SetEnvironmentVariable("CATALINA_HOME", $catalinaHome, [EnvironmentVariableTarget]::Machine)
        Write-Host "Set System CATALINA_HOME to: $catalinaHome" -ForegroundColor Green
    } else {
        Write-Host "System CATALINA_HOME is already set correctly." -ForegroundColor Gray
    }

    # Update Path for Tomcat
    $currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
    $tomcatBinPath = "$catalinaHome\bin"
    $pathParts = $currentPath -split ';'

    if ($pathParts -notcontains $tomcatBinPath) {
        # Prepend just after JDK if possible, or top. Let's prepend to ensure visibility.
        # Remove existing if any (handled by check above roughly, but let's be safe)
        $pathParts = $pathParts | Where-Object { $_ -ne $tomcatBinPath -and $_ -ne "" }
        $newPath = "$tomcatBinPath;$($pathParts -join ';')"
        [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
        Write-Host "Added Tomcat bin to System Path." -ForegroundColor Green
    } else {
        Write-Host "Tomcat bin is already in System Path." -ForegroundColor Gray
    }
    
    # 8. Configure Tomcat to use our JDK 17
    Write-Host "Configuring Tomcat to use JDK 17..." -ForegroundColor Cyan
    
    $tomcatBin = "$tomcatResultPath\bin"
    $tomcatExe = "$tomcatBin\tomcat9.exe" # Service wrapper tool
    $serviceName = "Tomcat9" # Default service name
    
    if (-not (Test-Path $tomcatExe)) {
        Write-Error "Could not find tomcat9.exe at $tomcatExe"
    }
    
    # Find jvm.dll in our JDK
    $jvmDll = "$javaHome\bin\server\jvm.dll"
    if (-not (Test-Path $jvmDll)) {
        # Fallback for some layouts
        $jvmDll = "$javaHome\lib\server\jvm.dll" 
    }
    
    if (-not (Test-Path $jvmDll)) {
        Write-Warning "Could not locate jvm.dll in $javaHome. Tomcat might use default registry Java."
    } else {
        Write-Host "Found JVM DLL: $jvmDll" -ForegroundColor Gray
        
        # Update Service Parameters
        # //US//ServiceName updates the service
        # --JavaHome sets the Java Home
        # --Jvm sets the specific DLL to use
        
        $updateArgs = "//US//$serviceName --JavaHome `"$javaHome`" --Jvm `"$jvmDll`""
        
        Write-Host "Updating Tomcat Service parameters..." -ForegroundColor Gray
        $cfgProc = Start-Process -FilePath $tomcatExe -ArgumentList $updateArgs -PassThru
        Wait-ProcessWithSpinner -Process $cfgProc -Message "Applying Tomcat Settings"
        
        if ($cfgProc.ExitCode -eq 0) {
            Write-Host "Successfully configured Tomcat service." -ForegroundColor Green
        } else {
            Write-Warning "Failed to update Tomcat service configuration. Exit code: $($cfgProc.ExitCode)"
        }
    }
    
    # Ensure Service is Stopped (so deploy script can run cleanly)
    Write-Host "Ensuring Tomcat Service is stopped..." -ForegroundColor Gray
    try {
        if ((Get-Service -Name $serviceName).Status -eq "Running") {
            Stop-Service -Name $serviceName -Force -ErrorAction Stop
            Write-Host "Tomcat Service stopped." -ForegroundColor Green
        } else {
             Write-Host "Tomcat Service is already stopped." -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not stop Tomcat service. Details: $_"
    }
}

# 9. Install VC++ Redistributable
Write-Host "`nChecking VC++ Redistributable..." -ForegroundColor Cyan
$vcInstallerPattern = "VC_redist*.exe"
$vcInstaller = Get-ChildItem -Path $PSScriptRoot -Filter $vcInstallerPattern | Select-Object -First 1

if (-not $vcInstaller) {
    Write-Warning "VC++ installer not found. Skipping."
} else {
    # Check if installed (simple registry check for 2015-2022+ runtimes)
    $vcReg = "HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64"
    if (Test-Path $vcReg) {
         Write-Host "VC++ Redistributable appears to be installed." -ForegroundColor Gray
    } else {
         Write-Section "Installing VC++ Redistributable"
         $vcProc = Start-Process -FilePath $vcInstaller.FullName -ArgumentList "/install", "/quiet", "/norestart" -PassThru
         Wait-ProcessWithSpinner -Process $vcProc -Message "Installing VC++ Redistributable"
         
         if ($vcProc.ExitCode -eq 0 -or $vcProc.ExitCode -eq 3010) {
             Write-Success "VC++ Installed successfully."
         } else {
             Write-Error "VC++ Install failed: $($vcProc.ExitCode)"
         }
    }
}

# 10. Install MySQL 8.x
Write-Host "`nStarting MySQL Installation..." -ForegroundColor Cyan

# Look for direct MySQL Server MSI first (preferred), then fall back to installer MSI
$mysqlDirectMsi = Get-ChildItem -Path $PSScriptRoot -Filter "mysql-*-winx64.msi" | Where-Object { $_.Name -notlike "*installer*" } | Select-Object -First 1
$mysqlInstallerMsi = Get-ChildItem -Path $PSScriptRoot -Filter "mysql-installer-*.msi" | Select-Object -First 1

if ($mysqlDirectMsi) {
    Write-Host "Found Direct MySQL Server MSI: $($mysqlDirectMsi.Name)" -ForegroundColor Cyan
    
    # Install directly using msiexec
    Write-Host "Installing MySQL Server (Silent)..." -ForegroundColor Gray
    $msiArgs = "/i", "`"$($mysqlDirectMsi.FullName)`"", "/quiet", "/norestart"
    $msiProc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -PassThru
    Wait-ProcessWithSpinner -Process $msiProc -Message "Installing MySQL Server"
    
    if ($msiProc.ExitCode -eq 0 -or $msiProc.ExitCode -eq 3010) {
        Write-Host "MySQL MSI installation completed." -ForegroundColor Green
    } else {
        Write-Warning "MySQL MSI returned code $($msiProc.ExitCode)."
    }

} elseif ($mysqlInstallerMsi) {
    Write-Host "Found MySQL Installer MSI: $($mysqlInstallerMsi.Name)" -ForegroundColor Cyan
    Write-Warning "Using Installer MSI. This may require internet or GUI interaction."
    
    # Install the Installer Tool
    $msiProc = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", "`"$($mysqlInstallerMsi.FullName)`"", "/quiet", "/norestart" -PassThru -Wait
    
    # Try Console
    $installerConsole = "${env:ProgramFiles(x86)}\MySQL\MySQL Installer for Windows\MySQLInstallerConsole.exe"
    if (Test-Path $installerConsole) {
        $consoleArgs = "community", "install", "server;*;x64", "--silent"
        $msiProc = Start-Process -FilePath $installerConsole -ArgumentList $consoleArgs -PassThru
        Wait-ProcessWithSpinner -Process $msiProc -Message "Installing MySQL Server"
    }
} else {
    Write-Warning "No MySQL installer found. Skipping MySQL setup."
}

# Detect MySQL Server Installation Path
$mysqlServerRoot = $null
$possibleMysqlBases = @(
    "$env:ProgramFiles\MySQL",
    "${env:ProgramFiles(x86)}\MySQL"
)

foreach ($base in $possibleMysqlBases) {
    if (Test-Path $base) {
        $found = Get-ChildItem -Path $base -Filter "MySQL Server*" -Directory | Sort-Object Name -Descending | Select-Object -First 1
        if ($found) {
            $mysqlServerRoot = $found.FullName
            break
        }
    }
}

if (-not $mysqlServerRoot) {
    Write-Warning "MySQL Server directory not found in default locations."
    $userInput = Request-UserInput -Message "Please enter the full path to MySQL Server folder"
    if (Test-Path $userInput) {
        $mysqlServerRoot = $userInput
    } else {
        Write-Error "MySQL Server path not found/invalid."
    }
}

Write-Host "MySQL Server found at: $mysqlServerRoot" -ForegroundColor Green
# 4. Configure MySQL
Write-Host "`nConfiguring MySQL..." -ForegroundColor Cyan

# Extract version from path (e.g., "MySQL Server 8.4" -> "8.4")
$serverDirName = Split-Path $mysqlServerRoot -Leaf
$mysqlVersion = $serverDirName -replace "MySQL Server ", ""

# Data Directory path (uses detected version)
# Data Directory path (uses detected version)
$programData = $env:ProgramData
if (-not $programData) { $programData = "C:\ProgramData" }
$mysqlDataDir = "$programData\MySQL\MySQL Server $mysqlVersion\Data"

# Password validation function
function Test-MySQLPassword {
    param([string]$Password, [string]$MySQLPath)
    $ErrorActionPreference = "SilentlyContinue"
    $result = & $MySQLPath -u root "-p$Password" -e "SELECT 1;" 2>&1
    $ErrorActionPreference = "Stop"
    return ($LASTEXITCODE -eq 0)
}

# Check if existing data exists FIRST
$existingData = Test-Path "$mysqlDataDir\mysql"

if ($existingData) {
    Write-Host "Existing MySQL Data detected." -ForegroundColor Yellow
    $maxAttempts = 3
    $attempt = 0
    $passwordValid = $false
    
    # First, ensure MySQL service is running so we can validate
    $mysqlExe = "$mysqlServerRoot\bin\mysql.exe"
    $possibleServiceNames = @("MySQL", "MySQL80", "MySQL84", "MySQL$($mysqlVersion -replace '\.', '')")
    $runningSvc = $null
    foreach ($sn in $possibleServiceNames) {
        $svc = Get-Service -Name $sn -ErrorAction SilentlyContinue
        if ($svc) {
            if ($svc.Status -ne 'Running') {
                Write-Host "Starting MySQL service '$sn' to validate password..." -ForegroundColor Gray
                Start-Service -Name $sn -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 3
            }
            $runningSvc = Get-Service -Name $sn -ErrorAction SilentlyContinue
            if ($runningSvc -and $runningSvc.Status -eq 'Running') { break }
        }
    }
    
    if (-not $runningSvc -or $runningSvc.Status -ne 'Running') {
        Write-Warning "Could not start MySQL service for password validation. Validation will occur later."
        $password = Request-UserInput -Message "Enter your EXISTING MySQL Root Password" -IsPassword
        $passwordValid = $true
    } else {
        # Service is running, we can validate
        while (-not $passwordValid -and $attempt -lt $maxAttempts) {
            $attempt++
            $password = Request-UserInput -Message "Enter your EXISTING MySQL Root Password (Attempt $attempt/$maxAttempts)" -IsPassword
            if ([string]::IsNullOrWhiteSpace($password)) { 
                Write-Warning "Password cannot be empty for existing installation."
                continue
            }
            
            # Validate password NOW
            Write-Host "  Validating password..." -ForegroundColor Gray
            if (Test-MySQLPassword -Password $password -MySQLPath $mysqlExe) {
                $passwordValid = $true
                Write-Host "  Password verified successfully." -ForegroundColor Green
            } else {
                Write-Host "  Incorrect password." -ForegroundColor Red
            }
        }
        
        if (-not $passwordValid) {
            Write-Error "Incorrect password after $maxAttempts attempts. Exiting to prevent data issues."
        }
    }
    $isNewInstall = $false

} else {
    Write-Host "Fresh MySQL installation detected." -ForegroundColor Cyan
    $password = Request-UserInput -Message "Enter NEW Root Password for MySQL (Leave empty for 'root')"
    if ([string]::IsNullOrWhiteSpace($password)) { $password = "root" }
    $isNewInstall = $true
}

# Stop existing service if any (try common names)
$possibleServiceNames = @("MySQL", "MySQL80", "MySQL84", "MySQL$($mysqlVersion -replace '\.','')")
foreach ($svcName in $possibleServiceNames) {
    if (Get-Service $svcName -ErrorAction SilentlyContinue) {
        Stop-Service $svcName -Force -ErrorAction SilentlyContinue
    }
}

# Initialize only if fresh install
if ($isNewInstall) {
    Write-Host "Initializing Database..." -ForegroundColor Cyan
    $mysqld = "$mysqlServerRoot\bin\mysqld.exe"
    
    # Create data dir if needed
    if (-not (Test-Path $mysqlDataDir)) {
        New-Item -Path $mysqlDataDir -ItemType Directory -Force | Out-Null
    }
    
    # Run initialize
    # Run initialize
    Write-Info "Initializing Database Data Directory..."
    $initProc = Start-Process -FilePath $mysqld -ArgumentList "--initialize-insecure", "--datadir=`"$mysqlDataDir`"", "--console" -PassThru -NoNewWindow
    
    # Wait for completion manually as exit code can be unreliable
    $initProc.WaitForExit()
    
    if (-not (Test-Path "$mysqlDataDir\mysql")) {
        Write-Error "Data directory was not initialized properly. Check logs."
    } else {
        Write-Host "  [SUCCESS] Database initialized successfully." -ForegroundColor Green
    }
    Write-Host "Database initialized successfully." -ForegroundColor Green
}

# 5. Modify my.ini
$myIniPath = "$programData\MySQL\MySQL Server $mysqlVersion\my.ini"

# Create default my.ini if missing
if (-not (Test-Path $myIniPath)) {
    Write-Host "Creating my.ini..." -ForegroundColor Gray
    $myIniDir = Split-Path $myIniPath -Parent
    if (-not (Test-Path $myIniDir)) {
        New-Item -Path $myIniDir -ItemType Directory -Force | Out-Null
    }
    $iniContent = @"
[mysqld]
basedir="$mysqlServerRoot"
datadir="$mysqlDataDir"
port=3306
sql_mode="STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
"@
    Set-Content -Path $myIniPath -Value $iniContent
    Write-Host "Created my.ini with IIQ-compatible settings." -ForegroundColor Green
} else {
    # Edit existing my.ini for sql_mode
    $iniContent = Get-Content -Path $myIniPath -Raw
    $targetMode = "STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION"
    
    if ($iniContent -match "sql_mode") {
        $iniContent = $iniContent -replace 'sql_mode\s*=\s*"[^"]*"', "sql_mode=`"$targetMode`""
    } else {
        $iniContent = $iniContent -replace '\[mysqld\]', "[mysqld]`nsql_mode=`"$targetMode`""
    }
    Set-Content -Path $myIniPath -Value $iniContent
    Write-Host "Updated my.ini (ONLY_FULL_GROUP_BY disabled)." -ForegroundColor Green
}

# 6. Install/Ensure Service
Write-Host "`nInstalling MySQL Service..." -ForegroundColor Cyan
$mysqld = "$mysqlServerRoot\bin\mysqld.exe"
$mysqlServiceName = "MySQL"

# Remove existing service first
$existingSvc = Get-Service $mysqlServiceName -ErrorAction SilentlyContinue
if ($existingSvc) {
    Write-Host "Removing existing MySQL service..." -ForegroundColor Gray
    Start-Process -FilePath $mysqld -ArgumentList "--remove", $mysqlServiceName -PassThru -Wait -NoNewWindow | Out-Null
    Start-Sleep -Seconds 2
}

# Install service
Write-Host "Registering MySQL service..." -ForegroundColor Gray
Start-Process -FilePath $mysqld -ArgumentList "--install", $mysqlServiceName, "--defaults-file=`"$myIniPath`"" -PassThru -Wait -NoNewWindow | Out-Null

# Verify and configure
Start-Sleep -Seconds 2
$svc = Get-Service $mysqlServiceName -ErrorAction SilentlyContinue
if (-not $svc) {
    Write-Error "MySQL service was not registered. Check if running as Administrator."
}
Set-Service -Name $mysqlServiceName -StartupType Automatic
Write-Host "Service registered successfully." -ForegroundColor Green

# 7. Start Service
Write-Host "Starting MySQL Service..." -ForegroundColor Cyan
Start-Service -Name $mysqlServiceName -ErrorAction Stop
Start-Sleep -Seconds 5

$svc = Get-Service $mysqlServiceName
if ($svc.Status -eq "Running") {
    Write-Host "MySQL Service is running." -ForegroundColor Green
} else {
    Write-Error "MySQL Service failed to start. Status: $($svc.Status)"
}

# 8. Set Root Password (only for fresh install)
if ($isNewInstall) {
    Write-Host "Setting Root Password..." -ForegroundColor Gray
    $mysqlAdmin = "$mysqlServerRoot\bin\mysqladmin.exe"
    Start-Sleep -Seconds 2
    Start-Process -FilePath $mysqlAdmin -ArgumentList "-u", "root", "password", $password -PassThru -Wait -NoNewWindow | Out-Null
    Write-Host "Root password set." -ForegroundColor Green
}

# 9. Environment Variables
Write-Host "Setting MySQL Environment Variables..." -ForegroundColor Cyan
[Environment]::SetEnvironmentVariable("MYSQL_HOME", $mysqlServerRoot, [EnvironmentVariableTarget]::Machine)

$currentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine)
$mysqlBin = "$mysqlServerRoot\bin"
if ($currentPath -split ';' -notcontains $mysqlBin) {
    $newPath = "$mysqlBin;$currentPath"
    [Environment]::SetEnvironmentVariable("Path", $newPath, [EnvironmentVariableTarget]::Machine)
    Write-Host "Added MySQL bin to Path." -ForegroundColor Green
} else {
    Write-Host "MySQL bin already in Path." -ForegroundColor Gray
}

# 10. Verify MySQL Connection
Write-Host "`nVerifying MySQL Connection..." -ForegroundColor Cyan
$mysql = "$mysqlBin\mysql.exe"
$env:Path = "$mysqlBin;$env:Path"

# Run verification with retry on password failure
$verificationPassed = $false
$maxRetries = 3
$retryCount = 0

while (-not $verificationPassed -and $retryCount -lt $maxRetries) {
    $ErrorActionPreference = "SilentlyContinue"
    $verifyResult = & $mysql -u root "-p$password" -e "SELECT VERSION() AS Version;" 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = "Stop"
    
    $verifyString = $verifyResult | Out-String
    
    if ($exitCode -eq 0 -and $verifyString -match "8\.\d+\.\d+") {
        Write-Host "MySQL Version: $($Matches[0])" -ForegroundColor Green
        Write-Host "SUCCESS: MySQL is running and accessible!" -ForegroundColor Green
        $verificationPassed = $true
    } elseif ($verifyString -match "Access denied") {
        $retryCount++
        if ($retryCount -lt $maxRetries) {
            Write-Warning "Incorrect password. Please try again. (Attempt $($retryCount + 1)/$maxRetries)"
            $password = Request-UserInput -Message "Enter MySQL Root Password" -IsPassword
        } else {
            Write-Error-Custom "Password verification failed after $maxRetries attempts."
            $choice = Request-UserInput -Message "Validation failed. (R)etry or (E)xit?"
            if ($choice -match "^[Rr]") {
                $retryCount = 0 
                $password = Request-UserInput -Message "Enter MySQL Root Password" -IsPassword
            } else {
                Write-Error "Exiting due to authentication failure."
            }
        }
    } else {
        # Check if service is running at least
        $svc = Get-Service $mysqlServiceName -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Write-Host "MySQL Service is running." -ForegroundColor Green
            $verificationPassed = $true
        } else {
             Write-Error "Could not verify MySQL connection. Please check logs."
        }
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  All SailPoint Prerequisites Installed!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  JDK 17:     $javaHome" -ForegroundColor White
Write-Host "  Tomcat 9:   $catalinaHome" -ForegroundColor White
Write-Host "  MySQL $mysqlVersion`:   $mysqlServerRoot" -ForegroundColor White
Write-Host "========================================`n" -ForegroundColor Cyan


# Remove local Read-Host at end
