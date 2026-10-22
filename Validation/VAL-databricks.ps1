<#
 CloudLabs validation | WRK560 Exercise 04, Task 2 (Delta Live Tables pipeline and curated tables)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID
               TenantId     = GET-TENANT-ID
               ClientId     = GET-SERVICEPRINCIPAL-APPLICATION-ID
               ClientSecret = GET-SERVICEPRINCIPAL-SECRET

 The service principal needs Reader on the lab subscription (CloudLabs default) and Contributor on the
 Databricks workspace, which deploy-01.json grants when validationSpObjectId = GET-SERVICEPRINCIPAL-SPOBJECT-ID.
 Contributor lets it sign in to the workspace as an admin. databricks-setup.ps1 grants BROWSE on the catalog
 to all account users, so it can list the catalog's tables.

 Passes when:
   - a pipeline named DLT_Pipeline exists and its latest update COMPLETED
   - litware_uc_<id>.curated has the tables churn_by_contract and sales_by_product (regular Delta tables)
#>
# CloudLabs injects the step parameters as variables before this script runs, so there is no param() block.
$DeploymentId = "$(Get-Variable -Name DeploymentId -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$TenantId     = "$(Get-Variable -Name TenantId     -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$ClientId     = "$(Get-Variable -Name ClientId     -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$ClientSecret = "$(Get-Variable -Name ClientSecret -ValueOnly -ErrorAction SilentlyContinue)".Trim()

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
$suffix         = $DeploymentId.ToLower()
$WorkspaceName  = "databricks-$suffix"
$CatalogName    = "litware_uc_$($suffix -replace '-', '_')"
$PipelineName   = "DLT_Pipeline"
$CuratedTables  = @("churn_by_contract", "sales_by_product")

function New-Result([string]$Status, [string]$Message) {
    @{ Status = $Status; Message = $Message } | ConvertTo-Json -Compress
}

function Get-Token([string]$Scope) {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = $Scope
    }
    (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body -ContentType "application/x-www-form-urlencoded").access_token
}

try {
    if (-not $DeploymentId) { throw "The DeploymentId parameter is empty. Map it to GET-DEPLOYMENT-ID." }
    if (-not ($TenantId -and $ClientId -and $ClientSecret)) { throw "TenantId, ClientId, and ClientSecret must all be set." }
    $failures = [System.Collections.Generic.List[string]]::new()

    # 1. Find the Databricks workspace and its URL. Databricks expects the management token for the
    #    management.core.windows.net audience, which ARM also accepts, so one token serves both.
    $mgmtToken = Get-Token "https://management.core.windows.net//.default"
    $arm = @{ Authorization = "Bearer $mgmtToken" }
    $workspace = $null
    $subs = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions?api-version=2022-12-01" -Headers $arm).value
    foreach ($sub in $subs) {
        $filter = [uri]::EscapeDataString("resourceType eq 'Microsoft.Databricks/workspaces' and name eq '$WorkspaceName'")
        $hit = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$($sub.subscriptionId)/resources?`$filter=$filter&api-version=2021-04-01" -Headers $arm).value | Select-Object -First 1
        if ($hit) { $workspace = Invoke-RestMethod -Uri "https://management.azure.com$($hit.id)?api-version=2024-05-01" -Headers $arm; break }
    }
    if (-not $workspace) { throw "Databricks workspace '$WorkspaceName' was not found. The lab deployment may still be running." }
    $url = "https://$($workspace.properties.workspaceUrl)"
    Write-Host "Workspace: $url"

    # 2. Sign in to the workspace as a service principal that isn't a workspace member yet (Contributor on the resource)
    $dbx = @{
        "Authorization"                            = "Bearer $(Get-Token '2ff814a6-3304-4ab8-85cb-cd0e6f879c1d/.default')"
        "X-Databricks-Azure-SP-Management-Token"   = $mgmtToken
        "X-Databricks-Azure-Workspace-Resource-Id" = $workspace.id
    }

    # 3. Pipeline and its latest update
    $pipelines = @((Invoke-RestMethod -Uri "$url/api/2.0/pipelines?max_results=100" -Headers $dbx).statuses | Where-Object { $_ })
    Write-Host "Pipelines: $(($pipelines | ForEach-Object { "$($_.name) [$($_.latest_updates[0].state)]" }) -join ', ')"
    $pipeline = $pipelines | Where-Object { $_.name -ieq $PipelineName } | Select-Object -First 1
    if (-not $pipeline) {
        $failures.Add("Pipeline '$PipelineName' was not found. Create it in Exercise 04, Task 2.")
    }
    else {
        $state = "$($pipeline.latest_updates[0].state)"
        if ($state -ne "COMPLETED") { $failures.Add("Pipeline '$PipelineName' last update is '$(if ($state) { $state } else { 'not started' })'. Select Start and wait for the update to complete.") }
    }

    # 4. Curated tables published for Fabric mirroring
    $tables = @((Invoke-RestMethod -Uri "$url/api/2.1/unity-catalog/tables?catalog_name=$CatalogName&schema_name=curated&include_browse=true" -Headers $dbx).tables | Where-Object { $_ })
    Write-Host "curated tables: $(($tables | ForEach-Object { "$($_.name) [$($_.table_type)]" }) -join ', ')"
    foreach ($name in $CuratedTables) {
        $t = $tables | Where-Object { $_.name -ieq $name } | Select-Object -First 1
        if (-not $t) { $failures.Add("Table $CatalogName.curated.$name was not found. Run the SQL in Exercise 04, Task 2, after the pipeline completes.") }
        elseif (@("MATERIALIZED_VIEW", "STREAMING_TABLE", "VIEW") -contains "$($t.table_type)") { $failures.Add("$CatalogName.curated.$name is a $($t.table_type). Recreate it with CREATE OR REPLACE TABLE ... AS SELECT so Fabric can mirror it.") }
    }

    if ($failures.Count -eq 0) {
        $message = New-Result "Succeeded" "Exercise 04, Task 2 complete: $PipelineName ran successfully and the curated tables are ready to mirror."
    }
    else {
        $i = 0
        $list = ($failures | ForEach-Object { $i++; "$i) $_" }) -join " "
        $message = New-Result "Failed" "Not complete yet. Fix the following and validate again: $list"
    }
}
catch {
    Write-Host "`nERROR:"
    Write-Host $_
    $message = New-Result "Failed" "The check could not complete. Please wait a minute and validate again. Details: $($_.Exception.Message)"
}

Write-Host "`n=== FINAL RESPONSE ==="
Write-Host $message

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::OK
    Body       = $message
})
