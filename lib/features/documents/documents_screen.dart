// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/pick.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../properties/data/property_models.dart';
import 'document_repository.dart';
import 'document_rules.dart';

/// Ownership documents (D-029). Primary: upload/replace/delete/download.
/// Co-listing: view/download only. Never cached; downloads are deleted
/// after sharing.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key, required this.property});
  final PrimaryProperty property;

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final repo = Get.find<DocumentRepository>();
  final _loader = GlobalKey<AsyncLoaderState<List<OwnershipDocument>>>();
  String? _busyType;

  PrimaryProperty get p => widget.property;

  Future<void> _upload(String type) async {
    final messenger = ScaffoldMessenger.of(context);
    PickedFile? f;
    try {
      f = await pickOwnershipDocument();
    } on PickError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Akses file ditolak. Izinkan akses di pengaturan perangkat.',
          ),
        ),
      );
      return;
    }
    if (f == null || !mounted) return;
    final picked = f;
    setState(() => _busyType = type);
    final ok = await runAction(
      context,
      () => repo.upload(
        p.id,
        docType: type,
        filePath: picked.path,
        fileName: picked.name,
      ),
      success: '${DocumentRules.label(type)} diunggah',
    );
    if (mounted) setState(() => _busyType = null);
    if (ok) await _loader.currentState?.reload();
  }

  Future<void> _share(OwnershipDocument d) async {
    setState(() => _busyType = d.docType);
    await runAction(context, () async {
      final file = await repo.download(p.id, d);
      try {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: d.mimeType)]),
        );
      } finally {
        await repo.discard(file);
      }
    });
    if (mounted) setState(() => _busyType = null);
  }

  Future<void> _delete(OwnershipDocument d) async {
    if (!await confirm(
      context,
      title: 'Hapus ${DocumentRules.label(d.docType)}?',
      message: 'Dokumen akan dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
    )) {
      return;
    }
    if (!mounted) return;
    final ok = await runAction(
      context,
      () => repo.delete(p.id, d.id),
      success: 'Dokumen dihapus',
    );
    if (ok) await _loader.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dokumen kepemilikan')),
    body: AsyncLoader<List<OwnershipDocument>>(
      key: _loader,
      load: (_) => repo.list(p.id),
      builder: (context, docs, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            Readable(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    p.isPrimary
                        ? 'PDF, JPEG, atau PNG, maksimal 5 MB. Satu dokumen per jenis; unggah ulang mengganti dokumen lama.'
                        : 'Anda co-listing: dokumen hanya dapat dilihat dan diunduh.',
                    style: context.t.bodySmall,
                  ),
                  const SizedBox(height: Gap.m),
                  for (final type in DocumentRules.typesFor(p.type))
                    _row(
                      type,
                      docs.where((d) => d.docType == type).firstOrNull,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _row(String type, OwnershipDocument? doc) {
    final flag = p.details.cert(type);
    final busy = _busyType == type;
    final canUpload = p.isPrimary && DocumentRules.canUpload(p, type);
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.s),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    doc == null ? LucideIcons.file : LucideIcons.fileCheck,
                    color: doc == null
                        ? context.c.textMuted
                        : context.c.success,
                  ),
                  const SizedBox(width: Gap.s),
                  Expanded(
                    child: Text(
                      DocumentRules.label(type),
                      style: context.t.titleMedium,
                    ),
                  ),
                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: Gap.xs),
              if (doc != null)
                Text(
                  '${doc.originalName} · ${(doc.sizeBytes / 1024).ceil()} KB · ${Fmt.date(doc.createdAt)}',
                  style: context.t.bodySmall,
                )
              else if (!flag)
                Text(
                  'Belum dicentang di listing.${p.isPrimary ? ' Aktifkan centang ${DocumentRules.label(type)} di Edit listing untuk mengunggah.' : ''}',
                  style: context.t.bodySmall,
                )
              else
                Text('Belum diunggah.', style: context.t.bodySmall),
              const SizedBox(height: Gap.s),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  if (doc != null)
                    OutlinedButton.icon(
                      onPressed: busy ? null : () => _share(doc),
                      icon: const Icon(LucideIcons.share2),
                      label: const Text('Unduh / bagikan'),
                    ),
                  if (canUpload)
                    FilledButton.tonalIcon(
                      onPressed: busy ? null : () => _upload(type),
                      icon: const Icon(LucideIcons.upload),
                      label: Text(doc == null ? 'Unggah' : 'Ganti'),
                    ),
                  if (doc != null && p.isPrimary)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: context.c.danger,
                      ),
                      onPressed: busy ? null : () => _delete(doc),
                      icon: const Icon(LucideIcons.trash2),
                      label: const Text('Hapus'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
