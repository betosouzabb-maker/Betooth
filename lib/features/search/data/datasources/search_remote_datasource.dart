import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/models/playlist_model.dart';
import '../../../../shared/models/track_model.dart';

final searchRemoteDatasourceProvider = Provider<SearchRemoteDatasource>(
  (ref) => SearchRemoteDatasource(ref.watch(dioProvider)),
);

class SearchArtistResult {
  const SearchArtistResult({
    required this.id,
    required this.name,
    required this.slug,
    required this.artistType,
    required this.isVerified,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String artistType;
  final bool isVerified;
  final String? imageUrl;

  factory SearchArtistResult.fromJson(Map<String, dynamic> json) {
    return SearchArtistResult(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      artistType: json['artistType'] as String? ?? 'SOLO',
      isVerified: json['isVerified'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}

class SearchAlbumResult {
  const SearchAlbumResult({
    required this.id,
    required this.title,
    required this.slug,
    required this.artist,
    this.coverUrl,
    this.releaseDate,
  });

  final String id;
  final String title;
  final String slug;
  final TrackArtistModel artist;
  final String? coverUrl;
  final DateTime? releaseDate;

  factory SearchAlbumResult.fromJson(Map<String, dynamic> json) {
    return SearchAlbumResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      coverUrl: json['coverUrl'] as String?,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.tryParse(json['releaseDate'] as String),
      artist: TrackArtistModel.fromJson(
        json['artist'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class SearchResults {
  const SearchResults({
    required this.tracks,
    required this.artists,
    required this.albums,
    required this.playlists,
  });

  final List<TrackModel> tracks;
  final List<SearchArtistResult> artists;
  final List<SearchAlbumResult> albums;
  final List<PlaylistModel> playlists;

  bool get isEmpty => tracks.isEmpty && artists.isEmpty && albums.isEmpty && playlists.isEmpty;

  factory SearchResults.empty() => const SearchResults(
        tracks: [],
        artists: [],
        albums: [],
        playlists: [],
      );

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    final tracks = (json['tracks'] as List<dynamic>? ?? [])
        .map((t) => TrackModel.fromJson(t as Map<String, dynamic>))
        .toList();
    final artists = (json['artists'] as List<dynamic>? ?? [])
        .map((a) => SearchArtistResult.fromJson(a as Map<String, dynamic>))
        .toList();
    final albums = (json['albums'] as List<dynamic>? ?? [])
        .map((a) => SearchAlbumResult.fromJson(a as Map<String, dynamic>))
        .toList();
    final playlists = (json['playlists'] as List<dynamic>? ?? [])
        .map((p) => PlaylistModel.fromJson(p as Map<String, dynamic>))
        .toList();
    return SearchResults(
      tracks: tracks,
      artists: artists,
      albums: albums,
      playlists: playlists,
    );
  }
}

class SearchHistoryItem {
  const SearchHistoryItem({required this.id, required this.query, required this.createdAt});
  final String id;
  final String query;
  final DateTime createdAt;

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] as String? ?? '',
      query: json['query'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class SearchRemoteDatasource {
  SearchRemoteDatasource(this._dio);

  final Dio _dio;

  Future<SearchResults> search(String query, {String? type, int page = 1}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search',
        queryParameters: {
          'q': query,
          'page': page,
          'visibility': 'public',
          if (type != null) 'type': type,
        },
      );
      final data = _unwrapMap(response.data);
      return SearchResults.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<String>> getSuggestions(String query) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/search/suggestions',
        queryParameters: {'q': query},
      );
      final data = _unwrapMap(response.data);
      final suggestions = data['suggestions'] as List<dynamic>? ?? [];
      return suggestions
          .map((s) => (s as Map<String, dynamic>)['text'] as String? ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } on DioException catch (_) {
      return [];
    }
  }

  Future<List<SearchHistoryItem>> getHistory() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/search/recent');
      final data = _unwrapMap(response.data);
      final history = data['history'] as List<dynamic>? ?? [];
      return history
          .map((h) => SearchHistoryItem.fromJson(h as Map<String, dynamic>))
          .toList();
    } on DioException catch (_) {
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      await _dio.delete<Map<String, dynamic>>('/search/recent');
    } on DioException catch (_) {}
  }

  Map<String, dynamic> _unwrapMap(Map<String, dynamic>? payload) {
    final data = payload?['data'];
    if (data is Map<String, dynamic>) return data;
    throw const AppException('Resposta inválida da API.');
  }

  AppException _mapError(DioException error) {
    if (error.error is AppException) return error.error! as AppException;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final msg = (responseData['error'] as Map<String, dynamic>?)?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return AppException(msg);
    }
    return const AppException('Não foi possível concluir a busca.');
  }
}
