// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/utils/pick.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_repository.dart';

/// Primary only: upload and delete listing photos and pick the cover.
class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key, required this.propertyId});
  final String propertyId;

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final repo = Get.find<PropertyRepository>();
  final _loader = GlobalKey<AsyncLoaderState<PublicProperty>>();
  bool _busy = false;

  Future<void> _upload() async {
    final messenger = ScaffoldMessenger.of(context);
    PickedFile? f;
    try {
      f = await pickListingImage();
    } on PickError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Akses galeri ditolak. Izinkan akses foto di pengaturan perangkat.',
          ),
        ),
      );
      return;
    }
    if (f == null || !mounted) return;
    setState(() => _busy = true);
    final picked = f;
    final ok = await runAction(
      context,
      () => repo.uploadImage(widget.propertyId, picked.path, picked.name),
      success: 'Foto diunggah',
    );
    if (mounted) setState(() => _busy = false);
    if (ok) await _loader.currentState?.reload();
  }

  Future<void> _delete(PropertyImage img) async {
    if (!await confirm(
      context,
      title: 'Hapus foto?',
      message: 'Foto akan dihapus dari listing.',
      confirmLabel: 'Hapus',
      destructive: true,
    )) {
      return;
    }
    if (!mounted) return;
    final ok = await runAction(
      context,
      () => repo.deleteImage(widget.propertyId, img.id),
      success: 'Foto dihapus',
    );
    if (ok) await _loader.currentState?.reload();
  }

  Future<void> _makeCover(PropertyImage img) async {
    final ok = await runAction(
      context,
      () => repo.setThumbnail(widget.propertyId, img.id),
      success: 'Sampul diganti',
    );
    if (ok) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Foto listing')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : _upload,
      icon: _busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(LucideIcons.imagePlus),
      label: Text(_busy ? 'Mengunggah…' : 'Tambah foto'),
    ),
    body: AsyncLoader<PublicProperty>(
      key: _loader,
      load: (force) => repo.detail(widget.propertyId, force: force),
      builder: (context, p, reload) {
        final imgs = [...p.images]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        if (imgs.isEmpty) {
          return const EmptyView(
            icon: LucideIcons.images,
            title: 'Belum ada foto',
            message:
                'Foto pertama menjadi sampul listing. JPEG, PNG, GIF, atau WebP, maksimal 5 MB.',
          );
        }
        return RefreshIndicator(
          onRefresh: reload,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisSpacing: Gap.m,
              crossAxisSpacing: Gap.m,
              childAspectRatio: 16 / 12,
            ),
            itemCount: imgs.length,
            itemBuilder: (_, i) => Card(
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PropertyPhoto(imgs[i].url, aspectRatio: 16 / 12),
                  if (imgs[i].isThumbnail)
                    Positioned(
                      left: Gap.s,
                      top: Gap.s,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.c.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Pill(label: 'Sampul', color: context.c.primary),
                      ),
                    )
                  else
                    Positioned(
                      left: Gap.xs,
                      bottom: Gap.xs,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _makeCover(imgs[i]),
                        icon: const Icon(LucideIcons.star, size: 18),
                        label: const Text('Jadikan sampul'),
                      ),
                    ),
                  Positioned(
                    right: Gap.xs,
                    top: Gap.xs,
                    child: IconButton.filledTonal(
                      tooltip: 'Hapus foto ${i + 1}',
                      icon: const Icon(LucideIcons.trash2),
                      onPressed: () => _delete(imgs[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
