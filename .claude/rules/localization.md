# Localization Rules

## Translation System
- Translations are inline in `lib/core/translations/app_translations.dart` (GetX `Translations` class).
- Access via `'key'.tr` in widgets.
- No JSON translation files — everything is in the Dart translations class.

## Language Defaults
- Customer & Driver apps: Arabic (RTL) is default.
- Admin panel: English is default.

## Adding New Strings
- Add BOTH Arabic (AR) and English (EN) keys BEFORE building widgets that use them.
- Never hardcode user-visible text in widgets — always use `.tr`.
- Group translation keys by feature for maintainability.

## RTL Testing
- Test every screen in Arabic RTL mode.
- Verify layouts don't break with longer Arabic text.
- Ensure directional icons flip correctly.

## Target Market
- Egypt only.
- Currency: EGP (Egyptian Pound).
- Phone format: +20 prefix, 11 digits.
