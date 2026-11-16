import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propmanaget/core/network/api_client.dart';
import 'package:propmanaget/core/network/api_exception.dart';
import 'package:propmanaget/core/storage/token_storage.dart';

import '../helpers/fake_adapter.dart';

void main() {
  final now = DateTime(2026, 11, 15, 10);
  late FakeAdapter adapter;
  late MemoryTokenStorage storage;
  late ApiClient api;

  TokenPair pair(String access, {Duration ttl = const Duration(minutes: 15)}) =>
      TokenPair(
        accessToken: access,
        refreshToken: 'r-$access',
        expiresAt: now.add(ttl),
      );

  ApiClient build() {
    final dio = Dio()..httpClientAdapter = adapter;
    return ApiClient(
      baseUrl: 'http://test/api/v1',
      tokens: storage,
      dio: dio,
      clock: () => now,
      retryDelay: Duration.zero,
    );
  }

  setUp(() {
    storage = MemoryTokenStorage();
    adapter = FakeAdapter((_) => FakeReply(200, ok({})));
    api = build();
  });

  test('parses envelope, meta and X-Request-ID', () async {
    adapter.handler = (_) => FakeReply(
      200,
      ok(
        [
          {'id': '1'},
        ],
        {'page': 2, 'limit': 20, 'total': 41, 'total_pages': 3},
      ),
      {'x-request-id': 'req-1'},
    );
    final res = await api.get('/properties', auth: false);
    expect(res.dataList.single['id'], '1');
    expect(res.meta!.page, 2);
    expect(res.meta!.hasNext, isTrue);
    expect(res.requestId, 'req-1');
  });

  test(
    'maps error statuses distinctly with request id and field errors',
    () async {
      final cases = {
        400: ApiErrorKind.badRequest,
        401: ApiErrorKind.unauthorized,
        403: ApiErrorKind.forbidden,
        404: ApiErrorKind.notFound,
        409: ApiErrorKind.conflict,
        422: ApiErrorKind.validation,
        429: ApiErrorKind.rateLimited,
        500: ApiErrorKind.server,
      };
      for (final entry in cases.entries) {
        adapter.handler = (_) => FakeReply(
          entry.key,
          failBody('boom', {'whatsapp_number': 'invalid'}),
          {'x-request-id': 'rid-${entry.key}', 'retry-after': '42'},
        );
        try {
          await api.post('/x', auth: false);
          fail('expected ${entry.key}');
        } on ApiException catch (e) {
          expect(e.kind, entry.value);
          expect(e.requestId, 'rid-${entry.key}');
          expect(e.fieldErrors['whatsapp_number'], 'invalid');
          if (entry.key == 429) {
            expect(e.retryAfter, const Duration(seconds: 42));
          }
        }
      }
    },
  );

  test('never retries 429, even for GET', () async {
    adapter.handler = (_) =>
        FakeReply(429, failBody('slow down'), {'retry-after': '5'});
    await expectLater(
      api.get('/properties', auth: false),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.rateLimited,
        ),
      ),
    );
    expect(adapter.calls, hasLength(1));
  });

  test('retries a GET once on 5xx, never a POST', () async {
    var n = 0;
    adapter.handler = (_) =>
        ++n == 1 ? FakeReply(503, failBody('x')) : FakeReply(200, ok('fine'));
    final res = await api.get('/master-data/provinces', auth: false);
    expect(res.data, 'fine');
    expect(adapter.calls, hasLength(2));

    adapter.calls.clear();
    n = 0;
    await expectLater(
      api.post('/x', auth: false),
      throwsA(isA<ApiException>()),
    );
    expect(adapter.calls, hasLength(1));
  });

  test(
    'retries a GET once on network error and maps the second failure',
    () async {
      adapter.throwOnce = 'offline';
      adapter.handler = (_) => FakeReply(200, ok(1));
      expect((await api.get('/a', auth: false)).data, 1);
      expect(adapter.calls, hasLength(2));
    },
  );

  test('attaches bearer token; guests send none', () async {
    await api.get('/properties');
    expect(adapter.calls.last.auth, isNull);
    await api.setSession(pair('A'));
    await api.get('/auth/me');
    expect(adapter.calls.last.auth, 'Bearer A');
    expect(storage.pair!.accessToken, 'A');
  });

  test(
    '401 → single in-flight refresh, GETs replayed with new token',
    () async {
      storage.pair = pair('old');
      api = build();
      var refreshes = 0;
      adapter.handler = (c) {
        if (c.path == '/auth/refresh') {
          refreshes++;
          return FakeReply(
            200,
            ok({
              'access_token': 'new',
              'refresh_token': 'r2',
              'expires_in': 900,
            }),
          );
        }
        return c.auth == 'Bearer new'
            ? FakeReply(200, ok('ok'))
            : FakeReply(401, failBody('expired'));
      };
      final results = await Future.wait([
        api.get('/a'),
        api.get('/b'),
        api.get('/c'),
      ]);
      expect(results.map((r) => r.data), everyElement('ok'));
      expect(refreshes, 1);
      expect(storage.pair!.accessToken, 'new');
      expect(storage.pair!.refreshToken, 'r2');
    },
  );

  test('401 on a write refreshes but does not replay it', () async {
    storage.pair = pair('old');
    api = build();
    var writes = 0;
    adapter.handler = (c) {
      if (c.path == '/auth/refresh') {
        return FakeReply(
          200,
          ok({'access_token': 'new', 'refresh_token': 'r2', 'expires_in': 900}),
        );
      }
      writes++;
      return FakeReply(401, failBody('expired'));
    };
    await expectLater(
      api.post('/properties', body: {}),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.sessionRefreshed,
        ),
      ),
    );
    expect(writes, 1);
  });

  test('rejected refresh clears tokens and signals session expiry', () async {
    storage.pair = pair('old');
    api = build();
    var expired = 0;
    api.onSessionExpired = () async => expired++;
    adapter.handler = (c) => c.path == '/auth/refresh'
        ? FakeReply(401, failBody('revoked'))
        : FakeReply(401, failBody('expired'));
    await expectLater(
      api.get('/auth/me'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiErrorKind.unauthorized,
        ),
      ),
    );
    expect(storage.pair, isNull);
    expect(expired, 1);
  });

  test(
    'refreshes proactively when the access token is about to expire',
    () async {
      storage.pair = pair('old', ttl: const Duration(seconds: 10));
      api = build();
      adapter.handler = (c) => c.path == '/auth/refresh'
          ? FakeReply(
              200,
              ok({
                'access_token': 'new',
                'refresh_token': 'r2',
                'expires_in': 900,
              }),
            )
          : FakeReply(200, ok('ok'));
      await api.get('/auth/me');
      expect(adapter.calls.first.path, '/auth/refresh');
      expect(adapter.calls.last.auth, 'Bearer new');
    },
  );

  test('refresh hit by 429 keeps the session', () async {
    storage.pair = pair('old', ttl: Duration.zero);
    api = build();
    adapter.handler = (_) =>
        FakeReply(429, failBody('slow'), {'retry-after': '3'});
    await expectLater(api.get('/auth/me'), throwsA(isA<ApiException>()));
    expect(storage.pair, isNotNull);
  });
}
