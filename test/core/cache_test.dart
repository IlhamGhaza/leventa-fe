import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propmanaget/core/cache/cache_store.dart';
import 'package:propmanaget/core/cache/cached_fetcher.dart';
import 'package:propmanaget/core/network/api_client.dart';
import 'package:propmanaget/core/network/api_exception.dart';
import 'package:propmanaget/core/storage/token_storage.dart';
import 'package:propmanaget/features/master_data/master_data_repository.dart';
import 'package:propmanaget/features/properties/data/property_models.dart';
import 'package:propmanaget/features/properties/data/property_query.dart';
import 'package:propmanaget/features/properties/data/property_repository.dart';

import '../helpers/fake_adapter.dart';

void main() {
  var now = DateTime(2026, 11, 15, 10);
  DateTime clock() => now;

  group('CacheStore', () {
    test('keys include session, path and sorted query', () {
      expect(
        CacheKeys.build('u1:sales', '/properties', {
          'page': 1,
          'type': 'house',
          'x': null,
        }),
        'u1:sales|/properties?page=1&type=house',
      );
      expect(
        CacheKeys.build('guest', '/p', {'b': 1, 'a': 2}),
        CacheKeys.build('guest', '/p', {'a': 2, 'b': 1}),
      );
    });

    test('TTL: fresh, then stale, then dropped', () {
      final c = CacheStore(clock: clock);
      c.write('k', 1, const Duration(minutes: 1));
      expect(c.read<int>('k')!.fresh, isTrue);
      now = now.add(const Duration(minutes: 2));
      expect(c.read<int>('k')!.fresh, isFalse);
      now = now.add(CacheStore.maxStale);
      expect(c.read<int>('k'), isNull);
    });

    test('clearSession keeps public entries only', () {
      final c = CacheStore(clock: clock);
      c.write('u1|/deals', 1, const Duration(minutes: 1));
      c.write(
        'public|/master-data/provinces',
        2,
        const Duration(hours: 24),
        scope: CacheScope.public,
      );
      c.clearSession();
      expect(c.read<int>('u1|/deals'), isNull);
      expect(c.read<int>('public|/master-data/provinces'), isNotNull);
    });
  });

  group('CachedFetcher', () {
    late CacheStore cache;
    late String session;
    late CachedFetcher fetcher;

    setUp(() {
      now = DateTime(2026, 11, 15, 10);
      cache = CacheStore(clock: clock);
      session = 'guest';
      fetcher = CachedFetcher(cache, () => session);
    });

    test('serves fresh hits; force bypasses', () async {
      var loads = 0;
      Future<int> load() async => ++loads;
      expect(
        await fetcher.fetch(
          path: '/p',
          ttl: const Duration(minutes: 1),
          load: load,
        ),
        1,
      );
      expect(
        await fetcher.fetch(
          path: '/p',
          ttl: const Duration(minutes: 1),
          load: load,
        ),
        1,
      );
      expect(
        await fetcher.fetch(
          path: '/p',
          ttl: const Duration(minutes: 1),
          load: load,
          force: true,
        ),
        2,
      );
    });

    test('sessions never share entries', () async {
      var loads = 0;
      Future<int> load() async => ++loads;
      await fetcher.fetch(
        path: '/deals',
        ttl: const Duration(minutes: 1),
        load: load,
      );
      session = 'userB:sales';
      expect(
        await fetcher.fetch(
          path: '/deals',
          ttl: const Duration(minutes: 1),
          load: load,
        ),
        2,
      );
    });

    test(
      'stale-while-revalidate returns stale and refreshes in background',
      () async {
        var loads = 0;
        Future<int> load() async => ++loads;
        await fetcher.fetch(
          path: '/p',
          ttl: const Duration(minutes: 5),
          load: load,
        );
        now = now.add(const Duration(minutes: 6));
        expect(
          await fetcher.fetch(
            path: '/p',
            ttl: const Duration(minutes: 5),
            load: load,
            staleWhileRevalidate: true,
          ),
          1,
        );
        await Future<void>.delayed(Duration.zero);
        expect(loads, 2);
        expect(cache.read<int>(CacheKeys.build('guest', '/p'))!.value, 2);
      },
    );

    test('401/403/404 drop the entry; errors are not cached', () async {
      for (final kind in [
        ApiErrorKind.unauthorized,
        ApiErrorKind.forbidden,
        ApiErrorKind.notFound,
      ]) {
        cache.write(CacheKeys.build('guest', '/p'), 1, Duration.zero);
        now = now.add(const Duration(seconds: 1));
        await expectLater(
          fetcher.fetch<int>(
            path: '/p',
            ttl: const Duration(minutes: 1),
            load: () async => throw ApiException(kind: kind, message: 'x'),
          ),
          throwsA(isA<ApiException>()),
        );
        expect(cache.read<int>(CacheKeys.build('guest', '/p')), isNull);
      }
      expect(cache.length, 0);
    });

    test('a load that finishes after logout is not stored', () async {
      session = 'u1:sales';
      await fetcher.fetch(
        path: '/deals',
        ttl: const Duration(minutes: 1),
        load: () async {
          session = 'guest';
          return 1;
        },
      );
      expect(cache.length, 0);
    });
  });

  group('PropertyRepository', () {
    late FakeAdapter adapter;
    late CacheStore cache;
    late PropertyRepository repo;
    var session = 'guest';

    setUp(() {
      now = DateTime(2026, 11, 15, 10);
      session = 'guest';
      adapter = FakeAdapter((c) {
        if (c.path == '/properties') {
          return FakeReply(
            200,
            ok(
              [
                {
                  'id': 'p1',
                  'name': 'A',
                  'type': 'house',
                  'is_available': true,
                },
              ],
              {'page': 1, 'limit': 20, 'total': 1, 'total_pages': 1},
            ),
          );
        }
        if (c.path == '/properties/p1') {
          return FakeReply(
            200,
            ok({
              'id': 'p1',
              'name': 'A',
              'type': 'house',
              'access_level': 'primary',
              'address': {'street_name': 'Jl. X'},
            }),
          );
        }
        if (c.path == '/properties/p1/owner') {
          return FakeReply(200, ok({'id': 'o1', 'name': 'Owner'}));
        }
        return FakeReply(200, ok({}));
      });
      final api = ApiClient(
        baseUrl: 'http://t/api/v1',
        tokens: MemoryTokenStorage(),
        dio: Dio()..httpClientAdapter = adapter,
        clock: clock,
        retryDelay: Duration.zero,
      );
      cache = CacheStore(clock: clock);
      repo = PropertyRepository(
        api,
        cache,
        CachedFetcher(cache, () => session),
      );
    });

    int hits(String path) => adapter.calls.where((c) => c.path == path).length;

    test('public list is cached; pull-to-refresh bypasses', () async {
      await repo.list(const PropertyQuery());
      await repo.list(const PropertyQuery());
      expect(hits('/properties'), 1);
      await repo.list(const PropertyQuery(), force: true);
      expect(hits('/properties'), 2);
    });

    test('mutation invalidates detail and every list page', () async {
      session = 'u1:sales';
      await repo.list(const PropertyQuery(scope: 'mine'));
      await repo.list(const PropertyQuery(page: 2));
      await repo.detail('p1');
      await repo.setStatus('p1', 'reserved');
      expect(cache.keys.where((k) => k.contains('/properties')), isEmpty);
    });

    test('owner data is never cached', () async {
      session = 'u1:sales';
      await repo.owner('p1');
      await repo.owner('p1');
      expect(hits('/properties/p1/owner'), 2);
      expect(cache.keys.where((k) => k.contains('owner')), isEmpty);
    });

    test(
      'private detail is cached for the session and cleared on logout',
      () async {
        session = 'u1:sales';
        final p = await repo.detail('p1');
        expect(p, isA<PrimaryProperty>());
        await repo.detail('p1');
        expect(hits('/properties/p1'), 1);
        cache.clearSession();
        session = 'guest';
        await repo.detail('p1');
        expect(hits('/properties/p1'), 2);
      },
    );

    test('rejects invalid queries before calling the backend', () async {
      await expectLater(
        repo.list(const PropertyQuery(minPrice: 10, maxPrice: 5)),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiErrorKind.validation,
          ),
        ),
      );
      expect(adapter.calls, isEmpty);
    });
  });

  group('MasterDataRepository', () {
    test('memory + disk, 24 h, survives a fresh memory cache', () async {
      now = DateTime(2026, 11, 15, 10);
      final adapter = FakeAdapter(
        (_) => FakeReply(
          200,
          ok([
            {'id': 'p', 'name': 'DKI Jakarta'},
          ]),
        ),
      );
      final api = ApiClient(
        baseUrl: 'http://t/api/v1',
        tokens: MemoryTokenStorage(),
        dio: Dio()..httpClientAdapter = adapter,
        clock: clock,
      );
      final disk = MemoryPublicDiskCache(clock: clock);
      final first = MasterDataRepository(api, CacheStore(clock: clock), disk);
      expect((await first.provinces()).single.name, 'DKI Jakarta');
      final second = MasterDataRepository(api, CacheStore(clock: clock), disk);
      expect((await second.provinces()).single.name, 'DKI Jakarta');
      expect(adapter.calls, hasLength(1));
      expect(adapter.calls.single.auth, isNull);
      now = now.add(const Duration(hours: 25));
      await MasterDataRepository(
        api,
        CacheStore(clock: clock),
        disk,
      ).provinces();
      expect(adapter.calls, hasLength(2));
    });
  });

  test('NamedRef list type stays public-safe', () {
    expect(const NamedRef(id: '1', name: 'x').toJson(), {
      'id': '1',
      'name': 'x',
    });
  });
}
