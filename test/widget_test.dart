// ignore: deprecated_member_use, see lib imports (material_ui shortcut).
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:propmanaget/app/routes.dart';
import 'package:propmanaget/app/theme.dart';
import 'package:propmanaget/core/cache/cache_store.dart';
import 'package:propmanaget/core/di.dart';
import 'package:propmanaget/core/network/api_client.dart';
import 'package:propmanaget/core/network/api_exception.dart';
import 'package:propmanaget/core/storage/token_storage.dart';
import 'package:propmanaget/core/widgets/app_shell.dart';
import 'package:propmanaget/core/widgets/common.dart';
import 'package:propmanaget/core/widgets/state_views.dart';
import 'package:propmanaget/features/auth/auth_controller.dart';
import 'package:propmanaget/features/auth/auth_screens.dart';
import 'package:propmanaget/features/documents/documents_screen.dart';
import 'package:propmanaget/features/marketing/listing_form.dart';
import 'package:propmanaget/features/properties/data/property_models.dart';
import 'package:propmanaget/features/properties/property_detail_screen.dart';
import 'package:propmanaget/main.dart';

import 'helpers/fake_adapter.dart';

Map<String, dynamic> property({
  String? access,
  String status = 'available',
  String? badge,
  Map<String, dynamic> extra = const {},
}) => {
  'id': 'p1',
  'code': 'LV-001',
  'name': 'Rumah Cluster Mawar',
  'type': 'house',
  'transaction_type': 'sale',
  'status': status,
  'status_badge': ?badge,
  'is_available': status == 'available',
  'price': 1500000000,
  'bedrooms': 3,
  'bathrooms': 2,
  'land_area': 120,
  'city': {'id': 'c', 'name': 'Bogor'},
  'province': {'id': 'pr', 'name': 'Jawa Barat'},
  'cert_shm': true,
  'living_rooms': 1,
  'has_garage': true,
  'dist_school': 800,
  'contact': {
    'name': 'Rina Marketing',
    'whatsapp_number': '6281',
    'whatsapp_url': 'https://wa.me/6281?text=Halo',
  },
  'access_level': ?access,
  if (access == 'primary' || access == 'co_listing') ...{
    'address': {'street_name': 'Jl. Mawar Rahasia', 'house_number': '7'},
    'marketing_team': [
      {'marketing_id': 'm1', 'name': 'Rina', 'assignment_type': 'primary'},
    ],
  },
  if (access == 'admin')
    'marketing_team': [
      {'marketing_id': 'm1', 'name': 'Rina', 'assignment_type': 'primary'},
    ],
  ...extra,
};

final page = {'page': 1, 'limit': 20, 'total': 1, 'total_pages': 1};

late FakeAdapter adapter;

Future<void> boot({
  TokenPair? token,
  FakeReply Function(FakeCall)? handler,
}) async {
  Get.reset();
  Get.testMode = true;
  adapter = FakeAdapter(
    handler ?? (c) => FakeReply(200, ok([property()], page)),
  );
  final storage = MemoryTokenStorage(token);
  await setupDependencies(
    tokenStorage: storage,
    diskCache: MemoryPublicDiskCache(),
    documentsDir: () async =>
        throw UnsupportedError('no file IO in widget tests'),
    apiClient: ApiClient(
      baseUrl: 'http://t/api/v1',
      tokens: storage,
      dio: Dio()..httpClientAdapter = adapter,
      retryDelay: Duration.zero,
    ),
  );
}

Widget host(Widget child) =>
    GetMaterialApp(theme: buildTheme(), home: child, getPages: Routes.pages);

Future<void> setSize(WidgetTester t, double w, double h) async {
  t.view.physicalSize = Size(w, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

class _Counter extends StatefulWidget {
  const _Counter();
  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int n = 0;
  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => setState(() => n++),
      child: Text('n=$n'),
    ),
  );
}

ui.DisplayFeature hinge(Rect r) => ui.DisplayFeature(
  bounds: r,
  type: ui.DisplayFeatureType.hinge,
  state: ui.DisplayFeatureState.unknown,
);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets('app opens in guest mode without a token', (t) async {
    await setSize(t, 390, 844);
    await boot();
    await t.pumpWidget(const LeventaApp());
    await t.pumpAndSettle();
    for (final label in ['Beranda', 'Cari', 'Riwayat', 'Akun']) {
      expect(find.text(label), findsWidgets);
    }
    expect(find.text('Rumah Cluster Mawar'), findsOneWidget);
    expect(adapter.calls.any((c) => c.path == '/auth/me'), isFalse);
    expect(adapter.calls.every((c) => c.auth == null), isTrue);
  });

  testWidgets('login has no role selector and no registration', (t) async {
    await boot();
    await t.pumpWidget(host(const LoginScreen()));
    await t.pumpAndSettle();
    expect(find.byType(TextFormField), findsNWidgets(2));
    for (final s in [
      'Daftar',
      'Registrasi',
      'Customer',
      'Pilih peran',
      'Sales',
      'Admin123',
    ]) {
      expect(find.textContaining(s), findsNothing);
    }
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    expect(find.byType(SegmentedButton<String>), findsNothing);
  });

  testWidgets('retired role after login → unsupported screen', (t) async {
    await setSize(t, 390, 844);
    await boot(
      handler: (c) => c.path == '/auth/login'
          ? FakeReply(
              200,
              ok({
                'access_token': 'a',
                'refresh_token': 'r',
                'expires_in': 900,
                'user': {
                  'id': 'u',
                  'name': 'X',
                  'email': 'x@x.test',
                  'role': 'customer',
                  'status': 'active',
                },
              }),
            )
          : FakeReply(200, ok([], page)),
    );
    await t.pumpWidget(const LeventaApp());
    await t.pumpAndSettle();
    Get.toNamed(Routes.login);
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField).at(0), 'x@x.test');
    await t.enterText(find.byType(TextFormField).at(1), 'pw');
    await t.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await t.pumpAndSettle();

    expect(find.text('Peran akun tidak didukung'), findsOneWidget);
  });

  group('detail projections', () {
    Future<void> openDetail(
      WidgetTester t,
      Map<String, dynamic> json, {
      double w = 390,
    }) async {
      await setSize(t, w, 2400);
      await boot(handler: (c) => FakeReply(200, ok(json)));
      await t.pumpWidget(host(const PropertyDetailScreen(id: 'p1')));
      await t.pumpAndSettle();
    }

    testWidgets('guest: all sections, SOLD badge, WhatsApp, nothing private', (
      t,
    ) async {
      await openDetail(t, property(status: 'sold', badge: 'SOLD'));
      for (final s in [
        'Data & keterangan',
        'Dokumen kepemilikan',
        'Spesifikasi ruangan',
        'Fasilitas',
        'Area luar',
        'Jarak ke fasilitas umum',
        'Lokasi umum',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('Terjual'), findsWidgets);
      expect(find.text('Hubungi lewat WhatsApp'), findsOneWidget);
      for (final s in [
        'Alamat lengkap',
        'Edit listing',
        'Data pemilik',
        'Dokumen',
        'Catat deal',
        'Jl. Mawar Rahasia',
      ]) {
        expect(find.text(s), findsNothing, reason: s);
      }
      expect(t.takeException(), isNull);
    });

    testWidgets('missing WhatsApp shows a clear state, not a dead button', (
      t,
    ) async {
      await openDetail(
        t,
        property(
          extra: {
            'contact': {'name': 'Rina'},
          },
        ),
      );
      expect(find.text('Hubungi lewat WhatsApp'), findsNothing);
      expect(
        find.textContaining('Kontak WhatsApp belum tersedia'),
        findsOneWidget,
      );
    });

    testWidgets('primary sees edit, owner and exact address', (t) async {
      await openDetail(t, property(access: 'primary'));
      expect(find.text('Edit listing'), findsOneWidget);
      expect(find.text('Data pemilik'), findsOneWidget);
      expect(find.text('Jl. Mawar Rahasia'), findsOneWidget);
    });

    testWidgets('co-listing is read-only plus status toggle', (t) async {
      await openDetail(t, property(access: 'co_listing'));
      expect(find.text('Ubah status'), findsOneWidget);
      expect(find.text('Dokumen'), findsOneWidget);
      expect(find.text('Edit listing'), findsNothing);
      expect(find.text('Data pemilik'), findsNothing);
      expect(find.text('Foto'), findsNothing);
      expect(find.text('Hapus'), findsNothing);
    });

    testWidgets('admin manages team and outcome, sees no address', (t) async {
      await openDetail(t, property(access: 'admin'), w: 1024);
      expect(find.text('Catat deal'), findsOneWidget);
      expect(find.text('Catat pembatalan'), findsOneWidget);
      expect(find.text('Tambah co-listing'), findsOneWidget);
      expect(find.text('Alamat lengkap'), findsNothing);
      expect(find.text('Edit listing'), findsNothing);
      expect(find.text('Dokumen'), findsNothing);
    });

    testWidgets('no overflow at 360 and 1024 px', (t) async {
      for (final w in [360.0, 1024.0]) {
        await openDetail(t, property(access: 'primary'), w: w);
        expect(t.takeException(), isNull, reason: 'width $w');
      }
    });
  });

  group('documents', () {
    PrimaryProperty prop(String access, {bool shm = true}) =>
        parsePropertyDetail(property(access: access, extra: {'cert_shm': shm}))
            as PrimaryProperty;

    Future<void> open(WidgetTester t, PrimaryProperty p) async {
      await setSize(t, 390, 2400);
      await boot(
        handler: (_) => FakeReply(
          200,
          ok([
            {
              'id': 'd1',
              'doc_type': 'shm',
              'original_name': 'shm.pdf',
              'mime_type': 'application/pdf',
              'size_bytes': 2048,
            },
          ]),
        ),
      );
      await t.pumpWidget(host(DocumentsScreen(property: p)));
      await t.pumpAndSettle();
    }

    testWidgets('primary can replace and delete; flag-off explains why', (
      t,
    ) async {
      await open(t, prop('primary'));
      expect(find.text('Ganti'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
      expect(find.textContaining('Aktifkan centang HGB'), findsOneWidget);
    });

    testWidgets('co-listing can only download', (t) async {
      await open(t, prop('co_listing'));
      expect(find.text('Unduh / bagikan'), findsOneWidget);
      expect(find.text('Ganti'), findsNothing);
      expect(find.text('Unggah'), findsNothing);
      expect(find.text('Hapus'), findsNothing);
    });
  });

  group('error states', () {
    testWidgets('429 waits for Retry-After before allowing retry', (t) async {
      var retried = false;
      await t.pumpWidget(
        host(
          Scaffold(
            body: ErrorView(
              error: ApiException(
                kind: ApiErrorKind.rateLimited,
                message: 'slow',
                retryAfter: const Duration(seconds: 2),
                requestId: 'rid-9',
              ),
              onRetry: () => retried = true,
            ),
          ),
        ),
      );
      expect(find.text('Coba lagi dalam 2 dtk'), findsOneWidget);
      await t.tap(find.text('Coba lagi dalam 2 dtk'));
      expect(retried, isFalse);
      await t.pump(const Duration(seconds: 3));
      await t.tap(find.text('Coba lagi'));
      expect(retried, isTrue);
      expect(find.textContaining('rid-9'), findsOneWidget);
    });

    testWidgets('403 is a permission state without retry', (t) async {
      await t.pumpWidget(
        host(
          Scaffold(
            body: ErrorView(
              error: ApiException(kind: ApiErrorKind.forbidden, message: 'no'),
              onRetry: () {},
            ),
          ),
        ),
      );
      expect(find.text('Akses ditolak'), findsOneWidget);
      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('a 403 list never renders as an empty success', (t) async {
      await setSize(t, 390, 844);
      await boot(handler: (_) => FakeReply(403, failBody('Forbidden')));
      await t.pumpWidget(const LeventaApp());
      await t.pumpAndSettle();
      expect(find.text('Akses ditolak'), findsOneWidget);
      expect(find.text('Belum ada listing'), findsNothing);
    });
  });

  testWidgets('home has no overflow at small phone and tablet widths', (
    t,
  ) async {
    for (final (w, h) in [(360.0, 800.0), (768.0, 1024.0), (1024.0, 768.0)]) {
      await setSize(t, w, h);
      await t.pumpWidget(const SizedBox()); // remount the app per size
      await boot();
      await t.pumpWidget(const LeventaApp());
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: '$w x $h');
      expect(Get.find<AuthController>().status.value, AuthStatus.guest);
    }
  });

  testWidgets('listing form save button stays visible without scrolling', (
    t,
  ) async {
    for (final (w, h) in [(360.0, 640.0), (768.0, 1024.0), (1280.0, 800.0)]) {
      await setSize(t, w, h);
      await t.pumpWidget(const SizedBox());
      await boot(handler: (c) => FakeReply(200, ok([])));
      await t.pumpWidget(host(const ListingForm()));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull, reason: '$w x $h');
      final btn = find.widgetWithText(FilledButton, 'Buat listing');
      expect(btn.hitTestable(), findsOneWidget, reason: '$w x $h');
      final bar = t.getRect(
        find.ancestor(of: btn, matching: find.byType(DecoratedBox)).first,
      );
      expect(bar.bottom, h, reason: 'pinned to the bottom at $w x $h');
      expect(bar.height, lessThan(120), reason: 'bar must not grow at $w');
    }
  });

  group('foldables', () {
    testWidgets('tab state survives folding and unfolding', (t) async {
      await setSize(t, 390, 800);
      await boot();
      await t.pumpWidget(
        host(
          AppShell(
            tabs: [
              ShellTab('A', Icons.home, (_) => const _Counter()),
              ShellTab('B', Icons.info, (_) => const SizedBox()),
            ],
          ),
        ),
      );
      await t.tap(find.text('n=0'));
      await t.pump();
      expect(find.text('n=1'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      await setSize(t, 1000, 800); // unfolded: rail layout
      await t.pump();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('n=1'), findsOneWidget, reason: 'state lost on unfold');

      await setSize(t, 390, 800); // folded again
      await t.pump();
      expect(find.text('n=1'), findsOneWidget, reason: 'state lost on fold');
    });

    testWidgets('a hinge keeps the app on one screen, a flat fold does not', (
      t,
    ) async {
      await setSize(t, 840, 800);
      await boot();
      await t.pumpWidget(const LeventaApp());
      await t.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      await t.tap(find.text('Akun').first);
      await t.pumpAndSettle();

      // Dual-screen hinge: 500 | 40 gap | 300. App moves to the larger left screen.
      t.view.displayFeatures = [hinge(const Rect.fromLTWH(500, 0, 40, 800))];
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(find.byType(NavigationRail), findsNothing);
      final bar = find.byType(NavigationBar);
      expect(t.getRect(bar).right, lessThanOrEqualTo(500));
      expect(
        t.widget<NavigationBar>(bar).selectedIndex,
        3,
        reason: 'opening the hinge reset the app',
      );

      // Flat fold (no gap, e.g. Galaxy Z Fold unfolded): full width again.
      t.view.displayFeatures = [
        const ui.DisplayFeature(
          bounds: Rect.fromLTWH(420, 0, 0, 800),
          type: ui.DisplayFeatureType.fold,
          state: ui.DisplayFeatureState.postureFlat,
        ),
      ];
      await t.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('TV / D-pad', () {
    testWidgets('remote can reach a listing card, see the ring and open it', (
      t,
    ) async {
      await setSize(t, 960, 540); // 1080p TV at 2x
      await boot();
      await t.pumpWidget(const LeventaApp());
      await t.pumpAndSettle();
      expect(find.byType(PropertyCard), findsOneWidget);

      bool onCard() =>
          FocusManager.instance.primaryFocus?.context
              ?.findAncestorWidgetOfExactType<PropertyCard>() !=
          null;
      for (var i = 0; i < 40 && !onCard(); i++) {
        await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await t.pump();
      }
      expect(onCard(), isTrue, reason: 'D-pad never reached the card');
      final card = t.widget<Card>(
        find.descendant(
          of: find.byType(PropertyCard),
          matching: find.byType(Card),
        ),
      );
      expect(card.shape, isNotNull, reason: 'no focus ring on the card');

      await t.sendKeyEvent(LogicalKeyboardKey.select);
      await t.pumpAndSettle();
      expect(find.byType(PropertyDetailScreen), findsOneWidget);
    });

    test('every button type draws a ring only while focused', () {
      final th = buildTheme();
      for (final style in [
        th.filledButtonTheme.style,
        th.outlinedButtonTheme.style,
        th.textButtonTheme.style,
        th.iconButtonTheme.style,
      ]) {
        expect(
          style!.side!.resolve({WidgetState.focused})!.width,
          3,
          reason: 'focused ring',
        );
      }
      expect(th.filledButtonTheme.style!.side!.resolve({}), isNull);
    });
  });
}
