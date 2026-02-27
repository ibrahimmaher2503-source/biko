# BikeRide 🏍️

Multi-platform ride-hailing and delivery service for Egypt, supporting motorcycles and scooters.

## 🏗️ Architecture

BikeRide uses a **multi-app architecture** with three separate entry points sharing a common codebase:

- **Customer App** - For users requesting rides/deliveries
- **Driver App** - For motorcycle/scooter drivers
- **Admin Panel** - Web-based management dashboard

All apps share:
- ✅ Theme system (light/dark modes)
- ✅ Widget library (6 production widgets)
- ✅ Localization (Arabic RTL + English LTR)
- ✅ Firebase backend integration
- ✅ GetX state management

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.9.2+
- Dart 3.9.2+
- Firebase project configured (see [Firebase Setup](#firebase-setup))

### Running the Apps

**Customer App (Mobile):**
```bash
flutter run -t lib/main_customer.dart
```

**Driver App (Mobile):**
```bash
flutter run -t lib/main_driver.dart
```

**Admin Panel (Web):**
```bash
flutter run -d chrome -t lib/main_admin.dart
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/core/theme/
flutter test test/core/widgets/

# Run with coverage
flutter test --coverage
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
flutter format lib/ test/

# Generate golden files (visual regression tests)
flutter test --update-goldens
```

## 📁 Project Structure

```
lib/
├── core/                      # Shared core functionality
│   ├── constants/            # App-wide constants
│   ├── routes/               # Route definitions
│   ├── services/             # Services (Firebase, etc.)
│   ├── theme/                # Theme system
│   ├── translations/         # Localization
│   └── widgets/              # Shared widgets (6 production widgets)
├── features/                  # Feature modules
│   └── auth/                 # Authentication feature
├── main_customer.dart        # Customer app entry point
├── main_driver.dart          # Driver app entry point
├── main_admin.dart           # Admin panel entry point
├── demo_theme_screen.dart    # Theme demo (development)
└── demo_widgets_screen.dart  # Widgets demo (development)
```

## 🎨 Theme System

BikeRide uses a centralized theme system with:

- **Colors**: Primary (#E0062E), Primary Dark (#B00423), Background Light (#F8F5F6), Background Dark (#230F13)
- **Typography**: Plus Jakarta Sans (English), Cairo (Arabic)
- **Material 3**: Modern Material Design with custom styling
- **Dark Mode**: Full dark theme support
- **RTL Support**: Automatic layout mirroring for Arabic

## 🧩 Widget Library

Six production-ready shared widgets:

1. **AppButton** - 4 variants (primary, secondary, outline, text) with loading states
2. **AppTextField** - Material 3 text input with validation
3. **AppCard** - Flexible card container with tap support
4. **AppLoading** - Dual-mode loading indicator (inline/overlay)
5. **AppSnackbar** - GetX-based notifications (4 types)
6. **AppMapWidget** - Map placeholder (Google Maps integration planned)

All widgets support:
- ✅ Light/dark themes
- ✅ RTL/LTR layouts
- ✅ Material 3 styling
- ✅ Accessibility (48dp touch targets)

## 🌍 Localization

Default languages:
- **Customer/Driver Apps**: Arabic (ar) with English fallback
- **Admin Panel**: English (en) with Arabic fallback

Switch languages programmatically:
```dart
Get.updateLocale(Locale('ar')); // Switch to Arabic
Get.updateLocale(Locale('en')); // Switch to English
```

## 🔥 Firebase Setup

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Add Android app with package name from `android/app/build.gradle`
3. Download `google-services.json` → `android/app/`
4. Add iOS app with bundle ID from `ios/Runner.xcodeproj`
5. Download `GoogleService-Info.plist` → `ios/Runner/`
6. For web, configure Firebase in `web/index.html`

## 🧪 Testing

**Test Coverage:**
- Theme system: 9 tests passing
- Widget library: 64 tests passing
- **Total: 73 tests passing** ✅

## 📱 Demo Screens

Two demo screens are available for development:

- `/demo-theme` - Theme system showcase (colors, typography, themes)
- `/demo-widgets` - Widget library showcase (all 6 widgets)

Access via routes in any app entry point.

## 🛠️ Development

### State Management

BikeRide uses **GetX** for:
- State management (reactive controllers)
- Routing & navigation
- Dependency injection
- Localization
- Snackbars & dialogs

### Code Style

- Follow Dart style guide
- Use meaningful variable names
- Document public APIs
- Keep widgets small and focused
- Prefer composition over inheritance

### Adding New Features

1. Create feature module in `lib/features/`
2. Follow feature-first structure
3. Add routes to `lib/core/routes/app_routes.dart`
4. Register controllers in app initializer if global
5. Write tests for new functionality

## 📄 License

Copyright © 2025 BikeRide. All rights reserved.

## 🤝 Contributing

This is a private project. Contact the development team for contribution guidelines.

---

**Built with Flutter** 💙 | **Powered by Firebase** 🔥 | **State Management by GetX** ⚡
