import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/app_logger.dart';
import 'sync_engine.dart';

final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  final monitor = ConnectivityMonitor(
    Connectivity(),
    ref.watch(syncEngineProvider),
  );
  ref.onDispose(monitor.dispose);
  return monitor;
});

/// Monitors network connectivity and triggers sync on reconnection.
class ConnectivityMonitor {
  ConnectivityMonitor(this._connectivity, this._syncEngine) {
    _init();
  }

  final Connectivity _connectivity;
  final SyncEngine _syncEngine;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _wasOffline = false;

  final _onlineController = StreamController<bool>.broadcast();
  Stream<bool> get isOnlineStream => _onlineController.stream;

  void _init() {
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object e) => appLogger.w('Connectivity error', error: e),
    );

    // Check initial connectivity
    _connectivity.checkConnectivity().then(_onConnectivityChanged).catchError(
      (Object e) => appLogger.w('Initial connectivity check failed', error: e),
    );
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    _onlineController.add(isOnline);

    if (isOnline && _wasOffline) {
      appLogger.d('Network reconnected — triggering sync');
      unawaited(_syncEngine.triggerSync());
    }

    _wasOffline = !isOnline;
  }

  Future<bool> checkIsOnline() async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
