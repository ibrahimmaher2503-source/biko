# Code Style & Lint Rules

## Dart/Flutter Conventions
- `prefer_single_quotes` — use single quotes for strings.
- `require_trailing_commas` — always add trailing commas in argument lists.
- `prefer_const_constructors` — use `const` wherever possible.
- `prefer_final_locals` — use `final` for local variables that aren't reassigned.
- `avoid_print` — use proper logging, never `print()`.
- `sort_child_properties_last` — `child:` goes last in widget constructors.
- `sort_constructors_first` — constructors appear before other members.

## Project Structure
- Feature-first: `lib/features/<feature>/screens/`, `controllers/`, `bindings/`, `widgets/`.
- Shared code: `lib/core/` — theme, routes, services, widgets, models, translations, constants.
- Features must NOT import from other features' internal files.
- Cross-feature communication goes through `core/` services or GetX route arguments.

## SDK
- Dart ^3.9.2, Flutter, Material 3.
- See `analysis_options.yaml` for full lint config.

## File Naming
- Snake_case for all Dart files.
- Feature folders match the feature name.
- Test files mirror source structure under `test/`.


RULE-01  Read stitch/ design file for the screen before writing any UI code
RULE-02  All colors → AppTheme.colorName (never Color(0xFF...))
RULE-03  All text strings → 'key'.tr (never hardcoded strings)
RULE-04  All spacing/radius → AppDimensions constants (never magic numbers)
RULE-05  Reuse existing shared widgets from lib/core/widgets/ before creating new ones
RULE-06  Controller must have no Firebase/Firestore imports — use services only
RULE-07  View must have no business logic — only Obx() reactive reads + user events
RULE-08  Service must have no UI imports (no BuildContext, no Navigator)
RULE-09  Every model needs fromMap(), toMap(), copyWith()
RULE-10  Every controller must cancel all stream subscriptions in onClose()
RULE-11  Every screen needs: loading state, error state, empty state
RULE-12  No print() — use debugPrint() or logger
RULE-13  Run flutter analyze after every file — fix all warnings before moving on
RULE-14  Screen width must work at 360px (small Android phone)
RULE-15  After each feature: run flutter test for the feature's widget tests

// Check these exist before creating duplicates:
lib/core/widgets/
├── app_map_widget.dart          // Map with polyline, markers — extend for tracking
├── app_button.dart              // Primary/secondary buttons
├── app_text_field.dart          // Styled text input
├── app_loading.dart             // Loading indicator
├── app_error_widget.dart        // Error state display
├── app_empty_state.dart         // Empty state with icon + message
├── app_bottom_sheet.dart        // Modal bottom sheet wrapper
├── app_dialog.dart              // Confirmation dialog
└── app_snackbar.dart            // Success/error/warning snackbars