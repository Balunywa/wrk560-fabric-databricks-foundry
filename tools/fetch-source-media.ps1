<#
 Copies the screenshots referenced by the lab guide from the WRK560 source repo into labguide/media.
 Run from the package root:  pwsh ./tools/fetch-source-media.ps1
 The source images are licensed under CC BY 4.0 (see LICENSE-DOCS in the source repo).
#>
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$repo = "microsoft/aitour26-WRK560-modernize-your-data-estate-ms-fabric-azure-databricks-and-microsoft-foundry"
$root = Split-Path -Parent $PSScriptRoot
$dest = Join-Path $root "labguide/media"
New-Item -ItemType Directory -Path $dest -Force | Out-Null

# Every ./media/<file> reference in the guide pages, except the CloudLabs screenshots you capture yourself
$refs = Get-ChildItem (Join-Path $root "labguide/*.md") |
    ForEach-Object { [regex]::Matches((Get-Content $_.FullName -Raw), '\]\(\./media/([^)]+)\)') } |
    ForEach-Object { $_.Groups[1].Value } |
    Where-Object { $_ -notlike "cloudlabs/*" } |
    Sort-Object -Unique

foreach ($file in $refs) {
    $url = "https://raw.githubusercontent.com/$repo/HEAD/lab/instructions/media/$file"
    Write-Host "Downloading $file"
    Invoke-WebRequest -Uri $url -OutFile (Join-Path $dest $file) -UseBasicParsing
}
Write-Host "Copied $($refs.Count) images to $dest"
