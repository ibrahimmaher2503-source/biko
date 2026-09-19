# Biko Driver App

Flutter operational app shared by independent and office drivers.

```powershell
flutter pub get
flutter test
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-public-publishable-key
```

Without Supabase values, the app intentionally opens in a disabled setup state.

## Code structure

- `main.dart`: startup, session lifecycle, notifications, and routes.
- `features/driver/driver_models.dart`: Driver App read models.
- `features/driver/driver_service.dart`: the Supabase boundary.
- `features/driver/driver_providers.dart`: Riverpod state and mutation recovery.
- `features/driver/driver_screens.dart`: stable presentation entrypoint.
- `features/driver/presentation/`: screen implementations grouped by user journey.

Keep business and authorization rules in the existing PostgreSQL RPCs; presentation files only compose state and actions.
