import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository(this._api, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final ApiClient _api;
  final DateTime Function() _clock;

  /// Email + password only; the backend decides the role.
  /// Errors: 401 wrong credentials, 403 inactive, 429 locked / rate limited.
  Future<AppUser> login(String email, String password) async {
    final res = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
      auth: false,
    );
    final data = res.dataMap;
    await _api.setSession(TokenPair.fromAuthJson(data, _clock()));
    return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
  }

  Future<AppUser> me() async {
    final res = await _api.get('/auth/me');
    return AppUser.fromJson(res.dataMap);
  }

  /// Sends only `whatsapp_number`; empty clears it. Returns the normalized
  /// value from the backend.
  Future<AppUser> updateWhatsApp(String number) async {
    final res = await _api.patch(
      '/auth/me',
      body: {'whatsapp_number': number.trim()},
    );
    return AppUser.fromJson(res.dataMap);
  }

  /// Best effort server revoke; local session is always cleared.
  Future<void> logout() async {
    try {
      if (await _api.hasSession()) await _api.post('/auth/logout');
    } catch (_) {
    } finally {
      await _api.clearSession();
    }
  }

  Future<bool> hasStoredSession() => _api.hasSession();
}
