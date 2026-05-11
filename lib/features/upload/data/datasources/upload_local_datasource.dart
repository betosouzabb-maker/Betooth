import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final uploadLocalDatasourceProvider = Provider<UploadLocalDatasource>(
  (ref) => UploadLocalDatasource(),
);

class PendingUpload {
  const PendingUpload({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.checksum,
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.privacy,
  });

  final String id;
  final String filePath;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final String checksum;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? privacy;

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'fileName': fileName,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'checksum': checksum,
        if (title != null) 'title': title,
        if (artist != null) 'artist': artist,
        if (album != null) 'album': album,
        if (genre != null) 'genre': genre,
        if (privacy != null) 'privacy': privacy,
      };

  factory PendingUpload.fromJson(Map<String, dynamic> json) => PendingUpload(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        fileName: json['fileName'] as String,
        mimeType: json['mimeType'] as String,
        sizeBytes: json['sizeBytes'] as int,
        checksum: json['checksum'] as String,
        title: json['title'] as String?,
        artist: json['artist'] as String?,
        album: json['album'] as String?,
        genre: json['genre'] as String?,
        privacy: json['privacy'] as String?,
      );
}

class UploadLocalDatasource {
  static const _fileName = 'pending_uploads.json';

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<PendingUpload>> getPendingUploads() async {
    try {
      final file = await _getFile();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => PendingUpload.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePendingUpload(PendingUpload upload) async {
    final uploads = await getPendingUploads();
    uploads.removeWhere((u) => u.id == upload.id);
    uploads.add(upload);
    final file = await _getFile();
    await file.writeAsString(jsonEncode(uploads.map((u) => u.toJson()).toList()));
  }

  Future<void> removePendingUpload(String uploadId) async {
    final uploads = await getPendingUploads();
    uploads.removeWhere((u) => u.id == uploadId);
    final file = await _getFile();
    await file.writeAsString(jsonEncode(uploads.map((u) => u.toJson()).toList()));
  }

  Future<void> clearAll() async {
    final file = await _getFile();
    if (await file.exists()) await file.delete();
  }
}
