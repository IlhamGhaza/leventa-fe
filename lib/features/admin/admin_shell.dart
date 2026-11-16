// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_screens.dart';
import '../deals/deal_models.dart';
import '../deals/deal_repository.dart';
import '../deals/transactions_screens.dart';
import '../guest/guest_shell.dart';
import '../properties/data/property_models.dart';
import '../properties/data/property_query.dart';
import 'master_data_screen.dart';
import 'users_screens.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) => AppShell(
    tabs: [
      ShellTab('Properti', LucideIcons.house, (_) => const AdminProperties()),
      ShellTab('Pengguna', LucideIcons.users, (_) => const UsersList()),
      ShellTab('Transaksi', LucideIcons.wallet, (_) => const TransactionsTab()),
      ShellTab('Lainnya', LucideIcons.ellipsis, (_) => const AdminMore()),
    ],
  );
}

class AdminProperties extends StatefulWidget {
  const AdminProperties({super.key});

  @override
  State<AdminProperties> createState() => _AdminPropertiesState();
}

class _AdminPropertiesState extends State<AdminProperties> {
  String? _status;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Semua properti')),
    body: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Gap.m),
          child: Row(
            children: [
              for (final s in const [
                null,
                PropertyStatus.available,
                PropertyStatus.reserved,
                PropertyStatus.draft,
                PropertyStatus.maintenance,
                PropertyStatus.sold,
                PropertyStatus.rented,
                PropertyStatus.archived,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: Gap.s),
                  child: ChoiceChip(
                    label: Text(s == null ? 'Semua' : PropertyStatus.label(s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: PropertySearch(
            key: ValueKey(_status),
            initial: PropertyQuery(status: _status),
            showStatus: true,
          ),
        ),
      ],
    ),
  );
}

class AdminMore extends StatelessWidget {
  const AdminMore({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lainnya')),
    body: ListView(
      padding: const EdgeInsets.all(Gap.m),
      children: [
        Readable(
          maxWidth: 640,
          child: Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(LucideIcons.scrollText),
                  title: const Text('Audit log'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Get.to(() => const AuditLogScreen()),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.mapPinned),
                  title: const Text('Master data'),
                  subtitle: const Text('Provinsi, kota, kecamatan, fasilitas'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Get.to(() => const MasterDataScreen()),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(LucideIcons.circleUser),
                  title: const Text('Profil'),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Get.to(() => const ProfileScreen()),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _module = TextEditingController();
  String? _filter;

  @override
  void dispose() {
    _module.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Audit log')),
    body: PagedList<AuditLog>(
      queryKey: _filter,
      fetch: (page, force) => Get.find<DealRepository>().auditLogs(
        module: _filter,
        page: page,
        force: force,
      ),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
        child: TextField(
          controller: _module,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            labelText: 'Filter modul',
            hintText: 'Contoh: property',
            prefixIcon: Icon(LucideIcons.funnel),
          ),
          onSubmitted: (s) =>
              setState(() => _filter = s.trim().isEmpty ? null : s.trim()),
        ),
      ),
      empty: const EmptyView(
        icon: LucideIcons.scrollText,
        title: 'Belum ada catatan audit',
      ),
      itemBuilder: (context, l) => Card(
        child: ListTile(
          title: Text('${l.module} · ${l.action}'),
          subtitle: Text(
            [
              l.userName ?? 'Sistem',
              Fmt.dateTime(l.createdAt),
              ?l.ipAddress,
            ].join(' · '),
          ),
        ),
      ),
    ),
  );
}
