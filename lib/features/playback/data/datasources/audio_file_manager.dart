import 'dart:io';

class AudioFileManager {
  static const _supportedExtensions = ['mp3', 'mp4', 'm4a', 'wav', 'flac', 'ogg'];

  static Future<bool> checkIntegrity(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return false;
    final size = await file.length();
    return size > 0;
  }

  static Future<List<String>> listAvailableOfflineFiles(
    String directoryPath,
  ) async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) return const [];

    final files = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final ext =
            entity.path.split('.').last.toLowerCase();
        if (_supportedExtensions.contains(ext)) {
          if (await checkIntegrity(entity.path)) {
            files.add(entity.path);
          }
        }
      }
    }
    return files;
  }

  static bool isSupportedFormat(String filePath) {
    final ext = filePath.split('.').last.toLowerCase();
    return _supportedExtensions.contains(ext);
  }
}
