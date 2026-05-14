import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/playback/core/audio_service_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BetoothAudioHandler? audioHandler;
  try {
    audioHandler = await AudioService.init<BetoothAudioHandler>(
      builder: BetoothAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.betooth.audio',
        androidNotificationChannelName: 'Betooth',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (e) {
    debugPrint('AudioService init failed: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        if (audioHandler != null)
          audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const BetoothApp(),
    ),
  );
}
