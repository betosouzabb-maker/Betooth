enum UploadStatus {
  pending,
  uploading,
  processing,
  completed,
  failed,
  cancelled,
}

class UploadEntity {
  const UploadEntity({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.status,
    this.progress = 0.0,
    this.trackId,
    this.errorMessage,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final int sizeBytes;
  final UploadStatus status;
  final double progress;
  final String? trackId;
  final String? errorMessage;

  UploadEntity copyWith({
    String? id,
    String? fileName,
    String? mimeType,
    int? sizeBytes,
    UploadStatus? status,
    double? progress,
    String? trackId,
    String? errorMessage,
  }) {
    return UploadEntity(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      trackId: trackId ?? this.trackId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UploadEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
