<#
 CloudLabs validation | WRK560 Exercise 03, Tasks 2-3 (Foundry connection and agent)

 Script Type : PowerShellV2      Run As : System
 Parameters  : DeploymentId = GET-DEPLOYMENT-ID
               TenantId     = GET-TENANT-ID
               ClientId     = GET-SERVICEPRINCIPAL-APPLICATION-ID
               ClientSecret = GET-SERVICEPRINCIPAL-SECRET

 The service principal needs Reader on the lab subscription (CloudLabs default) and the
 Azure AI User role on the Foundry resource, which deploy-01.json grants when
 validationSpObjectId = GET-SERVICEPRINCIPAL-SPOBJECT-ID.

 Passes when:
   - project foundry-project-<id> has a connection named ZavaDataAgent
   - the project has an agent named Zava-Insights-Agent (spaces and hyphens ignored)
   - that agent has a Microsoft Fabric tool
#>
# CloudLabs injects the step parameters as variables before this script runs, so there is no param() block.
$DeploymentId = "$(Get-Variable -Name DeploymentId -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$TenantId     = "$(Get-Variable -Name TenantId     -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$ClientId     = "$(Get-Variable -Name ClientId     -ValueOnly -ErrorAction SilentlyContinue)".Trim()
$ClientSecret = "$(Get-Variable -Name ClientSecret -ValueOnly -ErrorAction SilentlyContinue)".Trim()

$ErrorActionPreference = "Stop"
$ProgressPreference    = "SilentlyContinue"
$suffix         = $DeploymentId.ToLower()
$FoundryName    = "foundry-$suffix"
$ProjectName    = "foundry-project-$suffix"
$ConnectionName = "ZavaDataAgent"
$AgentKey       = "zavainsightsagent"
$ProjectEndpoint = "https://$FoundryName.services.ai.azure.com/api/projects/$ProjectName"

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

# Returns the response, or $null when the endpoint answers 400/404 (API version or route not offered by this project)
function Invoke-OrNull([string]$Uri, [hashtable]$Headers) {
    try { Invoke-RestMethod -Method Get -Uri $Uri -Headers $Headers }
    catch {
        if ($_.Exception.Response -and @(400, 404) -contains [int]$_.Exception.Response.StatusCode) {
            Write-Host "No result from $Uri ($([int]$_.Exception.Response.StatusCode))"
            return $null
        }
        throw
    }
}

function Get-NameKey([string]$Name) { ($Name -replace '[\s_-]', '').ToLower() }

try {
    if (-not $DeploymentId) { throw "The DeploymentId parameter is empty. Map it to GET-DEPLOYMENT-ID." }
    if (-not ($TenantId -and $ClientId -and $ClientSecret)) { throw "TenantId, ClientId, and ClientSecret must all be set." }
    $failures = [System.Collections.Generic.List[string]]::new()

    # 1. Find the Foundry resource in any subscription the service principal can read
    $arm = @{ Authorization = "Bearer $(Get-Token 'https://management.azure.com/.default')" }
    $accountId = $null
    $subs = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions?api-version=2022-12-01" -Headers $arm).value
    foreach ($sub in $subs) {
        $filter = [uri]::EscapeDataString("resourceType eq 'Microsoft.CognitiveServices/accounts' and name eq '$FoundryName'")
        $hit = (Invoke-RestMethod -Uri "https://management.azure.com/subscriptions/$($sub.subscriptionId)/resources?`$filter=$filter&api-version=2021-04-01" -Headers $arm).value | Select-Object -First 1
        if ($hit) { $accountId = $hit.id; break }
    }
    if (-not $accountId) { throw "Foundry resource '$FoundryName' was not found. The lab deployment may still be running." }
    Write-Host "Foundry resource: $accountId"

    # 2. Project connection to the Fabric data agent (control plane)
    $connections = (Invoke-RestMethod -Uri "https://management.azure.com$accountId/projects/$ProjectName/connections?api-version=2025-06-01" -Headers $arm).value
    $conn = $connections | Where-Object { $_.name -ieq $ConnectionName } | Select-Object -First 1
    Write-Host "Connections: $((@($connections) | ForEach-Object { "$($_.name) [$($_.properties.category)]" }) -join ', ')"
    if (-not $conn) { $failures.Add("Connection '$ConnectionName' was not found in project $ProjectName. Create it in Exercise 03, Task 2.") }

    # 3. Agent with a Fabric tool (data plane). Classic agents are under /assistants, new agents under /agents.
    $data = @{ Authorization = "Bearer $(Get-Token 'https://ai.azure.com/.default')" }
    $agents = @()
    $classic = Invoke-OrNull "$ProjectEndpoint/assistants?api-version=v1&limit=100" $data
    if ($classic) { $agents += @($classic.data | ForEach-Object { [pscustomobject]@{ Name = $_.name; Tools = ($_.tools | ConvertTo-Json -Depth 10 -Compress) } }) }
    $current = Invoke-OrNull "$ProjectEndpoint/agents?api-version=2025-11-15-preview&limit=100" $data
    if ($current) { $agents += @($current.data | ForEach-Object { [pscustomobject]@{ Name = $_.name; Tools = ($_.versions.latest.definition.tools | ConvertTo-Json -Depth 10 -Compress) } }) }
    Write-Host "Agents: $((@($agents) | ForEach-Object { $_.Name }) -join ', ')"

    $agent = $agents | Where-Object { (Get-NameKey $_.Name) -eq $AgentKey } | Select-Object -First 1
    if (-not $agent) {
        $failures.Add("Agent 'Zava-Insights-Agent' was not found. Create it in Exercise 03, Task 3.")
    }
    elseif ($agent.Tools -notmatch 'fabric') {
        $failures.Add("Agent '$($agent.Name)' has no Microsoft Fabric knowledge. Add the ZavaDataAgent connection under Knowledge in Exercise 03, Task 3.")
    }

    if ($failures.Count -eq 0) {
        $message = New-Result "Succeeded" "Exercise 03 complete: the ZavaDataAgent connection exists and agent '$($agent.Name)' is grounded with Microsoft Fabric."
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
