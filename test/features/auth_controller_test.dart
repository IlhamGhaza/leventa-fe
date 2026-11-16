import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propmanaget/core/cache/cache_store.dart';
import 'package:propmanaget/core/network/api_client.dart';
import 'package:propmanaget/core/network/api_exception.dart';
import 'package:propmanaget/core/storage/token_storage.dart';
import 'package:propmanaget/features/auth/auth_controller.dart';
import 'package:propmanaget/features/auth/data/auth_models.dart';
import 'package:propmanaget/features/auth/data/auth_repository.dart';

import '../helpers/fake_adapter.dart';

Map<String, dynamic> userJson(String id, String role) => {
  'id': id,
  'name': 'User $id',
  'email': '$id@x.test',
  'role': role,
  'status': 'active',
};

void main() {
  final now = DateTime(2026, 11, 15, 10);
  late FakeAdapter adapter;
  late MemoryTokenStorage storage;
  late CacheStore cache;
  late AuthController auth;
  late int purges;

  void build() {
    final api = ApiClient(
      baseUrl: 'http://t/api/v1',
      tokens: storage,
      dio: Dio()..httpClientAdapter = adapter,
      clock: () => now,
      retryDelay: Duration.zero,
    );
    cache = CacheStore(clock: () => now);
    purges = 0;
    auth = AuthController(
      repository: AuthRepository(api, clock: () => now),
      cache: cache,
      purgePrivateFiles: () async => purges++,
    );
    api.onSessionExpired = auth.onSessionExpired;
  }

  setUp(() {
    storage = MemoryTokenStorage();
    adapter = FakeAdapter((_) => FakeReply(200, ok({})));
    build();
  });

  group('shellFor (role routing)', () {
    AppUser u(String role) => AppUser.fromJson(userJson('1', role));
    test('maps roles; retired and unknown roles are unsupported', () {
      expect(shellFor(null), AppShell.guest);
      expect(shellFor(u('sales')), AppShell.marketing);
      expect(shellFor(u('admin')), AppShell.admin);
      expect(shellFor(u('customer')), AppShell.unsupported);
      expect(shellFor(u('staff')), AppShell.unsupported);
      expect(shellFor(u('')), AppShell.unsupported);
    });
  });

  test('no stored token → guest without any network call', () async {
    await auth.restore();
    expect(auth.status.value, AuthStatus.guest);
    expect(auth.sessionKey, 'guest');
    expect(adapter.calls, isEmpty);
  });

  test('stored token → /auth/me → authenticated with backend role', () async {
    storage.pair = TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    adapter.handler = (_) => FakeReply(200, ok(userJson('u1', 'admin')));
    build();
    await auth.restore();
    expect(auth.status.value, AuthStatus.authenticated);
    expect(auth.shell, AppShell.admin);
    expect(auth.sessionKey, 'u1:admin');
  });

  test('restore offline → restoreFailed, tokens kept', () async {
    storage.pair = TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    adapter.handler = (_) => FakeReply(503, failBody('down'));
    build();
    await auth.restore();
    expect(auth.status.value, AuthStatus.restoreFailed);
    expect(storage.pair, isNotNull);
  });

  test('login stores tokens securely and uses the returned role', () async {
    adapter.handler = (c) => FakeReply(
      200,
      ok({
        'access_token': 'acc',
        'refresh_token': 'ref',
        'expires_in': 900,
        'user': userJson('u1', 'sales'),
      }),
    );
    final user = await auth.login('a@x.test', 'pw');
    expect(user.role, 'sales');
    expect(auth.shell, AppShell.marketing);
    expect(storage.pair!.accessToken, 'acc');
    expect(adapter.calls.single.body, {'email': 'a@x.test', 'password': 'pw'});
  });

  test('login errors propagate (401 / 403 / 429)', () async {
    for (final s in [401, 403, 429]) {
      adapter.handler = (_) => FakeReply(s, failBody('no'));
      await expectLater(
        auth.login('a@x.test', 'bad'),
        throwsA(isA<ApiException>()),
      );
      expect(auth.status.value, isNot(AuthStatus.authenticated));
      expect(storage.pair, isNull);
    }
  });

  test(
    'logout clears tokens, session caches and private files; public stays',
    () async {
      adapter.handler = (c) => c.path == '/auth/login'
          ? FakeReply(
              200,
              ok({
                'access_token': 'a',
                'refresh_token': 'r',
                'expires_in': 900,
                'user': userJson('u1', 'sales'),
              }),
            )
          : FakeReply(200, ok(null));
      await auth.login('a@x.test', 'pw');
      cache.write('u1:sales|/deals', 1, const Duration(minutes: 1));
      cache.write(
        'public|/master-data/provinces',
        1,
        const Duration(hours: 1),
        scope: CacheScope.public,
      );
      final purgesBefore = purges;
      await auth.logout();
      expect(auth.status.value, AuthStatus.guest);
      expect(storage.pair, isNull);
      expect(cache.read<int>('u1:sales|/deals'), isNull);
      expect(cache.read<int>('public|/master-data/provinces'), isNotNull);
      expect(purges, purgesBefore + 1);
      expect(adapter.calls.any((c) => c.path == '/auth/logout'), isTrue);
    },
  );

  test('account switch A → B leaves no data of A', () async {
    var who = 'A';
    adapter.handler = (c) => FakeReply(
      200,
      ok({
        'access_token': 't$who',
        'refresh_token': 'r$who',
        'expires_in': 900,
        'user': userJson(who, 'sales'),
      }),
    );
    await auth.login('a@x.test', 'pw');
    cache.write(
      '${auth.sessionKey}|/commissions',
      'A-data',
      const Duration(minutes: 1),
    );
    who = 'B';
    await auth.login('b@x.test', 'pw');
    expect(auth.sessionKey, 'B:sales');
    expect(cache.keys.where((k) => k.startsWith('A:')), isEmpty);
  });

  test('refresh rejected → guest + sessionExpired flag', () async {
    storage.pair = TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    var stage = 0;
    adapter.handler = (c) {
      if (stage == 0) return FakeReply(200, ok(userJson('u1', 'sales')));
      return FakeReply(401, failBody('expired'));
    };
    build();
    await auth.restore();
    stage = 1;
    cache.write('u1:sales|/deals', 1, const Duration(minutes: 1));
    await auth.refreshMe();
    expect(auth.status.value, AuthStatus.guest);
    expect(auth.sessionExpired.value, isTrue);
    expect(cache.length, 0);
    expect(storage.pair, isNull);
  });

  test('role change on /auth/me clears session caches', () async {
    storage.pair = TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    var role = 'sales';
    adapter.handler = (_) => FakeReply(200, ok(userJson('u1', role)));
    build();
    await auth.restore();
    cache.write('u1:sales|/deals', 1, const Duration(minutes: 1));
    role = 'admin';
    await auth.refreshMe();
    expect(auth.shell, AppShell.admin);
    expect(cache.length, 0);
  });

  test(
    'WhatsApp edit sends only whatsapp_number and keeps normalized value',
    () async {
      storage.pair = TokenPair(
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: now.add(const Duration(hours: 1)),
      );
      adapter.handler = (c) => c.method == 'PATCH'
          ? FakeReply(
              200,
              ok({
                ...userJson('u1', 'sales'),
                'whatsapp_number': '6281234567890',
              }),
            )
          : FakeReply(200, ok(userJson('u1', 'sales')));
      build();
      await auth.restore();
      final u = await auth.updateWhatsApp(' 0812-3456-7890 ');
      final patch = adapter.calls.last;
      expect(patch.path, '/auth/me');
      expect(patch.body, {'whatsapp_number': '0812-3456-7890'});
      expect(u.whatsappNumber, '6281234567890');
    },
  );

  test('WhatsApp 422 maps to a field error', () async {
    storage.pair = TokenPair(
      accessToken: 'a',
      refreshToken: 'r',
      expiresAt: now.add(const Duration(hours: 1)),
    );
    adapter.handler = (c) => c.method == 'PATCH'
        ? FakeReply(
            422,
            failBody('Validation failed', {
              'whatsapp_number': 'invalid number',
            }),
          )
        : FakeReply(200, ok(userJson('u1', 'sales')));
    build();
    await auth.restore();
    try {
      await auth.updateWhatsApp('abc');
      fail('expected 422');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.validation);
      expect(e.fieldErrors['whatsapp_number'], 'invalid number');
    }
  });
}
