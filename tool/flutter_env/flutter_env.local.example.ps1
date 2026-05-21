# Copy this file to flutter_env.local.ps1 and update paths for your machine.
# flutter_env.local.ps1 is ignored by git and is loaded before environment
# variables are read by flutter_env_common.ps1.

$env:FLUTTER_OFFICIAL_HOME = "<path-to-official-flutter-sdk>"
$env:FLUTTER_OHOS_HOME = "<path-to-openharmony-flutter-sdk>"
$env:PUB_CACHE_OFFICIAL = "<path-to-official-pub-cache>"
$env:PUB_CACHE_OHOS = "<path-to-ohos-pub-cache>"
$env:DEVECO_SDK_HOME = "<path-to-deveco-sdk>"

# Optional mirrors.
# $env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
# $env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
