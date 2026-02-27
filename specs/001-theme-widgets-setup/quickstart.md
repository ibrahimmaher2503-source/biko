# Quickstart Guide: Theme System & Shared Widgets

**Feature**: 001-theme-widgets-setup
**Date**: 2026-02-27
**Audience**: Developers building screens for Customer, Driver, or Admin apps

## Overview

This guide shows you how to use the BikeRide theme system and shared widget library to build consistent, localized, and accessible screens quickly.

---

## 1. Using the Theme System

### Accessing Theme Values

```dart
import 'package:biko/core/theme/app_theme.dart';

// In your widget's build method:
@override
Widget build(BuildContext context) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;

  return Container(
    color: colorScheme.primary,        // #e0062e (red)
    child: Text(
      'BikeRide',
      style: theme.textTheme.headlineLarge,
    ),
  );
}
```

### Available Colors

```dart
// From theme.colorScheme
colorScheme.primary           // #e0062e (BikeRide red)
colorScheme.secondary         // #b00423 (dark red)
colorScheme.surface           // #f8f5f6 (light) / #230f13 (dark)
colorScheme.background        // Same as surface
colorScheme.error             // Default Material error color
colorScheme.onPrimary         // White (text on primary)
colorScheme.onSurface         // Dark gray (light mode) / Light gray (dark mode)
```

### Typography Styles

```dart
// Headlines (Cairo for Arabic, Plus Jakarta Sans for English)
theme.textTheme.headlineLarge   // 32sp, bold
theme.textTheme.headlineMedium  // 28sp, bold
theme.textTheme.headlineSmall   // 24sp, semibold

// Body text
theme.textTheme.bodyLarge       // 16sp, regular
theme.textTheme.bodyMedium      // 14sp, regular
theme.textTheme.bodySmall       // 12sp, regular

// Labels/buttons
theme.textTheme.labelLarge      // 16sp, bold (buttons)
theme.textTheme.labelMedium     // 14sp, semibold
```

### Spacing

```dart
// Use theme spacing constants
const EdgeInsets.all(AppSpacing.sm)    // 8dp
const EdgeInsets.all(AppSpacing.md)    // 16dp
const EdgeInsets.all(AppSpacing.lg)    // 24dp
const EdgeInsets.all(AppSpacing.xl)    // 32dp
```

### Border Radius

```dart
// From theme
BorderRadius.circular(theme.borderRadius.default)  // 8dp
BorderRadius.circular(theme.borderRadius.large)    // 12dp
BorderRadius.circular(theme.borderRadius.xl)       // 16dp
```

---

## 2. Using Shared Widgets

### Import

```dart
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_loading.dart';
import 'package:biko/core/widgets/app_snackbar.dart';
```

### AppButton

**Basic usage:**

```dart
AppButton(
  text: 'Get Started'.tr,
  onPressed: () {
    Get.toNamed(AppRoutes.home);
  },
)
```

**With loading state:**

```dart
class MyScreen extends StatelessWidget {
  final isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() => AppButton(
      text: 'Submit'.tr,
      onPressed: _handleSubmit,
      isLoading: isLoading.value,
    ));
  }

  void _handleSubmit() async {
    isLoading.value = true;
    await someAsyncOperation();
    isLoading.value = false;
  }
}
```

**With icon:**

```dart
AppButton(
  text: 'Continue'.tr,
  onPressed: _next,
  trailingIcon: Icons.arrow_forward,
)
```

**Variants:**

```dart
// Primary (default) - filled red button
AppButton(
  text: 'Submit'.tr,
  onPressed: _submit,
  variant: ButtonVariant.primary,
)

// Outline - transparent with red border
AppButton(
  text: 'Cancel'.tr,
  onPressed: () => Get.back(),
  variant: ButtonVariant.outline,
)

// Text only - transparent, no border
AppButton(
  text: 'Skip'.tr,
  onPressed: _skip,
  variant: ButtonVariant.text,
)
```

---

### AppTextField

**Basic text input:**

```dart
final nameController = TextEditingController();

AppTextField(
  controller: nameController,
  label: 'Full Name'.tr,
  hint: 'Enter your full name'.tr,
  prefixIcon: Icons.person,
)
```

**With validation:**

```dart
class ProfileForm extends StatelessWidget {
  final phoneController = TextEditingController();
  final phoneError = Rxn<String>();

  @override
  Widget build(BuildContext context) {
    return Obx(() => AppTextField(
      controller: phoneController,
      label: 'Phone Number'.tr,
      keyboardType: TextInputType.phone,
      prefixIcon: Icons.phone,
      errorText: phoneError.value,
      onChanged: _validatePhone,
    ));
  }

  void _validatePhone(String value) {
    if (value.isEmpty) {
      phoneError.value = 'Phone is required'.tr;
    } else if (!Validators.isValidPhone(value)) {
      phoneError.value = 'Invalid phone number'.tr;
    } else {
      phoneError.value = null;
    }
  }
}
```

**Password field:**

```dart
final passwordController = TextEditingController();
final obscurePassword = true.obs;

Obx(() => AppTextField(
  controller: passwordController,
  label: 'Password'.tr,
  obscureText: obscurePassword.value,
  suffixIcon: obscurePassword.value
      ? Icons.visibility_off
      : Icons.visibility,
  onTap: () => obscurePassword.toggle(),
))
```

---

### AppCard

**Static card:**

```dart
AppCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Trip Details'.tr, style: theme.textTheme.titleMedium),
      SizedBox(height: 8),
      Text('Cairo to Alexandria', style: theme.textTheme.bodyMedium),
    ],
  ),
)
```

**Tappable card:**

```dart
AppCard(
  onTap: () => Get.toNamed(AppRoutes.tripDetails, arguments: trip),
  child: ListTile(
    leading: Icon(Icons.location_on),
    title: Text(trip.destination),
    subtitle: Text(trip.distance),
    trailing: Icon(Icons.arrow_forward),
  ),
)
```

---

### AppLoading

**Inline loading:**

```dart
class MyScreen extends StatelessWidget {
  final isLoading = true.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (isLoading.value) {
        return Center(child: AppLoading());
      }
      return _buildContent();
    });
  }
}
```

**Full-screen overlay:**

```dart
Stack(
  children: [
    _buildContent(),
    if (isProcessing.value)
      AppLoading(
        showOverlay: true,
        message: 'Processing payment...'.tr,
      ),
  ],
)
```

---

### AppSnackbar

**Success message:**

```dart
void _saveProfile() async {
  try {
    await profileService.save(profile);
    AppSnackbar.success('Profile saved successfully'.tr);
  } catch (e) {
    AppSnackbar.error('Failed to save profile'.tr);
  }
}
```

**Info/Warning messages:**

```dart
AppSnackbar.info('Trip request sent to nearby drivers'.tr);
AppSnackbar.warning('Your wallet balance is low'.tr);
```

**With custom duration:**

```dart
AppSnackbar.show(
  message: 'Searching for drivers...'.tr,
  type: SnackbarType.info,
  duration: Duration(seconds: 5),
);
```

**With tap action:**

```dart
AppSnackbar.show(
  message: 'New message from driver'.tr,
  type: SnackbarType.info,
  onTap: () => Get.toNamed(AppRoutes.chat),
);
```

---

## 3. Localization

### Using Translations

```dart
import 'package:get/get.dart';

// In your widgets
Text('welcome'.tr)                    // Gets translation for current locale
Text('greeting'.trParams({'name': userName}))  // With parameters
```

### Switching Language

```dart
// In settings screen
void _changeLanguage(String langCode) {
  final locale = Locale(langCode);
  Get.updateLocale(locale);
  // Also save to SharedPreferences for persistence
}
```

### Available Locales

```dart
'ar' → Locale('ar')  // Arabic (RTL, Cairo font)
'en' → Locale('en')  // English (LTR, Plus Jakarta Sans)
```

---

## 4. RTL Support

### Automatic RTL

Most widgets automatically flip for RTL:

```dart
// This Row automatically reverses in RTL
Row(
  children: [
    Icon(Icons.arrow_back),  // Becomes arrow_forward in RTL
    SizedBox(width: 8),
    Text('Back'.tr),
  ],
)
```

### Manual RTL Handling

For custom layouts:

```dart
@override
Widget build(BuildContext context) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  return Row(
    children: [
      if (!isRtl) _buildLeadingIcon(),
      Expanded(child: Text('Content')),
      if (isRtl) _buildLeadingIcon(),
    ],
  );
}
```

---

## 5. Theme Switching

### Light/Dark Mode

```dart
// In settings screen or theme controller
void _toggleTheme() {
  Get.changeThemeMode(
    Get.isDarkMode ? ThemeMode.light : ThemeMode.dark
  );
  // Save preference to SharedPreferences
}
```

### Checking Current Theme

```dart
if (Get.isDarkMode) {
  // Dark mode specific logic
}

// OR
final brightness = Theme.of(context).brightness;
if (brightness == Brightness.dark) {
  // Dark mode
}
```

---

## 6. Complete Example Screen

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:biko/core/widgets/app_button.dart';
import 'package:biko/core/widgets/app_text_field.dart';
import 'package:biko/core/widgets/app_card.dart';
import 'package:biko/core/widgets/app_snackbar.dart';

class ProfileScreen extends StatelessWidget {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final isLoading = false.obs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'.tr),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile card
            AppCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Upload Photo'.tr,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Name field
            AppTextField(
              controller: nameController,
              label: 'Full Name'.tr,
              hint: 'Enter your full name'.tr,
              prefixIcon: Icons.person,
            ),

            SizedBox(height: 16),

            // Phone field
            AppTextField(
              controller: phoneController,
              label: 'Phone Number'.tr,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone,
            ),

            SizedBox(height: 32),

            // Submit button
            Obx(() => AppButton(
              text: 'Save Changes'.tr,
              onPressed: _saveProfile,
              isLoading: isLoading.value,
            )),

            SizedBox(height: 16),

            // Cancel button
            AppButton(
              text: 'Cancel'.tr,
              onPressed: () => Get.back(),
              variant: ButtonVariant.outline,
            ),
          ],
        ),
      ),
    );
  }

  void _saveProfile() async {
    // Validation
    if (nameController.text.isEmpty) {
      AppSnackbar.error('Name is required'.tr);
      return;
    }

    // Save
    isLoading.value = true;
    try {
      await Future.delayed(Duration(seconds: 2)); // Simulate API call
      AppSnackbar.success('Profile saved successfully'.tr);
      Get.back();
    } catch (e) {
      AppSnackbar.error('Failed to save profile'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}
```

---

## 7. Testing Your Screens

### Widget Test Template

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:biko/core/theme/app_theme.dart';

void main() {
  testWidgets('ProfileScreen renders correctly', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        home: ProfileScreen(),
      ),
    );

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.byType(AppButton), findsNWidgets(2));
  });

  testWidgets('ProfileScreen works in dark mode', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: ProfileScreen(),
      ),
    );

    // Verify dark theme applied
    final theme = Theme.of(tester.element(find.byType(ProfileScreen)));
    expect(theme.brightness, Brightness.dark);
  });
}
```

---

## 8. Common Patterns

### Form with Validation

```dart
class LoginForm extends StatelessWidget {
  final formKey = GlobalKey<FormState>();
  final phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          AppTextField(
            controller: phoneController,
            label: 'Phone Number'.tr,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Phone is required'.tr;
              }
              if (!Validators.isValidPhone(value!)) {
                return 'Invalid phone number'.tr;
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          AppButton(
            text: 'Continue'.tr,
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                _submitForm();
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### List of Cards

```dart
ListView.separated(
  itemCount: trips.length,
  separatorBuilder: (_, __) => SizedBox(height: 12),
  itemBuilder: (context, index) {
    final trip = trips[index];
    return AppCard(
      onTap: () => _viewTrip(trip),
      child: ListTile(
        leading: Icon(Icons.location_on, color: theme.colorScheme.primary),
        title: Text(trip.destination),
        subtitle: Text('${trip.distance} • ${trip.date}'),
        trailing: Icon(Icons.arrow_forward),
      ),
    );
  },
)
```

### Empty State

```dart
Center(
  child: AppCard(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inbox, size: 64, color: theme.colorScheme.primary.withOpacity(0.5)),
        SizedBox(height: 16),
        Text(
          'No trips yet'.tr,
          style: theme.textTheme.titleMedium,
        ),
        SizedBox(height: 8),
        Text(
          'Start your first ride now'.tr,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        AppButton(
          text: 'Request Ride'.tr,
          onPressed: () => Get.toNamed(AppRoutes.createTrip),
        ),
      ],
    ),
  ),
)
```

---

## 9. Best Practices

### ✅ Do

- Use theme colors instead of hardcoding: `theme.colorScheme.primary` not `Color(0xFFE0062E)`
- Use shared widgets instead of custom ones: `AppButton` not raw `ElevatedButton`
- Localize all strings: `'text'.tr` not `'text'`
- Test in both light and dark modes
- Test in both Arabic (RTL) and English (LTR)
- Use GetX reactive patterns: `.obs` and `Obx()`

### ❌ Don't

- Don't hardcode colors: `Colors.red` (use theme instead)
- Don't hardcode strings: `'Submit'` (use `'submit'.tr`)
- Don't use `setState`: Use GetX reactive state instead
- Don't create custom buttons/inputs: Use shared widgets
- Don't assume LTR: Always test RTL layouts
- Don't ignore accessibility: Maintain 48dp touch targets

---

## 10. Troubleshooting

### Theme not updating

**Problem**: Theme changes don't reflect immediately

**Solution**: Ensure you're using `GetMaterialApp` and `Get.changeThemeMode()`:

```dart
// ✅ Correct
Get.changeThemeMode(ThemeMode.dark);

// ❌ Wrong
setState(() => _themeMode = ThemeMode.dark);
```

### Translations not working

**Problem**: `.tr` returns key instead of translation

**Solution**: Verify locale files exist and GetMaterialApp has translations:

```dart
GetMaterialApp(
  translations: AppTranslations(),  // ✅ Required
  locale: Locale('ar'),
  fallbackLocale: Locale('en'),
)
```

### RTL layout broken

**Problem**: Icons/layouts don't flip for RTL

**Solution**: Ensure Directionality widget is at app root:

```dart
GetMaterialApp(
  builder: (context, child) {
    return Directionality(
      textDirection: Get.locale?.languageCode == 'ar'
          ? TextDirection.rtl
          : TextDirection.ltr,
      child: child!,
    );
  },
)
```

---

## Need Help?

- **Widget API Reference**: See `contracts/widget-api.md`
- **Theme Details**: See `lib/core/theme/app_theme.dart`
- **Examples**: See test files in `test/core/widgets/`
