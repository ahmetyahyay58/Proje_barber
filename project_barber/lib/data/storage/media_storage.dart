import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class MediaStorage {
  MediaStorage._();

  static const String bucket = 'app-media';

  static Future<String> uploadImage({
    required String folder,
    required String ownerId,
    required Uint8List bytes,
    required String? extension,
  }) async {
    final client = Supabase.instance.client;
    final ext = _normalizeExt(extension);
    final mime = _contentType(ext);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = '$folder/$ownerId/$fileName';
    await client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mime,
            upsert: true,
          ),
        );
    return client.storage.from(bucket).getPublicUrl(path);
  }

  static String _normalizeExt(String? extension) {
    final ext = (extension ?? 'png').toLowerCase();
    if (ext == 'jpg') return 'jpeg';
    return ext;
  }

  static String _contentType(String ext) {
    return switch (ext) {
      'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };
  }
}

