import 'track_model.dart';

class PlaylistModel {
  const PlaylistModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.visibility,
    required this.isCollaborative,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.coverUrl,
  });

  final String id;
  final String title;
  final String slug;
  final String? description;
  final String? coverUrl;
  final String visibility;
  final bool isCollaborative;
  final int itemCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPublic => visibility == 'PUBLIC';

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      visibility: json['visibility'] as String? ?? 'PRIVATE',
      isCollaborative: json['isCollaborative'] as bool? ?? false,
      itemCount: json['itemCount'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PlaylistItemModel {
  const PlaylistItemModel({
    required this.id,
    required this.position,
    required this.addedAt,
    required this.track,
  });

  final String id;
  final int position;
  final DateTime addedAt;
  final TrackModel track;

  factory PlaylistItemModel.fromJson(Map<String, dynamic> json) {
    return PlaylistItemModel(
      id: json['id'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      addedAt: DateTime.tryParse(json['addedAt'] as String? ?? '') ?? DateTime.now(),
      track: TrackModel.fromJson(json['track'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class PlaylistDetailModel extends PlaylistModel {
  const PlaylistDetailModel({
    required super.id,
    required super.title,
    required super.slug,
    required super.visibility,
    required super.isCollaborative,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.coverUrl,
    required this.items,
  }) : super(itemCount: items.length);

  final List<PlaylistItemModel> items;

  factory PlaylistDetailModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((i) => PlaylistItemModel.fromJson(i as Map<String, dynamic>))
        .toList();
    return PlaylistDetailModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      coverUrl: json['coverUrl'] as String?,
      visibility: json['visibility'] as String? ?? 'PRIVATE',
      isCollaborative: json['isCollaborative'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      items: items,
    );
  }
}
