import 'dart:async';

// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../network/api_exception.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Memuat'});
  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: label,
      child: const Padding(
        padding: EdgeInsets.all(Gap.l),
        child: CircularProgressIndicator(),
      ),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => _Centered(
    icon: icon,
    iconColor: context.c.textMuted,
    title: title,
    message: message,
    children: [?action],
  );
}

/// Every failure state from docs/SCREEN_SPEC.md: offline/timeout, 401, 403,
/// 404, 409, 422, 429 (countdown, no auto retry) and 5xx, with the
/// `X-Request-ID` so support can trace it.
class ErrorView extends StatefulWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;

  @override
  State<ErrorView> createState() => _ErrorViewState();
}

class _ErrorViewState extends State<ErrorView> {
  Timer? _timer;
  int _wait = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(ErrorView old) {
    super.didUpdateWidget(old);
    if (old.error != widget.error) _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    final e = widget.error;
    if (e is ApiException && e.kind == ApiErrorKind.rateLimited) {
      _wait = (e.retryAfter ?? const Duration(seconds: 60)).inSeconds;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return t.cancel();
        setState(() => _wait = _wait > 0 ? _wait - 1 : 0);
        if (_wait == 0) t.cancel();
      });
    } else {
      _wait = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.error;
    final api = e is ApiException ? e : null;
    final (icon, title) = switch (api?.kind) {
      ApiErrorKind.network ||
      ApiErrorKind.timeout => (LucideIcons.wifiOff, 'Tidak ada koneksi'),
      ApiErrorKind.forbidden => (LucideIcons.lock, 'Akses ditolak'),
      ApiErrorKind.notFound => (LucideIcons.searchX, 'Tidak ditemukan'),
      ApiErrorKind.unauthorized => (LucideIcons.logIn, 'Sesi berakhir'),
      ApiErrorKind.rateLimited => (
        LucideIcons.timer,
        'Terlalu banyak permintaan',
      ),
      ApiErrorKind.conflict => (LucideIcons.triangleAlert, 'Konflik data'),
      _ => (LucideIcons.circleAlert, 'Terjadi kesalahan'),
    };
    final message = api?.message ?? 'Terjadi kesalahan yang tidak terduga.';
    final canRetry =
        widget.onRetry != null &&
        api?.kind != ApiErrorKind.forbidden &&
        api?.kind != ApiErrorKind.notFound &&
        api?.kind != ApiErrorKind.unauthorized;
    return _Centered(
      icon: icon,
      iconColor: context.c.danger,
      title: title,
      message: message,
      children: [
        if (api?.kind == ApiErrorKind.unauthorized)
          FilledButton(
            onPressed: () => Get.toNamed('/login'),
            child: const Text('Masuk kembali'),
          ),
        if (canRetry)
          FilledButton.tonal(
            onPressed: _wait > 0 ? null : widget.onRetry,
            child: Text(_wait > 0 ? 'Coba lagi dalam $_wait dtk' : 'Coba lagi'),
          ),
        if (api?.requestId != null) RequestIdText(api!.requestId!),
      ],
    );
  }
}

/// Selectable request id; tapping copies it for support.
class RequestIdText extends StatelessWidget {
  const RequestIdText(this.id, {super.key});
  final String id;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () {
      Clipboard.setData(ClipboardData(text: id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kode permintaan disalin')));
    },
    icon: const Icon(LucideIcons.copy, size: 16),
    label: Text(
      'Kode permintaan: $id',
      style: context.t.bodySmall,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

class _Centered extends StatelessWidget {
  const _Centered({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.children = const [],
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(Gap.l),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: Gap.m),
            Text(
              title,
              style: context.t.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: Gap.s),
              Text(
                message!,
                style: context.t.bodyMedium?.copyWith(
                  color: context.c.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            for (final w in children) ...[const SizedBox(height: Gap.m), w],
          ],
        ),
      ),
    ),
  );
}

/// Shows the result of a write call: success message, or the backend's error
/// (with request id). Returns true on success.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
    if (success != null) {
      messenger.showSnackBar(SnackBar(content: Text(success)));
    }
    return true;
  } on ApiException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(errorText(e))));
    return false;
  }
}

String errorText(ApiException e) {
  final wait = e.kind == ApiErrorKind.rateLimited && e.retryAfter != null
      ? ' Coba lagi dalam ${e.retryAfter!.inSeconds} detik.'
      : '';
  final id = e.requestId == null ? '' : ' (Kode: ${e.requestId})';
  final fields = e.fieldErrors.values.join(', ');
  return '${e.message}${fields.isEmpty ? '' : ': $fields'}.$wait$id'.replaceAll(
    '..',
    '.',
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: ctx.c.danger)
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
