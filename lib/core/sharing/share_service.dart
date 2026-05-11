import 'package:share_plus/share_plus.dart';

import '../../shared/models/playlist_model.dart';
import '../../shared/models/track_model.dart';

/// Service for sharing content via the platform share sheet.
class ShareService {
  const ShareService._();

  static const ShareService instance = ShareService._();

  static const String _appStoreUrl = 'https://betooth.app';

  /// Share a [TrackModel] — sends a deep-link + artist/title text.
  Future<void> shareTrack(TrackModel track) async {
    final text =
        '🎵 Ouça "${track.title}" de ${track.artist.name} no Betooth!\n$_appStoreUrl/track/${track.slug}';
    await Share.share(text, subject: track.title);
  }

  /// Share a [PlaylistModel].
  Future<void> sharePlaylist(PlaylistModel playlist) async {
    final text =
        '🎧 Confira a playlist "${playlist.title}" no Betooth!\n$_appStoreUrl/playlist/${playlist.slug}';
    await Share.share(text, subject: playlist.title);
  }

  /// Share the app itself.
  Future<void> shareApp() async {
    const text =
        '🎶 Descubra músicas incríveis no Betooth!\nBaixe agora: $_appStoreUrl';
    await Share.share(text, subject: 'Betooth – música premium');
  }
}
