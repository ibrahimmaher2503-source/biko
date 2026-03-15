# Test Factory Contract

**Version**: 1.0.0
**Last Updated**: 2026-03-11
**Applies To**: All test data factories in `test/helpers/test_factories.dart`

## Purpose

Test factories generate realistic test data for domain models. Every factory MUST implement a consistent interface to ensure predictability and ease of use across all test files.

## Contract

### Required Static Methods

Every factory class (e.g., `UserFactory`, `TripFactory`, `BidFactory`) MUST implement:

```dart
class <Model>Factory {
  /// Creates a single instance with optional field overrides
  static <Model>Model create({
    // All model fields as optional named parameters
  }) { ... }

  /// Creates a list of instances with optional shared overrides
  static List<<Model>Model> createList(
    int count, {
    Map<String, dynamic>? overrides,
  }) { ... }
}
```

### Optional Specialized Methods

Factories MAY implement domain-specific convenience methods:

```dart
class UserFactory {
  static UserModel createCustomer({Map<String, dynamic>? overrides}) { ... }
  static UserModel createDriver({Map<String, dynamic>? overrides}) { ... }
  static UserModel createAdmin({Map<String, dynamic>? overrides}) { ... }
}

class TripFactory {
  static TripModel createPending({Map<String, dynamic>? overrides}) { ... }
  static TripModel createAccepted({Map<String, dynamic>? overrides}) { ... }
  static TripModel createCompleted({Map<String, dynamic>? overrides}) { ... }
}
```

## Constraints

### Uniqueness

- All generated IDs MUST be unique across test runs
- Use timestamp-based IDs: `'test_user_${DateTime.now().millisecondsSinceEpoch}'`
- Ensure concurrent factory calls generate distinct IDs

### Realistic Defaults

- Phone numbers: MUST follow Egyptian format `+20` prefix, 11 digits total
- Names: MUST use realistic Arabic names for Egyptian market
- Dates: MUST use recent timestamps (within last 7 days by default)
- Currency: MUST use `EGP` for all monetary fields
- Status enums: MUST use valid enum values from domain models

### Override Mechanism

- All fields MUST be overridable via named parameters
- Overrides MUST take precedence over defaults
- `createList()` overrides MUST apply to all generated instances

## Example Implementation

```dart
class UserFactory {
  static UserModel create({
    String? uid,
    String? phone,
    String? name,
    String? role,
    String? email,
    String? photoUrl,
    DateTime? createdAt,
    bool? isActive,
    double? rating,
    int? totalTrips,
  }) {
    return UserModel(
      uid: uid ?? 'test_user_${DateTime.now().millisecondsSinceEpoch}',
      phone: phone ?? '+201234567890',
      name: name ?? 'أحمد محمد',
      role: role ?? 'customer',
      email: email,
      photoUrl: photoUrl,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: isActive ?? true,
      rating: rating ?? 4.5,
      totalTrips: totalTrips ?? 0,
    );
  }

  static UserModel createCustomer({Map<String, dynamic>? overrides}) {
    return create(
      role: 'customer',
      ...?overrides,
    );
  }

  static List<UserModel> createList(int count, {Map<String, dynamic>? overrides}) {
    return List.generate(
      count,
      (index) => create(...?overrides),
    );
  }
}
```

## Usage in Tests

```dart
void main() {
  group('AuthController Tests', () {
    test('login with phone number', () {
      // Use factory with defaults
      final user = UserFactory.create();
      expect(user.phone, startsWith('+20'));

      // Use factory with overrides
      final customUser = UserFactory.create(
        phone: '+201111111111',
        name: 'Custom Name',
      );
      expect(customUser.phone, equals('+201111111111'));
    });

    test('create multiple users', () {
      // Create 5 users with shared override
      final users = UserFactory.createList(5, {'role': 'driver'});
      expect(users.length, equals(5));
      expect(users.every((u) => u.role == 'driver'), isTrue);
    });
  });
}
```

## Validation

Factories MUST be validated to ensure:
- ✅ All required model fields have defaults
- ✅ Generated IDs are unique across 100+ sequential calls
- ✅ Phone numbers pass `isValidEgyptianPhone()` validation
- ✅ Timestamps are recent (within 7 days)
- ✅ Overrides correctly replace defaults

## Non-Goals

Factories MUST NOT:
- ❌ Persist data to Firestore (factories only create in-memory objects)
- ❌ Call Firebase services (use mock services in tests instead)
- ❌ Generate invalid data (all factory output must pass model validation)
- ❌ Have side effects (factories are pure functions)
