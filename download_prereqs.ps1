<#
.SYNOPSIS
    Downloads SailPoint IdentityIQ prerequisites from GitHub releases.

.DESCRIPTION
    Checks for missing installer files and downloads them from a GitHub release.
    Run this before launcher.ps1 if you don't have the prerequisite files.

.NOTES
    Date: 2026-02-03
#>

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$ErrorActionPreference = "Stop"

# ============================================================================
# CONFIGURATION - GitHub Release URLs
# ============================================================================
$BaseUrl = "https://github.com/PhyG0/sailpoint_iiq_prereqs_8.3/releases/download/prereq"

$Prerequisites = @(
    @{
        Name = "JDK 17"
        FileName = "jdk-17.0.11_windows-x64_bin.exe"
        Url = "$BaseUrl/jdk-17.0.11_windows-x64_bin.exe"
        Pattern = "*jdk*.exe"
    },
    @{
        Name = "Apache Tomcat 9"
        FileName = "apache-tomcat-9.0.115.exe"
        Url = "$BaseUrl/apache-tomcat-9.0.115.exe"
        Pattern = "apache-tomcat-*.exe"
    },
    @{
        Name = "MySQL Server 8.4"
        FileName = "mysql-8.4.8-winx64.msi"
        Url = "$BaseUrl/mysql-8.4.8-winx64.msi"
        Pattern = "mysql-*.msi"
    },
    @{
        Name = "VC++ Redistributable"
        FileName = "VC_redist.x64.exe"
        Url = "$BaseUrl/VC_redist.x64.exe"
        Pattern = "VC_redist*.exe"
    },
    @{
        Name = "MySQL Connector/J"
        FileName = "mysql-connector-j-9.6.0.zip"
        Url = "$BaseUrl/mysql-connector-j-9.6.0.zip"
        Pattern = "mysql-connector-j-*.zip"
    }
)

# ============================================================================
# HEADER
# ============================================================================
Clear-Host
Write-Host ""
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host "  ||     SAILPOINT IDENTITYIQ - PREREQUISITE DOWNLOADER                   ||" -ForegroundColor Cyan
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host ""

$DestinationDir = $PSScriptRoot
Write-Host "  Download Location: $DestinationDir" -ForegroundColor Gray
Write-Host ""

# ============================================================================
# CHECK & DOWNLOAD
# ============================================================================
$missingCount = 0
$downloadedCount = 0

foreach ($prereq in $Prerequisites) {
    $existingFile = Get-ChildItem -Path $DestinationDir -Filter $prereq.Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if ($existingFile) {
        Write-Host "  [EXISTS] $($prereq.Name): $($existingFile.Name)" -ForegroundColor Green
    } else {
        $missingCount++
        Write-Host "  [MISSING] $($prereq.Name)" -ForegroundColor Yellow
    }
}

Write-Host ""

if ($missingCount -eq 0) {
    Write-Host "  All prerequisites are already present!" -ForegroundColor Green
    Write-Host ""
    # Auto-continue when called from launcher
    exit 0
}

Write-Host "  $missingCount file(s) will be downloaded." -ForegroundColor Yellow
Write-Host ""

# ============================================================================
# DOWNLOAD FUNCTION WITH PROGRESS BAR (BITS)
# ============================================================================
function Download-FileWithProgress {
    param(
        [string]$Url,
        [string]$DestPath,
        [string]$DisplayName
    )
    
    try {
        # Start BITS transfer job
        $job = Start-BitsTransfer -Source $Url -Destination $DestPath -Asynchronous -DisplayName $DisplayName
        
        $barWidth = 40
        while ($job.JobState -eq "Transferring" -or $job.JobState -eq "Connecting") {
            $percent = 0
            if ($job.BytesTotal -gt 0) {
                $percent = [math]::Floor(($job.BytesTransferred / $job.BytesTotal) * 100)
            }
            $received = [math]::Round($job.BytesTransferred / 1MB, 2)
            $total = [math]::Round($job.BytesTotal / 1MB, 2)
            
            $filled = [math]::Floor($barWidth * $percent / 100)
            $empty = $barWidth - $filled
            $bar = ("#" * $filled) + ("-" * $empty)
            Write-Host "`r    [$bar] $percent% ($received / $total MB)   " -NoNewline -ForegroundColor Cyan
            
            Start-Sleep -Milliseconds 500
        }
        
        # Complete the transfer
        if ($job.JobState -eq "Transferred") {
            Complete-BitsTransfer -BitsJob $job
            Write-Host "`r    [########################################] 100%                    " -ForegroundColor Green
            Write-Host ""
            return $true
        } else {
            Write-Host ""
            Write-Host "    Transfer failed with state: $($job.JobState)" -ForegroundColor Red
            Remove-BitsTransfer -BitsJob $job -ErrorAction SilentlyContinue
            return $false
        }
    } catch {
        Write-Host ""
        Write-Host "    BITS error: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "    Falling back to direct download..." -ForegroundColor Gray
        
        # Fallback to simple WebClient download
        try {
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($Url, $DestPath)
            $webClient.Dispose()
            Write-Host "    [########################################] 100%" -ForegroundColor Green
            return $true
        } catch {
            return $false
        }
    }
}

# ============================================================================
# DOWNLOAD MISSING FILES
# ============================================================================
foreach ($prereq in $Prerequisites) {
    $existingFile = Get-ChildItem -Path $DestinationDir -Filter $prereq.Pattern -ErrorAction SilentlyContinue | Select-Object -First 1
    
    if (-not $existingFile) {
        $destPath = Join-Path $DestinationDir $prereq.FileName
        Write-Host "  Downloading $($prereq.Name)..." -ForegroundColor Cyan
        Write-Host "    URL: $($prereq.Url)" -ForegroundColor Gray
        
        $global:lastPercent = 0
        $global:downloadComplete = $false
        
        try {
            $success = Download-FileWithProgress -Url $prereq.Url -DestPath $destPath -DisplayName $prereq.Name
            
            if ($success -and (Test-Path $destPath)) {
                $fileSize = (Get-Item $destPath).Length / 1MB
                Write-Host "    [DONE] Downloaded ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
                $downloadedCount++
            } else {
                Write-Host "    [FAIL] Download failed" -ForegroundColor Red
            }
        } catch {
            Write-Host "    [FAIL] $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host "  Downloaded $downloadedCount file(s). Continuing..." -ForegroundColor Green
Write-Host "  ===========================================================================" -ForegroundColor Cyan
Write-Host ""
