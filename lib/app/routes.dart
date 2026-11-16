import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../features/admin/admin_shell.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_screens.dart';
import '../features/auth/data/auth_models.dart';
import '../features/guest/guest_shell.dart';
import '../features/marketing/marketing_shell.dart';

class Routes {
  const Routes._();
  static const splash = '/';
  static const login = '/login';
  static const guest = '/guest';
  static const marketing = '/marketing';
  static const admin = '/admin';
  static const unsupported = '/unsupported';

  static final pages = [
    GetPage(name: splash, page: () => const SplashScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: guest, page: () => const GuestShell()),
    GetPage(
      name: marketing,
      page: () => const MarketingShell(),
      middlewares: [ShellGuard(AppShell.marketing)],
    ),
    GetPage(
      name: admin,
      page: () => const AdminShell(),
      middlewares: [ShellGuard(AppShell.admin)],
    ),
    GetPage(name: unsupported, page: () => const UnsupportedRoleScreen()),
  ];

  static String forShell(AppShell s) => switch (s) {
    AppShell.guest => guest,
    AppShell.marketing => marketing,
    AppShell.admin => admin,
    AppShell.unsupported => unsupported,
  };
}

/// Opens the shell of the current (backend-verified) role, clearing history.
void goHome() =>
    Get.offAllNamed(Routes.forShell(Get.find<AuthController>().shell));

/// UX guard only; the backend is the security boundary.
class ShellGuard extends GetMiddleware {
  ShellGuard(this.shell);
  final AppShell shell;

  @override
  RouteSettings? redirect(String? route) {
    final current = Get.find<AuthController>().shell;
    return current == shell
        ? null
        : RouteSettings(name: Routes.forShell(current));
  }
}

/// Reacts to session changes after start-up: expiry → guest + login,
/// role change → that role's shell; refreshes `/auth/me` on app resume.
class SessionWatcher with WidgetsBindingObserver {
  SessionWatcher(this.auth);
  final AuthController auth;
  final _workers = <Worker>[];

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _workers.add(
      ever<bool>(auth.sessionExpired, (expired) {
        if (!expired) return;
        Get.offAllNamed(Routes.guest);
        Get.toNamed(Routes.login, arguments: 'expired');
      }),
    );
    var last = auth.shell;
    _workers.add(
      ever<AppUser?>(auth.user, (_) {
        final now = auth.shell;
        final settled = auth.status.value == AuthStatus.authenticated;
        if (settled && now != last && Get.currentRoute != Routes.login) {
          goHome();
        }
        last = now;
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) auth.refreshMe();
  }
}
