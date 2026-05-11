import 'package:audio_service/audio_service.dart';

class TrackEntity {
  const TrackEntity({
    required this.id,
    required this.title,
    required this.artist,
    this.album,
    this.duration = Duration.zero,
    this.coverUrl,
    this.localPath,
    this.streamUrl,
    this.isDownloaded = false,
  });

  final String id;
  final String title;
  final String artist;
  final String? album;
  final Duration duration;
  final String? coverUrl;
  final String? localPath;
  final String? streamUrl;
  final bool isDownloaded;

  TrackEntity copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? coverUrl,
    String? localPath,
    String? streamUrl,
    bool? isDownloaded,
  }) {
    return TrackEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      coverUrl: coverUrl ?? this.coverUrl,
      localPath: localPath ?? this.localPath,
      streamUrl: streamUrl ?? this.streamUrl,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artUri: coverUrl != null ? Uri.tryParse(coverUrl!) : null,
      extras: <String, dynamic>{
        'localPath': localPath,
        'streamUrl': streamUrl,
        'isDownloaded': isDownloaded,
      },
    );
  }

  static TrackEntity fromMediaItem(MediaItem item) {
    return TrackEntity(
      id: item.id,
      title: item.title,
      artist: item.artist ?? 'Artista desconhecido',
      album: item.album,
      duration: item.duration ?? Duration.zero,
      coverUrl: item.artUri?.toString(),
      localPath: item.extras?['localPath'] as String?,
      streamUrl: item.extras?['streamUrl'] as String?,
      isDownloaded: (item.extras?['isDownloaded'] as bool?) ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TrackEntity && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
