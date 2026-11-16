// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/state_views.dart';
import '../master_data/master_data_repository.dart';
import '../properties/data/property_models.dart';

MasterDataRepository get _repo => Get.find<MasterDataRepository>();

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Master data'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Wilayah'),
            Tab(text: 'Fasilitas'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _NamedList(kind: 'provinces', title: 'Provinsi', childKind: 'cities'),
          const _NamedList(kind: 'facilities', title: 'Fasilitas'),
        ],
      ),
    ),
  );
}

/// One level of master data with add / rename / delete (409 while used).
class _NamedList extends StatefulWidget {
  const _NamedList({
    required this.kind,
    required this.title,
    this.parentId,
    this.childKind,
  });
  final String kind;
  final String title;
  final String? parentId;
  final String? childKind;

  @override
  State<_NamedList> createState() => _NamedListState();
}

class _NamedListState extends State<_NamedList> {
  final _loader = GlobalKey<AsyncLoaderState<List<NamedRef>>>();

  Future<List<NamedRef>> _load(bool force) => switch (widget.kind) {
    'provinces' => _repo.provinces(force: force),
    'cities' => _repo.cities(widget.parentId, force: force),
    'districts' => _repo.districts(widget.parentId, force: force),
    _ => _repo.facilities(force: force),
  };

  Future<String?> _askName(String title, [String initial = '']) {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().length >= 2) {
                Navigator.pop(ctx, ctrl.text.trim());
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).whenComplete(ctrl.dispose);
  }

  Future<void> _run(Future<void> Function() call, String success) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await call();
      messenger.showSnackBar(SnackBar(content: Text(success)));
      await _loader.currentState?.reload();
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.kind == ApiErrorKind.conflict
                ? 'Tidak bisa: data masih dipakai atau nama sudah ada.'
                : errorText(e),
          ),
        ),
      );
    }
  }

  String? get _childTitle => switch (widget.childKind) {
    'cities' => 'Kota/Kabupaten',
    'districts' => 'Kecamatan',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final body = AsyncLoader<List<NamedRef>>(
      key: _loader,
      load: _load,
      builder: (context, items, reload) => RefreshIndicator(
        onRefresh: reload,
        child: items.isEmpty
            ? ListView(
                children: [
                  EmptyView(
                    icon: LucideIcons.list,
                    title: 'Belum ada ${widget.title.toLowerCase()}',
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 96),
                itemCount: items.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (_, i) {
                  final it = items[i];
                  return ListTile(
                    title: Text(it.name),
                    onTap: widget.childKind == null
                        ? null
                        : () => Get.to(
                            () => Scaffold(
                              appBar: AppBar(
                                title: Text('$_childTitle — ${it.name}'),
                              ),
                              body: _NamedList(
                                kind: widget.childKind!,
                                title: _childTitle!,
                                parentId: it.id,
                                childKind: widget.childKind == 'cities'
                                    ? 'districts'
                                    : null,
                              ),
                            ),
                          ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Kelola ${it.name}',
                      onSelected: (a) async {
                        if (a == 'rename') {
                          final name = await _askName('Ubah nama', it.name);
                          if (name != null) {
                            await _run(
                              () => _repo.rename(widget.kind, it.id, name),
                              'Nama diubah',
                            );
                          }
                        } else {
                          if (!await confirm(
                            context,
                            title: 'Hapus ${it.name}?',
                            message:
                                'Tidak bisa dihapus jika masih dipakai listing.',
                            confirmLabel: 'Hapus',
                            destructive: true,
                          )) {
                            return;
                          }
                          await _run(
                            () => _repo.delete(widget.kind, it.id),
                            'Dihapus',
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text('Ubah nama'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: '${widget.kind}-${widget.parentId}',
        onPressed: () async {
          final name = await _askName('Tambah ${widget.title.toLowerCase()}');
          if (name != null) {
            await _run(
              () => _repo.create(widget.kind, name, parentId: widget.parentId),
              '${widget.title} ditambahkan',
            );
          }
        },
        icon: const Icon(LucideIcons.plus),
        label: Text('Tambah ${widget.title.toLowerCase()}'),
      ),
      body: body,
    );
  }
}
