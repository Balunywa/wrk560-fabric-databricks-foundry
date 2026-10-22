<#
 Sets up Litware's Unity Catalog objects and the DLT notebook for Exercise 04 (full lab only).
 Called by psscript.ps1 on the lab VM. Runs as the VM's managed identity, which has Contributor on the
 Databricks workspace, so the first call adds it to the workspace as a workspace admin. In a workspace that
 was enabled for Unity Catalog automatically, workspace admins can create storage credentials, external
 locations, and catalogs on the attached metastore.

 Unity Catalog objects are metastore-wide and the regional metastore is shared by every lab in the tenant,
 so every name carries the deployment ID and the catalog is bound to this workspace only.
 Written for Windows PowerShell 5.1 (the Custom Script Extension runs powershell.exe).
#>
Param (
    [Parameter(Mandatory = $true)] [string] $WorkspaceUrl,
    [Parameter(Mandatory = $true)] [string] $WorkspaceResourceId,
    [Parameter(Mandatory = $true)] [string] $WorkspaceId,
    [Parameter(Mandatory = $true)] [string] $AccessConnectorId,
    [Parameter(Mandatory = $true)] [string] $StorageAccountName,
    [Parameter(Mandatory = $true)] [string] $CatalogName,
    [Parameter(Mandatory = $true)] [string] $DeploymentID,
    [Parameter(Mandatory = $true)] [string] $LearnerUpn,
    [Parameter(Mandatory = $true)] [string] $NotebookPath,
    [string] $DataContainerName = "data",
    [string] $UnityContainerName = "unity"
)

$ErrorActionPreference = "Stop"
$WorkspaceUrl = $WorkspaceUrl.TrimEnd('/')
$id = ($DeploymentID.ToLower() -replace '[^a-z0-9]', '_')
$credentialName = "sc_build_$id"
$dataLocationName = "el_build_${id}_data"
$unityLocationName = "el_build_${id}_unity"
$dataUrl = "abfss://$DataContainerName@$StorageAccountName.dfs.core.windows.net/"
$unityUrl = "abfss://$UnityContainerName@$StorageAccountName.dfs.core.windows.net/"
$notebookFolder = "/Shared/Analytics with ADB"
$notebookName = "01 DLT Notebook"

# Managed identity tokens from the VM's instance metadata service
function Get-ImdsToken([string]$Resource) {
    $uri = "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=$([uri]::EscapeDataString($Resource))"
    (Invoke-RestMethod -Uri $uri -Headers @{ Metadata = "true" } -UseBasicParsing).access_token
}

function Get-DatabricksHeaders {
    @{
        "Authorization"                            = "Bearer $(Get-ImdsToken '2ff814a6-3304-4ab8-85cb-cd0e6f879c1d')"
        "X-Databricks-Azure-SP-Management-Token"   = (Get-ImdsToken "https://management.core.windows.net/")
        "X-Databricks-Azure-Workspace-Resource-Id" = $WorkspaceResourceId
    }
}

# Calls the Databricks REST API. Retries every failure (RBAC on the workspace and the access connector can take
# several minutes to propagate), and treats "already exists" as success so the extension can be re-run safely.
function Invoke-Databricks([string]$Method, [string]$Path, $Body = $null, [int]$Attempts = 20) {
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            $request = @{ Method = $Method; Uri = "$WorkspaceUrl$Path"; Headers = (Get-DatabricksHeaders); UseBasicParsing = $true }
            if ($null -ne $Body) {
                $request.Body = ($Body | ConvertTo-Json -Depth 10)
                $request.ContentType = "application/json"
            }
            return Invoke-RestMethod @request
        }
        catch {
            $status = 0
            if ($_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            $detail = "$($_.ErrorDetails.Message) $($_.Exception.Message)"
            if ($status -eq 409 -or $detail -match 'ALREADY_EXISTS|already exists') {
                Write-Host "$Method $Path : already exists, continuing."
                return $null
            }
            if ($i -eq $Attempts) { throw "Databricks call $Method $Path failed ($status): $detail" }
            Write-Host "$Method $Path attempt $i of $Attempts failed ($status): $detail. Retrying in 30 seconds."
            Start-Sleep -Seconds 30
        }
    }
}

Write-Host "Setting up Unity Catalog in $WorkspaceUrl for catalog $CatalogName"

# 1. Wait for the workspace, and register the managed identity as a workspace admin
Invoke-Databricks GET "/api/2.0/preview/scim/v2/Me" | Out-Null

# 2. Add the learner to the workspace and to the admins group
Invoke-Databricks POST "/api/2.0/preview/scim/v2/Users" @{
    schemas  = @("urn:ietf:params:scim:schemas:core:2.0:User")
    userName = $LearnerUpn
} | Out-Null
$filter = [uri]::EscapeDataString("userName eq `"$LearnerUpn`"")
$user = (Invoke-Databricks GET "/api/2.0/preview/scim/v2/Users?filter=$filter").Resources | Select-Object -First 1
$admins = (Invoke-Databricks GET "/api/2.0/preview/scim/v2/Groups?filter=$([uri]::EscapeDataString('displayName eq "admins"'))").Resources | Select-Object -First 1
if ($user -and $admins) {
    Invoke-Databricks PATCH "/api/2.0/preview/scim/v2/Groups/$($admins.id)" @{
        schemas    = @("urn:ietf:params:scim:api:messages:2.0:PatchOp")
        Operations = @(@{ op = "add"; value = @{ members = @(@{ value = $user.id }) } })
    } | Out-Null
}

# 3. Storage credential (access connector) and external locations on the lab storage account
Invoke-Databricks POST "/api/2.1/unity-catalog/storage-credentials" @{
    name                   = $credentialName
    azure_managed_identity = @{ access_connector_id = $AccessConnectorId }
    comment                = "WRK560 lab $DeploymentID"
} | Out-Null
Invoke-Databricks POST "/api/2.1/unity-catalog/external-locations" @{ name = $dataLocationName; url = $dataUrl; credential_name = $credentialName; comment = "Litware raw data" } | Out-Null
Invoke-Databricks POST "/api/2.1/unity-catalog/external-locations" @{ name = $unityLocationName; url = $unityUrl; credential_name = $credentialName; comment = "Litware catalog storage" } | Out-Null

# 4. Catalog with its own managed storage, visible from this workspace only
Invoke-Databricks POST "/api/2.1/unity-catalog/catalogs" @{ name = $CatalogName; storage_root = $unityUrl; comment = "Litware Inc. data for WRK560" } | Out-Null
Invoke-Databricks PATCH "/api/2.1/unity-catalog/catalogs/$CatalogName" @{ isolation_mode = "ISOLATED" } | Out-Null
Invoke-Databricks PATCH "/api/2.1/unity-catalog/bindings/catalog/$CatalogName" @{
    add = @(@{ workspace_id = [long]$WorkspaceId; binding_type = "BINDING_TYPE_READ_WRITE" })
} | Out-Null

# 5. Schemas: raw (volume over the seeded CSV files), medallion (pipeline output), curated (mirror-ready tables)
foreach ($schema in @("raw", "medallion", "curated")) {
    Invoke-Databricks POST "/api/2.1/unity-catalog/schemas" @{ name = $schema; catalog_name = $CatalogName } | Out-Null
}
Invoke-Databricks POST "/api/2.1/unity-catalog/volumes" @{
    catalog_name     = $CatalogName
    schema_name      = "raw"
    name             = "litwaredata"
    volume_type      = "EXTERNAL"
    storage_location = "${dataUrl}litwaredata"
} | Out-Null

# 6. Grants: the learner can build in the catalog and expose it to Fabric (EXTERNAL USE SCHEMA must be explicit);
#    every account user can browse metadata, which the validator relies on
Invoke-Databricks PATCH "/api/2.1/unity-catalog/permissions/catalog/$CatalogName" @{
    changes = @(
        @{ principal = $LearnerUpn; add = @("ALL_PRIVILEGES", "EXTERNAL_USE_SCHEMA") },
        @{ principal = "account users"; add = @("BROWSE") }
    )
} | Out-Null

# 7. Import the DLT notebook with this lab's catalog name filled in
$source = (Get-Content -Path $NotebookPath -Raw) -replace '__CATALOG__', $CatalogName
Invoke-Databricks POST "/api/2.0/workspace/mkdirs" @{ path = $notebookFolder } | Out-Null
Invoke-Databricks POST "/api/2.0/workspace/import" @{
    path      = "$notebookFolder/$notebookName"
    format    = "SOURCE"
    language  = "PYTHON"
    overwrite = $true
    content   = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($source))
} | Out-Null

# 8. A small serverless SQL warehouse for the publishing step in Task 2. Best effort: new workspaces usually
#    already have a Serverless Starter Warehouse, and serverless may not be enabled for every account.
try {
    $warehouses = @((Invoke-Databricks GET "/api/2.0/sql/warehouses" -Attempts 3).warehouses | Where-Object { $_ })
    if ($warehouses.Count -eq 0) {
        Invoke-Databricks POST "/api/2.0/sql/warehouses" @{
            name                      = "Zava SQL Warehouse"
            cluster_size              = "2X-Small"
            min_num_clusters          = 1
            max_num_clusters          = 1
            auto_stop_mins            = 10
            enable_serverless_compute = $true
            warehouse_type            = "PRO"
        } -Attempts 3 | Out-Null
    }
}
catch { Write-Warning "Could not check or create a SQL warehouse: $($_.Exception.Message)" }

Write-Host "Databricks setup complete: catalog $CatalogName, schemas raw/medallion/curated, volume raw.litwaredata, notebook '$notebookFolder/$notebookName'."
