# Agent Guide

## Project

- Flutter app with Riverpod state management and YAML persistence.
- Entry point: `lib/main.dart`; app shell and startup loading: `lib/main_app.dart`.
- UI screens live under `lib/screens/`.
- Providers and notifiers are defined in `lib/services/providers_service.dart`.
- Local persistence is implemented by `lib/services/storage_service.dart`, `lib/services/list_service.dart`, and `lib/services/settings_service.dart`.
- Google authentication and Drive `appDataFolder` access are owned by `lib/services/google_drive_service.dart`.

## Commands

- Install dependencies: `flutter pub get`
- Analyze Dart code: `flutter analyze`
- Run tests: `flutter test` (there is currently no `test/` directory)
- Run the app: `./run.ps1`
- Build Android APK and app bundle: `./build_android.ps1`
- Build the web app in debug mode: `./build_web.ps1`
- CI deploys web with base path `/listocheck/`; preserve that base path when changing deployment configuration.

Use the project PowerShell scripts when their behavior is intended. They pass `APP_VERSION` from `pubspec.yaml`; do not assume that Dart define is consumed unless the code explicitly reads it.

## Conventions

- Keep state changes in Riverpod notifiers/services and keep screens focused on UI and user actions.
- Edit localization source files `lib/l10n/app_*.arb`, then run `flutter gen-l10n`; do not edit `lib/l10n/generated/` manually.
- Preserve the existing Russian/English localization setup in `lib/l10n/l10n.dart` and verify both ARB key sets after localization changes.
- Keep shared filenames, defaults, and OAuth constants in `lib/constants.dart`.
- Verify web-specific code with `flutter build web`; `dart:io`, platform plugins, and browser APIs need explicit `kIsWeb`/platform handling.
- Web Google Sign-In uses `googleWebClientId` as `clientId`; do not pass `serverClientId` on web. OAuth authorized origins, enabled APIs, consent-screen settings, and People API access are configured outside this repository.

## Generated And Ignored Files

Do not manually edit or commit generated/build output such as:

- `build/`
- `.dart_tool/`
- `lib/l10n/generated/`
- generated plugin registrants and platform build intermediates

`analysis_options.yaml` excludes platform directories from analyzer checks, so native Android/iOS configuration changes require platform-specific validation.
