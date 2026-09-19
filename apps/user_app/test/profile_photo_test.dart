import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:user_app/features/profile/profile_service.dart';

void main() {
  test('profile photo accepts only bounded, real image signatures', () {
    expect(
      ProfilePhoto.fromBytes(Uint8List.fromList([0xff, 0xd8, 0xff])).mimeType,
      'image/jpeg',
    );
    expect(
      () => ProfilePhoto.fromBytes(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    expect(
      ProfilePhoto.isOwnedPath(
        'aabbccdd-0000-4000-8000-000000000001/123.jpg',
        'aabbccdd-0000-4000-8000-000000000001',
      ),
      isTrue,
    );
    expect(
      ProfilePhoto.isOwnedPath(
        'other-user/123.jpg',
        'aabbccdd-0000-4000-8000-000000000001',
      ),
      isFalse,
    );
    expect(ProfilePhone.isValid('+20 100 123 4567'), isTrue);
    expect(ProfilePhone.isValid('1-----'), isFalse);
    expect(ProfilePhone.isValid('+++123456'), isFalse);
  });
}
