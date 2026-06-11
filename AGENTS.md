# absensi — Flutter + Supabase

## stack

- Flutter (stable), Dart SDK `^3.11.4`, multi-platform (android/ios/linux/macos/web/windows)
- `supabase_flutter: ^2.14.2` for backend
- lint: `package:flutter_lints/flutter.yaml` (no custom rules)

## dev commands (run from repo root)

| command | what |
|---|---|
| `flutter pub get` | install deps |
| `flutter run` | run on connected device / emulator |
| `flutter analyze` | static analysis (lints + type checks) |
| `flutter test` | run all tests |
| `flutter test test/widget_test.dart` | single test file |
| `flutter build apk` / `flutter build ios` etc. | production builds |

## architecture

- **entrypoint:** `lib/main.dart` — calls `Supabase.initialize()` then `runApp(MyApp())`
- **supabase config** (url + anonKey) is hardcoded in `lib/main.dart:6-7` — move to env vars / .env before shipping
- all app code lives under `lib/` (currently just `main.dart` — a default counter template)

## testing

- `flutter_test` with `WidgetTester` — standard Flutter approach
- one smoke test in `test/widget_test.dart`

## important gotchas

- **supabase credentials are committed in plaintext** in `lib/main.dart`. Do not ever leak them in output; treat as sensitive.
- **no state management package** yet (no Riverpod/Bloc/Provider) — default to `setState` unless adding one
- **no assets directory** exists yet — `pubspec.yaml` has commented-out assets section
- **`.agents/PRD.md`** exists but is empty — the product requirements doc lives there
- **`.agents/skills/supabase-postgres-best-practices/`** skill is installed for Postgres/Supabase work
- `build/`, `.dart_tool/`, `.pub-cache/`, `coverage/` are gitignored
- generated files: `.flutter-plugins-dependencies`, `.dart_tool/`, platform-specific `GeneratedPluginRegistrant` files
