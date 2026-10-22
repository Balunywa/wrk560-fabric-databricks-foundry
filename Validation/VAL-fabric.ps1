<#
 CloudLabs validation | WRK560 Fabric checks (used by four validation steps)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID
               Stage        = ingest | report | dataagent | mirror   (fixed value per validation step)
               TenantId     = GET-TENANT-ID
               ClientId     = app ID of the Fabric validation app (fixed value, see Validation/README.md)
               ClientSecret = secret of the Fabric validation app (fixed value)

 Uses the Fabric read-only admin APIs, so the validation app must be in a security group that is
 allowed by the tenant settings "Service principals can use Fabric APIs" and
 "Service principals can access read-only admin APIs".

 Passes when:
   ingest    - workspace ZavaWorkspace_<id> exists on a Fabric capacity, with lakehouse ZavaLakehouse and a notebook
   report    - semantic model website_bounce_rate_model and at least one report exist in the workspace
   dataagent - data agent ZavaDataAgent exists in the workspace
   mirror    - a mirrored Azure Databricks catalog exists in the workspace (full lab, Exercise 04)
#>
# CloudLabs injects the step parameters as variables before this script runs, so there is no param() block.
$DeploymentId = "$(Get-Variable -Name DeploymentId -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$Stage        = "$(Get-Variable -Name Stage        -ValueOnly -ErrorAction SilentlyContinue)".Trim().ToLower()
$TenantId     = "$(Get-Variable -Name TenantId     -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$ClientId     = "$(Get-Variable -Name ClientId     -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$ClientSecret = "$(Get-Variable -Name ClientSecret -ValueOnly -ErrorAction SilentlyContinue)".Trim()

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
$WorkspaceName = "ZavaWorkspace_$DeploymentId"
$FabricApi     = "https://api.fabric.microsoft.com/v1"

function New-Result([string]$Status, [string]$Message) {
    @{ Status = $Status; Message = $Message } | ConvertTo-Json -Compress
}

function Get-FabricToken {
    $body = @{
        grant_type    = "client_credentials"
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "https://api.fabric.microsoft.com/.default"
    }
    (Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $body -ContentType "application/x-www-form-urlencoded").access_token
}

# Calls a Fabric list API and follows continuationUri until every page is read
function Get-FabricList([string]$Uri, [string]$Property, [hashtable]$Headers) {
    $all = @()
    while ($Uri) {
        $page = Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers
        $all += @($page.$Property)
        $Uri = $page.continuationUri
    }
    return $all
}

function Find-Item($Items, [string[]]$Types, [string]$Name) {
    $Items | Where-Object { $Types -contains $_.type -and (-not $Name -or $_.name -ieq $Name) } | Select-Object -First 1
}

try {
    if (-not $DeploymentId) { throw "The DeploymentId parameter is empty. Map it to GET-DEPLOYMENT-ID." }
    if (@("ingest", "report", "dataagent", "mirror") -notcontains $Stage) { throw "The Stage parameter must be ingest, report, dataagent, or mirror (got '$Stage')." }
    if (-not ($TenantId -and $ClientId -and $ClientSecret)) { throw "TenantId, ClientId, and ClientSecret must all be set." }
    Write-Host "Stage: $Stage | Workspace: $WorkspaceName"

    $headers = @{ Authorization = "Bearer $(Get-FabricToken)" }
    $failures = [System.Collections.Generic.List[string]]::new()

    $workspaces = Get-FabricList "$FabricApi/admin/workspaces?name=$([uri]::EscapeDataString($WorkspaceName))&state=Active&type=Workspace" "workspaces" $headers
    $ws = $workspaces | Where-Object { $_.name -ieq $WorkspaceName } | Select-Object -First 1

    if (-not $ws) {
        $failures.Add("Workspace '$WorkspaceName' was not found. Create it in Exercise 01, Task 1, with exactly this name.")
    }
    else {
        $items = Get-FabricList "$FabricApi/admin/items?workspaceId=$($ws.id)" "itemEntities" $headers
        Write-Host "Workspace $($ws.id) has $(@($items).Count) items: $((@($items) | ForEach-Object { "$($_.type):$($_.name)" }) -join ', ')"

        switch ($Stage) {
            "ingest" {
                if (-not $ws.capacityId) { $failures.Add("Workspace '$WorkspaceName' isn't assigned to a Fabric capacity. In Workspace settings > License info, select Fabric capacity and your lab capacity.") }
                if (-not (Find-Item $items @("Lakehouse") "ZavaLakehouse")) { $failures.Add("Lakehouse 'ZavaLakehouse' was not found. Create it in Exercise 01, Task 1.") }
                if (-not (Find-Item $items @("Notebook") $null)) { $failures.Add("No notebook was found. Create one from the lakehouse and run the code in Exercise 01, Task 3.") }
                $success = "Exercise 01 complete: workspace '$WorkspaceName' is on a Fabric capacity and has the ZavaLakehouse lakehouse and a notebook."
            }
            "report" {
                if (-not (Find-Item $items @("SemanticModel") "website_bounce_rate_model")) { $failures.Add("Semantic model 'website_bounce_rate_model' was not found. Create it in Exercise 02, Task 1.") }
                if (-not (Find-Item $items @("Report") $null)) { $failures.Add("No saved report was found. Save the Copilot report in Exercise 02, Task 2.") }
                $success = "Exercise 02 complete: the website_bounce_rate_model semantic model and a saved report exist."
            }
            "dataagent" {
                # The data agent item type was renamed from AISkill to DataAgent; accept both
                if (-not (Find-Item $items @("DataAgent", "AISkill") "ZavaDataAgent")) { $failures.Add("Data agent 'ZavaDataAgent' was not found. Create and publish it in Exercise 03, Task 1.") }
                $success = "Exercise 03, Task 1 complete: the ZavaDataAgent data agent exists."
            }
            "mirror" {
                if (-not (Find-Item $items @("MirroredAzureDatabricksCatalog") $null)) { $failures.Add("No mirrored Azure Databricks catalog was found. Create it in Exercise 04, Task 3.") }
                $success = "Exercise 04 complete: Litware's Azure Databricks catalog is mirrored into the workspace."
            }
        }
    }

    if ($failures.Count -eq 0) {
        $message = New-Result "Succeeded" $success
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
    $detail = $_.Exception.Message
    if ($detail -match "429") { $detail = "The Fabric admin API is busy (429). Wait a few minutes and validate again." }
    $message = New-Result "Failed" "The check could not complete. Please wait a minute and validate again. Details: $detail"
}

Write-Host "`n=== FINAL RESPONSE ==="
Write-Host $message

Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [System.Net.HttpStatusCode]::OK
    Body       = $message
})
