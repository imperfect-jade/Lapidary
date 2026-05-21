$ErrorActionPreference = "Stop"

$localConfigPath = Join-Path $PSScriptRoot "flutter_env.local.ps1"
if (Test-Path $localConfigPath) {
  . $localConfigPath
}

function Get-ConfiguredValue {
  param([Parameter(Mandatory = $true)][string]$Name)

  $value = [Environment]::GetEnvironmentVariable($Name, "Process")
  if ([string]::IsNullOrWhiteSpace($value)) {
    $value = [Environment]::GetEnvironmentVariable($Name, "User")
  }

  if ([string]::IsNullOrWhiteSpace($value)) {
    return $null
  }

  return $value
}

function Get-RequiredConfiguredValue {
  param([Parameter(Mandatory = $true)][string]$Name)

  $value = Get-ConfiguredValue $Name
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing required environment variable '$Name'. See tool\flutter_env\README.md for setup instructions."
  }

  return $value
}

$Script:OfficialFlutterHome = Get-ConfiguredValue "FLUTTER_OFFICIAL_HOME"
$Script:OhosFlutterHome = Get-ConfiguredValue "FLUTTER_OHOS_HOME"
$Script:OfficialPubCache = Get-ConfiguredValue "PUB_CACHE_OFFICIAL"
$Script:OhosPubCache = Get-ConfiguredValue "PUB_CACHE_OHOS"
$Script:PubHostedUrl = Get-ConfiguredValue "PUB_HOSTED_URL"
$Script:FlutterStorageBaseUrl = Get-ConfiguredValue "FLUTTER_STORAGE_BASE_URL"
$Script:DevecoSdkHome = Get-ConfiguredValue "DEVECO_SDK_HOME"
$Script:DevecoStudioHome = Get-ConfiguredValue "DEVECO_STUDIO_HOME"
$Script:OhosFlutterGitUrl = Get-ConfiguredValue "FLUTTER_GIT_URL"

if ([string]::IsNullOrWhiteSpace($Script:DevecoStudioHome) -and -not [string]::IsNullOrWhiteSpace($Script:DevecoSdkHome)) {
  $Script:DevecoStudioHome = Split-Path -Path $Script:DevecoSdkHome -Parent
}

if ([string]::IsNullOrWhiteSpace($Script:OhosFlutterGitUrl)) {
  $Script:OhosFlutterGitUrl = "https://gitcode.com/openharmony-tpc/flutter_flutter.git"
}

function Get-NormalizedPath {
  param([Parameter(Mandatory = $true)][string]$Path)

  try {
    return [System.IO.Path]::GetFullPath($Path).TrimEnd('\', '/')
  } catch {
    return $Path.TrimEnd('\', '/')
  }
}

function Get-OhosToolPaths {
  if ([string]::IsNullOrWhiteSpace($Script:DevecoStudioHome) -or [string]::IsNullOrWhiteSpace($Script:DevecoSdkHome)) {
    return @()
  }

  return @(
    (Join-Path $Script:DevecoStudioHome "tools\ohpm\bin"),
    (Join-Path $Script:DevecoStudioHome "tools\hvigor\bin"),
    (Join-Path $Script:DevecoStudioHome "tools\node"),
    (Join-Path $Script:DevecoSdkHome "default\openharmony\toolchains")
  )
}

function Remove-ManagedBinsFromPath {
  $flutterHomes = @(
    $Script:OfficialFlutterHome,
    $Script:OhosFlutterHome
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

  $binsToRemove = @()
  foreach ($flutterHome in $flutterHomes) {
    $binsToRemove += Join-Path $flutterHome "bin"
  }
  $binsToRemove += Get-OhosToolPaths
  $binsToRemove = $binsToRemove |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    ForEach-Object { Get-NormalizedPath $_ }

  $kept = foreach ($entry in ($env:Path -split ';')) {
    if ([string]::IsNullOrWhiteSpace($entry)) {
      continue
    }

    $normalized = Get-NormalizedPath $entry
    if ($binsToRemove -notcontains $normalized) {
      $entry
    }
  }

  $env:Path = ($kept -join ';')
}

function Prepend-PathIfExists {
  param([Parameter(Mandatory = $true)][string]$Path)

  if (-not (Test-Path $Path)) {
    return
  }

  $normalizedToAdd = Get-NormalizedPath $Path
  $kept = foreach ($entry in ($env:Path -split ';')) {
    if ([string]::IsNullOrWhiteSpace($entry)) {
      continue
    }

    $normalized = Get-NormalizedPath $entry
    if ($normalized -ne $normalizedToAdd) {
      $entry
    }
  }

  $env:Path = "$Path;$($kept -join ';')"
}

function Set-OptionalEnvironmentVariable {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [AllowNull()][string]$Value
  )

  if ([string]::IsNullOrWhiteSpace($Value)) {
    Remove-Item "Env:\$Name" -ErrorAction SilentlyContinue
  } else {
    Set-Item "Env:\$Name" -Value $Value
  }
}

function Use-FlutterEnvironment {
  param(
    [Parameter(Mandatory = $true)][ValidateSet("official", "ohos")][string]$Kind,
    [switch]$CheckVersion
  )

  if ($Kind -eq "official") {
    $flutterHome = Get-RequiredConfiguredValue "FLUTTER_OFFICIAL_HOME"
    $pubCache = Get-RequiredConfiguredValue "PUB_CACHE_OFFICIAL"
    $label = "Official Flutter"
  } else {
    $flutterHome = Get-RequiredConfiguredValue "FLUTTER_OHOS_HOME"
    $pubCache = Get-RequiredConfiguredValue "PUB_CACHE_OHOS"
    $devecoSdkHome = Get-RequiredConfiguredValue "DEVECO_SDK_HOME"
    $Script:DevecoSdkHome = $devecoSdkHome
    if ([string]::IsNullOrWhiteSpace($Script:DevecoStudioHome)) {
      $Script:DevecoStudioHome = Split-Path -Path $devecoSdkHome -Parent
    }
    $label = "OpenHarmony Flutter"
  }

  $flutterBin = Join-Path $flutterHome "bin"
  $flutterBat = Join-Path $flutterBin "flutter.bat"

  if (-not (Test-Path $flutterBat)) {
    throw "$label was not found at: $flutterBat"
  }

  Remove-ManagedBinsFromPath

  if (-not (Test-Path $pubCache)) {
    New-Item -ItemType Directory -Path $pubCache -Force | Out-Null
  }

  $env:Path = "$flutterBin;$env:Path"
  $env:FLUTTER_ROOT = $flutterHome
  $env:PUB_CACHE = $pubCache
  Set-OptionalEnvironmentVariable -Name "PUB_HOSTED_URL" -Value $Script:PubHostedUrl
  Set-OptionalEnvironmentVariable -Name "FLUTTER_STORAGE_BASE_URL" -Value $Script:FlutterStorageBaseUrl

  if ($Kind -eq "ohos") {
    $env:DEVECO_SDK_HOME = $Script:DevecoSdkHome
    $env:HOS_SDK_HOME = $Script:DevecoSdkHome
    $env:FLUTTER_GIT_URL = $Script:OhosFlutterGitUrl
    foreach ($toolPath in (Get-OhosToolPaths)) {
      Prepend-PathIfExists $toolPath
    }
  } else {
    Remove-Item Env:\FLUTTER_GIT_URL -ErrorAction SilentlyContinue
  }

  Write-Host ""
  Write-Host "Active environment: $label"
  Write-Host "FLUTTER_ROOT: $env:FLUTTER_ROOT"
  Write-Host "PUB_CACHE:    $env:PUB_CACHE"
  if ($Kind -eq "ohos") {
    Write-Host "DEVECO_SDK_HOME: $env:DEVECO_SDK_HOME"
  }
  Write-Host ""
  Write-Host "flutter:"
  where.exe flutter
  Write-Host ""
  Write-Host "dart:"
  where.exe dart

  if ($CheckVersion) {
    Write-Host ""
    flutter --version
  }
}
