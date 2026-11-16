import '../../../core/config/env.dart';
import '../../../core/utils/json.dart';

/// Property types (backend values).
class PropertyType {
  const PropertyType._();
  static const house = 'house';
  static const apartment = 'apartment';
  static const shopHouse = 'shop_house';
  static const factory = 'factory';
  static const all = [house, apartment, shopHouse, factory];

  static String label(String t) => switch (t) {
    house => 'Rumah',
    apartment => 'Apartemen',
    shopHouse => 'Ruko',
    factory => 'Pabrik',
    _ => t,
  };
}

class TransactionType {
  const TransactionType._();
  static const sale = 'sale';
  static const rent = 'rent';
  static String label(String t) => t == rent ? 'Sewa' : 'Jual';
}

class PropertyStatus {
  const PropertyStatus._();
  static const draft = 'draft';
  static const available = 'available';
  static const reserved = 'reserved';
  static const sold = 'sold';
  static const rented = 'rented';
  static const maintenance = 'maintenance';
  static const archived = 'archived';

  /// Statuses the Primary Marketing may set.
  static const primarySettable = [
    draft,
    available,
    reserved,
    maintenance,
    archived,
  ];

  /// Statuses a co-listing Marketing may set (availability toggle).
  static const coListingSettable = [available, reserved, maintenance];

  static String label(String s) => switch (s) {
    draft => 'Draf',
    available => 'Tersedia',
    reserved => 'Dipesan',
    sold => 'Terjual',
    rented => 'Tersewa',
    maintenance => 'Perbaikan',
    archived => 'Diarsipkan',
    _ => s,
  };
}

class NamedRef {
  const NamedRef({required this.id, required this.name, this.parentId});
  final String id;
  final String name;
  final String? parentId;

  factory NamedRef.fromJson(Map<String, dynamic> j, {String? parentKey}) =>
      NamedRef(
        id: strOr(j['id']),
        name: strOr(j['name']),
        parentId: parentKey == null ? null : str(j[parentKey]),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (parentId != null) 'parent_id': parentId,
  };

  static NamedRef? maybe(Object? v) {
    final m = obj(v);
    return m.isEmpty ? null : NamedRef.fromJson(m);
  }
}

class PropertyImage {
  const PropertyImage({
    required this.id,
    required this.url,
    required this.sortOrder,
    required this.isThumbnail,
  });
  final String id;
  final String url;
  final int sortOrder;
  final bool isThumbnail;

  factory PropertyImage.fromJson(Map<String, dynamic> j) => PropertyImage(
    id: strOr(j['id']),
    url: Env.resolveFileUrl(str(j['url'])) ?? '',
    sortOrder: intOr(j['sort_order']),
    isThumbnail: boolOr(j['is_thumbnail']),
  );
}

/// Representing Marketing user's public contact. Never the owner's.
class MarketingContact {
  const MarketingContact({
    required this.name,
    this.whatsappNumber,
    this.whatsappUrl,
  });
  final String name;
  final String? whatsappNumber;
  final String? whatsappUrl;

  /// Only https wa.me / api.whatsapp.com links are opened.
  Uri? get safeWhatsappUri {
    final url = whatsappUrl;
    if (url == null) return null;
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') return null;
    const hosts = {'wa.me', 'api.whatsapp.com'};
    return hosts.contains(uri.host) ? uri : null;
  }

  bool get canContact => safeWhatsappUri != null;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final s = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return s.isEmpty ? '?' : s;
  }

  factory MarketingContact.fromJson(Map<String, dynamic> j) => MarketingContact(
    name: strOr(j['name']),
    whatsappNumber: str(j['whatsapp_number']),
    whatsappUrl: str(j['whatsapp_url']),
  );
}

/// Listing detail fields (D-028). Shared by all projections and the forms.
class PropertyDetails {
  PropertyDetails({
    this.shortDescription,
    this.areaLabel,
    this.subDistrict,
    this.postalCode,
    this.orientation,
    this.maintenanceFee,
    Map<String, bool>? certs,
    Map<String, int>? rooms,
    this.electricityCapacity,
    this.airConditioners = 0,
    this.tvProvider,
    this.waterSource,
    this.furnishingStatus,
    Map<String, bool>? outdoor,
    Map<String, int?>? distances,
    List<String>? extraOutdoor,
    List<NearbyPlace>? extraDistances,
  }) : extraOutdoor = extraOutdoor ?? [],
       extraDistances = extraDistances ?? [],
       certs = certs ?? {for (final k in certKeys) k: false},
       rooms = rooms ?? {for (final k in roomKeys) k: 0},
       outdoor = outdoor ?? {for (final k in outdoorKeys) k: false},
       distances = distances ?? {for (final k in distanceKeys) k: null};

  String? shortDescription;
  String? areaLabel;
  String? subDistrict;
  String? postalCode;
  String? orientation;
  double? maintenanceFee;

  /// doc type (shm, hgb, ...) -> flag. JSON key is `cert_<type>`.
  final Map<String, bool> certs;

  /// JSON key -> count (living_rooms, ...).
  final Map<String, int> rooms;
  String? electricityCapacity;
  int airConditioners;
  String? tvProvider;
  String? waterSource;
  String? furnishingStatus;

  /// JSON key -> flag (has_pool, ...).
  final Map<String, bool> outdoor;

  /// JSON key -> meters (dist_school, ...).
  final Map<String, int?> distances;

  /// Custom outdoor areas typed by the marketing (not filterable).
  final List<String> extraOutdoor;

  /// Custom nearby places typed by the marketing (not filterable).
  final List<NearbyPlace> extraDistances;

  /// BE limit per custom list.
  static const maxExtras = 10;

  static const certKeys = [
    'shm',
    'hgb',
    'hgu',
    'shmsrs',
    'imb',
    'pbb',
    'girik',
    'slf',
    'other',
  ];
  static const roomKeys = [
    'living_rooms',
    'dining_rooms',
    'master_bedrooms',
    'child_bedrooms',
    'other_bedrooms',
    'master_bathrooms',
    'child_bathrooms',
    'other_bathrooms',
    'family_rooms',
    'study_rooms',
    'kitchens',
  ];
  static const outdoorKeys = [
    'has_pool',
    'has_garage',
    'has_front_yard',
    'has_back_yard',
    'has_balcony',
  ];
  static const distanceKeys = [
    'dist_school',
    'dist_bus_terminal',
    'dist_mrt_lrt',
    'dist_toll',
    'dist_hospital',
  ];
  static const furnishingValues = [
    'unfurnished',
    'semi_furnished',
    'furnished',
  ];

  bool cert(String docType) => certs[docType] ?? false;

  factory PropertyDetails.fromJson(Map<String, dynamic> j) => PropertyDetails(
    shortDescription: str(j['short_description']),
    areaLabel: str(j['area_label']),
    subDistrict: str(j['sub_district']),
    postalCode: str(j['postal_code']),
    orientation: str(j['orientation']),
    maintenanceFee: dblN(j['maintenance_fee']),
    certs: {for (final k in certKeys) k: boolOr(j['cert_$k'])},
    rooms: {for (final k in roomKeys) k: intOr(j[k])},
    electricityCapacity: str(j['electricity_capacity']),
    airConditioners: intOr(j['air_conditioners']),
    tvProvider: str(j['tv_provider']),
    waterSource: str(j['water_source']),
    furnishingStatus: str(j['furnishing_status']),
    outdoor: {for (final k in outdoorKeys) k: boolOr(j[k])},
    distances: {for (final k in distanceKeys) k: intN(j[k])},
    extraOutdoor: [
      for (final n in (j['extra_outdoor'] as List? ?? const []))
        if (n is String) n,
    ],
    extraDistances: objList(
      j['extra_distances'],
    ).map(NearbyPlace.fromJson).toList(),
  );

  Map<String, dynamic> toJson() => {
    'short_description': shortDescription ?? '',
    'area_label': areaLabel ?? '',
    'sub_district': subDistrict ?? '',
    'postal_code': postalCode ?? '',
    'orientation': orientation ?? '',
    'maintenance_fee': maintenanceFee,
    for (final k in certKeys) 'cert_$k': certs[k] ?? false,
    ...rooms,
    'electricity_capacity': electricityCapacity ?? '',
    'air_conditioners': airConditioners,
    'tv_provider': tvProvider ?? '',
    'water_source': waterSource ?? '',
    'furnishing_status': furnishingStatus ?? '',
    ...outdoor,
    ...distances,
    'extra_outdoor': extraOutdoor,
    'extra_distances': [for (final p in extraDistances) p.toJson()],
  };
}

class NearbyPlace {
  const NearbyPlace(this.name, this.meters);
  final String name;
  final int meters;

  factory NearbyPlace.fromJson(Map<String, dynamic> j) =>
      NearbyPlace(str(j['name']) ?? '', intOr(j['meters']));

  Map<String, dynamic> toJson() => {'name': name, 'meters': meters};
}

/// Public projection. Used for every list item and for guests' detail.
/// Contains no owner data, no restricted address and no coordinates.
class PublicProperty {
  PublicProperty({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.transactionType,
    required this.status,
    required this.isAvailable,
    required this.details,
    this.statusBadge,
    this.price,
    this.rentalPrice,
    this.description,
    this.province,
    this.city,
    this.district,
    this.facilities = const [],
    this.generalLocation,
    this.landArea,
    this.buildingArea,
    this.floor,
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.yearBuilt,
    this.thumbnail,
    this.images = const [],
    this.contact,
  });

  PublicProperty._copy(PublicProperty p)
    : id = p.id,
      code = p.code,
      name = p.name,
      type = p.type,
      transactionType = p.transactionType,
      status = p.status,
      statusBadge = p.statusBadge,
      isAvailable = p.isAvailable,
      price = p.price,
      rentalPrice = p.rentalPrice,
      description = p.description,
      province = p.province,
      city = p.city,
      district = p.district,
      facilities = p.facilities,
      generalLocation = p.generalLocation,
      landArea = p.landArea,
      buildingArea = p.buildingArea,
      floor = p.floor,
      bedrooms = p.bedrooms,
      bathrooms = p.bathrooms,
      yearBuilt = p.yearBuilt,
      thumbnail = p.thumbnail,
      images = p.images,
      contact = p.contact,
      details = p.details;

  final String id;
  final String code;
  final String name;
  final String type;
  final String transactionType;
  final String status;
  final String? statusBadge;
  final bool isAvailable;
  final double? price;
  final double? rentalPrice;
  final String? description;
  final NamedRef? province;
  final NamedRef? city;
  final NamedRef? district;
  final List<NamedRef> facilities;
  final String? generalLocation;
  final double? landArea;
  final double? buildingArea;
  final int? floor;
  final int bedrooms;
  final int bathrooms;
  final int? yearBuilt;
  final String? thumbnail;
  final List<PropertyImage> images;
  final MarketingContact? contact;
  final PropertyDetails details;

  bool get isRent => transactionType == TransactionType.rent;

  /// The price shown for this listing (sale price or rental price).
  double? get displayPrice => isRent ? rentalPrice : price;

  bool get isHistory => statusBadge == 'SOLD' || statusBadge == 'RENTED';

  /// Only general location (never restricted address).
  String get locationLabel {
    final parts = <String>[
      if (district != null) district!.name,
      if (city != null) city!.name,
      if (province != null) province!.name,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return generalLocation ?? details.areaLabel ?? '';
  }

  String? get coverUrl {
    if (thumbnail != null) return thumbnail;
    if (images.isEmpty) return null;
    final sorted = [...images]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted
        .firstWhere((i) => i.isThumbnail, orElse: () => sorted.first)
        .url;
  }

  factory PublicProperty.fromJson(Map<String, dynamic> j) => PublicProperty(
    id: strOr(j['id']),
    code: strOr(j['code']),
    name: strOr(j['name']),
    type: strOr(j['type']),
    transactionType: strOr(j['transaction_type'], TransactionType.sale),
    status: strOr(j['status']),
    statusBadge: str(j['status_badge']),
    isAvailable: boolOr(j['is_available']),
    price: dblN(j['price']),
    rentalPrice: dblN(j['rental_price']),
    description: str(j['description']),
    province: NamedRef.maybe(j['province']),
    city: NamedRef.maybe(j['city']),
    district: NamedRef.maybe(j['district']),
    facilities: objList(j['facilities']).map(NamedRef.fromJson).toList(),
    generalLocation: str(j['general_location']),
    landArea: dblN(j['land_area']),
    buildingArea: dblN(j['building_area']),
    floor: intN(j['floor']),
    bedrooms: intOr(j['bedrooms']),
    bathrooms: intOr(j['bathrooms']),
    yearBuilt: intN(j['year_built']),
    thumbnail: Env.resolveFileUrl(str(j['thumbnail'])),
    images: objList(j['images']).map(PropertyImage.fromJson).toList(),
    contact: obj(j['contact']).isEmpty
        ? null
        : MarketingContact.fromJson(obj(j['contact'])),
    details: PropertyDetails.fromJson(j),
  );
}

class TeamMember {
  const TeamMember({
    required this.marketingId,
    required this.name,
    required this.assignmentType,
    this.assignedAt,
  });
  final String marketingId;
  final String name;
  final String assignmentType;
  final DateTime? assignedAt;

  bool get isPrimary => assignmentType == 'primary';

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    marketingId: strOr(j['marketing_id']),
    name: strOr(j['name']),
    assignmentType: strOr(j['assignment_type']),
    assignedAt: date(j['assigned_at']),
  );
}

class RestrictedAddress {
  const RestrictedAddress({
    this.blockNumber,
    this.clusterName,
    this.streetName,
    this.houseNumber,
    this.floorNumber,
    this.roomNumber,
  });
  final String? blockNumber;
  final String? clusterName;
  final String? streetName;
  final String? houseNumber;
  final String? floorNumber;
  final String? roomNumber;

  bool get isEmpty => [
    blockNumber,
    clusterName,
    streetName,
    houseNumber,
    floorNumber,
    roomNumber,
  ].every((e) => e == null);

  factory RestrictedAddress.fromJson(Map<String, dynamic> j) =>
      RestrictedAddress(
        blockNumber: str(j['block_number']),
        clusterName: str(j['cluster_name']),
        streetName: str(j['street_name']),
        houseNumber: str(j['house_number']),
        floorNumber: str(j['floor_number']),
        roomNumber: str(j['room_number']),
      );
}

/// Admin projection: public fields + team. No address, no coordinates.
class InternalProperty extends PublicProperty {
  InternalProperty._(super.p, this.team) : super._copy();
  final List<TeamMember> team;

  factory InternalProperty.fromJson(Map<String, dynamic> j) =>
      InternalProperty._(
        PublicProperty.fromJson(j),
        objList(j['marketing_team']).map(TeamMember.fromJson).toList(),
      );
}

/// Primary / co-listing Marketing projection. Never contains owner data.
class PrimaryProperty extends PublicProperty {
  PrimaryProperty._(
    super.p, {
    required this.accessLevel,
    required this.address,
    required this.team,
    this.latitude,
    this.longitude,
  }) : super._copy();

  /// `primary` or `co_listing`.
  final String accessLevel;
  final RestrictedAddress address;
  final double? latitude;
  final double? longitude;
  final List<TeamMember> team;

  bool get isPrimary => accessLevel == 'primary';
  bool get isCoListing => accessLevel == 'co_listing';

  factory PrimaryProperty.fromJson(Map<String, dynamic> j) => PrimaryProperty._(
    PublicProperty.fromJson(j),
    accessLevel: strOr(j['access_level']),
    address: RestrictedAddress.fromJson(obj(j['address'])),
    latitude: dblN(j['latitude']),
    longitude: dblN(j['longitude']),
    team: objList(j['marketing_team']).map(TeamMember.fromJson).toList(),
  );
}

/// Picks the projection from `access_level` (absent → public).
PublicProperty parsePropertyDetail(Map<String, dynamic> j) {
  switch (j['access_level']) {
    case 'primary':
    case 'co_listing':
      return PrimaryProperty.fromJson(j);
    case 'admin':
      return InternalProperty.fromJson(j);
    default:
      return PublicProperty.fromJson(j);
  }
}

class Owner {
  const Owner({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.privateAddress,
  });
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? privateAddress;

  factory Owner.fromJson(Map<String, dynamic> j) => Owner(
    id: strOr(j['id']),
    name: strOr(j['name']),
    email: str(j['email']),
    phone: str(j['phone']),
    privateAddress: str(j['private_address']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (privateAddress != null) 'private_address': privateAddress,
  };
}
