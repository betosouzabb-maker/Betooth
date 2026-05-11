/// Simple in-memory TTL (time-to-live) cache.
///
/// Entries expire after [ttl] and are removed lazily on next access.
/// A periodic [Timer] can be started with [startEviction] to proactively
/// clear stale entries.
library;

import 'dart:async';

class _CacheEntry<V> {
  _CacheEntry(this.value, this.expiresAt);

  final V value;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class TtlCache<K, V> {
  TtlCache({this.ttl = const Duration(minutes: 5)});

  /// Default lifetime of each entry.
  final Duration ttl;

  final Map<K, _CacheEntry<V>> _store = {};
  Timer? _evictionTimer;

  /// Store [value] under [key]. Overwrites any existing entry.
  void set(K key, V value) {
    _store[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  /// Return the cached value for [key], or `null` if absent / expired.
  V? get(K key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _store.remove(key);
      return null;
    }
    return entry.value;
  }

  /// Returns `true` if [key] exists and has not expired.
  bool isValid(K key) => get(key) != null;

  /// Remove a single entry, regardless of expiry.
  void invalidate(K key) => _store.remove(key);

  /// Remove all entries.
  void clear() => _store.clear();

  /// Start a periodic timer that removes expired entries every [interval].
  /// Calling this again while a timer is active is a no-op.
  void startEviction([Duration interval = const Duration(minutes: 1)]) {
    _evictionTimer ??= Timer.periodic(interval, (_) => _evict());
  }

  /// Stop the eviction timer.
  void stopEviction() {
    _evictionTimer?.cancel();
    _evictionTimer = null;
  }

  void _evict() {
    _store.removeWhere((_, entry) => entry.isExpired);
  }

  /// Dispose: stop timer and clear store.
  void dispose() {
    stopEviction();
    _store.clear();
  }
}
