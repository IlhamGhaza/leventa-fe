import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../controllers/app_controller.dart';
import '../../widgets/responsive_layout.dart';
import 'customer_home_screen.dart';
import 'customer_search_screen.dart';
import 'customer_favorites_screen.dart';
import 'customer_notifications_screen.dart';
import 'customer_profile_screen.dart';

class CustomerMainScreen extends StatelessWidget {
  const CustomerMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController appCtrl = Get.find<AppController>();

    final screens = {
      'home': const CustomerHomeScreen(),
      'search': const CustomerSearchScreen(),
      'favorites': const CustomerFavoritesScreen(),
      'notifications': const CustomerNotificationsScreen(),
      'profile': const CustomerProfileScreen(),
    };

    final items = [
      {'id': 'home', 'icon': LucideIcons.home, 'label': 'Beranda'},
      {'id': 'search', 'icon': LucideIcons.search, 'label': 'Cari'},
      {'id': 'favorites', 'icon': LucideIcons.heart, 'label': 'Favorit'},
      {'id': 'notifications', 'icon': LucideIcons.bell, 'label': 'Notifikasi'},
      {'id': 'profile', 'icon': LucideIcons.user, 'label': 'Profil'},
    ];

    Widget buildBottomNav() {
      return Obx(() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: items.map((item) {
            final id = item['id'] as String;
            final isActive = appCtrl.customerTab.value == id;
            return Expanded(
              child: GestureDetector(
                onTap: () => appCtrl.customerTab.value = id,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item['icon'] as IconData, size: 20, color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade400),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isActive ? const Color(0xFF2563EB) : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ));
    }

    return ResponsiveLayout(
      mobile: Scaffold(
        body: Obx(() => screens[appCtrl.customerTab.value] ?? const SizedBox.shrink()),
        bottomNavigationBar: buildBottomNav(),
      ),
    );
  }
}
