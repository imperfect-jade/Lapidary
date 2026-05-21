param([switch]$CheckVersion)
. "$PSScriptRoot\flutter_env_common.ps1"
Use-FlutterEnvironment -Kind ohos -CheckVersion:$CheckVersion
