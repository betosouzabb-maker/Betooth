import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/upload_entity.dart';
import '../../domain/usecases/start_upload_usecase.dart';
import '../../domain/usecases/cancel_upload_usecase.dart';
import '../../domain/usecases/get_upload_status_usecase.dart';

class UploadItem {
  const UploadItem({
    required this.localId,
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.status,
    this.progress = 0.0,
    this.uploadId,
    this.trackId,
    this.errorMessage,
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.privacy,
  });

  final String localId;
  final String filePath;
  final String fileName;
  final int sizeBytes;
  final UploadStatus status;
  final double progress;
  final String? uploadId;
  final String? trackId;
  final String? errorMessage;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final String? privacy;

  UploadItem copyWith({
    String? localId,
    String? filePath,
    String? fileName,
    int? sizeBytes,
    UploadStatus? status,
    double? progress,
    String? uploadId,
    String? trackId,
    String? errorMessage,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? privacy,
  }) {
    return UploadItem(
      localId: localId ?? this.localId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      uploadId: uploadId ?? this.uploadId,
      trackId: trackId ?? this.trackId,
      errorMessage: errorMessage ?? this.errorMessage,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      privacy: privacy ?? this.privacy,
    );
  }
}

class UploadState {
  const UploadState({
    this.items = const [],
    this.isPickingFile = false,
  });

  final List<UploadItem> items;
  final bool isPickingFile;

  UploadState copyWith({
    List<UploadItem>? items,
    bool? isPickingFile,
  }) {
    return UploadState(
      items: items ?? this.items,
      isPickingFile: isPickingFile ?? this.isPickingFile,
    );
  }
}

final uploadControllerProvider =
    StateNotifierProvider<UploadController, UploadState>(
  (ref) => UploadController(
    ref.watch(startUploadUsecaseProvider),
    ref.watch(cancelUploadUsecaseProvider),
    ref.watch(getUploadStatusUsecaseProvider),
  ),
);

class UploadController extends StateNotifier<UploadState> {
  UploadController(
    this._startUpload,
    this._cancelUpload,
    this._getStatus,
  ) : super(const UploadState());

  final StartUploadUsecase _startUpload;
  final CancelUploadUsecase _cancelUpload;
  final GetUploadStatusUsecase _getStatus;

  void _updateItem(String localId, UploadItem Function(UploadItem) updater) {
    state = state.copyWith(
      items: state.items.map((item) {
        if (item.localId == localId) return updater(item);
        return item;
      }).toList(),
    );
  }

  Future<void> startUpload({
    required String filePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required String checksum,
    String? title,
    String? artist,
    String? album,
    String? genre,
    String? privacy,
  }) async {
    final localId = DateTime.now().microsecondsSinceEpoch.toString();

    final item = UploadItem(
      localId: localId,
      filePath: filePath,
      fileName: fileName,
      sizeBytes: sizeBytes,
      status: UploadStatus.uploading,
      progress: 0.0,
      title: title,
      artist: artist,
      album: album,
      genre: genre,
      privacy: privacy,
    );

    state = state.copyWith(items: [...state.items, item]);

    try {
      final result = await _startUpload.call(
        filePath: filePath,
        fileName: fileName,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        checksum: checksum,
        title: title,
        artist: artist,
        album: album,
        genre: genre,
        privacy: privacy,
        onProgress: (progress) {
          _updateItem(localId, (i) => i.copyWith(
                progress: progress,
                status: progress >= 0.9
                    ? UploadStatus.processing
                    : UploadStatus.uploading,
              ));
        },
      );

      _updateItem(
        localId,
        (i) => i.copyWith(
          uploadId: result.id,
          status: UploadStatus.completed,
          progress: 1.0,
          trackId: result.trackId,
        ),
      );
    } on Exception catch (e) {
      _updateItem(
        localId,
        (i) => i.copyWith(
          status: UploadStatus.failed,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> cancelUpload(String localId) async {
    final item = state.items.firstWhere(
      (i) => i.localId == localId,
      orElse: () => throw Exception('Upload não encontrado.'),
    );

    _updateItem(localId, (i) => i.copyWith(status: UploadStatus.cancelled));

    if (item.uploadId != null) {
      await _cancelUpload.call(item.uploadId!).catchError((_) {});
    }
  }

  Future<void> refreshStatus(String localId) async {
    final item = state.items.firstWhere(
      (i) => i.localId == localId,
      orElse: () => throw Exception('Upload não encontrado.'),
    );

    if (item.uploadId == null) return;

    try {
      final updated = await _getStatus.call(item.uploadId!);
      _updateItem(
        localId,
        (i) => i.copyWith(
          status: updated.status,
          trackId: updated.trackId,
          errorMessage: updated.errorMessage,
        ),
      );
    } catch (_) {}
  }

  void removeItem(String localId) {
    state = state.copyWith(
      items: state.items.where((i) => i.localId != localId).toList(),
    );
  }

  void setPickingFile(bool value) {
    state = state.copyWith(isPickingFile: value);
  }
}
