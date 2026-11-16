import 'package:flutter_test/flutter_test.dart';
import 'package:propmanaget/features/deals/deal_models.dart';
import 'package:propmanaget/features/documents/document_rules.dart';
import 'package:propmanaget/features/properties/data/property_models.dart';
import 'package:propmanaget/features/properties/data/property_query.dart';

Map<String, dynamic> base() => {
  'id': 'p1',
  'code': 'LV-1',
  'name': 'Cluster Mawar',
  'type': 'house',
  'transaction_type': 'sale',
  'status': 'available',
  'is_available': true,
  'price': 1500000000,
  'bedrooms': 3,
  'bathrooms': 2,
  'city': {'id': 'c', 'name': 'Bogor'},
  'province': {'id': 'p', 'name': 'Jawa Barat'},
  'thumbnail': '/uploads/a.jpg',
  'cert_shm': true,
  'living_rooms': 1,
  'has_pool': true,
  'dist_school': 500,
  'contact': {
    'name': 'Rina Marketing',
    'whatsapp_number': '6281',
    'whatsapp_url': 'https://wa.me/6281?text=Halo',
  },
};

void main() {
  group('property projections', () {
    test('public projection: no access level, general location only', () {
      final p = parsePropertyDetail(base());
      expect(p.runtimeType, PublicProperty);
      expect(p.locationLabel, 'Bogor, Jawa Barat');
      expect(p.displayPrice, 1500000000);
      expect(p.details.cert('shm'), isTrue);
      expect(p.details.rooms['living_rooms'], 1);
      expect(p.details.outdoor['has_pool'], isTrue);
      expect(p.details.distances['dist_school'], 500);
      expect(p.coverUrl, endsWith('/uploads/a.jpg'));
      expect(p.coverUrl, startsWith('http'));
    });

    test('primary and co-listing projections carry address + team', () {
      final p = parsePropertyDetail({
        ...base(),
        'access_level': 'co_listing',
        'address': {'street_name': 'Jl. Mawar', 'house_number': '5'},
        'latitude': -6.5,
        'longitude': 106.8,
        'marketing_team': [
          {'marketing_id': 'm1', 'name': 'A', 'assignment_type': 'primary'},
        ],
      });
      expect(p, isA<PrimaryProperty>());
      final pp = p as PrimaryProperty;
      expect(pp.isCoListing, isTrue);
      expect(pp.isPrimary, isFalse);
      expect(pp.address.streetName, 'Jl. Mawar');
      expect(pp.team.single.isPrimary, isTrue);
    });

    test('admin projection has team but no address type', () {
      final p = parsePropertyDetail({
        ...base(),
        'access_level': 'admin',
        'marketing_team': [],
      });
      expect(p, isA<InternalProperty>());
      expect(p, isNot(isA<PrimaryProperty>()));
    });

    test('rent uses rental price; SOLD/RENTED badge is history', () {
      final p = PublicProperty.fromJson({
        ...base(),
        'transaction_type': 'rent',
        'rental_price': 5000000,
        'status': 'rented',
        'status_badge': 'RENTED',
        'is_available': false,
      });
      expect(p.displayPrice, 5000000);
      expect(p.isHistory, isTrue);
      expect(p.isAvailable, isFalse);
    });

    test('tolerates missing optional fields', () {
      final p = PublicProperty.fromJson({'id': 'x', 'name': 'n'});
      expect(p.contact, isNull);
      expect(p.coverUrl, isNull);
      expect(p.facilities, isEmpty);
    });
  });

  group('WhatsApp contact', () {
    test('only https wa.me / api.whatsapp.com links are allowed', () {
      MarketingContact c(String? url) =>
          MarketingContact.fromJson({'name': 'Rina M', 'whatsapp_url': url});
      expect(c('https://wa.me/6281?text=x').canContact, isTrue);
      expect(c('https://api.whatsapp.com/send?phone=1').canContact, isTrue);
      expect(c('http://wa.me/6281').canContact, isFalse);
      expect(c('https://evil.example/wa.me').canContact, isFalse);
      expect(c(null).canContact, isFalse);
      expect(c(null).initials, 'RM');
    });
  });

  group('PropertyQuery', () {
    test('serializes only set values, facilities comma separated', () {
      final q = const PropertyQuery(
        search: '  rumah  ',
        type: 'house',
        transactionType: 'sale',
        facilityIds: ['a', 'b'],
        minPrice: 1,
        sort: 'price_asc',
        page: 2,
      ).toQuery();
      expect(q, {
        'search': 'rumah',
        'type': 'house',
        'transaction_type': 'sale',
        'facility_ids': 'a,b',
        'min_price': 1,
        'sort': 'price_asc',
        'page': 2,
        'limit': 20,
      });
    });

    test('history flags only without scope', () {
      expect(const PropertyQuery(history: true).toQuery()['history'], 'true');
      expect(
        const PropertyQuery(includeHistory: true).toQuery()['include_history'],
        'true',
      );
      final scoped = const PropertyQuery(
        scope: 'mine',
        history: true,
        includeHistory: true,
      ).toQuery();
      expect(scoped.containsKey('history'), isFalse);
      expect(scoped.containsKey('include_history'), isFalse);
      expect(scoped['scope'], 'mine');
    });

    test('caps: search 100 chars, 20 facilities, offset 10 000, min ≤ max', () {
      expect(
        PropertyQuery(search: 'x' * 150).toQuery()['search'],
        hasLength(100),
      );
      expect(PropertyQuery(search: 'x' * 101).validate(), isNotNull);
      expect(
        PropertyQuery(facilityIds: List.filled(21, 'f')).validate(),
        isNotNull,
      );
      expect(const PropertyQuery(page: 501, limit: 20).validate(), isNull);
      expect(const PropertyQuery(page: 502, limit: 20).validate(), isNotNull);
      expect(
        const PropertyQuery(minLandArea: 5, maxLandArea: 1).validate(),
        isNotNull,
      );
    });
  });

  group('DocumentRules', () {
    test('types per property type', () {
      expect(DocumentRules.typesFor('house'), contains('girik'));
      expect(DocumentRules.typesFor('house'), isNot(contains('slf')));
      expect(DocumentRules.typesFor('apartment'), contains('shmsrs'));
      expect(DocumentRules.typesFor('apartment'), isNot(contains('shm')));
      expect(DocumentRules.typesFor('factory'), contains('hgu'));
      expect(DocumentRules.typesFor('shop_house'), isNot(contains('hgu')));
    });

    test(
      'upload blocked when the matching flag is off or type not applicable',
      () {
        final p = PublicProperty.fromJson(base()); // house, cert_shm true
        expect(DocumentRules.canUpload(p, 'shm'), isTrue);
        expect(DocumentRules.canUpload(p, 'hgb'), isFalse);
        expect(DocumentRules.canUpload(p, 'slf'), isFalse);
      },
    );
  });

  group('deals and commissions', () {
    test('values are shown exactly as returned (no recalculation)', () {
      final c = Commission.fromJson({
        'id': 'c1',
        'deal_id': 'd1',
        'percentage': 3.1,
        'amount': 12345.67,
        'status': 'pending',
        'deal': {
          'id': 'd1',
          'outcome': 'deal',
          'price': 1000,
          'property': {'name': 'A', 'code': 'X', 'owner_id': 'secret'},
        },
      });
      expect(c.amount, 12345.67);
      expect(c.percentage, 3.1);
      expect(c.deal!.price, 1000);
      expect(c.deal!.propertyName, 'A');
      expect(c.isPending, isTrue);
    });
  });

  test('custom outdoor areas and nearby places parse and round-trip', () {
    final d = PropertyDetails.fromJson({
      'extra_outdoor': ['Rooftop', 7, null],
      'extra_distances': [
        {'name': 'Pasar', 'meters': 800},
        'bad',
      ],
    });
    expect(d.extraOutdoor, ['Rooftop']);
    expect(d.extraDistances.single.name, 'Pasar');
    expect(d.extraDistances.single.meters, 800);

    final copy = PropertyDetails.fromJson(d.toJson());
    copy.extraOutdoor.add('Gazebo');
    expect(d.extraOutdoor, ['Rooftop'], reason: 'copy must not share lists');
    expect(copy.toJson()['extra_distances'], [
      {'name': 'Pasar', 'meters': 800},
    ]);

    // Older API responses without the fields still give empty lists.
    final old = PropertyDetails.fromJson({});
    expect(old.extraOutdoor, isEmpty);
    expect(old.extraDistances, isEmpty);
  });
}
