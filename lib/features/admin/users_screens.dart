// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/format.dart';
import '../../core/utils/throttle.dart';
import '../../core/widgets/async_views.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import '../auth/auth_controller.dart';
import '../auth/data/auth_models.dart';
import '../deals/deal_repository.dart';

DealRepository get _repo => Get.find<DealRepository>();

/// Admin: every account is created here (no self-registration).
class UsersList extends StatefulWidget {
  const UsersList({super.key});

  @override
  State<UsersList> createState() => _UsersListState();
}

class _UsersListState extends State<UsersList> {
  final _debounce = Debouncer();
  final _list = GlobalKey<PagedListState<AppUser>>();
  String _search = '';
  String? _role;

  @override
  void dispose() {
    _debounce.cancel();
    super.dispose();
  }

  Future<void> _open(Widget screen) async {
    final changed = await Get.to<bool>(() => screen);
    if (changed == true) await _list.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pengguna')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _open(const UserForm()),
      icon: const Icon(LucideIcons.userPlus),
      label: const Text('Tambah pengguna'),
    ),
    body: PagedList<AppUser>(
      key: _list,
      queryKey: '$_search|$_role',
      minItemWidth: 420,
      fetch: (page, force) =>
          _repo.users(search: _search, role: _role, page: page, force: force),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(Gap.m, Gap.m, Gap.m, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Cari nama atau email',
                prefixIcon: Icon(LucideIcons.search),
                counterText: '',
              ),
              onChanged: (s) =>
                  _debounce(() => setState(() => _search = s.trim())),
            ),
            const SizedBox(height: Gap.s),
            Wrap(
              spacing: Gap.s,
              children: [
                for (final r in const [null, UserRole.sales, UserRole.admin])
                  ChoiceChip(
                    label: Text(r == null ? 'Semua' : UserRole.label(r)),
                    selected: _role == r,
                    onSelected: (_) => setState(() => _role = r),
                  ),
              ],
            ),
          ],
        ),
      ),
      empty: const EmptyView(
        icon: LucideIcons.users,
        title: 'Tidak ada pengguna',
        message: 'Tambahkan akun Marketing atau Admin.',
      ),
      itemBuilder: (context, u) => Card(
        child: ListTile(
          onTap: () => _open(UserDetail(id: u.id)),
          leading: Initials(u.initials),
          title: Text(u.name),
          subtitle: Text(
            '${UserRole.label(u.role)} · ${u.email}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: u.isActive
              ? null
              : Pill(
                  label: 'Nonaktif',
                  icon: LucideIcons.ban,
                  color: context.c.textMuted,
                ),
        ),
      ),
    ),
  );
}

class UserDetail extends StatefulWidget {
  const UserDetail({super.key, required this.id});
  final String id;

  @override
  State<UserDetail> createState() => _UserDetailState();
}

class _UserDetailState extends State<UserDetail> {
  bool _changed = false;

  Future<void> _act(
    Future<void> Function() call,
    String success,
    Future<void> Function() reload,
  ) async {
    final ok = await runAction(context, call, success: success);
    if (ok) {
      _changed = true;
      await reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = Get.find<AuthController>().user.value?.id;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Get.back(result: _changed);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail pengguna')),
        body: AsyncLoader<AppUser>(
          load: (force) => _repo.user(widget.id, force: force),
          builder: (context, u, reload) {
            final self = u.id == selfId;
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.all(Gap.m),
                children: [
                  Readable(
                    maxWidth: 640,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Initials(u.initials, size: 56),
                            const SizedBox(width: Gap.m),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(u.name, style: context.t.titleLarge),
                                  Text(
                                    UserRole.label(u.role),
                                    style: context.t.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Gap.m),
                        InfoTable([
                          ('Email', u.email),
                          ('Telepon', u.phone),
                          ('WhatsApp', u.whatsappNumber ?? 'Belum diisi'),
                          ('Status', u.isActive ? 'Aktif' : 'Nonaktif'),
                          ('Dibuat', Fmt.date(u.createdAt)),
                        ]),
                        const SizedBox(height: Gap.l),
                        Wrap(
                          spacing: Gap.s,
                          runSpacing: Gap.s,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                final saved = await Get.to<bool>(
                                  () => UserForm(existing: u),
                                );
                                if (saved == true) {
                                  _changed = true;
                                  await reload();
                                }
                              },
                              icon: const Icon(LucideIcons.pencil),
                              label: const Text('Edit'),
                            ),
                            if (!self) ...[
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final next = u.isActive
                                      ? 'inactive'
                                      : 'active';
                                  if (u.isActive &&
                                      !await confirm(
                                        context,
                                        title: 'Nonaktifkan ${u.name}?',
                                        message:
                                            'Pengguna tidak bisa masuk sampai diaktifkan lagi. Berlaku segera.',
                                        confirmLabel: 'Nonaktifkan',
                                        destructive: true,
                                      )) {
                                    return;
                                  }
                                  await _act(
                                    () => _repo.setUserStatus(u.id, next),
                                    u.isActive
                                        ? 'Pengguna dinonaktifkan'
                                        : 'Pengguna diaktifkan',
                                    reload,
                                  );
                                },
                                icon: Icon(
                                  u.isActive
                                      ? LucideIcons.userX
                                      : LucideIcons.userCheck,
                                ),
                                label: Text(
                                  u.isActive ? 'Nonaktifkan' : 'Aktifkan',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final next = u.role == UserRole.admin
                                      ? UserRole.sales
                                      : UserRole.admin;
                                  if (!await confirm(
                                    context,
                                    title:
                                        'Ubah peran menjadi ${UserRole.label(next)}?',
                                    message: 'Akses pengguna berubah segera.',
                                    confirmLabel: 'Ubah peran',
                                  )) {
                                    return;
                                  }
                                  await _act(
                                    () => _repo.setUserRole(u.id, next),
                                    'Peran diubah menjadi ${UserRole.label(next)}',
                                    reload,
                                  );
                                },
                                icon: const Icon(LucideIcons.shieldCheck),
                                label: Text(
                                  'Jadikan ${UserRole.label(u.role == UserRole.admin ? UserRole.sales : UserRole.admin)}',
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: context.c.danger,
                                ),
                                onPressed: () async {
                                  if (!await confirm(
                                    context,
                                    title: 'Hapus ${u.name}?',
                                    message:
                                        'Akun dihapus (soft delete) dan tidak bisa masuk lagi.',
                                    confirmLabel: 'Hapus',
                                    destructive: true,
                                  )) {
                                    return;
                                  }
                                  if (!context.mounted) return;
                                  final ok = await runAction(
                                    context,
                                    () => _repo.deleteUser(u.id),
                                    success: 'Pengguna dihapus',
                                  );
                                  if (ok) Get.back(result: true);
                                },
                                icon: const Icon(LucideIcons.trash2),
                                label: const Text('Hapus'),
                              ),
                            ],
                          ],
                        ),
                        if (self)
                          Padding(
                            padding: const EdgeInsets.only(top: Gap.s),
                            child: Text(
                              'Anda tidak dapat mengubah peran atau status akun sendiri.',
                              style: context.t.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Add (Admin creates every account) or edit a user.
class UserForm extends StatefulWidget {
  const UserForm({super.key, this.existing});
  final AppUser? existing;

  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _email = TextEditingController(text: widget.existing?.email);
  late final _phone = TextEditingController(text: widget.existing?.phone);
  late final _wa = TextEditingController(text: widget.existing?.whatsappNumber);
  final _password = TextEditingController();
  String _role = UserRole.sales;
  Map<String, String> _errors = {};
  bool _busy = false;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _wa, _password]) {
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
    try {
      if (_isEdit) {
        await _repo.updateUser(
          widget.existing!.id,
          name: _name.text,
          email: _email.text,
          phone: _phone.text,
          whatsappNumber: _wa.text,
        );
      } else {
        await _repo.createUser(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          role: _role,
          phone: _phone.text,
          whatsappNumber: _wa.text,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Pengguna disimpan' : 'Akun dibuat')),
      );
      Get.back(result: true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _errors = e.fieldErrors);
      final msg = e.kind == ApiErrorKind.conflict
          ? 'Email sudah dipakai akun lain.'
          : errorText(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEdit ? 'Edit pengguna' : 'Tambah pengguna')),
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
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Nama *',
                    errorText: _errors['name'],
                  ),
                  validator: (s) => (s ?? '').trim().length < 2
                      ? 'Nama minimal 2 karakter.'
                      : null,
                ),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email *',
                    errorText: _errors['email'],
                  ),
                  validator: (s) =>
                      RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch((s ?? '').trim())
                      ? null
                      : 'Format email tidak valid.',
                ),
                const SizedBox(height: Gap.m),
                if (!_isEdit) ...[
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Kata sandi awal *',
                      helperText:
                          'Aturan kekuatan kata sandi dicek oleh server.',
                      errorText: _errors['password'],
                    ),
                    validator: (s) =>
                        (s ?? '').length < 8 ? 'Minimal 8 karakter.' : null,
                  ),
                  const SizedBox(height: Gap.m),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: UserRole.sales,
                        label: Text('Marketing'),
                        icon: Icon(LucideIcons.briefcaseBusiness),
                      ),
                      ButtonSegment(
                        value: UserRole.admin,
                        label: Text('Admin'),
                        icon: Icon(LucideIcons.shieldCheck),
                      ),
                    ],
                    selected: {_role},
                    onSelectionChanged: (s) => setState(() => _role = s.first),
                  ),
                  const SizedBox(height: Gap.m),
                ],
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Telepon',
                    errorText: _errors['phone'],
                  ),
                ),
                const SizedBox(height: Gap.m),
                TextFormField(
                  controller: _wa,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Nomor WhatsApp',
                    helperText:
                        'Kontak publik di listing. Dinormalisasi ke format 62.',
                    errorText: _errors['whatsapp_number'],
                  ),
                ),
                const SizedBox(height: Gap.l),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: Text(
                    _busy
                        ? 'Menyimpan…'
                        : (_isEdit ? 'Simpan pengguna' : 'Buat akun'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
