// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/routes.dart';
import '../../app/theme.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/state_views.dart';
import 'auth_controller.dart';
import 'data/auth_models.dart';

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 32});
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    'Leventa',
    semanticsLabel: 'Leventa',
    style: TextStyle(
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -size * 0.04,
      color: context.c.primary,
    ),
  );
}

/// Restores the session from secure storage, then opens the right shell.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final auth = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    await auth.restore();
    if (auth.status.value != AuthStatus.restoreFailed) goHome();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Obx(() {
        final failed = auth.status.value == AuthStatus.restoreFailed;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Wordmark(size: 40),
            const SizedBox(height: Gap.l),
            if (!failed)
              const LoadingView(label: 'Memulihkan sesi')
            else ...[
              SizedBox(
                height: 320,
                child: ErrorView(error: auth.restoreError!, onRetry: _restore),
              ),
              TextButton(
                onPressed: () {
                  auth.continueAsGuest();
                  goHome();
                },
                child: const Text('Lanjut sebagai tamu'),
              ),
            ],
          ],
        );
      }),
    ),
  );
}

/// Email + password only. No role selector, no registration.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final auth = Get.find<AuthController>();
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _hide = true;
  bool _busy = false;
  String? _error;
  String? _requestId;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _requestId = null;
    });
    try {
      await auth.login(_email.text, _password.text);
      goHome();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _requestId = e.requestId;
        _error = switch (e.kind) {
          ApiErrorKind.unauthorized => 'Email atau kata sandi salah.',
          ApiErrorKind.forbidden => 'Akun Anda tidak aktif. Hubungi Admin.',
          ApiErrorKind.rateLimited =>
            'Terlalu banyak percobaan. Coba lagi dalam ${e.retryAfter?.inSeconds ?? 60} detik.',
          ApiErrorKind.validation => e.fieldErrors.values.join(', '),
          _ => e.message,
        };
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = Get.arguments == 'expired';
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Gap.l),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Wordmark(),
                      const SizedBox(height: Gap.s),
                      Text(
                        'Masuk untuk tim Marketing dan Admin',
                        style: context.t.titleMedium,
                      ),
                      const SizedBox(height: Gap.xs),
                      Text(
                        'Akun dibuat oleh Admin. Pengunjung dapat menjelajah listing tanpa masuk.',
                        style: context.t.bodySmall,
                      ),
                      if (expired) ...[
                        const SizedBox(height: Gap.m),
                        Pill(
                          label: 'Sesi berakhir. Silakan masuk kembali.',
                          icon: LucideIcons.info,
                          color: context.c.warning,
                        ),
                      ],
                      const SizedBox(height: Gap.l),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) {
                          final s = v?.trim() ?? '';
                          if (s.isEmpty) return 'Email wajib diisi.';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(s)) {
                            return 'Format email tidak valid.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: Gap.m),
                      TextFormField(
                        controller: _password,
                        obscureText: _hide,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Kata sandi',
                          suffixIcon: IconButton(
                            tooltip: _hide
                                ? 'Tampilkan kata sandi'
                                : 'Sembunyikan kata sandi',
                            icon: Icon(
                              _hide ? LucideIcons.eye : LucideIcons.eyeOff,
                            ),
                            onPressed: () => setState(() => _hide = !_hide),
                          ),
                        ),
                        validator: (v) => (v ?? '').isEmpty
                            ? 'Kata sandi wajib diisi.'
                            : null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: Gap.m),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _error!,
                            style: context.t.bodyMedium?.copyWith(
                              color: context.c.danger,
                            ),
                          ),
                        ),
                        if (_requestId != null) RequestIdText(_requestId!),
                      ],
                      const SizedBox(height: Gap.l),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        child: _busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Masuk'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Own profile: read-only identity, editable own WhatsApp number (D-033).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final auth = Get.find<AuthController>();
  late final _wa = TextEditingController(
    text: auth.user.value?.whatsappNumber ?? '',
  );
  bool _busy = false;
  String? _fieldError;

  @override
  void dispose() {
    _wa.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _fieldError = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final u = await auth.updateWhatsApp(_wa.text);
      _wa.text = u.whatsappNumber ?? '';
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            u.whatsappNumber == null
                ? 'Nomor WhatsApp dihapus'
                : 'Nomor WhatsApp disimpan: ${u.whatsappNumber}',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.validation) {
        setState(
          () => _fieldError =
              e.fieldErrors['whatsapp_number'] ?? 'Nomor WhatsApp tidak valid.',
        );
      } else {
        messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil')),
    body: Obx(() {
      final u = auth.user.value;
      if (u == null) return const LoadingView();
      return RefreshIndicator(
        onRefresh: auth.refreshMe,
        child: ListView(
          padding: const EdgeInsets.all(Gap.m),
          children: [
            Readable(
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
                  const SizedBox(height: Gap.l),
                  InfoTable([
                    ('Email', u.email),
                    ('Telepon', u.phone),
                    ('Peran', UserRole.label(u.role)),
                  ]),
                  const SizedBox(height: Gap.s),
                  Text(
                    'Nama, email, dan peran dikelola oleh Admin.',
                    style: context.t.bodySmall,
                  ),
                  const SizedBox(height: Gap.l),
                  SectionBlock(
                    title: 'Nomor WhatsApp',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Nomor ini menjadi kontak publik di setiap listing tempat Anda Marketing utama. Kosongkan untuk menghapus.',
                          style: context.t.bodySmall,
                        ),
                        const SizedBox(height: Gap.s),
                        TextField(
                          controller: _wa,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Nomor WhatsApp',
                            hintText: '0812-3456-7890',
                            errorText: _fieldError,
                          ),
                        ),
                        const SizedBox(height: Gap.s),
                        FilledButton(
                          onPressed: _busy ? null : _save,
                          child: Text(_busy ? 'Menyimpan…' : 'Simpan nomor'),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await confirm(
                        context,
                        title: 'Keluar?',
                        message: 'Data sesi di perangkat ini akan dihapus.',
                        confirmLabel: 'Keluar',
                      )) {
                        await auth.logout();
                        goHome();
                      }
                    },
                    icon: const Icon(LucideIcons.logOut),
                    label: const Text('Keluar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }),
  );
}

class UnsupportedRoleScreen extends StatelessWidget {
  const UnsupportedRoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: EmptyView(
          icon: LucideIcons.shieldOff,
          title: 'Peran akun tidak didukung',
          message:
              'Akun ini tidak dapat digunakan di aplikasi Leventa. Hubungi Admin.',
          action: FilledButton(
            onPressed: () async {
              await auth.logout();
              goHome();
            },
            child: const Text('Keluar'),
          ),
        ),
      ),
    );
  }
}
