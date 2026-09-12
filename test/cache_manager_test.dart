import 'package:flutter_test/flutter_test.dart';
import 'package:school_management_system/core/utils/cache_manager.dart';

void main() {
  group('MemoryCache Unit Tests', () {
    late MemoryCache<String> cache;

    setUp(() {
      cache = MemoryCache<String>(
        defaultTtl: const Duration(minutes: 5),
        maxCapacity: 3,
      );
    });

    test('stores and retrieves item before expiration', () {
      cache.set('user_1', 'Alice');
      expect(cache.get('user_1'), 'Alice');
      expect(cache.size, 1);
      expect(cache.stats.hits, 1);
      expect(cache.stats.misses, 0);
    });

    test('returns null and records miss for absent key', () {
      expect(cache.get('non_existent'), isNull);
      expect(cache.stats.hits, 0);
      expect(cache.stats.misses, 1);
    });

    test('expires item after TTL duration', () {
      final baseTime = DateTime(2026, 9, 12, 10, 0, 0);
      cache.set(
        'temp_key',
        'ExpiredData',
        ttl: const Duration(seconds: 30),
        now: baseTime,
      );

      // Not expired yet at 20 seconds
      expect(cache.get('temp_key', baseTime.add(const Duration(seconds: 20))), 'ExpiredData');

      // Expired at 35 seconds
      expect(cache.get('temp_key', baseTime.add(const Duration(seconds: 35))), isNull);
      expect(cache.containsKey('temp_key', baseTime.add(const Duration(seconds: 35))), isFalse);
    });

    test('evicts least recently used item when maxCapacity is exceeded', () {
      cache.set('k1', 'val1');
      cache.set('k2', 'val2');
      cache.set('k3', 'val3');

      // Access k1 so k2 becomes the least recently used
      cache.get('k1');

      // Inserting 4th item triggers eviction of k2
      cache.set('k4', 'val4');

      expect(cache.get('k2'), isNull);
      expect(cache.get('k1'), 'val1');
      expect(cache.get('k3'), 'val3');
      expect(cache.get('k4'), 'val4');
      expect(cache.stats.evictions, 1);
    });

    test('invalidates items by single tag', () {
      cache.set('s1', 'Student 1', tags: {'students', 'grade9'});
      cache.set('s2', 'Student 2', tags: {'students', 'grade10'});
      cache.set('t1', 'Teacher 1', tags: {'teachers'});

      expect(cache.size, 3);

      final removedCount = cache.invalidateByTag('students');
      expect(removedCount, 2);
      expect(cache.get('s1'), isNull);
      expect(cache.get('s2'), isNull);
      expect(cache.get('t1'), 'Teacher 1');
      expect(cache.size, 1);
    });

    test('invalidates items by multiple tags', () {
      cache.set('a', 'A', tags: {'alpha'});
      cache.set('b', 'B', tags: {'beta'});
      cache.set('c', 'C', tags: {'gamma'});

      final count = cache.invalidateByTags(['alpha', 'beta']);
      expect(count, 2);
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), isNull);
      expect(cache.get('c'), 'C');
    });

    test('getOrCompute calculates on miss and reuses on hit', () async {
      int computationCount = 0;
      Future<String> fetcher() async {
        computationCount++;
        return 'ComputedResult';
      }

      final res1 = await cache.getOrCompute('calc_key', fetcher);
      expect(res1, 'ComputedResult');
      expect(computationCount, 1);

      // Second call hits cache
      final res2 = await cache.getOrCompute('calc_key', fetcher);
      expect(res2, 'ComputedResult');
      expect(computationCount, 1);
    });

    test('purgeExpired removes only expired elements', () {
      final base = DateTime(2026, 9, 12, 12, 0, 0);
      cache.set('fast_expire', 'Fast', ttl: const Duration(seconds: 10), now: base);
      cache.set('slow_expire', 'Slow', ttl: const Duration(minutes: 60), now: base);

      final checkTime = base.add(const Duration(seconds: 15));
      final purged = cache.purgeExpired(checkTime);
      expect(purged, 1);
      expect(cache.size, 1);
      expect(cache.get('slow_expire', checkTime), 'Slow');
    });

    test('clear removes all entries and resets stats when requested', () {
      cache.set('k1', 'v1');
      cache.get('k1');
      cache.get('missing');

      expect(cache.stats.hits, 1);
      expect(cache.stats.misses, 1);

      cache.clear(resetStats: true);
      expect(cache.size, 0);
      expect(cache.stats.hits, 0);
      expect(cache.stats.misses, 0);
    });
  });

  group('CacheManager Registry Tests', () {
    final manager = CacheManager.instance;

    tearDown(() {
      manager.clearAll();
    });

    test('returns consistent typed cache instances', () {
      final cacheA = manager.getCache<int>('integers');
      final cacheB = manager.getCache<int>('integers');
      expect(identical(cacheA, cacheB), isTrue);

      cacheA.set('val', 42);
      expect(cacheB.get('val'), 42);
    });

    test('invalidateTagAcrossAll clears matching entries across multiple caches', () {
      final classCache = manager.getCache<String>('classes');
      final studentCache = manager.getCache<String>('students');

      classCache.set('c1', 'Grade 10', tags: {'academic'});
      studentCache.set('s1', 'John', tags: {'academic'});
      studentCache.set('s2', 'Jane', tags: {'non_academic'});

      final invalidated = manager.invalidateTagAcrossAll('academic');
      expect(invalidated, 2);
      expect(classCache.get('c1'), isNull);
      expect(studentCache.get('s1'), isNull);
      expect(studentCache.get('s2'), 'Jane');
    });
  });
}
