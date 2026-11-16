// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../documents/documents_screen.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_repository.dart';
import 'listing_form.dart';
import 'owner_screen.dart';
import 'photos_screen.dart';

/// Primary / co-listing view: exact address, team and the actions the
/// access level allows. Owner data is never shown here (separate endpoint,
/// Primary only).
class ListingPanel extends StatelessWidget {
  const ListingPanel({super.key, required this.p, required this.reload});
  final PrimaryProperty p;
  final Future<void> Function() reload;

  /// Statuses this user may move the listing to.
  static List<String> allowedTargets(PrimaryProperty p) {
    if (p.status == PropertyStatus.sold || p.status == PropertyStatus.rented) {
      return p.isPrimary ? const [PropertyStatus.archived] : const [];
    }
    if (p.isPrimary) {
      return PropertyStatus.primarySettable
          .where((s) => s != p.status)
          .toList();
    }
    if (p.status == PropertyStatus.draft ||
        p.status == PropertyStatus.archived) {
      return const [];
    }
    return PropertyStatus.coListingSettable
        .where((s) => s != p.status)
        .toList();
  }

  Future<void> _changeStatus(BuildContext context) async {
    final targets = allowedTargets(p);
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.m),
              child: Text('Ubah status', style: ctx.t.titleMedium),
            ),
            for (final s in targets)
              ListTile(
                leading: StatusChip(s),
                title: Text(PropertyStatus.label(s)),
                onTap: () => Navigator.pop(ctx, s),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !context.mounted) return;
    if (picked == PropertyStatus.archived &&
        !await confirm(
          context,
          title: 'Arsipkan listing?',
          message: 'Listing yang diarsipkan disembunyikan dari semua daftar.',
          confirmLabel: 'Arsipkan',
          destructive: true,
        )) {
      return;
    }
    if (!context.mounted) return;
    final ok = await runAction(
      context,
      () => Get.find<PropertyRepository>().setStatus(p.id, picked),
      success: 'Status diubah menjadi ${PropertyStatus.label(picked)}',
    );
    if (ok) await reload();
  }

  Future<void> _delete(BuildContext context) async {
    if (!await confirm(
      context,
      title: 'Hapus listing?',
      message: 'Jika listing sudah memiliki deal, listing akan diarsipkan.',
      confirmLabel: 'Hapus',
      destructive: true,
    )) {
      return;
    }
    if (!context.mounted) return;
    final ok = await runAction(
      context,
      () => Get.find<PropertyRepository>().remove(p.id),
      success: 'Listing dihapus',
    );
    if (ok) Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final a = p.address;
    final targets = allowedTargets(p);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Pill(
                    label: p.isPrimary
                        ? 'Marketing utama'
                        : 'Co-listing (hanya baca)',
                    icon: p.isPrimary ? LucideIcons.crown : LucideIcons.users,
                    color: context.c.primary,
                  ),
                ],
              ),
              const SizedBox(height: Gap.m),
              Text('Alamat lengkap', style: context.t.titleSmall),
              const SizedBox(height: Gap.xs),
              InfoTable([
                ('Cluster', a.clusterName),
                ('Blok', a.blockNumber),
                ('Jalan', a.streetName),
                ('Nomor', a.houseNumber),
                ('Lantai', a.floorNumber),
                ('Unit', a.roomNumber),
                (
                  'Koordinat',
                  p.latitude == null || p.longitude == null
                      ? null
                      : '${p.latitude}, ${p.longitude}',
                ),
              ]),
              const SizedBox(height: Gap.m),
              Text('Tim Marketing', style: context.t.titleSmall),
              for (final m in p.team)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Initials(
                    m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                    size: 36,
                  ),
                  title: Text(m.name),
                  subtitle: Text(m.isPrimary ? 'Utama' : 'Co-listing'),
                ),
              const Divider(),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  if (targets.isNotEmpty)
                    FilledButton.tonalIcon(
                      onPressed: () => _changeStatus(context),
                      icon: const Icon(LucideIcons.refreshCw),
                      label: const Text('Ubah status'),
                    ),
                  if (p.isPrimary) ...[
                    OutlinedButton.icon(
                      onPressed: () async {
                        final saved = await Get.to<bool>(
                          () => ListingForm(existing: p),
                        );
                        if (saved == true) await reload();
                      },
                      icon: const Icon(LucideIcons.pencil),
                      label: const Text('Edit listing'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Get.to(() => PhotosScreen(propertyId: p.id));
                        await reload();
                      },
                      icon: const Icon(LucideIcons.images),
                      label: const Text('Foto'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Get.to(() => OwnerScreen(propertyId: p.id)),
                      icon: const Icon(LucideIcons.userRound),
                      label: const Text('Data pemilik'),
                    ),
                  ],
                  OutlinedButton.icon(
                    onPressed: () => Get.to(() => DocumentsScreen(property: p)),
                    icon: const Icon(LucideIcons.fileText),
                    label: const Text('Dokumen'),
                  ),
                  if (p.isPrimary)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: context.c.danger,
                      ),
                      onPressed: () => _delete(context),
                      icon: const Icon(LucideIcons.trash2),
                      label: const Text('Hapus'),
                    ),
                ],
              ),
              if (!p.isPrimary)
                Padding(
                  padding: const EdgeInsets.only(top: Gap.s),
                  child: Text(
                    'Hanya Marketing utama yang dapat mengedit listing dan melihat data pemilik.',
                    style: context.t.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
