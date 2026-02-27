# Tasks: Core Theme System and Shared Widgets

**Input**: Design documents from `/specs/001-theme-widgets-setup/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/widget-api.md

**Tests**: Tests are included as recommended in plan.md (widget tests and golden tests for visual regression)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Using Flutter multi-app architecture as defined in plan.md:
- Core code: `lib/core/` (theme, widgets, services, models)
- App entry points: `lib/main_*.dart`
- Assets: `assets/lang/`
- Tests: `test/core/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Flutter dependencies

- [X] T001 Add required dependencies to pubspec.yaml (get: ^4.6.6, firebase_core, google_fonts, flutter_localizations, intl, shared_preferences)
- [X] T002 Run flutter pub get to install dependencies
- [X] T003 [P] Create core directory structure: lib/core/{theme,widgets,constants,routes,services}
- [X] T004 [P] Create assets directory structure: assets/lang/
- [X] T005 [P] Create test directory structure: test/core/{theme,widgets}
- [X] T006 [P] Create features directory: lib/features/auth/controllers/
- [X] T007 Update pubspec.yaml to include assets/lang/ in asset declarations

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T008 Create lib/core/constants/app_constants.dart with spacing scale (8, 12, 16, 24, 32, 48dp)
- [X] T009 [P] Create assets/lang/ar.json with initial common UI strings (app_name, buttons, validation messages)
- [X] T010 [P] Create assets/lang/en.json with matching keys from ar.json
- [X] T011 Create lib/core/routes/app_routes.dart with route name constants for shared, customer, driver, and admin routes
- [X] T012 Create lib/features/auth/controllers/auth_controller.dart as a minimal GetX controller stub (empty for now, needed by entry points)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Consistent Visual Identity Across All Apps (Priority: P1) 🎯 MVP

**Goal**: Centralized theme system with light/dark modes, RTL/LTR support, and consistent typography across all three apps

**Independent Test**: Create a demo screen (lib/demo_theme_screen.dart) that displays all theme colors, both font families, and allows toggling between light/dark modes and Arabic/English languages. Verify colors match design specification exactly.

### Implementation for User Story 1

- [X] T013 [US1] Create lib/core/theme/app_theme.dart with AppColors class defining primary (#e0062e), primaryDark (#b00423), backgroundLight (#f8f5f6), backgroundDark (#230f13), neutralTint (#fcecee)
- [X] T014 [US1] In app_theme.dart, create lightTheme ThemeData with ColorScheme.light() using defined colors, Material 3 enabled
- [X] T015 [US1] In app_theme.dart, create darkTheme ThemeData with ColorScheme.dark() using dark variants
- [X] T016 [US1] In app_theme.dart, configure textTheme for English using GoogleFonts.plusJakartaSansTextTheme() with weights 300-800
- [X] T017 [US1] In app_theme.dart, configure textTheme for Arabic using GoogleFonts.cairoTextTheme() with weights 300-800
- [X] T018 [US1] In app_theme.dart, define borderRadius values in theme extension: default (8dp), large (12dp), xl (16dp), full (9999)
- [X] T019 [US1] In app_theme.dart, configure InputDecorationTheme with rounded borders (xl), focus colors (primary)
- [X] T020 [US1] In app_theme.dart, configure ElevatedButtonThemeData with height 56dp, xl border radius, primary color
- [X] T021 [US1] Create lib/demo_theme_screen.dart demonstrating all theme colors, typography styles, light/dark switching, and RTL/LTR support
- [X] T022 [US1] Create test/core/theme/app_theme_test.dart to verify color values match specification (#e0062e, #f8f5f6, etc.)
- [X] T023 [US1] In app_theme_test.dart, add tests for light and dark theme ColorScheme correctness
- [X] T024 [US1] In app_theme_test.dart, add golden test for theme color palette in light mode saved to test/core/theme/goldens/light_theme.png
- [X] T025 [US1] In app_theme_test.dart, add golden test for theme color palette in dark mode saved to test/core/theme/goldens/dark_theme.png

**Checkpoint**: At this point, User Story 1 should be fully functional - theme system works, demo screen shows all colors/fonts, tests pass

---

## Phase 4: User Story 2 - Reusable Widget Library for Rapid Development (Priority: P2)

**Goal**: Six shared widgets (AppButton, AppTextField, AppCard, AppLoading, AppSnackbar, AppMapWidget) that follow the theme and support RTL/LTR

**Independent Test**: Create a demo screen (lib/demo_widgets_screen.dart) displaying all six widgets in a scrollable list. Test each widget in light/dark modes, Arabic/English, and verify RTL icon flipping, touch targets (48dp min), and theme adaptation.

### Implementation: AppButton Widget

- [X] T026 [P] [US2] Create lib/core/widgets/app_button.dart with ButtonVariant enum (primary, secondary, outline, text)
- [X] T027 [US2] In app_button.dart, implement AppButton StatelessWidget with required text and onPressed parameters
- [X] T028 [US2] In app_button.dart, add optional parameters: variant, isLoading, leadingIcon, trailingIcon, width, height (default 56)
- [X] T029 [US2] In app_button.dart, implement build method returning ElevatedButton/OutlinedButton/TextButton based on variant
- [X] T030 [US2] In app_button.dart, handle disabled state (onPressed == null) with 50% opacity
- [X] T031 [US2] In app_button.dart, handle loading state (isLoading == true) showing CircularProgressIndicator
- [X] T032 [US2] In app_button.dart, implement RTL icon flipping for leadingIcon/trailingIcon using Directionality.of(context)
- [X] T033 [US2] Create test/core/widgets/app_button_test.dart with widget tests for all variants (primary, secondary, outline, text)
- [X] T034 [US2] In app_button_test.dart, add tests for disabled and loading states
- [X] T035 [US2] In app_button_test.dart, add golden tests for each variant in light mode saved to test/core/widgets/goldens/app_button_*.png
- [X] T036 [US2] In app_button_test.dart, add golden tests for RTL layout saved to test/core/widgets/goldens/app_button_rtl.png

### Implementation: AppTextField Widget

- [X] T037 [P] [US2] Create lib/core/widgets/app_text_field.dart with AppTextField StatefulWidget
- [X] T038 [US2] In app_text_field.dart, add required TextEditingController parameter
- [X] T039 [US2] In app_text_field.dart, add optional parameters: label, hint, errorText, prefixIcon, suffixIcon, obscureText, enabled, keyboardType, textInputAction, maxLength, maxLines, validator, onTap, onChanged, onEditingComplete
- [X] T040 [US2] In app_text_field.dart, implement build method returning TextField/TextFormField with Material 3 styling
- [X] T041 [US2] In app_text_field.dart, configure InputDecoration with floatingLabelBehavior, border styles (default, focused, error)
- [X] T042 [US2] In app_text_field.dart, implement RTL icon flipping for prefixIcon/suffixIcon
- [X] T043 [US2] In app_text_field.dart, handle error state with red border and error text below field
- [X] T044 [US2] Create test/core/widgets/app_text_field_test.dart with widget tests for default, focused, error, and disabled states
- [X] T045 [US2] In app_text_field_test.dart, add golden tests for text field states saved to test/core/widgets/goldens/app_text_field_*.png
- [X] T046 [US2] In app_text_field_test.dart, add golden test for RTL layout with prefix/suffix icons

### Implementation: AppCard Widget

- [X] T047 [P] [US2] Create lib/core/widgets/app_card.dart with AppCard StatelessWidget
- [X] T048 [US2] In app_card.dart, add required child parameter and optional parameters: onTap, padding (default 16dp), elevation (default 2), backgroundColor, borderRadius (default 12)
- [X] T049 [US2] In app_card.dart, implement build method returning Card with Material 3 styling
- [X] T050 [US2] In app_card.dart, wrap child in InkWell if onTap is provided for ripple effect
- [X] T051 [US2] Create test/core/widgets/app_card_test.dart with widget tests for tappable and non-tappable variants
- [X] T052 [US2] In app_card_test.dart, add golden tests for card with different elevations saved to test/core/widgets/goldens/app_card_*.png

### Implementation: AppLoading Widget

- [X] T053 [P] [US2] Create lib/core/widgets/app_loading.dart with AppLoading StatelessWidget
- [X] T054 [US2] In app_loading.dart, add optional parameters: showOverlay (default false), color, size (default 40), message
- [X] T055 [US2] In app_loading.dart, implement inline mode (no overlay) with Center + CircularProgressIndicator
- [X] T056 [US2] In app_loading.dart, implement overlay mode with Stack, black overlay (50% opacity), and centered spinner
- [X] T057 [US2] In app_loading.dart, add optional message Text widget below spinner if message parameter provided
- [X] T058 [US2] Create test/core/widgets/app_loading_test.dart with widget tests for inline and overlay modes
- [X] T059 [US2] In app_loading_test.dart, add golden tests for loading states saved to test/core/widgets/goldens/app_loading_*.png

### Implementation: AppSnackbar Utility

- [X] T060 [P] [US2] Create lib/core/widgets/app_snackbar.dart with SnackbarType enum (success, error, info, warning)
- [X] T061 [US2] In app_snackbar.dart, create AppSnackbar class with static show() method accepting message, type, duration, onTap
- [X] T062 [US2] In app_snackbar.dart, implement show() using Get.snackbar() with Material 3 styling
- [X] T063 [US2] In app_snackbar.dart, configure background colors for each type: success (#4CAF50), error (#F44336), info (#2196F3), warning (#FF9800)
- [X] T064 [US2] In app_snackbar.dart, add appropriate icons for each type (check_circle, error, info, warning)
- [X] T065 [US2] In app_snackbar.dart, create convenience methods: success(), error(), info(), warning()
- [X] T066 [US2] In app_snackbar.dart, configure auto-dismiss duration (default 3 seconds), swipe to dismiss, and onTap callback
- [X] T067 [US2] Create test/core/widgets/app_snackbar_test.dart with widget tests for all snackbar types
- [X] T068 [US2] In app_snackbar_test.dart, add tests for auto-dismiss behavior and tap handling

### Implementation: AppMapWidget Placeholder

- [X] T069 [P] [US2] Create lib/core/widgets/app_map_widget.dart with AppMapWidget StatelessWidget
- [X] T070 [US2] In app_map_widget.dart, add optional parameters: height (default 300), initialPosition, zoom (default 15)
- [X] T071 [US2] In app_map_widget.dart, implement build method returning Container with placeholder UI (gray background, map icon, "Map will be implemented" text)
- [X] T072 [US2] In app_map_widget.dart, add TODO comment referencing google_maps_flutter integration in future
- [X] T073 [US2] Create test/core/widgets/app_map_widget_test.dart with basic widget test for placeholder rendering

### Demo and Validation

- [X] T074 [US2] Create lib/demo_widgets_screen.dart demonstrating all six widgets in a scrollable ListView
- [X] T075 [US2] In demo_widgets_screen.dart, add theme toggle button and language toggle button to test widget adaptation
- [X] T076 [US2] In demo_widgets_screen.dart, demonstrate each AppButton variant with examples
- [X] T077 [US2] In demo_widgets_screen.dart, demonstrate AppTextField with validation example
- [X] T078 [US2] In demo_widgets_screen.dart, demonstrate AppCard as both tappable and static
- [X] T079 [US2] In demo_widgets_screen.dart, demonstrate AppLoading in both inline and overlay modes
- [X] T080 [US2] In demo_widgets_screen.dart, add button to trigger AppSnackbar examples for each type
- [X] T081 [US2] In demo_widgets_screen.dart, show AppMapWidget placeholder
- [X] T082 [US2] Run flutter test --update-goldens to generate all golden files for visual regression
- [X] T083 [US2] Run flutter test to verify all widget tests and golden tests pass

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently - theme system + complete widget library with tests

---

## Phase 5: User Story 3 - Proper Entry Points for Multi-App Architecture (Priority: P3)

**Goal**: Three separate entry point files that initialize Firebase, GetX, localization, and navigate to the correct initial screen for each app type

**Independent Test**: Run each app entry point individually (flutter run -t lib/main_customer.dart, etc.) and verify successful initialization, theme application, language loading, and navigation to demo screen. Test on Android, iOS, and Web (for admin).

### Implementation for User Story 3

- [X] T084 [P] [US3] Create lib/core/services/firebase_service.dart with FirebaseService class
- [X] T085 [US3] In firebase_service.dart, implement static initialize() method calling Firebase.initializeApp()
- [X] T086 [US3] In firebase_service.dart, add error handling for Firebase initialization failure
- [X] T087 [P] [US3] Create lib/core/translations/app_translations.dart implementing GetX Translations class
- [X] T088 [US3] In app_translations.dart, implement keys getter loading ar.json and en.json
- [X] T089 [US3] In app_translations.dart, map 'ar' locale to Arabic strings and 'en' locale to English strings
- [X] T090 [P] [US3] Create lib/core/app_initializer.dart with AppInitializer class
- [X] T091 [US3] In app_initializer.dart, create static init() method accepting appBuilder callback and appName parameter
- [X] T092 [US3] In app_initializer.dart, call WidgetsFlutterBinding.ensureInitialized()
- [X] T093 [US3] In app_initializer.dart, call FirebaseService.initialize() with error handling
- [X] T094 [US3] In app_initializer.dart, register AuthController globally using Get.put(AuthController(), permanent: true)
- [X] T095 [US3] In app_initializer.dart, call runApp() with provided appBuilder widget
- [X] T096 [P] [US3] Create lib/main_customer.dart entry point
- [X] T097 [US3] In main_customer.dart, implement main() function calling AppInitializer.init() with CustomerApp builder
- [X] T098 [US3] In main_customer.dart, create CustomerApp widget extending StatelessWidget
- [X] T099 [US3] In CustomerApp build method, return GetMaterialApp with theme (AppTheme.lightTheme), darkTheme (AppTheme.darkTheme), themeMode (ThemeMode.system)
- [X] T100 [US3] In CustomerApp, configure translations (AppTranslations()), locale (Locale('ar')), fallbackLocale (Locale('en'))
- [X] T101 [US3] In CustomerApp, add builder wrapping child in Directionality widget checking Get.locale for RTL/LTR
- [X] T102 [US3] In CustomerApp, set initialRoute to AppRoutes.demoTheme (demo screen from US1)
- [X] T103 [US3] In CustomerApp, configure getPages with demo routes
- [X] T104 [P] [US3] Create lib/main_driver.dart entry point mirroring main_customer.dart structure
- [X] T105 [US3] In main_driver.dart, create DriverApp widget with same configuration as CustomerApp
- [X] T106 [P] [US3] Create lib/main_admin.dart entry point for Flutter Web
- [X] T107 [US3] In main_admin.dart, create AdminApp widget with same configuration but web-optimized routes
- [X] T108 [US3] Update lib/core/routes/app_routes.dart with demo screen routes (demoTheme, demoWidgets)
- [X] T109 [US3] Test customer app launch: flutter run -t lib/main_customer.dart (verify Firebase init, theme, language, demo screen)
- [X] T110 [US3] Test driver app launch: flutter run -t lib/main_driver.dart (verify same as customer)
- [X] T111 [US3] Test admin app launch: flutter run -d chrome -t lib/main_admin.dart (verify web compatibility)

**Checkpoint**: All user stories should now be independently functional - theme + widgets + entry points all working

--- 

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories and final validation

- [X] T112 [P] Update README.md with quickstart instructions for running each app (flutter run -t lib/main_*.dart)
- [X] T113 [P] Add code comments to app_theme.dart explaining how to add custom semantic colors
- [X] T114 [P] Add code comments to shared widgets explaining RTL handling and theme adaptation
- [X] T115 Verify all widgets maintain 48dp minimum touch targets per accessibility requirements
- [X] T116 Verify color contrast ratios meet WCAG AA standards (4.5:1 for text, 3:1 for UI)
- [X] T117 Run flutter analyze to check for linting issues
- [X] T118 Run flutter test to verify all tests pass (theme tests, widget tests, golden tests)
- [X] T119 Test theme switching performance (<16ms per research.md requirement) using Flutter DevTools
- [X] T120 Test app initialization time (<3 seconds per plan.md requirement) on mid-range device
- [X] T121 Create example usage documentation in specs/001-theme-widgets-setup/quickstart.md demonstrating each widget (already created)
- [X] T122 Validate demo screens work correctly in both light/dark modes
- [X] T123 Validate demo screens work correctly in both Arabic (RTL) and English (LTR)
- [X] T124 Take screenshots of demo_theme_screen and demo_widgets_screen for documentation
- [X] T125 Commit all changes with message: "feat: implement core theme system and shared widgets (US1, US2, US3)"

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - **US1 (Theme)**: Can start after Foundational - No dependencies on other stories
  - **US2 (Widgets)**: Can start after Foundational, BUT should ideally wait for US1 theme to be complete for proper theme integration
  - **US3 (Entry Points)**: Can start after Foundational, BUT should ideally wait for US1+US2 to have something to launch
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: ✅ Can start immediately after Foundational - Fully independent
- **User Story 2 (P2)**: ⚠️ Recommended to complete US1 first (widgets need theme), but technically can run in parallel with stub theme
- **User Story 3 (P3)**: ⚠️ Recommended to complete US1+US2 first (entry points need theme + widgets to demo), but technically can run in parallel with stub components

**Recommended Sequential Order**: Phase 1 → Phase 2 → Phase 3 (US1) → Phase 4 (US2) → Phase 5 (US3) → Phase 6

**Aggressive Parallel Order** (if team capacity allows):
1. Phase 1 + Phase 2 (all tasks marked [P] can run in parallel within each phase)
2. After Phase 2: Launch US1, US2, US3 in parallel across three developers
3. Phase 6 polish tasks (many marked [P])

### Within Each User Story

**User Story 1 (Theme)**:
- T013-T020: Theme definition tasks can run sequentially (same file)
- T021: Demo screen depends on T013-T020 completion
- T022-T025: Tests can run in parallel after T013-T021

**User Story 2 (Widgets)**:
- T026-T036: AppButton tasks (can run in parallel with other widgets)
- T037-T046: AppTextField tasks (can run in parallel with other widgets)
- T047-T052: AppCard tasks (can run in parallel with other widgets)
- T053-T059: AppLoading tasks (can run in parallel with other widgets)
- T060-T068: AppSnackbar tasks (can run in parallel with other widgets)
- T069-T073: AppMapWidget tasks (can run in parallel with other widgets)
- T074-T083: Demo and validation depend on all widget implementations

**User Story 3 (Entry Points)**:
- T084-T086: FirebaseService (can run in parallel with translations)
- T087-T089: Translations (can run in parallel with FirebaseService)
- T090-T095: AppInitializer depends on FirebaseService completion
- T096-T103: Customer app (can run in parallel with driver/admin after T090-T095)
- T104-T105: Driver app (can run in parallel with customer/admin)
- T106-T107: Admin app (can run in parallel with customer/driver)
- T108-T111: Testing depends on all entry points being created

### Parallel Opportunities

**Phase 1 (Setup)**: All 7 tasks can run in parallel (different directories)

**Phase 2 (Foundational)**: T009 and T010 (localization files) can run in parallel, others sequential

**Phase 3 (US1 - Theme)**: Tests (T022-T025) can run in parallel after implementation

**Phase 4 (US2 - Widgets)**: All 6 widgets can be implemented in parallel by different developers:
- Developer 1: AppButton (T026-T036)
- Developer 2: AppTextField (T037-T046)
- Developer 3: AppCard (T047-T052)
- Developer 4: AppLoading (T053-T059)
- Developer 5: AppSnackbar (T060-T068)
- Developer 6: AppMapWidget (T069-T073)

**Phase 5 (US3 - Entry Points)**: FirebaseService (T084-T086) + Translations (T087-T089) in parallel, then all 3 entry points (T096-T107) in parallel

**Phase 6 (Polish)**: T112-T114 (documentation) can run in parallel

---

## Parallel Example: User Story 2 (Widgets)

If you have 6 developers available, launch all widgets simultaneously:

```bash
# Developer 1:
Task: "Create AppButton widget implementation and tests (T026-T036)"

# Developer 2:
Task: "Create AppTextField widget implementation and tests (T037-T046)"

# Developer 3:
Task: "Create AppCard widget implementation and tests (T047-T052)"

# Developer 4:
Task: "Create AppLoading widget implementation and tests (T053-T059)"

# Developer 5:
Task: "Create AppSnackbar utility implementation and tests (T060-T068)"

# Developer 6:
Task: "Create AppMapWidget placeholder implementation and tests (T069-T073)"

# After all complete, one developer:
Task: "Create demo screen and validate all widgets (T074-T083)"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

For minimal viable product, complete only the theme system:

1. Complete Phase 1: Setup (T001-T007)
2. Complete Phase 2: Foundational (T008-T012)
3. Complete Phase 3: User Story 1 - Theme (T013-T025)
4. **STOP and VALIDATE**: Test theme system independently using demo screen
5. **MVP READY**: Theme system is functional, developers can start using it

**Deliverable**: Centralized theme system with light/dark modes, RTL/LTR support, verified by tests

### Incremental Delivery (Recommended)

For staged rollout with increasing functionality:

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 (Theme) → Test independently → **Deploy/Demo MVP** ✅
3. Add User Story 2 (Widgets) → Test independently → **Deploy/Demo with Widget Library** ✅
4. Add User Story 3 (Entry Points) → Test independently → **Deploy/Demo Full Multi-App** ✅
5. Add Polish (Phase 6) → Final validation → **Production Ready** 🚀

**Benefits**: Each phase adds value, early feedback, reduced risk

### Parallel Team Strategy

With 3 developers after Foundational phase:

1. **Team completes Setup + Foundational together** (T001-T012)
2. **Developer A**: User Story 1 - Theme System (T013-T025)
3. **Wait for Developer A to finish theme**
4. **Parallel execution after theme ready**:
   - **Developer A**: User Story 3 - Entry Points (T084-T111)
   - **Developer B**: User Story 2 - Widgets 1-3 (T026-T052: AppButton, AppTextField, AppCard)
   - **Developer C**: User Story 2 - Widgets 4-6 (T053-T073: AppLoading, AppSnackbar, AppMapWidget)
5. **Convergence**: All developers validate and test integration
6. **Final Polish**: Distribute Phase 6 tasks (T112-T125)

---

## Notes

- **[P] tasks** = Can run in parallel (different files, no shared state dependencies)
- **[Story] label** = Maps task to specific user story for traceability
- **Tests included**: Widget tests and golden tests per plan.md recommendations
- **Golden tests**: Run `flutter test --update-goldens` first time to generate baseline images
- **Visual regression**: Golden tests catch unintended UI changes across theme updates
- **RTL testing**: Every widget must be tested in both LTR and RTL layouts
- **Theme switching**: Verify theme updates propagate instantly (<16ms)
- **Commit strategy**: Commit after completing each user story phase for clean rollback points
- **Demo screens**: Created for US1 (theme) and US2 (widgets) to enable independent testing
- **Entry points**: US3 wires everything together, making all three apps launchable
- **Firebase config**: Assumed to be added manually (google-services.json, GoogleService-Info.plist) per assumptions in spec.md

---

## Task Summary

- **Total Tasks**: 125 tasks
- **Setup (Phase 1)**: 7 tasks
- **Foundational (Phase 2)**: 5 tasks (BLOCKS all user stories)
- **User Story 1 - Theme (Phase 3)**: 13 tasks (MVP scope)
- **User Story 2 - Widgets (Phase 4)**: 58 tasks (largest phase, highly parallelizable)
- **User Story 3 - Entry Points (Phase 5)**: 28 tasks
- **Polish (Phase 6)**: 14 tasks
- **Parallel opportunities**: ~40 tasks marked [P] can run concurrently
- **Independent stories**: Each user story can be validated independently per acceptance scenarios

---

## Success Validation

After completing all tasks, verify against spec.md success criteria:

- ✅ **SC-001**: Demo screen shows developers can use only theme values and shared widgets
- ✅ **SC-002**: All three apps (customer, driver, admin) display identical widgets when launched
- ✅ **SC-003**: Theme switching in demo screen updates instantly without lag
- ✅ **SC-004**: Language switching in demo screen updates text direction and font
- ✅ **SC-005**: All widgets maintain 48dp touch targets in both RTL/LTR (verified in tests)
- ✅ **SC-006**: Each app initializes and shows demo screen within 3 seconds
- ✅ **SC-007**: Theme colors match design: #e0062e primary, #f8f5f6 light bg, #230f13 dark bg
- ✅ **SC-008**: Text uses Cairo (Arabic) and Plus Jakarta Sans (English) fonts

**Final Checkpoint**: Run all three apps, toggle themes and languages, verify all success criteria met ✅
