# deploy-winsvc.ps1

Deploys and manages Windows Services from Azure Blob Storage. Supports version comparison via JSON manifest, automatic backup, rollback to previous version (local or remote), and first-time service installation.

## Prerequisites

- PowerShell 5.1+
- Azure CLI installed and authenticated
- Environment variables set on the target machine:
  - `ENV_NAME` — target environment (e.g. `DEV`, `UAT`, `PRD`)
  - `AZURE_STORAGE_SAS_TOKEN` — SAS token for blob storage authentication
  - `DEPLOYDRIVE` — drive letter where the service will be deployed (e.g. `C:`, `E:`)

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `service` | string | ✓ | | Name of the Windows Service to deploy |
| `rollback` | bool | | `$false` | If `$true`, rolls back to the previous version |

## Usage

**Standard deployment:**
```powershell
.\deploy-winsvc.ps1 -service "MyWorkerService"
```

**Rollback to previous version:**
```powershell
.\deploy-winsvc.ps1 -service "MyWorkerService" -rollback $true
```

## How It Works

**First-time deployment:**
1. Creates the required directory structure under `C:\deploy\`
2. Downloads the artifact (`.zip`) from blob storage
3. Extracts binaries to the configured drive
4. Registers the Windows Service and starts it

**Subsequent deployments:**
1. Downloads `version.json` from blob storage and compares `serviceVersion` with the local one
2. If versions match, ensures the service is running — no deployment needed
3. If versions differ, stops the service, backs up the current binaries, deploys the new artifact, and restarts

**Rollback:**
1. Stops the service
2. If a local backup exists, restores it directly
3. Otherwise downloads the backup artifact from blob storage and restores it
4. Restarts the service

## Blob Storage Structure

```
<container>/
└── <service>/
    └── <ENV>/
        ├── latest/
        │   ├── <service>.zip
        │   └── version.json
        ├── <service>.zip       ← backup artifact
        └── version.json        ← backup manifest
```

## Notes

- All operations are logged to `C:\deploy\logs\`
- A `.bat` launcher is auto-generated in `C:\deploy\batch\` for scheduled task integration
- Rollback requires the service to already exist on the target machine
- Stop/start operations retry up to 4 times with 30-second intervals before failing


