// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../auth/data/auth_models.dart';
import '../deals/deal_repository.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_repository.dart';

/// Admin on a property: team (co-listing, transfer) and outcome
/// (Deal / Cancel). Admin never edits listing content, never sees owner
/// data, exact address or documents (the projection has none).
class AdminListingPanel extends StatelessWidget {
  const AdminListingPanel({super.key, required this.p, required this.reload});
  final InternalProperty p;
  final Future<void> Function() reload;

  static const maxTeam = 3;

  bool get _hasOutcome => const [
    PropertyStatus.sold,
    PropertyStatus.rented,
    PropertyStatus.archived,
  ].contains(p.status);

  Future<void> _team(
    BuildContext context,
    Future<void> Function() call,
    String success,
  ) async {
    final ok = await runAction(context, call, success: success);
    if (ok) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final repo = Get.find<PropertyRepository>();
    final members = p.team.map((m) => m.marketingId).toSet();
    final coCount = p.team.where((m) => !m.isPrimary).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.l),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Gap.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Tim Marketing', style: context.t.titleMedium),
              Text(
                'Maksimal $maxTeam orang termasuk Marketing utama.',
                style: context.t.bodySmall,
              ),
              for (final m in p.team)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Initials(
                    m.name.isEmpty ? '?' : m.name[0].toUpperCase(),
                    size: 36,
                  ),
                  title: Text(m.name),
                  subtitle: Text(
                    '${m.isPrimary ? 'Utama' : 'Co-listing'} · sejak ${Fmt.date(m.assignedAt)}',
                  ),
                  trailing: m.isPrimary
                      ? null
                      : PopupMenuButton<String>(
                          tooltip: 'Kelola ${m.name}',
                          onSelected: (action) async {
                            if (action == 'replace') {
                              final u = await pickMarketing(
                                context,
                                exclude: members,
                              );
                              if (u == null || !context.mounted) return;
                              await _team(
                                context,
                                () => repo.replaceCoListing(
                                  p.id,
                                  m.marketingId,
                                  u.id,
                                ),
                                '${m.name} diganti dengan ${u.name}',
                              );
                            } else if (action == 'remove') {
                              if (!await confirm(
                                context,
                                title: 'Keluarkan ${m.name}?',
                                message:
                                    'Marketing ini tidak lagi menjadi co-listing.',
                                confirmLabel: 'Keluarkan',
                                destructive: true,
                              )) {
                                return;
                              }
                              if (!context.mounted) return;
                              await _team(
                                context,
                                () => repo.removeCoListing(p.id, m.marketingId),
                                '${m.name} dikeluarkan',
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'replace',
                              child: Text('Ganti'),
                            ),
                            PopupMenuItem(
                              value: 'remove',
                              child: Text('Keluarkan'),
                            ),
                          ],
                        ),
                ),
              Wrap(
                spacing: Gap.s,
                runSpacing: Gap.s,
                children: [
                  if (coCount < maxTeam - 1)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final u = await pickMarketing(
                          context,
                          exclude: members,
                        );
                        if (u == null || !context.mounted) return;
                        await _team(
                          context,
                          () => repo.addCoListing(p.id, u.id),
                          '${u.name} ditambahkan sebagai co-listing',
                        );
                      },
                      icon: const Icon(LucideIcons.userPlus),
                      label: const Text('Tambah co-listing'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final primary = p.team
                          .where((m) => m.isPrimary)
                          .map((m) => m.marketingId)
                          .toSet();
                      final u = await pickMarketing(context, exclude: primary);
                      if (u == null || !context.mounted) return;
                      if (!await confirm(
                        context,
                        title: 'Pindahkan Marketing utama ke ${u.name}?',
                        message:
                            'Marketing utama lama menjadi co-listing. Data pemilik ikut berpindah ke Marketing utama baru. Tindakan ini tercatat di audit log.',
                        confirmLabel: 'Pindahkan',
                      )) {
                        return;
                      }
                      if (!context.mounted) return;
                      await _team(
                        context,
                        () => repo.transferOwnership(p.id, u.id),
                        'Marketing utama sekarang ${u.name}',
                      );
                    },
                    icon: const Icon(LucideIcons.arrowLeftRight),
                    label: const Text('Pindahkan utama'),
                  ),
                ],
              ),
              const Divider(height: Gap.xl),
              Text('Hasil properti', style: context.t.titleMedium),
              const SizedBox(height: Gap.xs),
              if (_hasOutcome)
                Text(
                  'Properti ini sudah memiliki hasil (${PropertyStatus.label(p.status)}).',
                  style: context.t.bodySmall,
                )
              else ...[
                Text(
                  'Catat setelah Marketing melaporkan deal atau pembatalan. Satu properti hanya punya satu hasil.',
                  style: context.t.bodySmall,
                ),
                const SizedBox(height: Gap.s),
                Wrap(
                  spacing: Gap.s,
                  runSpacing: Gap.s,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        final ok = await Get.to<bool>(
                          () => DealForm(property: p),
                        );
                        if (ok == true) await reload();
                      },
                      icon: const Icon(LucideIcons.handshake),
                      label: const Text('Catat deal'),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: context.c.danger,
                      ),
                      onPressed: () => _cancel(context),
                      icon: const Icon(LucideIcons.ban),
                      label: const Text('Catat pembatalan'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cancel(BuildContext context) async {
    final notes = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Catat pembatalan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pemilik tidak lagi menjual/menyewakan. Properti diarsipkan dan hilang dari semua daftar. Tidak ada komisi.',
            ),
            const SizedBox(height: Gap.m),
            TextField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ctx.c.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Catat pembatalan'),
          ),
        ],
      ),
    );
    final text = notes.text;
    notes.dispose();
    if (go != true || !context.mounted) return;
    final ok = await runAction(
      context,
      () => Get.find<PropertyRepository>().cancel(p.id, notes: text.trim()),
      success: 'Pembatalan dicatat; properti diarsipkan',
    );
    if (ok) await reload();
  }
}

/// Picks an active Marketing (`sales`) user. The backend re-validates.
Future<AppUser?> pickMarketing(
  BuildContext context, {
  Set<String> exclude = const {},
}) => showModalBottomSheet<AppUser>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (ctx) => SizedBox(
    height: MediaQuery.sizeOf(ctx).height * 0.75,
    child: Column(
      children: [
        Text('Pilih Marketing', style: ctx.t.titleMedium),
        Expanded(
          child: PagedList<AppUser>(
            fetch: (page, force) => Get.find<DealRepository>().users(
              role: UserRole.sales,
              status: 'active',
              page: page,
              force: force,
            ),
            empty: const EmptyView(
              icon: LucideIcons.users,
              title: 'Tidak ada Marketing aktif',
            ),
            itemBuilder: (c, u) {
              final taken = exclude.contains(u.id);
              return ListTile(
                enabled: !taken,
                leading: Initials(u.initials, size: 36),
                title: Text(u.name),
                subtitle: Text(taken ? 'Sudah di tim' : u.email),
                onTap: taken ? null : () => Navigator.pop(c, u),
              );
            },
          ),
        ),
      ],
    ),
  ),
);

/// Admin records a Deal. The backend sets sold/rented and creates the
/// commission; the app calculates nothing.
class DealForm extends StatefulWidget {
  const DealForm({super.key, required this.property});
  final PublicProperty property;

  @override
  State<DealForm> createState() => _DealFormState();
}

class _DealFormState extends State<DealForm> {
  final _form = GlobalKey<FormState>();
  final _price = TextEditingController();
  final _buyer = TextEditingController();
  final _notes = TextEditingController();
  DateTime _date = DateTime.now();
  Map<String, String> _errors = {};
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_price, _buyer, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _errors = {};
    });
    final p = widget.property;
    try {
      await Get.find<PropertyRepository>().recordDeal(
        p.id,
        type: p.transactionType,
        price: num.parse(_price.text.trim()),
        buyerName: _buyer.text.trim(),
        dealDate: Fmt.isoDate(_date),
        notes: _notes.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deal dicatat; properti kini ${p.isRent ? 'tersewa' : 'terjual'}',
          ),
        ),
      );
      Get.back(result: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      final msg = e.kind == ApiErrorKind.conflict
          ? 'Properti ini sudah memiliki hasil (deal atau pembatalan).'
          : errorText(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return Scaffold(
      appBar: AppBar(title: const Text('Catat deal')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            Readable(
              maxWidth: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(p.name, style: context.t.titleMedium),
                  Text(
                    'Jenis: ${TransactionType.label(p.transactionType)} (mengikuti listing)',
                    style: context.t.bodySmall,
                  ),
                  const SizedBox(height: Gap.l),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga final (Rp) *',
                      errorText: _errors['price'],
                    ),
                    validator: (s) => (num.tryParse((s ?? '').trim()) ?? 0) <= 0
                        ? 'Harga harus lebih dari 0.'
                        : null,
                  ),
                  const SizedBox(height: Gap.m),
                  TextFormField(
                    controller: _buyer,
                    decoration: InputDecoration(
                      labelText: p.isRent ? 'Nama penyewa *' : 'Nama pembeli *',
                      errorText: _errors['buyer_name'],
                    ),
                    validator: (s) => (s ?? '').trim().length < 2
                        ? 'Minimal 2 karakter.'
                        : null,
                  ),
                  const SizedBox(height: Gap.m),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _date = d);
                    },
                    icon: const Icon(LucideIcons.calendar),
                    label: Text('Tanggal deal: ${Fmt.date(_date)}'),
                  ),
                  const SizedBox(height: Gap.m),
                  TextFormField(
                    controller: _notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan (opsional)',
                    ),
                  ),
                  const SizedBox(height: Gap.l),
                  Text(
                    'Komisi dibuat otomatis oleh sistem untuk Marketing utama.',
                    style: context.t.bodySmall,
                  ),
                  const SizedBox(height: Gap.m),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_busy ? 'Menyimpan…' : 'Catat deal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
