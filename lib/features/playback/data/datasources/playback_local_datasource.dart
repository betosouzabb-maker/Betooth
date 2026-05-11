import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final playbackLocalDatasourceProvider = Provider<PlaybackLocalDatasource>(
  (ref) => PlaybackLocalDatasource(),
);

class PlaybackLocalDatasource {
  static const _audioSubDir = 'audio';

  Future<String> get audioDirectoryPath async {
    final dir = await getApplicationDocumentsDirectory();
    final audioPath = '${dir.path}/$_audioSubDir';
    final d = Directory(audioPath);
    if (!await d.exists()) {
      await d.create(recursive: true);
    }
    return audioPath;
  }

  Future<String?> getLocalPath(String trackId) async {
    final basePath = await audioDirectoryPath;
    for (final ext in ['mp3', 'mp4', 'm4a', 'wav', 'flac', 'ogg']) {
      final path = '$basePath/$trackId.$ext';
      if (await File(path).exists()) {
        return path;
      }
    }
    return null;
  }

  Future<List<String>> listAvailableTrackIds() async {
    final basePath = await audioDirectoryPath;
    final dir = Directory(basePath);
    if (!await dir.exists()) return const [];

    final ids = <String>[];
    await for (final entity in dir.list()) {
      if (entity is File) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final id = name.contains('.')
            ? name.substring(0, name.lastIndexOf('.'))
            : name;
        ids.add(id);
      }
    }
    return ids;
  }
}
