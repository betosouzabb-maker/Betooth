import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_monitor.dart';
import 'sync_engine.dart';
import 'sync_models.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  return SyncController(
    syncEngine: ref.watch(syncEngineProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
});

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

enum SyncStatus { idle, syncing, synced, error }

class SyncState {
  const SyncState({
    required this.status,
    required this.pendingCount,
    this.errorMessage,
    this.lastSyncedAt,
  });

  const SyncState.initial()
      : status = SyncStatus.idle,
        pendingCount = 0,
        errorMessage = null,
        lastSyncedAt = null;

  final SyncStatus status;
  final int pendingCount;
  final String? errorMessage;
  final DateTime? lastSyncedAt;

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasError => status == SyncStatus.error;
  bool get hasPending => pendingCount > 0;

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCount,
    String? errorMessage,
    bool clearError = false,
    DateTime? lastSyncedAt,
  }) {
    return SyncState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

class SyncController extends StateNotifier<SyncState> {
  SyncController({
    required SyncEngine syncEngine,
    required ConnectivityMonitor connectivityMonitor,
  })  : _syncEngine = syncEngine,
        super(const SyncState.initial()) {
    _init(connectivityMonitor);
  }

  final SyncEngine _syncEngine;
  StreamSubscription<SyncEngineEvent>? _eventsSubscription;

  void _init(ConnectivityMonitor connectivityMonitor) {
    unawaited(_syncEngine.initialize());

    _eventsSubscription = _syncEngine.events.listen((event) {
      switch (event.type) {
        case SyncEngineEventType.syncStarted:
          state = state.copyWith(status: SyncStatus.syncing, clearError: true);
        case SyncEngineEventType.syncCompleted:
          state = state.copyWith(
            status: SyncStatus.synced,
            pendingCount: event.pendingCount ?? 0,
            clearError: true,
            lastSyncedAt: DateTime.now(),
          );
        case SyncEngineEventType.syncError:
          state = state.copyWith(
            status: SyncStatus.error,
            errorMessage: event.error,
          );
        case SyncEngineEventType.pendingCountChanged:
          state = state.copyWith(pendingCount: event.pendingCount ?? 0);
        case SyncEngineEventType.deltaReceived:
          // Deltas are handled by feature controllers via direct SyncEngine stream
          break;
      }
    });
  }

  /// Enqueue a mutation for sync.
  Future<void> enqueue(SyncMutation mutation) {
    return _syncEngine.enqueue(mutation);
  }

  /// Manually trigger a sync.
  Future<void> sync() {
    return _syncEngine.triggerSync();
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
