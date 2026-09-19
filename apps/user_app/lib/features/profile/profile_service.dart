import 'dart:typed_data';

import 'package:app_core/app_core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/features/profile/profile_model.dart';

class ProfileService {
  ProfileService(
    this._client, {
    Duration? readTimeout,
    Duration? mutationTimeout,
  }) : _readTimeout = readTimeout ?? recoveryReadTimeout,
       _mutationTimeout = mutationTimeout ?? mutationWaitTimeout;

  final SupabaseClient _client;
  final Duration _readTimeout;
  final Duration _mutationTimeout;

  Future<CustomerProfile> load() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw const ReadFailure(ReadFailureKind.auth);
      final data = await _client
          .from('profiles')
          .select('full_name,phone,profile_photo_url')
          .eq('id', user.id)
          .maybeSingle()
          .timeout(_readTimeout);
      _ensureSameUser(user.id);
      if (data == null) throw const ReadFailure(ReadFailureKind.unavailable);
      final photoPath = data['profile_photo_url'] as String?;
      String? photoUrl;
      if (photoPath != null) {
        try {
          photoUrl = ProfilePhoto.isOwnedPath(photoPath, user.id)
              ? await _client.storage
                    .from('profile-photos')
                    .createSignedUrl(photoPath, 3600)
                    .timeout(_readTimeout)
              : photoPath;
        } catch (_) {
          // The profile remains usable when an old or unavailable photo cannot be read.
        }
      }
      _ensureSameUser(user.id);
      return CustomerProfile(
        email: user.email ?? '',
        fullName: (data['full_name'] as String?)?.trim().isNotEmpty == true
            ? data['full_name'] as String
            : 'عميل بيكو',
        phone: data['phone'] as String?,
        photoPath: photoPath,
        photoUrl: photoUrl,
      );
    } catch (error) {
      throw classifyReadError(error);
    }
  }

  Future<void> save({
    required CustomerProfile current,
    required String fullName,
    required String? phone,
    XFile? newPhoto,
    required bool removePhoto,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw const ReadFailure(ReadFailureKind.auth);
    String? uploadedPath;
    var profileMutationStarted = false;
    try {
      if (newPhoto != null) {
        final bytes = await newPhoto.readAsBytes().timeout(_readTimeout);
        final photo = ProfilePhoto.fromBytes(bytes);
        uploadedPath =
            '${user.id}/${DateTime.now().microsecondsSinceEpoch}.${photo.extension}';
        await _client.storage
            .from('profile-photos')
            .uploadBinary(
              uploadedPath,
              bytes,
              fileOptions: FileOptions(contentType: photo.mimeType),
            )
            .timeout(_mutationTimeout);
      }
      _ensureSameUser(user.id);
      final nextPath = removePhoto ? null : uploadedPath ?? current.photoPath;
      profileMutationStarted = true;
      final savedPath =
          await _client
                  .rpc(
                    'update_own_profile',
                    params: {
                      'p_full_name': fullName,
                      'p_phone': phone,
                      'p_photo_path': nextPath,
                    },
                  )
                  .timeout(_mutationTimeout)
              as String?;
      _ensureSameUser(user.id);
      if (current.photoPath != null &&
          ProfilePhoto.isOwnedPath(current.photoPath!, user.id) &&
          current.photoPath != savedPath) {
        await _deletePhoto(current.photoPath!);
      }
    } catch (_) {
      // A mutation may commit after its client timeout. Keep that object rather
      // than deleting a photo the profile may now reference.
      if (uploadedPath != null &&
          !profileMutationStarted &&
          !await _photoWasApplied(uploadedPath)) {
        await _deletePhoto(uploadedPath);
      }
      rethrow;
    }
  }

  Future<bool> _photoWasApplied(String path) async {
    try {
      return (await load()).photoPath == path;
    } catch (_) {
      return true;
    }
  }

  Future<void> _deletePhoto(String path) async {
    try {
      await _client.storage
          .from('profile-photos')
          .remove([path])
          .timeout(_mutationTimeout);
    } catch (_) {
      // A failed cleanup is harmless; the private object remains owner-scoped.
    }
  }

  void _ensureSameUser(String expectedUserId) {
    if (_client.auth.currentUser?.id != expectedUserId) {
      throw const ReadFailure(ReadFailureKind.auth);
    }
  }
}

class ProfilePhoto {
  const ProfilePhoto._(this.mimeType, this.extension);

  final String mimeType;
  final String extension;

  static bool isOwnedPath(String path, String userId) => RegExp(
    '^${RegExp.escape(userId)}/[^/]+[.](jpg|jpeg|png|webp)' r'$',
  ).hasMatch(path);

  static ProfilePhoto fromBytes(Uint8List bytes) {
    if (bytes.length > 2 * 1024 * 1024) {
      throw const FormatException('الحد الأقصى لحجم الصورة هو 2 ميجابايت.');
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff) {
      return const ProfilePhoto._('image/jpeg', 'jpg');
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0d &&
        bytes[5] == 0x0a &&
        bytes[6] == 0x1a &&
        bytes[7] == 0x0a) {
      return const ProfilePhoto._('image/png', 'png');
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return const ProfilePhoto._('image/webp', 'webp');
    }
    throw const FormatException('اختر صورة بصيغة JPG أو PNG أو WebP.');
  }
}

abstract final class ProfilePhone {
  static bool isValid(String value) {
    final trimmed = value.trim();
    return trimmed.length <= 32 &&
        RegExp(r'^\+?[0-9][0-9 ()-]*$').hasMatch(trimmed) &&
        RegExp(r'[0-9]').allMatches(trimmed).length >= 6;
  }
}
