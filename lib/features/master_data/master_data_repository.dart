import '../../core/cache/cache_store.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';
import '../properties/data/property_models.dart';

/// Public master data: memory + disk, 24 h (identical for every session).
class MasterDataRepository {
  MasterDataRepository(this._api, this._cache, this._disk);

  final ApiClient _api;
  final CacheStore _cache;
  final PublicDiskCache _disk;

  static const ttl = Duration(hours: 24);

  Future<List<NamedRef>> provinces({bool force = false}) =>
      _get('/master-data/provinces', null, null, force);

  Future<List<NamedRef>> cities(String? provinceId, {bool force = false}) =>
      _get(
        '/master-data/cities',
        provinceId == null ? null : {'province_id': provinceId},
        'province_id',
        force,
      );

  Future<List<NamedRef>> districts(String? cityId, {bool force = false}) =>
      _get(
        '/master-data/districts',
        cityId == null ? null : {'city_id': cityId},
        'city_id',
        force,
      );

  Future<List<NamedRef>> facilities({bool force = false}) =>
      _get('/master-data/facilities', null, null, force);

  Future<List<NamedRef>> _get(
    String path,
    Map<String, dynamic>? query,
    String? parentKey,
    bool force,
  ) async {
    final key = CacheKeys.build('public', path, query);
    if (!force) {
      final mem = _cache.read<List<NamedRef>>(key);
      if (mem != null && mem.fresh) return mem.value;
      final disk = await _disk.read(key, ttl);
      if (disk != null && disk.fresh) {
        final list = objList(
          disk.value,
        ).map((j) => NamedRef.fromJson(j, parentKey: 'parent_id')).toList();
        _cache.write(key, list, ttl, scope: CacheScope.public);
        return list;
      }
    }
    final res = await _api.get(path, query: query, auth: false);
    final list = res.dataList
        .map((j) => NamedRef.fromJson(j, parentKey: parentKey))
        .toList();
    _cache.write(key, list, ttl, scope: CacheScope.public);
    await _disk.write(key, list.map((e) => e.toJson()).toList());
    return list;
  }

  // ---- Admin writes (invalidate afterwards) ------------------------------

  Future<void> create(String kind, String name, {String? parentId}) async {
    final body = <String, dynamic>{'name': name};
    if (kind == 'cities') body['province_id'] = parentId;
    if (kind == 'districts') body['city_id'] = parentId;
    await _api.post('/master-data/$kind', body: body);
    await invalidate(kind);
  }

  Future<void> rename(String kind, String id, String name) async {
    await _api.put('/master-data/$kind/$id', body: {'name': name});
    await invalidate(kind);
  }

  Future<void> delete(String kind, String id) async {
    await _api.delete('/master-data/$kind/$id');
    await invalidate(kind);
  }

  Future<void> invalidate(String kind) async {
    final fragment = '/master-data/$kind';
    _cache.invalidate(fragment);
    await _disk.removeContaining(fragment);
  }
}
