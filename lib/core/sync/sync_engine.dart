import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';
import '../../core/network/dio_client.dart';
import 'sync_models.dart';

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(ref.watch(dioProvider));
  ref.onDispose(engine.dispose);
  return engine;
});

/// Main sync engine.
///
/// Responsibilities:
/// - Maintain a persistent outbox of pending mutations
/// - Push mutations to server when online
/// - Pull deltas from server periodically or on reconnect
/// - Retry with exponential backoff
/// - Conflict resolution: last-write-wins for favorites/settings,
///   merge-additive for play history
class SyncEngine {
  SyncEngine(this._dio);

  final dynamic _dio; // Dio

  final List<SyncMutation> _outbox = [];
  int _currentVersion = 0;
  bool _isSyncing = false;
  int _retryCount = 0;
  Timer? _retryTimer;
  Timer? _periodicTimer;

  final _syncStateController = StreamController<SyncEngineEvent>.broadcast();
  Stream<SyncEngineEvent> get events => _syncStateController.stream;

  static const _maxRetries = 5;
  static const _baseRetryDelayMs = 1000;
  static const _periodicSyncIntervalSeconds = 60;

  // ---------------------------------------------------------------------------
  // Outbox management (persisted to JSON file)
  // ---------------------------------------------------------------------------

  Future<File> _outboxFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sync_outbox.json');
  }

  Future<void> _loadOutbox() async {
    try {
      final file = await _outboxFile();
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      _outbox.clear();
      _outbox.addAll(
        list.map((e) => SyncMutation.fromJson(e as Map<String, dynamic>)),
      );
    } catch (e) {
      appLogger.w('Failed to load sync outbox', error: e);
    }
  }

  Future<void> _saveOutbox() async {
    try {
      final file = await _outboxFile();
      await file.writeAsString(jsonEncode(_outbox.map((m) => m.toJson()).toList()));
    } catch (e) {
      appLogger.w('Failed to save sync outbox', error: e);
    }
  }

  Future<File> _versionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/sync_version.json');
  }

  Future<void> _loadVersion() async {
    try {
      final file = await _versionFile();
      if (!file.existsSync()) return;
      final content = await file.readAsString();
      _currentVersion = (jsonDecode(content) as Map<String, dynamic>)['version'] as int? ?? 0;
    } catch (e) {
      appLogger.w('Failed to load sync version', error: e);
    }
  }

  Future<void> _saveVersion(int version) async {
    try {
      final file = await _versionFile();
      await file.writeAsString(jsonEncode({'version': version}));
      _currentVersion = version;
    } catch (e) {
      appLogger.w('Failed to save sync version', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> initialize() async {
    await _loadOutbox();
    await _loadVersion();
    _startPeriodicSync();
  }

  void dispose() {
    _retryTimer?.cancel();
    _periodicTimer?.cancel();
    _syncStateController.close();
  }

  /// Enqueue a mutation to be sent on next sync.
  Future<void> enqueue(SyncMutation mutation) async {
    _outbox.add(mutation);
    await _saveOutbox();
    _syncStateController.add(SyncEngineEvent.pendingCountChanged(_outbox.length));
    unawaited(triggerSync());
  }

  /// Trigger a full sync cycle (push then pull).
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncStateController.add(SyncEngineEvent.syncStarted());

    try {
      await _pushPendingMutations();
      await _pullDeltas();
      _retryCount = 0;
      _retryTimer?.cancel();
      _syncStateController.add(SyncEngineEvent.syncCompleted(_outbox.length));
    } catch (e, st) {
      appLogger.e('Sync failed', error: e, stackTrace: st);
      _syncStateController.add(SyncEngineEvent.syncError(e.toString()));
      _scheduleRetry();
    } finally {
      _isSyncing = false;
    }
  }

  int get pendingCount => _outbox.length;
  int get currentVersion => _currentVersion;

  // ---------------------------------------------------------------------------
  // Push
  // ---------------------------------------------------------------------------

  Future<void> _pushPendingMutations() async {
    if (_outbox.isEmpty) return;

    final batch = List<SyncMutation>.from(_outbox);
    final response = await _dio.post<Map<String, dynamic>>(
      '/sync/push',
      data: {
        'mutations': batch.map((m) => m.toJson()).toList(),
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final result = PushResult.fromJson(data);

    // Remove successfully applied mutations
    final appliedIds = result.applied.map((a) => a.clientMutationId).toSet();
    _outbox.removeWhere((m) => appliedIds.contains(m.clientMutationId));
    await _saveOutbox();

    if (result.conflicts.isNotEmpty) {
      appLogger.w('Sync conflicts: ${result.conflicts.map((c) => c.reason).join(', ')}');
      // Discard conflicting mutations (last-write-wins server side)
      final conflictIds = result.conflicts.map((c) => c.clientMutationId).toSet();
      _outbox.removeWhere((m) => conflictIds.contains(m.clientMutationId));
      await _saveOutbox();
    }
  }

  // ---------------------------------------------------------------------------
  // Pull
  // ---------------------------------------------------------------------------

  Future<void> _pullDeltas() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/sync/pull',
      queryParameters: {'sinceVersion': _currentVersion},
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    if (data == null) return;

    final result = PullResult.fromJson(data);

    if (result.changes.isNotEmpty) {
      _applyDeltas(result.changes);
      await _saveVersion(result.currentVersion);

      // Ack back to server
      await _ackDeltas('all', result.currentVersion);
    }

    // Keep pulling if there's more
    if (result.hasMore) {
      await _pullDeltas();
    }
  }

  Future<void> _ackDeltas(String entityType, int version) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/sync/ack',
        data: {'entityType': entityType, 'version': version},
      );
    } catch (e) {
      appLogger.w('Failed to ack deltas', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Conflict resolution
  // ---------------------------------------------------------------------------

  void _applyDeltas(List<SyncDelta> deltas) {
    // Broadcast deltas to listeners (UI will rebuild from remote data)
    for (final delta in deltas) {
      _syncStateController.add(SyncEngineEvent.deltaReceived(delta));
    }
  }

  // ---------------------------------------------------------------------------
  // Retry & periodic
  // ---------------------------------------------------------------------------

  void _scheduleRetry() {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    final delayMs = _baseRetryDelayMs * (1 << (_retryCount - 1)); // exponential
    appLogger.d('Scheduling sync retry in ${delayMs}ms (attempt $_retryCount)');
    _retryTimer?.cancel();
    _retryTimer = Timer(Duration(milliseconds: delayMs), () => unawaited(triggerSync()));
  }

  void _startPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(
      const Duration(seconds: _periodicSyncIntervalSeconds),
      (_) => unawaited(triggerSync()),
    );
  }
}

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

enum SyncEngineEventType {
  syncStarted,
  syncCompleted,
  syncError,
  deltaReceived,
  pendingCountChanged,
}

class SyncEngineEvent {
  const SyncEngineEvent._({
    required this.type,
    this.delta,
    this.pendingCount,
    this.error,
  });

  factory SyncEngineEvent.syncStarted() =>
      const SyncEngineEvent._(type: SyncEngineEventType.syncStarted);

  factory SyncEngineEvent.syncCompleted(int pendingCount) => SyncEngineEvent._(
        type: SyncEngineEventType.syncCompleted,
        pendingCount: pendingCount,
      );

  factory SyncEngineEvent.syncError(String error) => SyncEngineEvent._(
        type: SyncEngineEventType.syncError,
        error: error,
      );

  factory SyncEngineEvent.deltaReceived(SyncDelta delta) => SyncEngineEvent._(
        type: SyncEngineEventType.deltaReceived,
        delta: delta,
      );

  factory SyncEngineEvent.pendingCountChanged(int count) => SyncEngineEvent._(
        type: SyncEngineEventType.pendingCountChanged,
        pendingCount: count,
      );

  final SyncEngineEventType type;
  final SyncDelta? delta;
  final int? pendingCount;
  final String? error;
}
