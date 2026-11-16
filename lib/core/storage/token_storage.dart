import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// `expires_in` is in seconds (backend AuthResponse).
  factory TokenPair.fromAuthJson(Map<String, dynamic> j, DateTime now) =>
      TokenPair(
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
        expiresAt: now.add(
          Duration(seconds: (j['expires_in'] as num?)?.toInt() ?? 0),
        ),
      );
}

/// Session tokens live only in platform secure storage (Keychain /
/// Android Keystore). Guests store nothing. Never log the values.
abstract class TokenStorage {
  Future<TokenPair?> read();
  Future<void> write(TokenPair pair);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'leventa.access_token';
  static const _kRefresh = 'leventa.refresh_token';
  static const _kExpires = 'leventa.expires_at';

  @override
  Future<TokenPair?> read() async {
    try {
      final access = await _storage.read(key: _kAccess);
      final refresh = await _storage.read(key: _kRefresh);
      final expires = await _storage.read(key: _kExpires);
      if (access == null || refresh == null) return null;
      return TokenPair(
        accessToken: access,
        refreshToken: refresh,
        expiresAt:
            DateTime.tryParse(expires ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    } catch (_) {
      // Corrupted keystore entry (e.g. after a backup restore): start as guest.
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(TokenPair pair) async {
    await _storage.write(key: _kAccess, value: pair.accessToken);
    await _storage.write(key: _kRefresh, value: pair.refreshToken);
    await _storage.write(
      key: _kExpires,
      value: pair.expiresAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _kAccess);
      await _storage.delete(key: _kRefresh);
      await _storage.delete(key: _kExpires);
    } catch (_) {}
  }
}

/// In-memory implementation for tests.
class MemoryTokenStorage implements TokenStorage {
  MemoryTokenStorage([this.pair]);
  TokenPair? pair;

  @override
  Future<TokenPair?> read() async => pair;
  @override
  Future<void> write(TokenPair p) async => pair = p;
  @override
  Future<void> clear() async => pair = null;
}
