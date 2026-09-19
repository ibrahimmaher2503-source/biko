# User App runtime gallery — wave 2026-09-08

This ledger records only images inspected after capture. The preview target is
`test/ui_preview.dart`: a debug-only, test-directory entrypoint with in-memory
order, map, profile, and onboarding fixtures. It has no runtime path from
`lib/main.dart`, uses no hosted Supabase/Maps/Push credentials, and is not
release acceptance.

| Area | Fixture acceptance | Live-service acceptance | Evidence |
| --- | --- | --- | --- |
| Onboarding and account choice | Pending current emulator build | Not applicable; local onboarding persistence only | — |
| Home, history, profile bottom navigation | Pending current emulator build | Supabase session/history not exercised | — |
| Booking, price entry and keyboard | Pending current emulator build | Places/route quotes use deterministic fake gateway | — |
| Offers, assigned driver, active and terminal states | Pending current emulator build | Order transitions and driver data are not exercised | — |
| Location map and true IME | Pending current emulator build | Live Maps/location permission and hosted Places remain unaccepted | — |

## Runtime checkpoint — BLOCKED_BY_LOCAL_GRADLE

- 2026-09-08: approved `inst_stable` AVD booted; `adb -s emulator-5554 shell
  getprop sys.boot_completed` returned `1`.
- `flutter run -d emulator-5554 -t test/ui_preview.dart
  --dart-define=PREVIEW=onboarding --dart-define=PREVIEW_SELECTOR=true` reached
  `Running Gradle task 'assembleDebug'...` and made no further visible build or
  install progress. The owned Flutter process was inspected once; its Dart
  process was idle and the Gradle daemon log contained only lock heartbeats.
- One bounded retry with `flutter run --no-pub` reached the identical Gradle
  point. Its owned Flutter shell, cmd, and Dart processes were stopped. The
  unrelated Gradle daemon and the booted emulator were deliberately left
  running. No stale installed APK or prior-wave image was substituted.
- Result: **zero new captures**. Onboarding, account choice, Home, booking/IME,
  offers, terminal states, History, and Profile all remain unaccepted at
  runtime until an updated debug build can install.
- `UserShell` captures cover display and its actual bottom navigation only.
  Service-tap navigation is not accepted in this fixture because the target is
  intentionally not the production `GoRouter` app shell.
