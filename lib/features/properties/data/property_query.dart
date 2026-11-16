/// Filters for `GET /properties`. Serializes only set values and enforces the
/// backend search caps (docs/API_INTEGRATION.md) before calling.
class PropertyQuery {
  const PropertyQuery({
    this.search,
    this.type,
    this.transactionType,
    this.provinceId,
    this.cityId,
    this.districtId,
    this.facilityIds = const [],
    this.minPrice,
    this.maxPrice,
    this.minLandArea,
    this.maxLandArea,
    this.minBuildingArea,
    this.maxBuildingArea,
    this.bedrooms,
    this.bathrooms,
    this.sort,
    this.history = false,
    this.includeHistory = false,
    this.scope,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  static const maxSearchLength = 100;
  static const maxFacilities = 20;
  static const maxOffset = 10000;
  static const sorts = [
    'newest',
    'oldest',
    'price_asc',
    'price_desc',
    'name_asc',
    'name_desc',
  ];

  final String? search;
  final String? type;
  final String? transactionType;
  final String? provinceId;
  final String? cityId;
  final String? districtId;
  final List<String> facilityIds;
  final num? minPrice;
  final num? maxPrice;
  final num? minLandArea;
  final num? maxLandArea;
  final num? minBuildingArea;
  final num? maxBuildingArea;
  final int? bedrooms;
  final int? bathrooms;
  final String? sort;

  /// Only sold/rented (guest/default list only).
  final bool history;

  /// Available + history in one list (guest/default list only).
  final bool includeHistory;

  /// Marketing only: `mine` or `co_listing`.
  final String? scope;

  /// Internal roles only.
  final String? status;
  final int page;
  final int limit;

  /// Whether page [p] would exceed the backend offset cap.
  bool canRequestPage(int p) => (p - 1) * limit <= maxOffset;

  /// Client-side validation mirroring the backend 422 rules.
  String? validate() {
    if ((search?.length ?? 0) > maxSearchLength) {
      return 'Pencarian maksimal $maxSearchLength karakter.';
    }
    if (facilityIds.length > maxFacilities) {
      return 'Maksimal $maxFacilities fasilitas.';
    }
    if (!canRequestPage(page)) {
      return 'Terlalu banyak hasil. Persempit filter pencarian.';
    }
    bool bad(num? a, num? b) => a != null && b != null && a > b;
    if (bad(minPrice, maxPrice) ||
        bad(minLandArea, maxLandArea) ||
        bad(minBuildingArea, maxBuildingArea)) {
      return 'Nilai minimum tidak boleh lebih besar dari maksimum.';
    }
    return null;
  }

  Map<String, dynamic> toQuery() {
    final s = search?.trim();
    final q = <String, dynamic>{
      if (s != null && s.isNotEmpty)
        'search': s.length > maxSearchLength
            ? s.substring(0, maxSearchLength)
            : s,
      'type': type,
      'transaction_type': transactionType,
      'province_id': provinceId,
      'city_id': cityId,
      'district_id': districtId,
      if (facilityIds.isNotEmpty) 'facility_ids': facilityIds.join(','),
      'min_price': minPrice,
      'max_price': maxPrice,
      'min_land_area': minLandArea,
      'max_land_area': maxLandArea,
      'min_building_area': minBuildingArea,
      'max_building_area': maxBuildingArea,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'sort': sort,
      'scope': scope,
      'status': status,
      // history flags apply only to the default list (no scope).
      if (scope == null && history) 'history': 'true',
      if (scope == null && !history && includeHistory)
        'include_history': 'true',
      'page': page,
      'limit': limit,
    };
    q.removeWhere((_, v) => v == null);
    return q;
  }

  bool get isScoped => scope != null || status != null;

  PropertyQuery copyWith({
    String? search,
    String? type,
    String? transactionType,
    String? provinceId,
    String? cityId,
    String? districtId,
    List<String>? facilityIds,
    num? minPrice,
    num? maxPrice,
    num? minLandArea,
    num? maxLandArea,
    num? minBuildingArea,
    num? maxBuildingArea,
    int? bedrooms,
    int? bathrooms,
    String? sort,
    bool? history,
    bool? includeHistory,
    String? scope,
    String? status,
    int? page,
    int? limit,
  }) => PropertyQuery(
    search: search ?? this.search,
    type: type ?? this.type,
    transactionType: transactionType ?? this.transactionType,
    provinceId: provinceId ?? this.provinceId,
    cityId: cityId ?? this.cityId,
    districtId: districtId ?? this.districtId,
    facilityIds: facilityIds ?? this.facilityIds,
    minPrice: minPrice ?? this.minPrice,
    maxPrice: maxPrice ?? this.maxPrice,
    minLandArea: minLandArea ?? this.minLandArea,
    maxLandArea: maxLandArea ?? this.maxLandArea,
    minBuildingArea: minBuildingArea ?? this.minBuildingArea,
    maxBuildingArea: maxBuildingArea ?? this.maxBuildingArea,
    bedrooms: bedrooms ?? this.bedrooms,
    bathrooms: bathrooms ?? this.bathrooms,
    sort: sort ?? this.sort,
    history: history ?? this.history,
    includeHistory: includeHistory ?? this.includeHistory,
    scope: scope ?? this.scope,
    status: status ?? this.status,
    page: page ?? this.page,
    limit: limit ?? this.limit,
  );
}
