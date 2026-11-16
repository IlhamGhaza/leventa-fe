// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../auth/data/auth_models.dart';
import '../properties/property_detail_screen.dart';
import 'deal_models.dart';
import 'deal_repository.dart';

bool get _isAdmin => Get.find<AuthController>().shell == AppShell.admin;

/// Deals and commissions. Marketing: own records, read-only.
/// Admin: all records plus commission management.
class TransactionsTab extends StatelessWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        bottom: const TabBar(
          tabs: [
            Tab(text: 'Deal & pembatalan'),
            Tab(text: 'Komisi'),
          ],
        ),
      ),
      body: const TabBarView(children: [DealList(), CommissionList()]),
    ),
  );
}

class DealList extends StatelessWidget {
  const DealList({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<DealRepository>();
    return PagedList<Deal>(
      minItemWidth: 420,
      fetch: (page, force) => repo.deals(page: page, force: force),
      empty: EmptyView(
        icon: LucideIcons.handshake,
        title: 'Belum ada deal',
        message: _isAdmin
            ? 'Catat deal atau pembatalan dari halaman detail properti.'
            : 'Laporkan deal ke Admin; Admin yang mencatatnya.',
      ),
      itemBuilder: (context, d) => Card(
        child: ListTile(
          onTap: () => Get.to(() => DealDetail(id: d.id)),
          leading: Icon(
            d.isCancelled ? LucideIcons.ban : LucideIcons.handshake,
            color: d.isCancelled ? context.c.textMuted : context.c.success,
          ),
          title: Text(
            d.propertyName ?? 'Properti',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            d.isCancelled
                ? 'Dibatalkan · ${Fmt.date(d.dealDate)}'
                : '${d.type == 'rent' ? 'Sewa' : 'Jual'} · ${Fmt.date(d.dealDate)}',
          ),
          trailing: d.isCancelled
              ? null
              : Text(Fmt.rupiahCompact(d.price), style: context.t.titleSmall),
        ),
      ),
    );
  }
}

class DealDetail extends StatelessWidget {
  const DealDetail({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail deal')),
    body: AsyncLoader<Deal>(
      load: (force) => Get.find<DealRepository>().deal(id, force: force),
      builder: (context, d, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            Readable(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoTable([
                    ('Hasil', d.isCancelled ? 'Dibatalkan' : 'Deal'),
                    (
                      'Properti',
                      [
                        d.propertyName,
                        d.propertyCode,
                      ].whereType<String>().join(' · '),
                    ),
                    (
                      'Jenis',
                      d.type == null
                          ? null
                          : (d.type == 'rent' ? 'Sewa' : 'Jual'),
                    ),
                    (
                      'Harga final',
                      d.price == null ? null : Fmt.rupiah(d.price),
                    ),
                    ('Pembeli / penyewa', d.buyerName),
                    ('Tanggal', Fmt.date(d.dealDate)),
                    ('Marketing', d.salesName),
                    ('Catatan', d.notes),
                  ]),
                  const SizedBox(height: Gap.m),
                  if (!d.isCancelled)
                    OutlinedButton.icon(
                      onPressed: () => openProperty(d.propertyId),
                      icon: const Icon(LucideIcons.house),
                      label: const Text('Lihat properti'),
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

class CommissionList extends StatefulWidget {
  const CommissionList({super.key});

  @override
  State<CommissionList> createState() => _CommissionListState();
}

class _CommissionListState extends State<CommissionList> {
  String? _status;
  final _list = GlobalKey<PagedListState<Commission>>();

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<DealRepository>();
    return PagedList<Commission>(
      key: _list,
      queryKey: _status,
      minItemWidth: 420,
      fetch: (page, force) =>
          repo.commissions(status: _status, page: page, force: force),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
        child: Wrap(
          spacing: Gap.s,
          children: [
            for (final s in const [null, 'pending', 'paid', 'cancelled'])
              ChoiceChip(
                label: Text(s == null ? 'Semua' : Commission.statusLabel(s)),
                selected: _status == s,
                onSelected: (_) => setState(() => _status = s),
              ),
          ],
        ),
      ),
      empty: const EmptyView(
        icon: LucideIcons.wallet,
        title: 'Belum ada komisi',
        message: 'Komisi dibuat otomatis saat Admin mencatat deal.',
      ),
      itemBuilder: (context, c) => Card(
        child: ListTile(
          onTap: () async {
            await Get.to(() => CommissionDetail(id: c.id));
            if (_isAdmin) {
              await _list.currentState?.refresh(); // may have changed
            }
          },
          title: Text(
            c.deal?.propertyName ?? 'Komisi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            [
              if (_isAdmin && c.salesName != null) c.salesName!,
              '${Fmt.percent(c.percentage)} · ${Fmt.date(c.createdAt)}',
            ].join(' · '),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Fmt.rupiahCompact(c.amount), style: context.t.titleSmall),
              _CommissionStatus(c.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommissionStatus extends StatelessWidget {
  const _CommissionStatus(this.status);
  final String status;

  @override
  Widget build(BuildContext context) => Pill(
    label: Commission.statusLabel(status),
    icon: switch (status) {
      'paid' => LucideIcons.circleCheck,
      'cancelled' => LucideIcons.ban,
      _ => LucideIcons.clock,
    },
    color: switch (status) {
      'paid' => context.c.success,
      'cancelled' => context.c.textMuted,
      _ => context.c.warning,
    },
  );
}

/// Values are shown exactly as returned; Admin changes go to the backend,
/// which recalculates the amount.
class CommissionDetail extends StatelessWidget {
  const CommissionDetail({super.key, required this.id});
  final String id;

  Future<void> _editPercentage(
    BuildContext context,
    Commission c,
    Future<void> Function() reload,
  ) async {
    final ctrl = TextEditingController(text: c.percentage.toString());
    final value = await showDialog<num>(
      context: context,
      builder: (ctx) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Ubah persentase komisi'),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Persentase (0–100)',
                suffixText: '%',
                errorText: error,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  final v = num.tryParse(ctrl.text.replaceAll(',', '.'));
                  if (v == null || v < 0 || v > 100) {
                    return setState(
                      () => error = 'Masukkan angka 0 sampai 100.',
                    );
                  }
                  Navigator.pop(ctx, v);
                },
                child: const Text('Simpan persentase'),
              ),
            ],
          ),
        );
      },
    );
    ctrl.dispose();
    if (value == null || !context.mounted) return;
    final ok = await runAction(
      context,
      () => Get.find<DealRepository>().setCommissionPercentage(c.id, value),
      success: 'Persentase disimpan; nominal dihitung ulang oleh sistem',
    );
    if (ok) await reload();
  }

  Future<void> _setStatus(
    BuildContext context,
    Commission c,
    String status,
    Future<void> Function() reload,
  ) async {
    final label = status == 'paid' ? 'Tandai dibayar' : 'Batalkan komisi';
    if (!await confirm(
      context,
      title: '$label?',
      message: 'Status final tidak dapat diubah lagi.',
      confirmLabel: label,
      destructive: status == 'cancelled',
    )) {
      return;
    }
    if (!context.mounted) return;
    final ok = await runAction(
      context,
      () => Get.find<DealRepository>().setCommissionStatus(c.id, status),
      success: 'Status komisi: ${Commission.statusLabel(status)}',
    );
    if (ok) await reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detail komisi')),
    body: AsyncLoader<Commission>(
      load: (force) => Get.find<DealRepository>().commission(id, force: force),
      builder: (context, c, reload) => RefreshIndicator(
        onRefresh: reload,
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            Readable(
              maxWidth: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    Fmt.rupiah(c.amount),
                    style: context.t.headlineSmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: Gap.xs),
                  Row(children: [_CommissionStatus(c.status)]),
                  const SizedBox(height: Gap.m),
                  InfoTable([
                    ('Persentase', Fmt.percent(c.percentage)),
                    ('Properti', c.deal?.propertyName),
                    (
                      'Harga deal',
                      c.deal?.price == null ? null : Fmt.rupiah(c.deal!.price),
                    ),
                    ('Tanggal deal', Fmt.date(c.deal?.dealDate)),
                    ('Marketing', c.salesName),
                    ('Dibuat', Fmt.date(c.createdAt)),
                  ]),
                  const SizedBox(height: Gap.s),
                  Text(
                    'Nilai komisi ditetapkan oleh sistem.',
                    style: context.t.bodySmall,
                  ),
                  if (_isAdmin && c.isPending) ...[
                    const SizedBox(height: Gap.l),
                    Wrap(
                      spacing: Gap.s,
                      runSpacing: Gap.s,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _editPercentage(context, c, reload),
                          icon: const Icon(LucideIcons.percent),
                          label: const Text('Ubah persentase'),
                        ),
                        FilledButton.icon(
                          onPressed: () =>
                              _setStatus(context, c, 'paid', reload),
                          icon: const Icon(LucideIcons.circleCheck),
                          label: const Text('Tandai dibayar'),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: context.c.danger,
                          ),
                          onPressed: () =>
                              _setStatus(context, c, 'cancelled', reload),
                          icon: const Icon(LucideIcons.ban),
                          label: const Text('Batalkan komisi'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
