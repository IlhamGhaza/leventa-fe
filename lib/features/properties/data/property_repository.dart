import 'package:dio/dio.dart';

import '../../../core/cache/cache_store.dart';
import '../../../core/cache/cached_fetcher.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import 'property_models.dart';
import 'property_query.dart';

/// Listings, detail projections, listing writes, images, owner, team and
/// Admin outcome endpoints. Caching follows docs/APP_ARCHITECTURE.md.
class PropertyRepository {
  PropertyRepository(this._api, this._cache, this._fetcher);

  final ApiClient _api;
  final CacheStore _cache;
  final CachedFetcher _fetcher;

  static const publicTtl = Duration(minutes: 5);
  static const privateTtl = Duration(minutes: 1);

  // ---- reads --------------------------------------------------------------

  Future<Paged<PublicProperty>> list(
    PropertyQuery query, {
    bool force = false,
  }) async {
    final error = query.validate();
    if (error != null) {
      throw ApiException(kind: ApiErrorKind.validation, message: error);
    }
    final q = query.toQuery();
    final scoped = query.isScoped;
    return _fetcher.fetch(
      path: '/properties',
      query: q,
      ttl: scoped ? privateTtl : publicTtl,
      force: force,
      staleWhileRevalidate: !scoped,
      load: () async {
        final res = await _api.get('/properties', query: q);
        return Paged(
          res.dataList.map(PublicProperty.fromJson).toList(),
          res.meta ??
              PageMeta(
                page: query.page,
                limit: query.limit,
                total: res.dataList.length,
                totalPages: 1,
              ),
        );
      },
    );
  }

  /// Returns [PublicProperty], [PrimaryProperty] or [InternalProperty].
  Future<PublicProperty> detail(String id, {bool force = false}) async {
    final path = '/properties/$id';
    final key = CacheKeys.build(_fetcher.sessionKey(), path);
    final hit = force ? null : _cache.read<PublicProperty>(key);
    if (hit != null) {
      final ttl = hit.value.runtimeType == PublicProperty
          ? publicTtl
          : privateTtl;
      final stillFresh = hit.fresh;
      if (stillFresh || hit.value.runtimeType == PublicProperty) {
        // Public: stale-while-revalidate. Private: only while fresh.
        if (!stillFresh) _revalidateDetail(id, key, ttl);
        return hit.value;
      }
    }
    return _loadDetail(id, key);
  }

  void _revalidateDetail(String id, String key, Duration ttl) {
    _loadDetail(id, key).then((_) {}, onError: (_) {});
  }

  Future<PublicProperty> _loadDetail(String id, String key) async {
    final session = _fetcher.sessionKey();
    try {
      final res = await _api.get('/properties/$id');
      final p = parsePropertyDetail(res.dataMap);
      if (_fetcher.sessionKey() == session) {
        _cache.write(
          key,
          p,
          p.runtimeType == PublicProperty ? publicTtl : privateTtl,
        );
      }
      return p;
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized ||
          e.kind == ApiErrorKind.forbidden ||
          e.kind == ApiErrorKind.notFound) {
        _cache.remove(key);
      }
      rethrow;
    }
  }

  Future<List<TeamMember>> team(String id, {bool force = false}) =>
      _fetcher.fetch(
        path: '/properties/$id/co-listings',
        ttl: privateTtl,
        force: force,
        load: () async {
          final res = await _api.get('/properties/$id/co-listings');
          return res.dataList.map(TeamMember.fromJson).toList();
        },
      );

  /// Owner PII: Primary only. Never cached.
  Future<Owner> owner(String id) async {
    final res = await _api.get('/properties/$id/owner');
    return Owner.fromJson(res.dataMap);
  }

  // ---- Marketing writes ---------------------------------------------------

  /// [body] follows CreateProperty: listing fields, details and `owner`.
  Future<PrimaryProperty> create(Map<String, dynamic> body) async {
    final res = await _api.post('/properties', body: body);
    invalidateListings();
    final data = Map<String, dynamic>.of(res.dataMap);
    data.putIfAbsent('access_level', () => 'primary');
    return PrimaryProperty.fromJson(data);
  }

  Future<void> update(String id, Map<String, dynamic> body) async {
    await _api.patch('/properties/$id', body: body);
    invalidateListing(id);
  }

  Future<void> remove(String id) async {
    await _api.delete('/properties/$id');
    invalidateListing(id);
  }

  Future<void> setStatus(String id, String status) async {
    await _api.put('/properties/$id/status', body: {'status': status});
    invalidateListing(id, outcome: true);
  }

  Future<void> uploadImage(String id, String filePath, String fileName) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    await _api.upload('/properties/$id/images', form);
    invalidateListing(id);
  }

  Future<void> deleteImage(String id, String imageId) async {
    await _api.delete('/properties/$id/images/$imageId');
    invalidateListing(id);
  }

  Future<void> setThumbnail(String id, String imageId) async {
    await _api.put('/properties/$id/images/$imageId/thumbnail');
    invalidateListing(id);
  }

  Future<Owner> updateOwner(String id, Owner owner) async {
    final res = await _api.patch('/properties/$id/owner', body: owner.toJson());
    return res.dataMap.isEmpty ? owner : Owner.fromJson(res.dataMap);
  }

  // ---- Admin --------------------------------------------------------------

  Future<List<TeamMember>> addCoListing(String id, String marketingId) => _team(
    () => _api.post(
      '/properties/$id/co-listings',
      body: {'marketing_id': marketingId},
    ),
    id,
  );

  Future<List<TeamMember>> replaceCoListing(
    String id,
    String currentMarketingId,
    String newMarketingId,
  ) => _team(
    () => _api.put(
      '/properties/$id/co-listings/$currentMarketingId',
      body: {'marketing_id': newMarketingId},
    ),
    id,
  );

  Future<void> removeCoListing(String id, String marketingId) async {
    await _api.delete('/properties/$id/co-listings/$marketingId');
    invalidateListing(id);
  }

  Future<List<TeamMember>> transferOwnership(String id, String marketingId) =>
      _team(
        () => _api.post(
          '/properties/$id/transfer-ownership',
          body: {'marketing_id': marketingId},
        ),
        id,
      );

  Future<List<TeamMember>> _team(
    Future<ApiResponse> Function() call,
    String id,
  ) async {
    final res = await call();
    invalidateListing(id);
    return res.dataList.map(TeamMember.fromJson).toList();
  }

  /// Admin records a Deal. `price` is the backend's final value; the app never
  /// calculates commission.
  Future<void> recordDeal(
    String id, {
    required String type,
    required num price,
    required String buyerName,
    String? dealDate,
    String? notes,
  }) async {
    await _api.post(
      '/properties/$id/deal',
      body: {
        'type': type,
        'price': price,
        'buyer_name': buyerName,
        if (dealDate != null && dealDate.isNotEmpty) 'deal_date': dealDate,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    invalidateListing(id, outcome: true);
  }

  Future<void> cancel(String id, {String? notes}) async {
    await _api.post(
      '/properties/$id/cancel',
      body: {if (notes != null && notes.isNotEmpty) 'notes': notes},
    );
    invalidateListing(id, outcome: true);
  }

  // ---- invalidation -------------------------------------------------------

  void invalidateListings() => _cache.invalidateWhere(
    (k) => k.contains('|/properties?') || k.endsWith('|/properties'),
  );

  /// Listing change → that detail + all list pages (+ team).
  /// [outcome] (status/Deal/Cancel) also drops deals and commissions.
  void invalidateListing(String id, {bool outcome = false}) {
    invalidateListings();
    _cache.invalidate('/properties/$id');
    if (outcome) {
      _cache.invalidate('|/deals');
      _cache.invalidate('|/commissions');
    }
  }
}
