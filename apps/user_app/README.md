# Biko User App

Flutter customer app for motorcycle rides and parcel delivery.

```powershell
flutter pub get
flutter test
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=your-public-publishable-key
```

Without Supabase values, the app intentionally opens in a disabled setup state.

## Code structure

- `app/`: `user_app`, `user_router`, `user_shell`, and `user_theme`.
- `core/widgets/`: the few widgets shared across features.
- `features/orders/`: order models, rules, service, providers, pages, and widgets.
- `features/maps/`: location picker, route map, place search, and polyline decoding.
- `features/home/`, `features/profile/`, and `features/notifications/`: small focused features with direct file names.

Keep trusted order, pricing, and authorization rules in the existing PostgreSQL RPCs; the User App only validates input, presents state, and invokes those contracts.
