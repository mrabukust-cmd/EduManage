import 'dart:async';
import 'dart:collection';

/// Represents a cached entry with expiration and metadata.
class CacheEntry<T> {
  final T value;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Set<String> tags;
  int accessCount;
  DateTime lastAccessedAt;

  CacheEntry({
    required this.value,
    required this.createdAt,
    this.expiresAt,
    Set<String>? tags,
  })  : tags = tags ?? const <String>{},
        accessCount = 0,
        lastAccessedAt = DateTime.now();

  /// Whether the entry is expired relative to [now].
  bool isExpired([DateTime? now]) {
    if (expiresAt == null) return false;
    final currentTime = now ?? DateTime.now();
    return currentTime.isAfter(expiresAt!);
  }

  /// Mark the entry as accessed.
  void recordAccess([DateTime? now]) {
    accessCount++;
    lastAccessedAt = now ?? DateTime.now();
  }
}

/// Statistics for cache efficiency monitoring.
class CacheStats {
  final int hits;
  final int misses;
  final int evictions;
  final int size;
  final int capacity;

  const CacheStats({
    required this.hits,
    required this.misses,
    required this.evictions,
    required this.size,
    required this.capacity,
  });

  int get totalRequests => hits + misses;

  double get hitRatio => totalRequests == 0 ? 0.0 : hits / totalRequests;

  @override
  String toString() =>
      'CacheStats(hits: $hits, misses: $misses, evictions: $evictions, size: $size/$capacity, hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%)';
}

/// In-memory LRU cache with configurable TTL, capacity limits, and tag invalidation.
class MemoryCache<T> {
  final Duration? defaultTtl;
  final int maxCapacity;

  // LinkedHashMap retains insertion/access order for LRU tracking.
  final LinkedHashMap<String, CacheEntry<T>> _store =
      LinkedHashMap<String, CacheEntry<T>>();

  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;

  MemoryCache({
    this.defaultTtl,
    this.maxCapacity = 100,
  }) : assert(maxCapacity > 0, 'maxCapacity must be greater than zero');

  /// Current number of active cached items.
  int get size => _store.length;

  /// Current cache performance metrics.
  CacheStats get stats => CacheStats(
        hits: _hits,
        misses: _misses,
        evictions: _evictions,
        size: _store.length,
        capacity: maxCapacity,
      );

  /// Put an item in cache with optional custom [ttl] and [tags].
  void set(
    String key,
    T value, {
    Duration? ttl,
    Set<String>? tags,
    DateTime? now,
  }) {
    final effectiveTtl = ttl ?? defaultTtl;
    final currentTime = now ?? DateTime.now();
    final expiresAt =
        effectiveTtl != null ? currentTime.add(effectiveTtl) : null;

    // If key already exists, remove first so it gets re-inserted at the end of LRU order.
    if (_store.containsKey(key)) {
      _store.remove(key);
    } else if (_store.length >= maxCapacity) {
      _evictLru();
    }

    _store[key] = CacheEntry<T>(
      value: value,
      createdAt: currentTime,
      expiresAt: expiresAt,
      tags: tags,
    );
  }

  /// Retrieve an item if present and not expired. Returns null on miss or expiry.
  T? get(String key, [DateTime? now]) {
    final entry = _store[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    final currentTime = now ?? DateTime.now();
    if (entry.isExpired(currentTime)) {
      _store.remove(key);
      _misses++;
      return null;
    }

    _hits++;
    entry.recordAccess(currentTime);

    // Re-insert to mark as recently used
    _store.remove(key);
    _store[key] = entry;

    return entry.value;
  }

  /// Check whether a valid non-expiring key exists without updating LRU rank.
  bool containsKey(String key, [DateTime? now]) {
    final entry = _store[key];
    if (entry == null) return false;
    if (entry.isExpired(now)) {
      _store.remove(key);
      return false;
    }
    return true;
  }

  /// Get cached value or compute and store asynchronously if missing.
  Future<T> getOrCompute(
    String key,
    Future<T> Function() computer, {
    Duration? ttl,
    Set<String>? tags,
  }) async {
    final cached = get(key);
    if (cached != null) return cached;

    final computed = await computer();
    set(key, computed, ttl: ttl, tags: tags);
    return computed;
  }

  /// Remove a specific key from the cache.
  bool remove(String key) {
    return _store.remove(key) != null;
  }

  /// Invalidate all entries matching [tag].
  int invalidateByTag(String tag) {
    final keysToRemove = <String>[];
    for (final entry in _store.entries) {
      if (entry.value.tags.contains(tag)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _store.remove(key);
    }
    return keysToRemove.length;
  }

  /// Invalidate all entries matching any tag in [tags].
  int invalidateByTags(Iterable<String> tags) {
    final tagSet = tags.toSet();
    final keysToRemove = <String>[];
    for (final entry in _store.entries) {
      if (entry.value.tags.any(tagSet.contains)) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _store.remove(key);
    }
    return keysToRemove.length;
  }

  /// Evict all expired entries currently stored.
  int purgeExpired([DateTime? now]) {
    final currentTime = now ?? DateTime.now();
    final expiredKeys = <String>[];
    for (final entry in _store.entries) {
      if (entry.value.isExpired(currentTime)) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _store.remove(key);
    }
    return expiredKeys.length;
  }

  /// Clear all entries and reset stats.
  void clear({bool resetStats = false}) {
    _store.clear();
    if (resetStats) {
      _hits = 0;
      _misses = 0;
      _evictions = 0;
    }
  }

  void _evictLru() {
    if (_store.isEmpty) return;
    final oldestKey = _store.keys.first;
    _store.remove(oldestKey);
    _evictions++;
  }
}

/// Global registry managing typed named caches across the application.
class CacheManager {
  CacheManager._();
  static final CacheManager instance = CacheManager._();

  final Map<String, MemoryCache<dynamic>> _namedCaches = {};

  /// Get or create a typed named cache.
  MemoryCache<T> getCache<T>(
    String name, {
    Duration? defaultTtl,
    int maxCapacity = 100,
  }) {
    if (!_namedCaches.containsKey(name)) {
      _namedCaches[name] = MemoryCache<T>(
        defaultTtl: defaultTtl,
        maxCapacity: maxCapacity,
      );
    }
    return _namedCaches[name]! as MemoryCache<T>;
  }

  /// Invalidate a tag across all registered named caches.
  int invalidateTagAcrossAll(String tag) {
    int total = 0;
    for (final cache in _namedCaches.values) {
      total += cache.invalidateByTag(tag);
    }
    return total;
  }

  /// Clear all registered caches.
  void clearAll() {
    for (final cache in _namedCaches.values) {
      cache.clear(resetStats: true);
    }
    _namedCaches.clear();
  }
}
