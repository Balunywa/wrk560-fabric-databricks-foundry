Param (
    [Parameter(Mandatory = $true)]
    [string]
    $AzureUserName,

    [string]
    $AzurePassword,

    [string]
    $AzureTenantID,

    [string]
    $AzureSubscriptionID,

    [string]
    $DeploymentID,

    [string]
    $adminUsername,

    [string]
    $adminPassword,

    [string]
    $trainerUserName,

    [string]
    $trainerUserPassword,

    [string]
    $StorageAccountName,

    [string]
    $DataContainerName = "data",

    [string]
    $DataSasB64,

    [string]
    $LabDataZipUrl,

    [string]
    $DatabricksWorkspaceUrl,

    [string]
    $DatabricksWorkspaceResourceId,

    [string]
    $DatabricksWorkspaceId,

    [string]
    $AccessConnectorId,

    [string]
    $CatalogName,

    [string]
    $UnityContainerName = "unity"
)

Start-Transcript -Path C:\WindowsAzure\Logs\CloudLabsCustomScriptExtension.txt -Append
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
$ProgressPreference = "SilentlyContinue"

# Import CloudLabs common functions (downloaded next to this script by the Custom Script Extension)
$path = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
. "$path\cloudlabs-windows-functions.ps1"

# Run imported functions from cloudlabs-windows-functions.ps1
WindowsServerCommon
CreateCredFile $AzureUserName $AzurePassword $AzureTenantID $AzureSubscriptionID $DeploymentID
Enable-CloudLabsEmbeddedShadow $adminUsername $trainerUserName $trainerUserPassword

# Downloads a file, retrying a few times so a transient network error doesn't fail the deployment
function Get-FileWithRetry([string]$Uri, [string]$OutFile, [int]$Attempts = 4) {
    for ($i = 1; $i -le $Attempts; $i++) {
        try {
            Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
            return $true
        }
        catch {
            Write-Host "Download attempt $i of $Attempts failed for $Uri : $($_.Exception.Message)"
            Start-Sleep -Seconds (10 * $i)
        }
    }
    return $false
}

# Skip the Microsoft Edge first-run pages so learners land straight on the lab sites
$edgePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
New-Item -Path $edgePolicy -Force | Out-Null
Set-ItemProperty -Path $edgePolicy -Name "HideFirstRunExperience" -Value 1 -Type DWord
Set-ItemProperty -Path $edgePolicy -Name "BrowserSignin" -Value 0 -Type DWord
Set-ItemProperty -Path $edgePolicy -Name "PromotionalTabsEnabled" -Value 0 -Type DWord

# Desktop shortcuts for the three portals used in the lab guide
$edgeExe = "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgeExe)) { $edgeExe = "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe" }
$shell = New-Object -ComObject WScript.Shell
$shortcuts = [ordered]@{
    "Microsoft Fabric"  = "https://app.fabric.microsoft.com"
    "Azure Portal"      = "https://portal.azure.com"
    "Microsoft Foundry" = "https://ai.azure.com"
}
foreach ($name in $shortcuts.Keys) {
    $lnk = $shell.CreateShortcut("C:\Users\Public\Desktop\$name.lnk")
    $lnk.TargetPath = $edgeExe
    $lnk.Arguments = $shortcuts[$name]
    $lnk.Save()
}

# Seed Litware's data into ADLS Gen2: <container>/litwaredata/*.csv
$expectedFiles = @(
    "CustomerChurnData.csv", "dimcustomer.csv", "dimdate.csv", "dimproduct.csv",
    "dimreseller.csv", "factinternetsales.csv", "factresellersales.csv", "website_bounce_rate.csv"
)
if ([string]::IsNullOrWhiteSpace($LabDataZipUrl)) {
    Write-Warning "LabDataZipUrl is empty. Skipping data seeding: the litwaredata shortcut in Exercise 01 will be empty."
}
else {
    $work = "C:\LabFiles\litwaredata-seed"
    New-Item -ItemType Directory -Path "$work\extract", "$work\upload" -Force | Out-Null

    if (-not (Get-FileWithRetry $LabDataZipUrl "$work\litwaredata.zip")) { throw "Could not download the lab data from LabDataZipUrl." }
    Expand-Archive -Path "$work\litwaredata.zip" -DestinationPath "$work\extract" -Force

    # Flatten: the zip may hold the CSV files at its root or inside a folder
    Get-ChildItem -Path "$work\extract" -Recurse -Filter *.csv | Copy-Item -Destination "$work\upload" -Force
    $found = (Get-ChildItem -Path "$work\upload" -Filter *.csv).Name
    $missing = $expectedFiles | Where-Object { $found -notcontains $_ }
    if ($missing) { Write-Warning "Lab data is missing expected files: $($missing -join ', ')" }

    if (-not (Get-FileWithRetry "https://aka.ms/downloadazcopy-v10-windows" "$work\azcopy.zip")) { throw "Could not download AzCopy." }
    Expand-Archive -Path "$work\azcopy.zip" -DestinationPath "$work\azcopy" -Force
    $azcopy = (Get-ChildItem -Path "$work\azcopy" -Recurse -Filter azcopy.exe | Select-Object -First 1).FullName

    $sas = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($DataSasB64))
    $destination = "https://$StorageAccountName.blob.core.windows.net/$DataContainerName/litwaredata?$sas"
    & $azcopy copy "$work\upload\*" $destination --recursive=true --overwrite=true --log-level=WARNING
    if ($LASTEXITCODE -ne 0) { throw "AzCopy failed with exit code $LASTEXITCODE while seeding the lab data." }
    Write-Host "Seeded $($found.Count) files into $DataContainerName/litwaredata on $StorageAccountName."

    Remove-Item -Path $work -Recurse -Force -ErrorAction SilentlyContinue
}

# Full lab only: set up Litware's Unity Catalog catalog and the DLT notebook for Exercise 04
if ([string]::IsNullOrWhiteSpace($DatabricksWorkspaceUrl)) {
    Write-Host "No Databricks workspace in this deployment (Fabric-only variant). Skipping Databricks setup."
}
else {
    & "$path\databricks-setup.ps1" `
        -WorkspaceUrl $DatabricksWorkspaceUrl `
        -WorkspaceResourceId $DatabricksWorkspaceResourceId `
        -WorkspaceId $DatabricksWorkspaceId `
        -AccessConnectorId $AccessConnectorId `
        -StorageAccountName $StorageAccountName `
        -DataContainerName $DataContainerName `
        -UnityContainerName $UnityContainerName `
        -CatalogName $CatalogName `
        -DeploymentID $DeploymentID `
        -LearnerUpn $AzureUserName `
        -NotebookPath "$path\dlt-notebook.py"
}

Stop-Transcript
