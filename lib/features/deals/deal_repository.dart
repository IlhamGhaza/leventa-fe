import '../../core/cache/cache_store.dart';
import '../../core/cache/cached_fetcher.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../auth/data/auth_models.dart';
import 'deal_models.dart';

/// Deals, commissions, users and audit logs. Marketing gets own records only
/// (backend-scoped); Admin gets all. Memory only, 1 min, current session.
class DealRepository {
  DealRepository(this._api, this._cache, this._fetcher);

  final ApiClient _api;
  final CacheStore _cache;
  final CachedFetcher _fetcher;

  static const ttl = Duration(minutes: 1);

  Future<Paged<T>> _page<T>(
    String path,
    Map<String, dynamic> query,
    T Function(Map<String, dynamic>) parse,
    bool force,
  ) {
    query.removeWhere((_, v) => v == null || v == '');
    return _fetcher.fetch(
      path: path,
      query: query,
      ttl: ttl,
      force: force,
      load: () async {
        final res = await _api.get(path, query: query);
        final items = res.dataList.map(parse).toList();
        return Paged(
          items,
          res.meta ??
              PageMeta(
                page: 1,
                limit: items.length,
                total: items.length,
                totalPages: 1,
              ),
        );
      },
    );
  }

  Future<T> _one<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
    bool force,
  ) => _fetcher.fetch(
    path: path,
    ttl: ttl,
    force: force,
    load: () async => parse((await _api.get(path)).dataMap),
  );

  // ---- deals / commissions -----------------------------------------------

  Future<Paged<Deal>> deals({
    int page = 1,
    int limit = 20,
    bool force = false,
  }) => _page('/deals', {'page': page, 'limit': limit}, Deal.fromJson, force);

  Future<Deal> deal(String id, {bool force = false}) =>
      _one('/deals/$id', Deal.fromJson, force);

  Future<Paged<Commission>> commissions({
    String? status,
    int page = 1,
    int limit = 20,
    bool force = false,
  }) => _page(
    '/commissions',
    {'status': status, 'page': page, 'limit': limit},
    Commission.fromJson,
    force,
  );

  Future<Commission> commission(String id, {bool force = false}) =>
      _one('/commissions/$id', Commission.fromJson, force);

  /// Admin: percentage 0–100, pending only. Backend recalculates the amount.
  Future<void> setCommissionPercentage(String id, num percentage) async {
    await _api.patch('/commissions/$id', body: {'percentage': percentage});
    _cache.invalidate('|/commissions');
  }

  /// Admin: `paid` or `cancelled`, pending only.
  Future<void> setCommissionStatus(String id, String status) async {
    await _api.patch('/commissions/$id/status', body: {'status': status});
    _cache.invalidate('|/commissions');
  }

  // ---- users (Admin) ------------------------------------------------------

  Future<Paged<AppUser>> users({
    String? search,
    String? role,
    String? status,
    int page = 1,
    int limit = 20,
    bool force = false,
  }) => _page(
    '/users',
    {
      'search': search,
      'role': role,
      'status': status,
      'page': page,
      'limit': limit,
    },
    AppUser.fromJson,
    force,
  );

  Future<AppUser> user(String id, {bool force = false}) =>
      _one('/users/$id', AppUser.fromJson, force);

  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
    String? whatsappNumber,
  }) async {
    final res = await _api.post(
      '/users',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'role': role,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty)
          'whatsapp_number': whatsappNumber.trim(),
      },
    );
    _invalidateUsers();
    return AppUser.fromJson(res.dataMap);
  }

  Future<void> updateUser(
    String id, {
    required String name,
    required String email,
    String? phone,
    String? whatsappNumber,
  }) async {
    await _api.put(
      '/users/$id',
      body: {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim() ?? '',
        'whatsapp_number': whatsappNumber?.trim() ?? '',
      },
    );
    _invalidateUsers();
    // The user may be the contact on cached listings.
    _cache.invalidate('|/properties');
  }

  Future<void> setUserStatus(String id, String status) async {
    await _api.patch('/users/$id/status', body: {'status': status});
    _invalidateUsers();
  }

  /// Nobody can change their own role (backend returns 403).
  Future<void> setUserRole(String id, String role) async {
    await _api.patch('/users/$id/role', body: {'role': role});
    _invalidateUsers();
  }

  Future<void> deleteUser(String id) async {
    await _api.delete('/users/$id');
    _invalidateUsers();
  }

  void _invalidateUsers() => _cache.invalidate('|/users');

  // ---- audit (Admin) -----------------------------------------------------

  Future<Paged<AuditLog>> auditLogs({
    String? module,
    String? action,
    int page = 1,
    int limit = 20,
    bool force = false,
  }) => _page(
    '/audit-logs',
    {'module': module, 'action': action, 'page': page, 'limit': limit},
    AuditLog.fromJson,
    force,
  );
}
