import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/app_controller.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/customer/customer_main_screen.dart';
import 'screens/customer/customer_detail_screen.dart';
import 'screens/customer/customer_inquiries_screen.dart';
import 'screens/sales/sales_main_screen.dart';
import 'screens/sales/sales_lead_detail_screen.dart';
import 'widgets/responsive_layout.dart';

void main() {
  Get.put(AppController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'PropManager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.blueGrey.shade900,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(name: '/splash', page: () => const ResponsiveLayout(mobile: SplashScreen())),
        GetPage(name: '/onboarding', page: () => const ResponsiveLayout(mobile: OnboardingScreen())),
        GetPage(name: '/login', page: () => const ResponsiveLayout(mobile: LoginScreen())),
        GetPage(name: '/customer', page: () => const CustomerMainScreen()),
        GetPage(name: '/customer_detail', page: () => const ResponsiveLayout(mobile: CustomerDetailScreen())),
        GetPage(name: '/customer_inquiries', page: () => const ResponsiveLayout(mobile: CustomerInquiriesScreen())),
        GetPage(name: '/sales', page: () => const SalesMainScreen()),
        GetPage(name: '/sales_lead_detail', page: () => const ResponsiveLayout(mobile: SalesLeadDetailScreen())),
      ],
    );
  }
}
