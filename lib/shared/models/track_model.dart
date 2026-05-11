class TrackArtistModel {
  const TrackArtistModel({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String? imageUrl;

  factory TrackArtistModel.fromJson(Map<String, dynamic> json) {
    return TrackArtistModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class TrackAlbumModel {
  const TrackAlbumModel({
    required this.id,
    required this.title,
    required this.slug,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String slug;
  final String? coverUrl;

  factory TrackAlbumModel.fromJson(Map<String, dynamic> json) {
    return TrackAlbumModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
    );
  }
}

class TrackVersionModel {
  const TrackVersionModel({
    required this.id,
    required this.audioUrl,
    this.bitrateKbps,
    this.codec,
    required this.isLossless,
  });

  final String id;
  final String audioUrl;
  final int? bitrateKbps;
  final String? codec;
  final bool isLossless;

  factory TrackVersionModel.fromJson(Map<String, dynamic> json) {
    return TrackVersionModel(
      id: json['id'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      bitrateKbps: json['bitrateKbps'] as int?,
      codec: json['codec'] as String?,
      isLossless: json['isLossless'] as bool? ?? false,
    );
  }
}

class TrackGenreModel {
  const TrackGenreModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory TrackGenreModel.fromJson(Map<String, dynamic> json) {
    return TrackGenreModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }
}

class TrackModel {
  const TrackModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.durationSeconds,
    required this.isExplicit,
    required this.status,
    required this.artist,
    this.album,
    this.genre,
    this.coverUrl,
    this.versions = const [],
    this.isPrivate = false,
  });

  final String id;
  final String title;
  final String slug;
  final int durationSeconds;
  final bool isExplicit;
  final String status;
  final TrackArtistModel artist;
  final TrackAlbumModel? album;
  final TrackGenreModel? genre;
  final String? coverUrl;
  final List<TrackVersionModel> versions;
  final bool isPrivate;

  String? get thumbnailUrl => coverUrl ?? album?.coverUrl;
  String? get primaryAudioUrl => versions.isNotEmpty ? versions.first.audioUrl : null;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    final versionsList = (json['versions'] as List<dynamic>? ?? [])
        .map((v) => TrackVersionModel.fromJson(v as Map<String, dynamic>))
        .toList();

    return TrackModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      isExplicit: json['isExplicit'] as bool? ?? false,
      status: json['status'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      isPrivate: json['isPrivate'] as bool? ?? false,
      artist: TrackArtistModel.fromJson(
        json['artist'] as Map<String, dynamic>? ?? {},
      ),
      album: json['album'] == null
          ? null
          : TrackAlbumModel.fromJson(json['album'] as Map<String, dynamic>),
      genre: json['genre'] == null
          ? null
          : TrackGenreModel.fromJson(json['genre'] as Map<String, dynamic>),
      versions: versionsList,
    );
  }
}
