import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'features/playback/core/audio_service_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final overrides = <Override>[];

  try {
    final audioHandler = await AudioService.init<BetoothAudioHandler>(
      builder: BetoothAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.betooth.audio',
        androidNotificationChannelName: 'Betooth',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    overrides.add(audioHandlerProvider.overrideWithValue(audioHandler));
  } catch (e, st) {
    debugPrint('AudioService init failed: $e\n$st');
  }

  runApp(
    ProviderScope(
      overrides: overrides,
      child: const BetoothApp(),
    ),
  );
}
