// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_screens.dart';
import '../deals/deal_repository.dart';
import '../deals/transactions_screens.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_query.dart';
import '../properties/data/property_repository.dart';
import '../properties/property_detail_screen.dart';
import 'listing_form.dart';

class MarketingShell extends StatelessWidget {
  const MarketingShell({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    tabs: [
      ShellTab(
        'Dashboard',
        LucideIcons.layoutDashboard,
        (_) => const MarketingDashboard(),
      ),
      ShellTab('Listing', LucideIcons.house, (_) => const MyListings()),
      ShellTab('Transaksi', LucideIcons.wallet, (_) => const TransactionsTab()),
      ShellTab('Profil', LucideIcons.circleUser, (_) => const ProfileScreen()),
    ],
  );
}

typedef _Counts = Map<String, int>;

class MarketingDashboard extends StatelessWidget {
  const MarketingDashboard({super.key});

  static Future<_Counts> _load(bool force) async {
    final props = Get.find<PropertyRepository>();
    final deals = Get.find<DealRepository>();
    Future<int> count(PropertyQuery q) async =>
        (await props.list(q, force: force)).meta.total;
    final keys = <String, Future<int>>{
      'mine': count(const PropertyQuery(scope: 'mine', limit: 1)),
      'co': count(const PropertyQuery(scope: 'co_listing', limit: 1)),
      for (final s in const [
        PropertyStatus.available,
        PropertyStatus.reserved,
        PropertyStatus.draft,
        PropertyStatus.maintenance,
      ])
        s: count(PropertyQuery(scope: 'mine', status: s, limit: 1)),
      'deals': deals.deals(limit: 1, force: force).then((p) => p.meta.total),
      'pending': deals
          .commissions(status: 'pending', limit: 1, force: force)
          .then((p) => p.meta.total),
    };
    final values = await Future.wait(keys.values);
    return Map.fromIterables(keys.keys, values);
  }

  @override
  Widget build(BuildContext context) {
    final user = Get.find<AuthController>().user.value;
    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${user?.name.split(' ').first ?? 'Marketing'}'),
      ),
      body: AsyncLoader<_Counts>(
        load: _load,
        builder: (context, c, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.all(Gap.m),
            children: [
              Readable(
                maxWidth: 1000,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (user?.whatsappNumber == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.m),
                        child: Card(
                          child: ListTile(
                            leading: Icon(
                              LucideIcons.messageCircleWarning,
                              color: context.c.warning,
                            ),
                            title: const Text('Nomor WhatsApp belum diisi'),
                            subtitle: const Text(
                              'Pengunjung tidak bisa menghubungi Anda dari listing. Isi di tab Profil.',
                            ),
                          ),
                        ),
                      ),
                    Text('Listing saya', style: context.t.titleMedium),
                    const SizedBox(height: Gap.s),
                    _Grid([
                      _Stat('Utama', c['mine']!, LucideIcons.crown),
                      _Stat('Co-listing', c['co']!, LucideIcons.users),
                      _Stat(
                        'Tersedia',
                        c[PropertyStatus.available]!,
                        LucideIcons.circleCheck,
                      ),
                      _Stat(
                        'Dipesan',
                        c[PropertyStatus.reserved]!,
                        LucideIcons.clock,
                      ),
                      _Stat(
                        'Draf',
                        c[PropertyStatus.draft]!,
                        LucideIcons.pencilLine,
                      ),
                      _Stat(
                        'Perbaikan',
                        c[PropertyStatus.maintenance]!,
                        LucideIcons.wrench,
                      ),
                    ]),
                    const SizedBox(height: Gap.l),
                    Text('Transaksi saya', style: context.t.titleMedium),
                    const SizedBox(height: Gap.s),
                    _Grid([
                      _Stat(
                        'Deal tercatat',
                        c['deals']!,
                        LucideIcons.handshake,
                      ),
                      _Stat(
                        'Komisi menunggu',
                        c['pending']!,
                        LucideIcons.wallet,
                      ),
                    ]),
                    const SizedBox(height: Gap.l),
                    FilledButton.icon(
                      onPressed: () => Get.to(() => const ListingForm()),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Buat listing baru'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);
  final String label;
  final int value;
  final IconData icon;
}

class _Grid extends StatelessWidget {
  const _Grid(this.items);
  final List<_Stat> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth >= 720 ? 3 : 2;
      final w = (box.maxWidth - Gap.s * (cols - 1)) / cols;
      return Wrap(
        spacing: Gap.s,
        runSpacing: Gap.s,
        children: [
          for (final s in items)
            SizedBox(
              width: w,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(Gap.m),
                  child: Semantics(
                    label: '${s.label}: ${s.value}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(s.icon, size: 18, color: context.c.textMuted),
                        const SizedBox(height: Gap.s),
                        Text(
                          '${s.value}',
                          style: context.t.headlineSmall?.copyWith(
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(s.label, style: context.t.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class MyListings extends StatefulWidget {
  const MyListings({super.key});

  @override
  State<MyListings> createState() => _MyListingsState();
}

class _MyListingsState extends State<MyListings> {
  final repo = Get.find<PropertyRepository>();
  String? _status;
  int _rev =
      0; // bumps after visiting a detail; mutations already dropped the cache

  Widget _list(String scope) => PagedList<PublicProperty>(
    queryKey: '$scope-$_status-$_rev',
    minItemWidth: 340,
    fetch: (page, force) => repo.list(
      PropertyQuery(
        scope: scope,
        status: scope == 'mine' ? _status : null,
        page: page,
      ),
      force: force,
    ),
    itemBuilder: (_, p) => PropertyCard(
      p,
      showStatus: true,
      onTap: () async {
        await openProperty(p.id);
        if (mounted) setState(() => _rev++);
      },
    ),
    header: scope != 'mine'
        ? Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
            child: Text(
              'Listing tempat Anda ditambahkan sebagai co-listing. Hanya baca, kecuali ubah ketersediaan.',
              style: context.t.bodySmall,
            ),
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
            child: Row(
              children: [
                for (final s in const [
                  null,
                  ...PropertyStatus.primarySettable,
                  PropertyStatus.sold,
                  PropertyStatus.rented,
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: Gap.s),
                    child: ChoiceChip(
                      label: Text(
                        s == null ? 'Semua' : PropertyStatus.label(s),
                      ),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ),
              ],
            ),
          ),
    empty: scope == 'mine'
        ? EmptyView(
            icon: LucideIcons.house,
            title: 'Belum ada listing',
            message:
                'Buat listing pertama Anda; Anda menjadi Marketing utamanya.',
            action: FilledButton(
              onPressed: () => Get.to(() => const ListingForm()),
              child: const Text('Buat listing'),
            ),
          )
        : const EmptyView(
            icon: LucideIcons.users,
            title: 'Belum ada co-listing',
            message: 'Admin menambahkan Anda ke tim listing lain.',
          ),
  );

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Listing saya'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Utama'),
            Tab(text: 'Co-listing'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const ListingForm()),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Listing baru'),
      ),
      body: TabBarView(children: [_list('mine'), _list('co_listing')]),
    ),
  );
}
