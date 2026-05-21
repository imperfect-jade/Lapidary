# Flutter environment switch

This project can be developed with two Flutter SDKs:

- Official Flutter for Android.
- OpenHarmony Flutter for HarmonyOS.

The two SDKs should not share the same Pub cache. The scripts in this folder
only change the current terminal session; they do not permanently rewrite the
global `Path`.

## Required user variables

Configure these paths on each development machine before using the switch
scripts:

```powershell
[Environment]::SetEnvironmentVariable("FLUTTER_OFFICIAL_HOME", "<path-to-official-flutter-sdk>", "User")
[Environment]::SetEnvironmentVariable("FLUTTER_OHOS_HOME", "<path-to-openharmony-flutter-sdk>", "User")
[Environment]::SetEnvironmentVariable("PUB_CACHE_OFFICIAL", "<path-to-official-pub-cache>", "User")
[Environment]::SetEnvironmentVariable("PUB_CACHE_OHOS", "<path-to-ohos-pub-cache>", "User")
[Environment]::SetEnvironmentVariable("DEVECO_SDK_HOME", "<path-to-deveco-sdk>", "User")
```

Optional variables:

- `DEVECO_STUDIO_HOME`: DevEco Studio root. If omitted, it is inferred from
  `DEVECO_SDK_HOME`.
- `PUB_HOSTED_URL`: Pub mirror, for example `https://pub.flutter-io.cn`.
- `FLUTTER_STORAGE_BASE_URL`: Flutter storage mirror, for example
  `https://storage.flutter-io.cn`.
- `FLUTTER_GIT_URL`: OpenHarmony Flutter git URL. If omitted, the script uses
  `https://gitcode.com/openharmony-tpc/flutter_flutter.git` for HarmonyOS
  terminals only.

Restart the terminal after setting user variables, or run the scripts from a
new PowerShell window.

Alternatively, copy `flutter_env.local.example.ps1` to
`flutter_env.local.ps1` and fill in local paths. `flutter_env.local.ps1` is
ignored by git, so it can keep machine-specific SDK locations without leaking
them into commits.

OpenHarmony Flutter is intentionally not added to the global `Path`.
The global `flutter` command remains the official SDK.

The HarmonyOS script adds DevEco tools only to the current terminal session:

- `tools\ohpm\bin`
- `tools\hvigor\bin`
- `tools\node`
- `sdk\default\openharmony\toolchains`

It also sets `FLUTTER_GIT_URL` only for the HarmonyOS terminal session so the
OpenHarmony Flutter fork does not affect official Flutter.

## Version note

The project currently uses `sdk: ^3.11.4` in `pubspec.yaml`. If the installed
OpenHarmony Flutter SDK uses an older Dart SDK, HarmonyOS dependency resolution
may need a separate compatibility branch or SDK constraint adjustment.

## Android / official Flutter

Open PowerShell in the project root and run:

```powershell
.\tool\flutter_env\use_flutter_official.ps1
flutter pub get
flutter run
```

## HarmonyOS / OpenHarmony Flutter

Open PowerShell in the project root and run:

```powershell
.\tool\flutter_env\use_flutter_ohos.ps1
flutter pub get
flutter create --platforms ohos .
flutter build hap --debug --target-platform ohos-arm64
```

## Optional version check

The scripts skip `flutter --version` by default because Flutter may spend a
long time initializing its cache. To include a version check:

```powershell
.\tool\flutter_env\use_flutter_official.ps1 -CheckVersion
.\tool\flutter_env\use_flutter_ohos.ps1 -CheckVersion
```

## CMD shortcuts

If you use CMD or want a terminal that stays open:

```cmd
tool\flutter_env\open_official_flutter_cmd.cmd
tool\flutter_env\open_ohos_flutter_cmd.cmd
```
