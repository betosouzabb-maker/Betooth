import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/playback/core/audio_service_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioHandler = await AudioService.init<BetoothAudioHandler>(
    builder: BetoothAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.betooth.audio',
      androidNotificationChannelName: 'Betooth',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(audioHandler),
      ],
      child: const BetoothApp(),
    ),
  );
}
