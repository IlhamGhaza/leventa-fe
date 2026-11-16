import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';

/// Cache scope. `session` entries belong to one login (or the guest session)
/// and are wiped on logout / account switch / role change. `public` entries
/// (master data) are identical for everyone and may survive logout.
enum CacheScope { session, public }

class _Entry {
  _Entry(this.value, this.storedAt, this.ttl, this.scope);
  final Object? value;
  final DateTime storedAt;
  final Duration ttl;
  final CacheScope scope;
}

class CacheHit<T> {
  const CacheHit(this.value, {required this.fresh});
  final T value;
  final bool fresh;
}

/// Small in-memory TTL cache (docs/APP_ARCHITECTURE.md → Caching).
/// Keys must already contain the session key; see [CacheKeys].
class CacheStore {
  CacheStore({Clock? clock}) : _clock = clock ?? DateTime.now;

  final Clock _clock;
  final Map<String, _Entry> _entries = {};

  /// Stale entries older than ttl + this are dropped instead of served.
  static const maxStale = Duration(minutes: 30);

  CacheHit<T>? read<T>(String key) {
    final e = _entries[key];
    if (e == null) return null;
    final age = _clock().difference(e.storedAt);
    if (age > e.ttl + maxStale) {
      _entries.remove(key);
      return null;
    }
    return CacheHit<T>(e.value as T, fresh: age <= e.ttl);
  }

  void write(
    String key,
    Object? value,
    Duration ttl, {
    CacheScope scope = CacheScope.session,
  }) {
    _entries[key] = _Entry(value, _clock(), ttl, scope);
  }

  void remove(String key) => _entries.remove(key);

  /// Removes every key containing [fragment] (e.g. `/properties`).
  void invalidate(String fragment) =>
      _entries.removeWhere((k, _) => k.contains(fragment));

  void invalidateWhere(bool Function(String key) test) =>
      _entries.removeWhere((k, _) => test(k));

  /// Logout, account switch, role change, failed refresh.
  void clearSession() =>
      _entries.removeWhere((_, e) => e.scope == CacheScope.session);

  void clearAll() => _entries.clear();

  int get length => _entries.length;
  Iterable<String> get keys => _entries.keys;
}

class CacheKeys {
  const CacheKeys._();

  /// endpoint + full (sorted) query + session key.
  static String build(
    String session,
    String path, [
    Map<String, dynamic>? query,
  ]) {
    final q = (query ?? const {}).entries.where((e) => e.value != null).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final qs = q.map((e) => '${e.key}=${e.value}').join('&');
    return '$session|$path${qs.isEmpty ? '' : '?$qs'}';
  }
}

/// Disk cache for PUBLIC data only (master data). Never use it for private
/// projections, owner data, deals, commissions or documents.
abstract class PublicDiskCache {
  Future<CacheHit<Object?>?> read(String key, Duration ttl);
  Future<void> write(String key, Object? json);
  Future<void> remove(String key);

  /// Removes every entry whose key contains [fragment].
  Future<void> removeContaining(String fragment);
}

class PrefsPublicDiskCache implements PublicDiskCache {
  PrefsPublicDiskCache({Clock? clock}) : _clock = clock ?? DateTime.now;
  final Clock _clock;
  static const _prefix = 'leventa.public_cache.';

  @override
  Future<CacheHit<Object?>?> read(String key, Duration ttl) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_prefix$key');
      if (raw == null) return null;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final at = DateTime.parse(m['at'] as String);
      return CacheHit(m['v'], fresh: _clock().difference(at) <= ttl);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_prefix$key',
        jsonEncode({'at': _clock().toIso8601String(), 'v': json}),
      );
    } catch (_) {}
  }

  @override
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (_) {}
  }

  @override
  Future<void> removeContaining(String fragment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in prefs.getKeys().toList()) {
        if (k.startsWith(_prefix) && k.contains(fragment)) {
          await prefs.remove(k);
        }
      }
    } catch (_) {}
  }
}

class MemoryPublicDiskCache implements PublicDiskCache {
  MemoryPublicDiskCache({Clock? clock}) : _clock = clock ?? DateTime.now;
  final Clock _clock;
  final Map<String, (DateTime, Object?)> data = {};

  @override
  Future<CacheHit<Object?>?> read(String key, Duration ttl) async {
    final e = data[key];
    if (e == null) return null;
    return CacheHit(e.$2, fresh: _clock().difference(e.$1) <= ttl);
  }

  @override
  Future<void> write(String key, Object? json) async =>
      data[key] = (_clock(), json);

  @override
  Future<void> remove(String key) async => data.remove(key);

  @override
  Future<void> removeContaining(String fragment) async =>
      data.removeWhere((k, _) => k.contains(fragment));
}
