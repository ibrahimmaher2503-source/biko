# Biko Motorcycle Platform

Arabic-first motorcycle mobility and parcel delivery MVP. The repository contains two Flutter apps, one shared Flutter package, one Next.js dashboard, and a Supabase backend.

## Projects

- `apps/user_app`: customer Flutter app.
- `apps/driver_app`: driver Flutter app.
- `apps/dashboard`: unified Admin/Office Next.js dashboard.
- `packages/app_core`: shared mobile domain types and environment configuration.
- `supabase`: reproducible local backend configuration, migrations, and seed data.
- `docs`: product and implementation specifications.

## Local checks

```powershell
flutter test packages/app_core
flutter test apps/user_app
flutter test apps/driver_app
npm --prefix apps/dashboard run lint
npm --prefix apps/dashboard run build
npx supabase db reset
```

The mobile apps run without credentials in a safe setup state. To connect them, pass the values from the app's `.env.example` as Dart defines:

```powershell
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-public-publishable-key
```

Never pass a Supabase service-role key to a mobile app or browser build.
