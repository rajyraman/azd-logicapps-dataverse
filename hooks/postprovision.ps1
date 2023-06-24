$env = azd env get-values;
$config = $env.Split("`r`n");
$applicationId = ($config | Where-Object { $_ -like "DATAVERSE_APPLICATION_ID*" }).Split("=")[1].Replace("""", "");
$dataverseUrl = ($config | Where-Object { $_ -like "DATAVERSE_URL*" }).Split("=")[1].Replace("""", "");
$appName = az ad sp list --filter "appId eq '$($applicationId)'" --query '[].displayName' --output tsv;
Write-Host "`n‼ Confirm that Application ""$appName"" with AppId ""$applicationId"" has the right role in $dataverseUrl ‼" -ForegroundColor Yellow;