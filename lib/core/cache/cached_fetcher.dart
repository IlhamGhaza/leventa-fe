import 'dart:async';

import '../network/api_exception.dart';
import 'cache_store.dart';

/// Read-through helper for repositories.
class CachedFetcher {
  CachedFetcher(this.cache, this.sessionKey);

  final CacheStore cache;
  final String Function() sessionKey;

  /// [force] (pull-to-refresh / retry) bypasses the cache.
  /// [staleWhileRevalidate] serves a stale copy and refreshes in background.
  Future<T> fetch<T>({
    required String path,
    Map<String, dynamic>? query,
    required Duration ttl,
    required Future<T> Function() load,
    bool force = false,
    bool staleWhileRevalidate = false,
  }) async {
    final session = sessionKey();
    final key = CacheKeys.build(session, path, query);
    if (!force) {
      final hit = cache.read<T>(key);
      if (hit != null && hit.fresh) return hit.value;
      if (hit != null && staleWhileRevalidate) {
        unawaited(_load(key, session, ttl, load).then((_) {}, onError: (_) {}));
        return hit.value;
      }
    }
    return _load(key, session, ttl, load);
  }

  Future<T> _load<T>(
    String key,
    String session,
    Duration ttl,
    Future<T> Function() load,
  ) async {
    try {
      final value = await load();
      // Session changed while loading (logout/switch): do not store.
      if (sessionKey() == session) cache.write(key, value, ttl);
      return value;
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized ||
          e.kind == ApiErrorKind.forbidden ||
          e.kind == ApiErrorKind.notFound) {
        cache.remove(key);
      }
      rethrow; // errors and 429 are never cached
    }
  }
}
