// Stub for package:file_picker/file_picker.dart
// This file exists because `flutter pub get` requires git which is unavailable.
// Once git is installed, run `flutter pub get` and remove this stub directory.

class PlatformFile {
  const PlatformFile({
    this.name = '',
    this.size = 0,
    this.path,
    this.bytes,
    this.readStream,
    this.identifier,
    this.extension,
  });

  final String name;
  final int size;
  final String? path;
  final List<int>? bytes;
  final Stream<List<int>>? readStream;
  final String? identifier;
  final String? extension;
}

class FilePickerResult {
  const FilePickerResult(this.files);
  final List<PlatformFile> files;
  bool get isSinglePick => files.length == 1;
  PlatformFile? get single => files.isNotEmpty ? files.first : null;
}

enum FileType { any, audio, image, video, media, custom }

abstract class FilePicker {
  static final FilePicker platform = _FilePickerImpl();

  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    String? dialogTitle,
    String? initialDirectory,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  });

  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  });

  Future<void> clearTemporaryFiles();
}

class _FilePickerImpl extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles({
    FileType type = FileType.any,
    String? dialogTitle,
    String? initialDirectory,
    bool allowMultiple = false,
    List<String>? allowedExtensions,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
  }) async =>
      null;

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      null;

  @override
  Future<void> clearTemporaryFiles() async {}
}
