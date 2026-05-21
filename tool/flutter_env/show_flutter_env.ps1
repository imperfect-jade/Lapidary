$localConfigPath = Join-Path $PSScriptRoot "flutter_env.local.ps1"
if (Test-Path $localConfigPath) {
  . $localConfigPath
}

Write-Host ""
Write-Host "flutter locations:"
where.exe flutter

Write-Host ""
Write-Host "dart locations:"
where.exe dart

Write-Host ""
Write-Host "Selected environment variables:"
@(
  "FLUTTER_ROOT",
  "FLUTTER_OFFICIAL_HOME",
  "FLUTTER_OHOS_HOME",
  "PUB_CACHE",
  "PUB_CACHE_OFFICIAL",
  "PUB_CACHE_OHOS",
  "PUB_HOSTED_URL",
  "FLUTTER_STORAGE_BASE_URL",
  "DEVECO_SDK_HOME",
  "HOS_SDK_HOME",
  "FLUTTER_GIT_URL"
) | ForEach-Object {
  $value = [Environment]::GetEnvironmentVariable($_, "Process")
  if ([string]::IsNullOrWhiteSpace($value)) {
    $value = [Environment]::GetEnvironmentVariable($_, "User")
  }
  if ($null -eq $value) {
    $value = ""
  }
  "{0}={1}" -f $_, $value
}
