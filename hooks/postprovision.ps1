#Credit: https://github.com/Azure/azure-dev/issues/1697#issue-1617610507
$output = azd env get-values
foreach ($line in $output) {
  $name, $value = $line.Split("=")
  $value = $value -replace '^\"|\"$'
  [Environment]::SetEnvironmentVariable($name, $value)
}
$appName = az ad sp list --filter "appId eq '$env:DATAVERSE_APPLICATION_ID'" --query '[].displayName' --output tsv;
Write-Host "`n‼ Confirm that Application ""$appName"" with AppId ""$env:DATAVERSE_APPLICATION_ID"" has the right role in $env:DATAVERSE_URL ‼" -ForegroundColor Yellow;