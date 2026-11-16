// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../admin/admin_listing_panel.dart';
import '../documents/document_rules.dart';
import '../marketing/listing_panel.dart';
import 'data/property_models.dart';
import 'data/property_repository.dart';

Future<void> openProperty(String id) async =>
    Get.to(() => PropertyDetailScreen(id: id), preventDuplicates: false);

class PropertyDetailScreen extends StatelessWidget {
  const PropertyDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<PropertyRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Detail properti')),
      body: AsyncLoader<PublicProperty>(
        load: (force) => repo.detail(id, force: force),
        builder: (context, p, reload) => _Body(p: p, reload: reload),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.p, required this.reload});
  final PublicProperty p;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.wide(context);
    final side = <Widget>[
      if (p is PrimaryProperty)
        ListingPanel(p: p as PrimaryProperty, reload: reload),
      if (p is InternalProperty)
        AdminListingPanel(p: p as InternalProperty, reload: reload),
      ContactCard(contact: p.contact),
    ];
    final main = <Widget>[
      _Gallery(p.images, p.coverUrl),
      const SizedBox(height: Gap.m),
      _Header(p),
      const SizedBox(height: Gap.l),
      ...PropertySections.of(p),
    ];
    final content = wide
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: main,
                ),
              ),
              const SizedBox(width: Gap.l),
              SizedBox(
                width: 340,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: side,
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [...main.take(3), ...side, ...main.skip(3)],
          );
    return RefreshIndicator(
      onRefresh: reload,
      child: ListView(
        padding: const EdgeInsets.all(Gap.m),
        children: [Readable(maxWidth: 1100, child: content)],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  const _Gallery(this.images, this.cover);
  final List<PropertyImage> images;
  final String? cover;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final imgs = [...widget.images]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final radius = BorderRadius.circular(Radii.card);
    if (imgs.length <= 1) {
      return ClipRRect(
        borderRadius: radius,
        child: PropertyPhoto(imgs.isEmpty ? widget.cover : imgs.first.url),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => Semantics(
                label: 'Foto ${i + 1} dari ${imgs.length}',
                image: true,
                child: PropertyPhoto(imgs[i].url),
              ),
            ),
            Positioned(
              right: Gap.s,
              bottom: Gap.s,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.c.text.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_page + 1}/${imgs.length}',
                    style: context.t.labelMedium?.copyWith(
                      color: context.c.surface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.p);
  final PublicProperty p;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: Gap.s,
        runSpacing: Gap.s,
        children: [
          if (p.isHistory || p is PrimaryProperty || p is InternalProperty)
            StatusChip(p.status, badge: p.statusBadge),
          Pill(
            label: PropertyType.label(p.type),
            color: context.c.primary,
            icon: LucideIcons.house,
          ),
          Pill(
            label: TransactionType.label(p.transactionType),
            color: context.c.primary,
          ),
        ],
      ),
      const SizedBox(height: Gap.s),
      Text(p.name, style: context.t.headlineSmall),
      const SizedBox(height: Gap.xs),
      PriceText(p, large: true),
      const SizedBox(height: Gap.xs),
      Row(
        children: [
          Icon(LucideIcons.mapPin, size: 16, color: context.c.textMuted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              [
                p.details.areaLabel,
                p.locationLabel,
              ].whereType<String>().where((s) => s.isNotEmpty).join(' — '),
              style: context.t.bodyMedium?.copyWith(color: context.c.textMuted),
            ),
          ),
        ],
      ),
      if (p.code.isNotEmpty) Text('Kode ${p.code}', style: context.t.bodySmall),
      if (p.details.shortDescription != null) ...[
        const SizedBox(height: Gap.m),
        Text(p.details.shortDescription!, style: context.t.bodyLarge),
      ],
    ],
  );
}

/// All structured sections (Cluster Mawar reference). Public fields only.
class PropertySections {
  const PropertySections._();

  static const roomLabels = {
    'living_rooms': 'Ruang tamu',
    'dining_rooms': 'Ruang makan',
    'master_bedrooms': 'Kamar tidur utama',
    'child_bedrooms': 'Kamar tidur anak',
    'other_bedrooms': 'Kamar tidur lain',
    'master_bathrooms': 'Kamar mandi utama',
    'child_bathrooms': 'Kamar mandi anak',
    'other_bathrooms': 'Kamar mandi lain',
    'family_rooms': 'Ruang keluarga',
    'study_rooms': 'Ruang belajar',
    'kitchens': 'Dapur',
  };
  static const outdoorLabels = {
    'has_pool': 'Kolam renang',
    'has_garage': 'Garasi',
    'has_front_yard': 'Taman depan',
    'has_back_yard': 'Taman belakang',
    'has_balcony': 'Balkon',
  };
  static const distanceLabels = {
    'dist_school': 'Sekolah',
    'dist_bus_terminal': 'Terminal bus',
    'dist_mrt_lrt': 'MRT/LRT',
    'dist_toll': 'Gerbang tol',
    'dist_hospital': 'Rumah sakit',
  };
  static const furnishingLabels = {
    'unfurnished': 'Tanpa perabot',
    'semi_furnished': 'Semi perabot',
    'furnished': 'Lengkap perabot',
  };

  static List<Widget> of(PublicProperty p) {
    final d = p.details;
    final docs = DocumentRules.typesFor(p.type);
    return [
      SectionBlock(
        title: 'Data & keterangan',
        child: InfoTable([
          ('Kelurahan', d.subDistrict),
          ('Kode pos', d.postalCode),
          ('Luas tanah', p.landArea == null ? null : Fmt.area(p.landArea)),
          (
            'Luas bangunan',
            p.buildingArea == null ? null : Fmt.area(p.buildingArea),
          ),
          ('Jumlah lantai', p.floor?.toString()),
          ('Tahun dibangun', p.yearBuilt?.toString()),
          ('Kamar tidur', p.bedrooms > 0 ? '${p.bedrooms}' : null),
          ('Kamar mandi', p.bathrooms > 0 ? '${p.bathrooms}' : null),
          ('Menghadap', d.orientation),
          (
            'Biaya pemeliharaan / bulan',
            d.maintenanceFee == null ? null : Fmt.rupiah(d.maintenanceFee),
          ),
        ]),
      ),
      if (docs.isNotEmpty)
        SectionBlock(
          title: 'Dokumen kepemilikan',
          child: _Checks({
            for (final t in docs) DocumentRules.label(t): d.cert(t),
          }),
        ),
      SectionBlock(
        title: 'Spesifikasi ruangan',
        child: InfoTable([
          for (final e in roomLabels.entries)
            (e.value, (d.rooms[e.key] ?? 0) > 0 ? '${d.rooms[e.key]}' : null),
        ]),
      ),
      SectionBlock(
        title: 'Fasilitas',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoTable([
              ('Listrik', d.electricityCapacity),
              (
                'AC',
                d.airConditioners > 0 ? '${d.airConditioners} unit' : null,
              ),
              ('TV', d.tvProvider),
              ('Sumber air', d.waterSource),
              ('Perabot', furnishingLabels[d.furnishingStatus]),
            ]),
            if (p.facilities.isNotEmpty) ...[
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  for (final f in p.facilities) Chip(label: Text(f.name)),
                ],
              ),
            ],
          ],
        ),
      ),
      SectionBlock(
        title: 'Area luar',
        child: _Checks({
          for (final e in outdoorLabels.entries)
            e.value: d.outdoor[e.key] ?? false,
          for (final n in d.extraOutdoor) n: true,
        }),
      ),
      SectionBlock(
        title: 'Jarak ke fasilitas umum',
        child: InfoTable([
          for (final e in distanceLabels.entries)
            (
              e.value,
              d.distances[e.key] == null
                  ? null
                  : Fmt.distance(d.distances[e.key]),
            ),
          for (final pl in d.extraDistances) (pl.name, Fmt.distance(pl.meters)),
        ]),
      ),
      if (p.description != null)
        SectionBlock(title: 'Deskripsi', child: Text(p.description!)),
      SectionBlock(
        title: 'Lokasi umum',
        child: InfoTable([
          ('Area', d.areaLabel),
          ('Kecamatan', p.district?.name),
          ('Kota/Kabupaten', p.city?.name),
          ('Provinsi', p.province?.name),
          ('Lokasi', p.generalLocation),
        ]),
      ),
    ];
  }
}

/// Yes/no list with icon and text (not color alone).
class _Checks extends StatelessWidget {
  const _Checks(this.items);
  final Map<String, bool> items;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: Gap.s,
    runSpacing: Gap.s,
    children: [
      for (final e in items.entries)
        Semantics(
          label: '${e.key}: ${e.value ? 'ada' : 'tidak ada'}',
          excludeSemantics: true,
          child: Pill(
            label: e.key,
            icon: e.value ? LucideIcons.check : LucideIcons.minus,
            color: e.value ? context.c.success : context.c.textMuted,
          ),
        ),
    ],
  );
}

/// Representing Marketing's contact. Never the owner's number.
class ContactCard extends StatelessWidget {
  const ContactCard({super.key, required this.contact});
  final MarketingContact? contact;

  Future<void> _open(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('WhatsApp tidak dapat dibuka di perangkat ini.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = contact;
    final uri = c?.safeWhatsappUri;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Marketing',
                style: context.t.labelLarge?.copyWith(
                  color: context.c.textMuted,
                ),
              ),
              const SizedBox(height: Gap.s),
              Row(
                children: [
                  Initials(c?.initials ?? '?'),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Text(
                      c?.name ?? 'Belum ada Marketing',
                      style: context.t.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.m),
              if (uri != null)
                // Primary fill: white on brand green is only ~3.3:1.
                FilledButton.icon(
                  onPressed: () => _open(context, uri),
                  icon: const Icon(LucideIcons.messageCircle),
                  label: const Text('Hubungi lewat WhatsApp'),
                )
              else
                Text(
                  'Kontak WhatsApp belum tersedia untuk listing ini. Coba lagi nanti.',
                  style: context.t.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
