import 'package:get/get.dart';

import '../../core/cache/cache_store.dart';
import '../../core/network/api_exception.dart';
import 'data/auth_models.dart';
import 'data/auth_repository.dart';

enum AuthStatus {
  /// Splash: reading the secure token store / `GET /auth/me`.
  initializing,

  /// No session. The app shows the guest shell.
  guest,
  authenticated,

  /// A stored session exists but `/auth/me` failed for a non-auth reason
  /// (offline, 5xx, 429). The user may retry or continue as guest.
  restoreFailed,
  loggingOut,
}

/// Session state. Role and identity come only from the backend response.
class AuthController extends GetxController {
  AuthController({
    required AuthRepository repository,
    required this._cache,
    required this._purgePrivateFiles,
  }) : _repo = repository;

  final AuthRepository _repo;
  final CacheStore _cache;
  final Future<void> Function() _purgePrivateFiles;

  final status = AuthStatus.initializing.obs;
  final user = Rxn<AppUser>();

  /// Set when the backend rejected the refresh token; UI routes to login.
  final sessionExpired = false.obs;
  ApiException? restoreError;

  AppShell get shell => shellFor(user.value);

  /// Cache partition: `guest`, or user ID + role.
  String get sessionKey {
    final u = user.value;
    return u == null ? 'guest' : '${u.id}:${u.role}';
  }

  Future<void> restore() async {
    status.value = AuthStatus.initializing;
    restoreError = null;
    if (!await _repo.hasStoredSession()) {
      _setGuest();
      return;
    }
    try {
      user.value = await _repo.me();
      status.value = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized ||
          e.kind == ApiErrorKind.forbidden) {
        await _repo.logout();
        await _clearLocal();
        _setGuest();
      } else {
        restoreError = e;
        status.value = AuthStatus.restoreFailed;
      }
    }
  }

  /// Continue as guest after a failed restore, without deleting the session.
  void continueAsGuest() => _setGuest();

  Future<AppUser> login(String email, String password) async {
    // Account switch: nothing of a previous session may survive.
    await _clearLocal();
    final u = await _repo.login(email, password);
    user.value = u;
    sessionExpired.value = false;
    status.value = AuthStatus.authenticated;
    return u;
  }

  /// Refetch after token refresh and app resume. A role or user change
  /// clears every session cache.
  Future<void> refreshMe() async {
    if (status.value != AuthStatus.authenticated) return;
    try {
      final fresh = await _repo.me();
      final old = user.value;
      if (old == null || old.id != fresh.id || old.role != fresh.role) {
        await _clearLocal();
      }
      user.value = fresh;
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized) await onSessionExpired();
    }
  }

  Future<AppUser> updateWhatsApp(String number) async {
    final updated = await _repo.updateWhatsApp(number);
    user.value = updated;
    // Profile + every cached detail where this user is the contact.
    _cache.invalidate('|/auth/me');
    _cache.invalidate('|/properties');
    return updated;
  }

  Future<void> logout() async {
    status.value = AuthStatus.loggingOut;
    await _repo.logout();
    await _clearLocal();
    sessionExpired.value = false;
    _setGuest();
  }

  /// Called by the API client after the refresh token was rejected.
  Future<void> onSessionExpired() async {
    if (user.value == null && status.value == AuthStatus.guest) return;
    await _clearLocal();
    sessionExpired.value = true;
    _setGuest();
  }

  void _setGuest() {
    user.value = null;
    status.value = AuthStatus.guest;
  }

  Future<void> _clearLocal() async {
    _cache.clearSession();
    await _purgePrivateFiles();
  }
}
