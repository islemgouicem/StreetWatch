# mobile_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Presets (VS Code)

This app reads backend URL from a compile-time define:

- `API_BASE_URL`

If no value is provided, the app uses:

- `http://localhost:8000/api/v1`

Preconfigured launch profiles are available in `.vscode/launch.json`:

- `StreetWatch (Dev - Default)`
- `StreetWatch (Dev - Android Emulator)`
- `StreetWatch (Staging)`
- `StreetWatch (Production)`

Update staging/production URLs in `.vscode/launch.json` before using them.

You can also run manually:

```bash
flutter run --dart-define=API_BASE_URL=https://your-domain.com/api/v1
```
