param( [string]$service,[bool]$rollback = $false  )
# WARN! Rollback is false by default. If set to true: 1) Service MUST already exists on VM as winsvc. 2) If activated, it expects to find local or blob storage backup.

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$ErrorActionPreference = "Stop"
$progressPreference = "silentlyContinue"

$env:DEPLOYDRIVE # # Values: "C:,E:". To choose where to deploy the service executable.
# Define Blob Storage Env
$script:service = $service
$script:environment = $env:ENV_NAME # Values: "ENV,UAT,PRD". Must be set as System Environment Variable.
$env:AZURE_STORAGE_SAS_TOKEN # Storage Account SAS Token. Must be set as System Environment Variable.
$script:storageAccount = "saname"
$script:container = "cname"

# Define Blob Storage Paths
$blobList = @{
    blobBackupJsonPath = Join-Path $script:service ( Join-Path $script:environment "version.json" )
    blobBackupZipPath = Join-Path $script:service ( Join-Path $script:environment "$script:service.zip" )
    blobLatestJsonPath = Join-Path $script:service ( Join-Path $script:environment ( Join-Path "latest" "version.json" ) )
    blobLatestZipPath = Join-Path $script:service ( Join-Path $script:environment ( Join-Path "latest" "$script:service.zip" ) )
}

# Define Dir structure
$drive = $env:DEPLOYDRIVE
$deployDir = Join-Path "C:" "deploy";
$dirList = [ordered]@{
    backupDir = Join-Path $deployDir "backup";
    batchDir = Join-Path $deployDir "batch"
    logsDir   = Join-Path $deployDir "logs";
    serviceDir = Join-Path $drive $script:service;
    tempDir = Join-Path $deployDir "temp"
}

#Define all File paths
$fileList = @{
    batchFilePath = Join-Path $dirList.batchDir "deploy-$($script:service).bat"
    exeBackupFilePath = Join-Path $dirList.backupDir ( Join-Path $service "$script:service.exe" )
    exeFilePath = Join-Path $dirList.serviceDir "$script:service.exe"
    jsonBackupFilePath = Join-Path $dirList.backupDir ( Join-Path $service "version.json" )
    jsonFilePath = Join-Path $dirList.serviceDir "version.json"
    logFilePath = Join-Path $dirList.logsDir "$script:service.$(Get-Date -Format 'yyyyMMdd.HHmmss').log"
    newJsonFilePath = Join-Path $dirList.tempDir "$($script:service).json"
    newZipFilePath = Join-Path $dirList.tempDir "$script:service.zip"
    scriptPath = Join-Path $deployDir "deploy.ps1"
}

# Define Functions
function BlobContentGet { param([string]$src,[string]$dest)
    Write-Host "Downloading $src in $dest ..."
    $null = az storage blob download -c $script:container --account-name $script:storageAccount -n $src -f $dest | Out-Null
}
function JsonCompare { param([hashtable]$blobList,[hashtable]$fileList)

    BlobContentGet -src $blobList.blobLatestJsonPath  -dest $fileList.newJsonFilePath

    $currentJson = if (Test-Path $fileList.jsonFilePath) { (Get-Content -Path $fileList.jsonFilePath -Raw | ConvertFrom-Json).serviceVersion } else { $currentJson = "0.0.0-null" }

    $newJson = (Get-Content -Path $fileList.newJsonFilePath -Raw | ConvertFrom-Json).serviceVersion
    Write-Host "Current version: $currentJson`nNew version: $newJson"
    Remove-Item $fileList.newJsonFilePath -Force

    return $currentJson -eq $newJson
}
function BinariesDeploy { param([bool]$skipDownload = $false,[hashtable]$dirList,[hashtable]$fileList,[hashtable]$blobList)

    if (-not $skipDownload) { BlobContentGet -src $blobList.blobLatestZipPath -dest $fileList.newZipFilePath }

    if (Test-Path $dirList.backupDir) {
        Remove-Item -Path "$($dirList.backupDir)/*" -Force -Recurse
        Write-Host "Cleared backup directory: $($dirList.backupDir)"
    }

    Copy-Item -Path $dirList.serviceDir -Destination $dirList.backupDir -Force -Recurse
    Write-Host "Backup completed: $($dirList.serviceDir) to $($dirList.backupDir)"
    Get-ChildItem -Path "$($dirList.serviceDir)/*" -Recurse | Remove-Item -Force -Recurse
    Write-Host "Cleared service directory: $($dirList.serviceDir)"
    Expand-Archive -Path $fileList.newZipFilePath -DestinationPath $dirList.serviceDir -Force
    Write-Host "Deployment completed: Files extracted to $($dirList.serviceDir)"
    Remove-Item -Path $fileList.newZipFilePath -Force
    Write-Host "Cleanup completed: Removed $($fileList.newZipFilePath)"

}
function ServiceWaitSt { param([ValidateSet("start","stop")][string]$action)

    $desiredStatus = if ($action -eq "start") { @("Started", "Running") } else { @("Stopped") }
    $currentRetry = 1

    while ($currentRetry -lt 5) {

        Start-Sleep -Seconds 30
        if ($action -eq "start") { Start-Service $script:service } else { Stop-Service $script:service }
        $status = (Get-Service -Name $script:service).Status
        if ($status -in $desiredStatus) {
            Write-Host "Service $script:service successfully $action`ed."
            return
        }
        Write-Warning "Attempt: $currentRetry`. Failed to $action service $script:service`."
        $currentRetry++

    } throw "Cannot $action the service: $script:service after 4 attempts."
}
function Rollback { [hashtable]$fileList,[hashtable]$dirList,[hashtable]$blobList

    Write-Host "Rollback requested. Starting rollback process..."
    ServiceWaitSt -action "stop"

    if (Test-Path  $fileList.jsonBackupFilePath){
        $version = (Get-Content -Path  $fileList.jsonBackupFilePath -Raw | ConvertFrom-Json).serviceVersion
        Write-Host "Local Backup Found with version: $version"
        Get-ChildItem -Path "$($dirList.serviceDir)/*" -Recurse | Remove-Item -Force -Recurse
        Move-Item -Path "$($dirList.backupDir)/$($script:service)/*" -Destination "$($dirList.serviceDir)"
    } else {
        BlobContentGet -src $blobList.blobBackupZipPath -dest $fileList.newZipFilePath
        BinariesDeploy -skipDownload $true -dirList $dirList -fileList $fileList -blobList $blobList
    }

    ServiceWaitSt -action "start"
    Write-Host "Rollback completed."
}

# Script Start
Start-Transcript -Path $fileList.logFilePath -Append
Set-Location $deployDir

if (Test-Path  $dirList.tempDir) { Remove-Item -Force -Recurse -Path $dirList.tempDir }
foreach ( $dir in $dirList.Values ) {
    $message = if (Test-Path $dir) { "Path: '$dir' already exists." } else { New-Item $dir -ItemType Directory | Out-Null; "Created: '$dir'" }
    Write-Host $message
    
}
Set-Content -Path $fileList.batchFilePath -Value "powershell.exe -File $($fileList.scriptPath) -service $service"
Write-Host "Batch file: $($fileList.batchFilePath) created."

if ($rollback) {
    Rollback -fileList $fileList -dirList $dirList -blobList $blobList | Out-Null
    Stop-Transcript
    return
}

$exists = (Get-Service -Name $script:service -ErrorAction SilentlyContinue).Name
if ( !( $exists ) ){
    BinariesDeploy -dirList $dirList -fileList $fileList -blobList $blobList
    New-Service -Name $script:service -BinaryPathName $fileList.exeFilePath
    ServiceWaitSt -action "start"
    Stop-Transcript
    return
}

$equal = JsonCompare -blobList $blobList -fileList $fileList

if ( ! ( $equal ) ) {
    ServiceWaitSt -action "stop"
    BinariesDeploy -dirList $dirList -fileList $fileList -blobList $blobList
    ServiceWaitSt -action "start"
    } else { ServiceWaitSt -action "start" }

Stop-Transcript


