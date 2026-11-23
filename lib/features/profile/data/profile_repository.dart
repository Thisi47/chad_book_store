import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(Supabase.instance.client);
});

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;

  User get _user {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Connectez-vous pour modifier votre profil.');
    }
    return user;
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required String email,
  }) async {
    final user = _user;
    await _client.auth.updateUser(
      UserAttributes(
        email: email.trim() == user.email ? null : email.trim(),
        data: {
          ...?user.userMetadata,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
        },
      ),
    );
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _user;
    final extension = fileName.split('.').last.toLowerCase();
    final allowedTypes = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'webp': 'image/webp',
    };
    final contentType = allowedTypes[extension];
    if (contentType == null) {
      throw ArgumentError('Format d’image non pris en charge.');
    }

    final path = '${user.id}/avatar.$extension';
    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);
    await _client.auth.updateUser(
      UserAttributes(data: {...?user.userMetadata, 'avatar_url': publicUrl}),
    );
    return publicUrl;
  }
}
