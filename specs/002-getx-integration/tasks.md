# Tasks: GetX Ecosystem Validation

**Input**: Design documents from `/specs/002-getx-integration/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: This feature is entirely test-focused - all tasks create validation tests for existing GetX integration.

**Organization**: Tasks are grouped by user story (P1-P5) to enable independent implementation and testing of each GetX feature category.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (US1, US2, US3, US4, US5)
- Include exact file paths in descriptions

## Path Conventions

- **Tests**: `test/core/getx/` for unit tests, `test/integration/` for integration tests
- **Test Controllers**: Created inline in test files (not production code)
- Paths follow Flutter/Dart conventions from plan.md structure

---

## Phase 1: Setup (Test Infrastructure)

**Purpose**: Create test directory structure and helper utilities

- [X] T001 Create test directory structure: `test/core/getx/` and `test/integration/`
- [X] T002 [P] Verify Flutter test dependencies in pubspec.yaml (flutter_test, get: ^4.6.5)
- [X] T003 [P] Create test helper file `test/helpers/getx_test_helpers.dart` with Get.reset() utilities

**Checkpoint**: Test infrastructure ready - user story test implementation can begin

---

## Phase 2: Foundational (No Blocking Prerequisites)

**Purpose**: This is a validation feature with no foundational blocking tasks. Each user story is independently testable.

**⚠️ NOTE**: Skip this phase - proceed directly to user story implementation

---

## Phase 3: User Story 1 - State Management Validation (Priority: P1) 🎯 MVP

**Goal**: Validate that GetX reactive state management (Rx variables, controllers, GetBuilder, lifecycle) works correctly across all app entry points.

**Independent Test**: Create TestCounterController with reactive variables, trigger state changes, verify observer updates and lifecycle hooks execute properly.

**Contract Reference**: `contracts/state-management-tests.md` (18 tests specified)

### Test Controller for User Story 1

- [X] T004 [US1] Create TestCounterController inline in test file `test/core/getx/state_management_test.dart` with Rx variables (count, message, items, config, isLoading), GetBuilder counter, and lifecycle tracking

### Test Implementation for User Story 1

- [X] T005 [P] [US1] Test: Reactive int (RxInt) triggers observer updates in `test/core/getx/state_management_test.dart`
- [X] T006 [P] [US1] Test: Reactive string (RxString) triggers observer updates in `test/core/getx/state_management_test.dart`
- [X] T007 [P] [US1] Test: Reactive list (RxList) triggers observer updates on add in `test/core/getx/state_management_test.dart`
- [X] T008 [P] [US1] Test: Reactive map (RxMap) triggers observer updates on key change in `test/core/getx/state_management_test.dart`
- [X] T009 [P] [US1] Test: Reactive bool (RxBool) toggles correctly in `test/core/getx/state_management_test.dart`
- [X] T010 [P] [US1] Test: Multiple observers receive updates simultaneously in `test/core/getx/state_management_test.dart`
- [X] T011 [P] [US1] Test: Observer updates reflect correct new value in `test/core/getx/state_management_test.dart`
- [X] T012 [P] [US1] Test: GetBuilder updates only when update() called in `test/core/getx/state_management_test.dart`
- [X] T013 [P] [US1] Test: GetBuilder rebuilds after update() call in `test/core/getx/state_management_test.dart`
- [X] T014 [P] [US1] Test: GetBuilder with ID updates selectively in `test/core/getx/state_management_test.dart`
- [X] T015 [P] [US1] Test: onInit executes before controller usage in `test/core/getx/state_management_test.dart`
- [X] T016 [P] [US1] Test: onReady executes after onInit in `test/core/getx/state_management_test.dart`
- [X] T017 [P] [US1] Test: onClose executes on disposal in `test/core/getx/state_management_test.dart`
- [X] T018 [P] [US1] Test: Lifecycle hooks execute in correct order (onInit → onReady → onClose) in `test/core/getx/state_management_test.dart`
- [X] T019 [P] [US1] Test: Permanent controller survives Get.delete() in `test/core/getx/state_management_test.dart`
- [X] T020 [P] [US1] Test: Non-permanent controller is deleted in `test/core/getx/state_management_test.dart`
- [X] T021 [P] [US1] Test: Permanent controller persists across route changes in `test/core/getx/state_management_test.dart`
- [X] T022 [P] [US1] Test: Get.find() returns same instance (singleton behavior) in `test/core/getx/state_management_test.dart`

**Checkpoint**: User Story 1 complete - Run `flutter test test/core/getx/state_management_test.dart` to verify all 18 tests pass

---

## Phase 4: User Story 2 - Navigation & Routing Validation (Priority: P2)

**Goal**: Validate that GetX navigation (named routes, route parameters, navigation stack management) works correctly across all app entry points.

**Independent Test**: Create TestNavigationController, trigger navigation scenarios (Get.toNamed, Get.offNamed, Get.back), verify correct route transitions and parameter passing.

**Contract Reference**: `contracts/navigation-tests.md` (18 tests specified)

### Test Controller for User Story 2

- [X] T023 [US2] Create TestNavigationController inline in test file `test/core/getx/navigation_test.dart` with route tracking (currentRoute, navigationHistory, lastArguments)

### Test Implementation for User Story 2

- [X] T024 [P] [US2] Test: Get.toNamed navigates to correct route in `test/core/getx/navigation_test.dart`
- [X] T025 [P] [US2] Test: Get.toNamed passes route arguments in `test/core/getx/navigation_test.dart`
- [X] T026 [P] [US2] Test: Get.toNamed adds route to navigation stack in `test/core/getx/navigation_test.dart`
- [X] T027 [P] [US2] Test: Get.offNamed replaces current route in `test/core/getx/navigation_test.dart`
- [X] T028 [P] [US2] Test: Get.offNamed with arguments in `test/core/getx/navigation_test.dart`
- [X] T029 [P] [US2] Test: Get.offAllNamed clears entire stack in `test/core/getx/navigation_test.dart`
- [X] T030 [P] [US2] Test: Get.offAllNamed with predicate in `test/core/getx/navigation_test.dart`
- [X] T031 [P] [US2] Test: Get.back returns to previous route in `test/core/getx/navigation_test.dart`
- [X] T032 [P] [US2] Test: Get.back with result passes data in `test/core/getx/navigation_test.dart`
- [X] T033 [P] [US2] Test: Get.back on root route does nothing in `test/core/getx/navigation_test.dart`
- [X] T034 [P] [US2] Test: Route parameters accessible via Get.arguments in `test/core/getx/navigation_test.dart`
- [X] T035 [P] [US2] Test: Route parameters persist during route lifetime in `test/core/getx/navigation_test.dart`
- [X] T036 [P] [US2] Test: Route parameters cleared on new navigation in `test/core/getx/navigation_test.dart`
- [X] T037 [P] [US2] Test: Bindings instantiate controller on route access in `test/core/getx/navigation_test.dart`
- [X] T038 [P] [US2] Test: Bindings dispose controller on route exit in `test/core/getx/navigation_test.dart`
- [X] T039 [P] [US2] Test: Customer app routes work correctly in `test/core/getx/navigation_test.dart`
- [X] T040 [P] [US2] Test: Driver app routes work correctly in `test/core/getx/navigation_test.dart`
- [X] T041 [P] [US2] Test: Admin app routes work correctly in `test/core/getx/navigation_test.dart`

**Checkpoint**: User Story 2 complete - Run `flutter test test/core/getx/navigation_test.dart` to verify all 18 tests pass

---

## Phase 5: User Story 3 - Dependency Injection Validation (Priority: P3)

**Goal**: Validate that GetX dependency injection (Get.put, Get.lazyPut, Get.find, Get.delete) works correctly with proper singleton behavior and lifecycle management.

**Independent Test**: Create TestServiceController with unique instance ID, test all DI strategies, verify singleton behavior and disposal.

**Contract Reference**: `contracts/di-tests.md` (21 tests specified)

### Test Controller for User Story 3

- [X] T042 [US3] Create TestServiceController inline in test file `test/core/getx/dependency_injection_test.dart` with instanceId, instantiationTime, accessCount, and disposal tracking

### Test Implementation for User Story 3

- [X] T043 [P] [US3] Test: Get.put creates controller immediately in `test/core/getx/dependency_injection_test.dart`
- [X] T044 [P] [US3] Test: Get.put returns singleton instance in `test/core/getx/dependency_injection_test.dart`
- [X] T045 [P] [US3] Test: Get.put with permanent flag persists in `test/core/getx/dependency_injection_test.dart`
- [X] T046 [P] [US3] Test: Get.put without permanent flag can be deleted in `test/core/getx/dependency_injection_test.dart`
- [X] T047 [P] [US3] Test: Get.lazyPut delays instantiation in `test/core/getx/dependency_injection_test.dart`
- [X] T048 [P] [US3] Test: Get.lazyPut instantiates on first Get.find() in `test/core/getx/dependency_injection_test.dart`
- [X] T049 [P] [US3] Test: Get.lazyPut returns same instance on subsequent finds in `test/core/getx/dependency_injection_test.dart`
- [X] T050 [P] [US3] Test: Get.lazyPut with fenix recreates after delete in `test/core/getx/dependency_injection_test.dart`
- [X] T051 [P] [US3] Test: Get.find throws error if not registered in `test/core/getx/dependency_injection_test.dart`
- [X] T052 [P] [US3] Test: Get.find returns correct type in `test/core/getx/dependency_injection_test.dart`
- [X] T053 [P] [US3] Test: Get.find with tag returns tagged instance in `test/core/getx/dependency_injection_test.dart`
- [X] T054 [P] [US3] Test: Get.delete removes controller in `test/core/getx/dependency_injection_test.dart`
- [X] T055 [P] [US3] Test: Get.delete triggers onClose lifecycle in `test/core/getx/dependency_injection_test.dart`
- [X] T056 [P] [US3] Test: Get.delete with tag removes only tagged instance in `test/core/getx/dependency_injection_test.dart`
- [X] T057 [P] [US3] Test: Get.delete on permanent controller does nothing in `test/core/getx/dependency_injection_test.dart`
- [X] T058 [P] [US3] Test: Get.putAsync waits for async initialization in `test/core/getx/dependency_injection_test.dart`
- [X] T059 [P] [US3] Test: Get.putAsync completes before returning instance in `test/core/getx/dependency_injection_test.dart`
- [X] T060 [P] [US3] Test: Get.reset clears all controllers in `test/core/getx/dependency_injection_test.dart`
- [X] T061 [P] [US3] Test: Get.reset disposes non-permanent controllers in `test/core/getx/dependency_injection_test.dart`
- [X] T062 [P] [US3] Test: Get.reset clears permanent controllers too (hard reset) in `test/core/getx/dependency_injection_test.dart`
- [X] T063 [P] [US3] Test: FirebaseService singleton accessible globally in `test/core/getx/dependency_injection_test.dart`

**Checkpoint**: User Story 3 complete - Run `flutter test test/core/getx/dependency_injection_test.dart` to verify all 21 tests pass

---

## Phase 6: User Story 4 - Localization & Translations Validation (Priority: P4)

**Goal**: Validate that GetX translations (translation lookup, locale switching, RTL/LTR) work correctly for Arabic and English.

**Independent Test**: Create TestLocalizationController, switch locales, verify translations update immediately and text direction changes correctly.

**Contract Reference**: `contracts/localization-tests.md` (20 tests specified)

### Test Controller for User Story 4

- [ ] T064 [US4] Create TestLocalizationController inline in test file `test/core/getx/localization_test.dart` with currentLocale and isRTL tracking

### Test Implementation for User Story 4

- [ ] T065 [P] [US4] Test: Translations return correct Arabic strings in `test/core/getx/localization_test.dart`
- [ ] T066 [P] [US4] Test: Translations return correct English strings in `test/core/getx/localization_test.dart`
- [ ] T067 [P] [US4] Test: Missing translation key returns key itself (fallback) in `test/core/getx/localization_test.dart`
- [ ] T068 [P] [US4] Test: All required keys exist in both locales in `test/core/getx/localization_test.dart`
- [ ] T069 [P] [US4] Test: Get.updateLocale switches to Arabic in `test/core/getx/localization_test.dart`
- [ ] T070 [P] [US4] Test: Get.updateLocale switches to English in `test/core/getx/localization_test.dart`
- [ ] T071 [P] [US4] Test: Translations update immediately after locale switch in `test/core/getx/localization_test.dart`
- [ ] T072 [P] [US4] Test: Locale persists across widget rebuilds in `test/core/getx/localization_test.dart`
- [ ] T073 [P] [US4] Test: Arabic locale sets RTL text direction in `test/core/getx/localization_test.dart`
- [ ] T074 [P] [US4] Test: English locale sets LTR text direction in `test/core/getx/localization_test.dart`
- [ ] T075 [P] [US4] Test: RTL switches to LTR on locale change in `test/core/getx/localization_test.dart`
- [ ] T076 [P] [US4] Test: Icon positions flip in RTL (widget test) in `test/core/getx/localization_test.dart`
- [ ] T077 [P] [US4] Test: trParams replaces placeholders correctly in `test/core/getx/localization_test.dart`
- [ ] T078 [P] [US4] Test: trParams with multiple placeholders in `test/core/getx/localization_test.dart`
- [ ] T079 [P] [US4] Test: trParams with missing parameter in `test/core/getx/localization_test.dart`
- [ ] T080 [P] [US4] Test: Customer app defaults to Arabic in `test/core/getx/localization_test.dart`
- [ ] T081 [P] [US4] Test: Driver app defaults to Arabic in `test/core/getx/localization_test.dart`
- [ ] T082 [P] [US4] Test: Admin app defaults to English in `test/core/getx/localization_test.dart`
- [ ] T083 [P] [US4] Test: Fallback locale used when preferred not available in `test/core/getx/localization_test.dart`
- [ ] T084 [P] [US4] Test: Device locale auto-detected in `test/core/getx/localization_test.dart`

**Checkpoint**: User Story 4 complete - Run `flutter test test/core/getx/localization_test.dart` to verify all 20 tests pass

---

## Phase 7: User Story 5 - Snackbar & Dialogs Validation (Priority: P5)

**Goal**: Validate that GetX snackbars work correctly (color mapping, enum validation) and can be displayed without BuildContext.

**Independent Test**: Validate snackbar color constants and enum values (unit tests only due to animation lifecycle limitation). Integration tests validate full rendering.

**Contract Reference**: `contracts/snackbar-tests.md` (11 unit tests + 5 integration tests specified)

**⚠️ KNOWN LIMITATION**: GetX snackbars use AnimationController which fails in unit tests. Only test color mapping and enum validation in unit tests. Full rendering requires integration tests.

### Test Controller for User Story 5

- [ ] T085 [US5] Create TestSnackbarController inline in test file `test/core/getx/snackbar_test.dart` with snackbar history tracking

### Unit Test Implementation for User Story 5

- [ ] T086 [P] [US5] Test: SnackbarType enum has all expected values (success, error, info, warning) in `test/core/getx/snackbar_test.dart`
- [ ] T087 [P] [US5] Test: SnackbarType values accessible by name in `test/core/getx/snackbar_test.dart`
- [ ] T088 [P] [US5] Test: Success type maps to green color in `test/core/getx/snackbar_test.dart`
- [ ] T089 [P] [US5] Test: Error type maps to red color in `test/core/getx/snackbar_test.dart`
- [ ] T090 [P] [US5] Test: Info type maps to blue color in `test/core/getx/snackbar_test.dart`
- [ ] T091 [P] [US5] Test: Warning type maps to orange color in `test/core/getx/snackbar_test.dart`
- [ ] T092 [P] [US5] Test: AppSnackbar.success method exists in `test/core/getx/snackbar_test.dart`
- [ ] T093 [P] [US5] Test: AppSnackbar.error method exists in `test/core/getx/snackbar_test.dart`
- [ ] T094 [P] [US5] Test: AppSnackbar.info method exists in `test/core/getx/snackbar_test.dart`
- [ ] T095 [P] [US5] Test: AppSnackbar.warning method exists in `test/core/getx/snackbar_test.dart`
- [ ] T096 [P] [US5] Test: AppSnackbar.show works without BuildContext in `test/core/getx/snackbar_test.dart`

### Integration Test Implementation for User Story 5

- [ ] T097 [P] [US5] Integration test: Snackbar appears after AppSnackbar.success call in `test/integration/snackbar_integration_test.dart`
- [ ] T098 [P] [US5] Integration test: Snackbar shows correct message text in `test/integration/snackbar_integration_test.dart`
- [ ] T099 [P] [US5] Integration test: Snackbar auto-dismisses after duration in `test/integration/snackbar_integration_test.dart`
- [ ] T100 [P] [US5] Integration test: Snackbar dismisses on tap in `test/integration/snackbar_integration_test.dart`
- [ ] T101 [P] [US5] Integration test: Multiple snackbars queue correctly in `test/integration/snackbar_integration_test.dart`

**Checkpoint**: User Story 5 complete - Run `flutter test test/core/getx/snackbar_test.dart` for unit tests and `flutter test test/integration/snackbar_integration_test.dart` for integration tests

---

## Phase 8: Multi-App Integration Tests

**Goal**: Validate that all three app entry points (customer, driver, admin) initialize GetX correctly with proper locale defaults.

**Independent Test**: Full widget tests that pump each app entry point and verify GetX initialization.

- [ ] T102 [P] Integration test: Customer app initializes GetX correctly with Arabic default in `test/integration/multi_app_init_test.dart`
- [ ] T103 [P] Integration test: Driver app initializes GetX correctly with Arabic default in `test/integration/multi_app_init_test.dart`
- [ ] T104 [P] Integration test: Admin app initializes GetX correctly with English default in `test/integration/multi_app_init_test.dart`
- [ ] T105 [P] Integration test: Full navigation flow across all app routes in `test/integration/full_navigation_flow_test.dart`

**Checkpoint**: All integration tests complete - Run `flutter test test/integration/` to verify all apps initialize correctly

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Documentation, coverage reports, performance profiling, and final validation

- [ ] T106 [P] Run all GetX tests and verify 100% pass rate: `flutter test test/core/getx/`
- [ ] T107 [P] Run all integration tests: `flutter test test/integration/`
- [ ] T108 Generate code coverage report: `flutter test --coverage`
- [ ] T109 Verify coverage exceeds 90% for GetX code paths
- [ ] T110 [P] Run flutter analyze and verify zero GetX-related warnings
- [ ] T111 [P] Create test execution summary in `specs/002-getx-integration/TEST_RESULTS.md`
- [ ] T112 [P] Update README.md with GetX validation results and test execution commands
- [ ] T113 Performance profiling: Use flutter DevTools to check for memory leaks (manual step, document findings in plan.md)
- [ ] T114 Performance profiling: Verify no frame drops during state updates (manual step, document findings in plan.md)
- [ ] T115 Run quickstart.md validation: Execute all commands from quickstart guide
- [ ] T116 Mark all checklist items complete in `specs/002-getx-integration/checklists/requirements.md`

**Final Checkpoint**: All tests pass, coverage > 90%, zero warnings, performance validated

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **User Story 1-5 (Phase 3-7)**: All depend on Setup completion
  - User stories can proceed in parallel (different test files) OR sequentially in priority order (P1 → P2 → P3 → P4 → P5)
- **Multi-App Integration (Phase 8)**: Depends on User Stories 1-4 (navigation and localization needed)
- **Polish (Phase 9)**: Depends on all previous phases being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Setup - No dependencies on other stories ✅ MVP
- **User Story 2 (P2)**: Can start after Setup - No dependencies on other stories
- **User Story 3 (P3)**: Can start after Setup - No dependencies on other stories
- **User Story 4 (P4)**: Can start after Setup - No dependencies on other stories
- **User Story 5 (P5)**: Can start after Setup - No dependencies on other stories
- **Multi-App (Phase 8)**: Depends on US2 (navigation) and US4 (localization) for full app testing

### Within Each User Story

- Test controller creation BEFORE test implementation
- All tests within a story can run in parallel (marked [P])
- Story complete when all tests pass independently

### Parallel Opportunities

**Massive Parallelism Available**:
- All Setup tasks (T001-T003) can run in parallel
- After Setup, ALL 5 user stories (Phase 3-7) can run in parallel (different test files, no conflicts)
- Within each story, ALL tests can run in parallel (all marked [P])
- Integration tests (T097-T105) can all run in parallel
- Polish tasks (T106-T116) can mostly run in parallel

**Example: Launch all User Story 1 tests simultaneously**:
```bash
# All 18 state management tests can be implemented in parallel by different developers
Task T005, T006, T007, T008, T009, T010, T011, T012, T013, T014, T015, T016, T017, T018, T019, T020, T021, T022
```

---

## Parallel Example: All User Stories

After Phase 1 (Setup) completes, ALL user stories can start simultaneously:

```bash
# Developer/Agent 1: User Story 1 (State Management)
Launch T004-T022 in parallel

# Developer/Agent 2: User Story 2 (Navigation)
Launch T023-T041 in parallel

# Developer/Agent 3: User Story 3 (Dependency Injection)
Launch T042-T063 in parallel

# Developer/Agent 4: User Story 4 (Localization)
Launch T064-T084 in parallel

# Developer/Agent 5: User Story 5 (Snackbar)
Launch T085-T101 in parallel
```

---

## Implementation Strategy

### MVP First (User Story 1 Only) 🎯

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 3: User Story 1 - State Management (T004-T022)
3. **STOP and VALIDATE**: Run `flutter test test/core/getx/state_management_test.dart`
4. ✅ MVP Complete: State management validated (most critical GetX feature)

### Incremental Delivery

1. MVP: User Story 1 (State Management) → Test → Validate ✅
2. Add: User Story 2 (Navigation) → Test → Validate ✅
3. Add: User Story 3 (Dependency Injection) → Test → Validate ✅
4. Add: User Story 4 (Localization) → Test → Validate ✅
5. Add: User Story 5 (Snackbar) → Test → Validate ✅
6. Add: Multi-App Integration → Test → Validate ✅
7. Polish: Coverage, performance, documentation → Complete ✅

Each story adds validation coverage without breaking previous stories.

### Parallel Team Strategy

With multiple developers or agents:

1. Complete Setup together (3 tasks, fast)
2. Once Setup done, split user stories:
   - Agent A: User Story 1 (18 tests)
   - Agent B: User Story 2 (18 tests)
   - Agent C: User Story 3 (21 tests)
   - Agent D: User Story 4 (20 tests)
   - Agent E: User Story 5 (16 tests)
3. Stories complete independently, merge results
4. Run integration tests together
5. Polish and validate together

**Total Time (Sequential)**: ~2-3 hours
**Total Time (5 Parallel Agents)**: ~30-45 minutes

---

## Task Summary

| Phase | Task Range | Count | User Story | Test Type |
|-------|-----------|-------|------------|-----------|
| Setup | T001-T003 | 3 | - | Infrastructure |
| US1: State Management | T004-T022 | 19 | P1 🎯 MVP | Unit tests |
| US2: Navigation | T023-T041 | 19 | P2 | Widget tests |
| US3: Dependency Injection | T042-T063 | 22 | P3 | Unit tests |
| US4: Localization | T064-T084 | 21 | P4 | Unit + Widget tests |
| US5: Snackbar | T085-T101 | 17 | P5 | Unit + Integration tests |
| Multi-App Integration | T102-T105 | 4 | - | Integration tests |
| Polish | T106-T116 | 11 | - | Validation |
| **TOTAL** | **T001-T116** | **116** | - | - |

**Test Count Breakdown**:
- State Management: 18 tests
- Navigation: 18 tests
- Dependency Injection: 21 tests
- Localization: 20 tests
- Snackbar: 11 unit + 5 integration = 16 tests
- Multi-App: 4 integration tests
- **Total: ~97 validation tests**

**Parallel Opportunities**: 110+ tasks can run in parallel (95% of all tasks!)

**Suggested MVP**: User Story 1 only (T001-T022 = 22 tasks, ~18 tests)

---

## Notes

- [P] = Parallel (different files, no dependencies) - 110+ tasks marked parallel
- [US1-US5] = User story label for traceability
- Each user story is independently completable and testable
- All tests use `Get.testMode = true` and `Get.reset()` in setUp/tearDown
- Snackbar tests limited by animation lifecycle (see research.md for workaround)
- No production code changes - this feature only validates existing GetX integration
- Commit after each user story completion
- Stop at any checkpoint to validate story independently
