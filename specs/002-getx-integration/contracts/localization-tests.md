# Test Contract: GetX Localization & Translations

**Test Suite**: `test/core/getx/localization_test.dart`
**Controller**: `TestLocalizationController`
**Priority**: P4 (Medium-Low)

---

## Test Coverage Requirements

### 1. Translation Lookup

**Test**: `translations return correct Arabic strings`
- **Given**: AppTranslations with Arabic locale
- **When**: Access translation via `'app_name'.tr`
- **Then**: Returns Arabic text (e.g., 'بايك رايد')

**Test**: `translations return correct English strings`
- **Given**: AppTranslations with English locale
- **When**: Access translation via `'app_name'.tr`
- **Then**: Returns English text (e.g., 'BikeRide')

**Test**: `missing translation key returns key itself`
- **Given**: Translation key 'nonexistent_key' not defined
- **When**: Access via `'nonexistent_key'.tr`
- **Then**: Returns 'nonexistent_key' (fallback behavior)

**Test**: `all required keys exist in both locales`
- **Given**: AppTranslations with ar and en maps
- **When**: Verify key counts
- **Then**: Same keys exist in both locales (no missing translations)

---

### 2. Locale Switching

**Test**: `Get.updateLocale switches to Arabic`
- **Given**: App running in English
- **When**: `Get.updateLocale(Locale('ar'))` is called
- **Then**: `Get.locale` equals `Locale('ar')`

**Test**: `Get.updateLocale switches to English`
- **Given**: App running in Arabic
- **When**: `Get.updateLocale(Locale('en'))` is called
- **Then**: `Get.locale` equals `Locale('en')`

**Test**: `translations update immediately after locale switch`
- **Given**: App in Arabic, displaying 'app_name'.tr
- **When**: Switch to English via Get.updateLocale()
- **Then**: Displayed text changes from Arabic to English immediately

**Test**: `locale persists across widget rebuilds`
- **Given**: Locale switched to Arabic
- **When**: Widget rebuilds (e.g., via setState)
- **Then**: Locale still Arabic (not reset to default)

---

### 3. RTL/LTR Text Direction

**Test**: `Arabic locale sets RTL text direction`
- **Given**: App with `locale: Locale('ar')`
- **When**: Check `Directionality.of(context)`
- **Then**: Returns `TextDirection.rtl`

**Test**: `English locale sets LTR text direction`
- **Given**: App with `locale: Locale('en')`
- **When**: Check `Directionality.of(context)`
- **Then**: Returns `TextDirection.ltr`

**Test**: `RTL switches to LTR on locale change`
- **Given**: App in Arabic (RTL)
- **When**: Switch to English via Get.updateLocale()
- **Then**: Directionality changes to LTR

**Test**: `icon positions flip in RTL`
- **Given**: Widget with leading icon in RTL mode
- **When**: Render widget
- **Then**: Icon appears on right side (trailing position in RTL)

---

### 4. Translation Parameters

**Test**: `trParams replaces placeholders correctly`
- **Given**: Translation key 'welcome' = 'Hello @name'
- **When**: Call `'welcome'.trParams({'name': 'John'})`
- **Then**: Returns 'Hello John'

**Test**: `trParams with multiple placeholders`
- **Given**: Translation key 'order' = 'Order #@id for @customer'
- **When**: Call `'order'.trParams({'id': '123', 'customer': 'Alice'})`
- **Then**: Returns 'Order #123 for Alice'

**Test**: `trParams with missing parameter`
- **Given**: Translation key 'hello' = 'Hello @name'
- **When**: Call `'hello'.trParams({})` (no name provided)
- **Then**: Returns 'Hello @name' (placeholder not replaced)

---

### 5. App Entry Point Defaults

**Test**: `customer app defaults to Arabic`
- **Given**: Customer app entry point (main_customer.dart)
- **When**: App initializes
- **Then**: `Get.locale` equals `Locale('ar')`

**Test**: `driver app defaults to Arabic`
- **Given**: Driver app entry point (main_driver.dart)
- **When**: App initializes
- **Then**: `Get.locale` equals `Locale('ar')`

**Test**: `admin app defaults to English`
- **Given**: Admin app entry point (main_admin.dart)
- **When**: App initializes
- **Then**: `Get.locale` equals `Locale('en')`

---

### 6. Fallback Behavior

**Test**: `fallback locale used when preferred not available`
- **Given**: App with `fallbackLocale: Locale('en')`
- **When**: Request unsupported locale (e.g., French)
- **Then**: Falls back to English translations

**Test**: `device locale auto-detected`
- **Given**: No explicit locale set
- **When**: App initializes
- **Then**: Uses device system locale if supported

---

### 7. Real-World Translation Keys

**Test**: `common.welcome key exists in both locales`
- **Given**: AppTranslations definition
- **When**: Access `'common.welcome'.tr` in Arabic and English
- **Then**: Returns translated string in both locales

**Test**: `error.network key exists in both locales`
- **Given**: AppTranslations definition
- **When**: Access `'error.network'.tr` in Arabic and English
- **Then**: Returns translated string in both locales

---

## Expected Test Count

**Total**: 20 tests
- Translation lookup: 4 tests
- Locale switching: 4 tests
- RTL/LTR: 4 tests
- Translation parameters: 3 tests
- Entry point defaults: 3 tests
- Fallback: 2 tests
- Real-world keys: 2 tests

---

## Success Criteria

- ✅ All tests pass with zero failures
- ✅ Both Arabic and English locales fully validated
- ✅ RTL/LTR behavior verified in widget tests
- ✅ All three app entry points tested
- ✅ No missing translation keys detected

---

## Edge Cases to Test

- **Empty translation strings**: Key exists but value is empty string
- **Special characters**: Translations with emojis, numbers, punctuation
- **Long translations**: Very long strings that might cause overflow
- **Nested keys**: Translation keys with dot notation (e.g., 'common.welcome')
- **HTML/Markdown**: Translations containing markup (should render as plain text)

---

## Implementation Notes

- **GetMaterialApp required**: Must use GetMaterialApp (not MaterialApp) for translations
- **Translations class**: AppTranslations must implement `Translations` from GetX
- **Widget tests for RTL**: RTL/LTR validation requires full widget tests with context
- **Translation map structure**: Use nested maps: `{'ar': {...}, 'en': {...}}`
- **Cairo font**: Arabic text renders with Cairo font (verify font loads)
- **Plus Jakarta Sans**: English text renders with Plus Jakarta Sans (verify font loads)
