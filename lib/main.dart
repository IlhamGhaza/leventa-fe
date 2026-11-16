// ignore: deprecated_member_use, shortcut: GetX/plugins still use flutter/material types; migrate to material_ui when they do.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'core/di.dart';
import 'core/widgets/hinge_safe.dart';
import 'features/auth/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  await setupDependencies();
  SessionWatcher(Get.find<AuthController>()).start();
  runApp(const LeventaApp());
}

class LeventaApp extends StatelessWidget {
  const LeventaApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
    title: 'Leventa',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID'), Locale('en')],
    // ignore: deprecated_member_use, same material_ui shortcut as the imports.
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => HingeSafe(child: child!),
    initialRoute: Routes.splash,
    getPages: Routes.pages,
  );
}
