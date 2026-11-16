// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/utils/throttle.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_screens.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_query.dart';
import '../properties/data/property_repository.dart';
import '../properties/property_detail_screen.dart';
import 'filter_sheet.dart';

/// Default shell when nobody is logged in.
class GuestShell extends StatelessWidget {
  const GuestShell({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    tabs: [
      ShellTab('Beranda', LucideIcons.house, (_) => const GuestHome()),
      ShellTab('Cari', LucideIcons.search, (_) => const PropertySearch()),
      ShellTab('Riwayat', LucideIcons.history, (_) => const HistoryList()),
      ShellTab('Akun', LucideIcons.circleUser, (_) => const GuestAccount()),
    ],
  );
}

class GuestHome extends StatelessWidget {
  const GuestHome({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<PropertyRepository>();
    void search(PropertyQuery q) => Get.to(
      () => Scaffold(
        appBar: AppBar(title: const Text('Cari properti')),
        body: PropertySearch(initial: q),
      ),
    );
    return Scaffold(
      body: SafeArea(
        child: PagedList<PublicProperty>(
          minItemWidth: 340,
          fetch: (page, force) => repo.list(
            PropertyQuery(sort: 'newest', page: page),
            force: force,
          ),
          itemBuilder: (_, p) =>
              PropertyCard(p, onTap: () => openProperty(p.id)),
          empty: const EmptyView(
            icon: LucideIcons.house,
            title: 'Belum ada listing',
            message: 'Listing baru akan tampil di sini.',
          ),
          header: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.l, Gap.m, Gap.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Wordmark(size: 28),
                const SizedBox(height: Gap.s),
                Text(
                  'Rumah, apartemen, ruko, dan pabrik untuk dijual atau disewa.',
                  style: context.t.titleMedium,
                ),
                const SizedBox(height: Gap.m),
                TextField(
                  maxLength: PropertyQuery.maxSearchLength,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama, kode, atau lokasi',
                    labelText: 'Cari properti',
                    prefixIcon: Icon(LucideIcons.search),
                    counterText: '',
                  ),
                  onSubmitted: (s) => search(PropertyQuery(search: s)),
                ),
                const SizedBox(height: Gap.m),
                Wrap(
                  spacing: Gap.s,
                  runSpacing: Gap.s,
                  children: [
                    for (final (t, icon) in const [
                      (PropertyType.house, LucideIcons.house),
                      (PropertyType.apartment, LucideIcons.building),
                      (PropertyType.shopHouse, LucideIcons.store),
                      (PropertyType.factory, LucideIcons.factory),
                    ])
                      ActionChip(
                        avatar: Icon(icon, size: 18),
                        label: Text(PropertyType.label(t)),
                        onPressed: () => search(PropertyQuery(type: t)),
                      ),
                  ],
                ),
                const SizedBox(height: Gap.l),
                Text('Listing terbaru', style: context.t.titleLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Search with debounce (400 ms), 100-char cap and server-side filters.
class PropertySearch extends StatefulWidget {
  const PropertySearch({
    super.key,
    this.initial = const PropertyQuery(),
    this.showStatus = false,
  });
  final PropertyQuery initial;
  final bool showStatus;

  @override
  State<PropertySearch> createState() => _PropertySearchState();
}

class _PropertySearchState extends State<PropertySearch> {
  final repo = Get.find<PropertyRepository>();
  final _debounce = Debouncer();
  late PropertyQuery _q = widget.initial;
  late final _text = TextEditingController(text: widget.initial.search ?? '');

  @override
  void dispose() {
    _debounce.cancel();
    _text.dispose();
    super.dispose();
  }

  int get _activeFilters =>
      [
        _q.type,
        _q.transactionType,
        _q.provinceId,
        _q.minPrice,
        _q.maxPrice,
        _q.minLandArea,
        _q.maxLandArea,
        _q.minBuildingArea,
        _q.maxBuildingArea,
        _q.bedrooms,
        _q.bathrooms,
        _q.sort,
      ].where((v) => v != null).length +
      (_q.facilityIds.isEmpty ? 0 : 1);

  @override
  Widget build(BuildContext context) => SafeArea(
    child: PagedList<PublicProperty>(
      queryKey: _q,
      minItemWidth: 340,
      fetch: (page, force) => repo.list(_q.copyWith(page: page), force: force),
      itemBuilder: (_, p) => PropertyCard(
        p,
        showStatus: widget.showStatus,
        onTap: () => openProperty(p.id),
      ),
      empty: EmptyView(
        icon: LucideIcons.searchX,
        title: 'Tidak ada hasil',
        message: 'Ubah kata kunci atau longgarkan filter.',
        action: _activeFilters > 0
            ? OutlinedButton(
                onPressed: () =>
                    setState(() => _q = PropertyQuery(search: _q.search)),
                child: const Text('Hapus filter'),
              )
            : null,
      ),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                maxLength: PropertyQuery.maxSearchLength,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Cari properti',
                  prefixIcon: Icon(LucideIcons.search),
                  counterText: '',
                ),
                onChanged: (s) => _debounce(
                  () => setState(() => _q = _q.copyWith(search: s)),
                ),
              ),
            ),
            const SizedBox(width: Gap.s),
            Badge(
              isLabelVisible: _activeFilters > 0,
              label: Text('$_activeFilters'),
              child: IconButton.outlined(
                tooltip: 'Filter',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                icon: const Icon(LucideIcons.slidersHorizontal),
                onPressed: () async {
                  final q = await showFilterSheet(
                    context,
                    _q.copyWith(search: _text.text),
                  );
                  if (q != null) setState(() => _q = q);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Sold/rented history (`history=true`).
class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<PropertyRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat terjual & tersewa')),
      body: PagedList<PublicProperty>(
        minItemWidth: 340,
        fetch: (page, force) =>
            repo.list(PropertyQuery(history: true, page: page), force: force),
        itemBuilder: (_, p) => PropertyCard(p, onTap: () => openProperty(p.id)),
        empty: const EmptyView(
          icon: LucideIcons.history,
          title: 'Belum ada riwayat',
          message: 'Properti yang terjual atau tersewa tampil di sini.',
        ),
      ),
    );
  }
}

class GuestAccount extends StatelessWidget {
  const GuestAccount({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Akun')),
    body: EmptyView(
      icon: LucideIcons.briefcaseBusiness,
      title: 'Untuk tim Marketing dan Admin',
      message:
          'Pengunjung tidak perlu akun. Hubungi Marketing langsung lewat tombol WhatsApp di setiap listing.',
      action: FilledButton(
        onPressed: () => Get.toNamed(Routes.login),
        child: const Text('Masuk'),
      ),
    ),
  );
}
